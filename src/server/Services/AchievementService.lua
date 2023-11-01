local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BadgeDefinitions = require(ReplicatedStorage.Shared.Data.BadgeDefinitions)
local Comm = require(ReplicatedStorage.Packages.Comm)
local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local DataCrunchService = require(ServerScriptService.Server.Services.DataCrunchService)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Sift = require(ReplicatedStorage.Packages.Sift)

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local Loader = require(ReplicatedStorage.Shared.Loader)

-- constants
local DS2_KEY = "Badges"
local DEFAULT_BADGES = {}

type Badge = {
	awarded: boolean,
	condition: any,
}

type Data = { [BadgeDefinitions.BadgeId]: Badge }

DataStore2.Combine(Configuration.DataStoreKey, DS2_KEY)

local AchievementService = {}
AchievementService.className = "AchievementService"
AchievementService.priority = 0

function AchievementService:_awardBadge(player, def: BadgeDefinitions.BadgeDefinition)
	if def.badgeId then BadgeService:AwardBadge(player.UserId, def.badgeId) end
	DataCrunchService:custom(player, `achievement:completed:{def.id}`)
	self:_destroyBadge(player, def.id)
	DataStore2(DS2_KEY, player):Update(function(oldData: Data)
		return Sift.Dictionary.set(oldData or {}, def.id, { awarded = true })
	end)
end

function AchievementService:_createBadge(player: Player, def: BadgeDefinitions.BadgeDefinition, save)
	if save and save.awarded then return end

	local condition = Badger.onCompleted(Badger.create(def.maker(player)), function()
		self:_awardBadge(player, def)
	end)
	if save then
		condition:load(save.condition)
		if condition:isComplete() then return end
	end

	return Badger.start(condition)
end

function AchievementService:_destroyBadge(player: Player, id: BadgeDefinitions.BadgeId)
	if not self._playerBadges[player] then return end

	local condition = self._playerBadges[player][id]
	Badger.stop(condition)

	self._playerBadges[player][id] = nil
end

function AchievementService:_createPlayerBadges(player, data: Data)
	self._playerBadges[player] = Sift.Dictionary.map(BadgeDefinitions, function(def)
		local save = data[def.id]
		return self:_createBadge(player, def, save)
	end)
end

function AchievementService:init()
	self._playerBadges = {}
end

function AchievementService:start()
	local _serverComm = Comm.ServerComm.new(ReplicatedStorage, "AchievementService")

	local function onPlayerJoin(player: Player)
		local store = DataStore2(DS2_KEY, player)
		store:GetAsync(DEFAULT_BADGES):andThen(function(data: Data)
			self:_createPlayerBadges(player, data)
		end)
	end

	Players.PlayerAdded:Connect(onPlayerJoin)
	for _, player in Players:GetPlayers() do
		onPlayerJoin(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local store = DataStore2(DS2_KEY, player)

		for id, condition in self._playerBadges[player] do
			store:Update(function(oldData: Data)
				return Sift.Dictionary.set(oldData or {}, id, {
					awarded = false,
					condition = condition:save(),
				})
			end)
			Badger.stop(condition)
		end

		self._playerBadges[player] = nil
	end)
end

return Loader:registerSingleton(AchievementService)
