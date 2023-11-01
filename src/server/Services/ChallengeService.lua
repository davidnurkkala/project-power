local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local Comm = require(ReplicatedStorage.Packages.Comm)
local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

local ChallengeModuleFolder = ReplicatedStorage.Shared.Data.Challenges
local Challenges = Sift.Dictionary.map(ChallengeModuleFolder:GetChildren(), function(module)
	return require(module), module.Name
end)

local DAY = 24 * 60 * 60

local DATA_KEY = "Challenges"
local DEFAULT_DATA = {
	challenges = {},
}

type UnixTimestamp = number
type Challenge = {
	metadata: {
		challengeId: string,
		created: UnixTimestamp,
		completed: boolean,
	},
	challenge: any,
}
type Data = {
	challenges: { Challenge },
}

DataStore2.Combine(Configuration.DataStoreKey, DATA_KEY)

local ChallengeService = {}
ChallengeService.className = "ChallengeService"
ChallengeService.priority = 0

local challengeListsByPlayer: { [Player]: { Challenge } } = {}

function ChallengeService:_savePlayer(player: Player)
	return Promise.try(function()
		local list = challengeListsByPlayer[player]
		if not challengeListsByPlayer[player] then return end

		local store = DataStore2(DATA_KEY, player)
		store:Set({
			challenges = Sift.Array.map(list, function(challenge)
				local builder = Challenges[challenge.metadata.challengeId]
				if not builder then return end

				local data = {
					metadata = Sift.Dictionary.copyDeep(challenge.metadata),
					challenge = builder.save(challenge.challenge),
				}

				return data
			end),
		})

		self._stateRemote:SetFor(player, {
			timestamp = list[1].metadata.created + DAY,
			descriptions = Sift.Array.map(list, function(challenge)
				local builder = Challenges[challenge.metadata.challengeId]
				if not builder then return end

				return {
					description = builder.getDescription(player, builder.save(challenge.challenge)),
					completed = challenge.metadata.completed,
				}
			end),
		})
	end)
end

function ChallengeService:_saveAll()
	for _, player in Players:GetPlayers() do
		self:_savePlayer(player)
	end
end

function ChallengeService:init()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "ChallengeService")
	self._stateRemote = self._comm:CreateProperty("State", nil)
	self._completed = self._comm:CreateSignal("Completed")
end

function ChallengeService:rerollPlayer(player: Player)
	self:_initPlayer(player, DEFAULT_DATA)
end

function ChallengeService:_initPlayer(player: Player, data: Data)
	local now = DateTime.now().UnixTimestamp

	local challengeSaves = Sift.Array.filter(data.challenges, function(challenge)
		if not Challenges[challenge.metadata.challengeId] then return false end

		local duration = now - challenge.metadata.created
		return duration < DAY
	end)

	local challengeList = {}

	for index = 1, Configuration.DailyChallenges.Count do
		local save = challengeSaves[index]
		if save then
			local builder = Challenges[save.metadata.challengeId]
			local challenge = {
				metadata = Sift.Dictionary.copyDeep(save.metadata),
				challenge = builder.load(player, save.challenge),
			}
			table.insert(challengeList, challenge)
		else
			local challenge
			repeat
				local challengeId = pickRandom(Sift.Dictionary.keys(Challenges))
				local builder = Challenges[challengeId]
				challenge = {
					metadata = {
						created = now,
						challengeId = challengeId,
						completed = false,
					},
					challenge = builder.new(player),
				}

				local hash = builder.getHash(challenge.challenge)
				local hashExists = Sift.Array.some(challengeList, function(existingChallenge)
					local existingBuilder = Challenges[existingChallenge.metadata.challengeId]
					local existingHash = existingBuilder.getHash(existingChallenge.challenge)
					return existingHash == hash
				end)
			until not hashExists

			table.insert(challengeList, challenge)
		end
	end

	for _, challenge in challengeList do
		if challenge.metadata.completed then continue end

		Badger.start(Badger.onCompleted(challenge.challenge.condition, function(condition)
			challenge.metadata.completed = true

			local reward = Configuration.DailyChallenges.Reward
			self._completed:Fire(player, reward)
			CurrencyService:addCurrency(player, reward.Currency, reward.Amount)
			Badger.stop(condition)
		end))
	end

	challengeListsByPlayer[player] = challengeList
end

function ChallengeService:start()
	local function onPlayerAdded(player)
		local store = DataStore2(DATA_KEY, player)
		store:GetAsync(DEFAULT_DATA):andThen(function(data: Data)
			self:_initPlayer(player, data)
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	local function onPlayerRemoved(player)
		self:_savePlayer(player):andThen(function()
			if not challengeListsByPlayer[player] then return end

			for _, challenge in challengeListsByPlayer[player] do
				Badger.stop(challenge.challenge.condition)
			end
			challengeListsByPlayer[player] = nil
			self._stateRemote:ClearFor(player)
		end)
	end
	Players.PlayerRemoving:Connect(onPlayerRemoved)

	task.spawn(function()
		while true do
			task.wait(1)
			self:_saveAll()
		end
	end)
end

return Loader:registerSingleton(ChallengeService)
