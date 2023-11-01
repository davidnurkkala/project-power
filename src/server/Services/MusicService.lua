local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local Construct = require(ReplicatedStorage.Shared.Util.Construct)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Loader = require(ReplicatedStorage.Shared.Loader)
local MusicDefinitions = require(ReplicatedStorage.Shared.Data.MusicDefinitions)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)

local DATA_KEY = "Music"
local DEFAULT_DATA = {
	muted = false,
}

DataStore2.Combine(Configuration.DataStoreKey, DATA_KEY)

local MusicService = {}
MusicService.className = "MusicService"
MusicService.priority = 0

function MusicService:init() end

function MusicService:start()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "MusicService")
	self._mutedRemote = self._comm:CreateProperty("Muted", false)

	self._comm:CreateSignal("MutedChanged"):Connect(function(player, state)
		self._mutedRemote:SetFor(player, state)
		DataStore2(DATA_KEY, player):Set({
			muted = state,
		})
	end)

	Players.PlayerAdded:Connect(function(player)
		DataStore2(DATA_KEY, player):GetAsync(DEFAULT_DATA):andThen(function(data)
			self._mutedRemote:SetFor(player, data.muted)
		end)
	end)

	self._lobbyMusic = Construct("Sound", {
		Name = "LobbyMusic",
		Volume = 0.25,
		Parent = workspace,
	})
	self:loop(self._lobbyMusic, MusicDefinitions.Lobby)

	self._battleMusic = Construct("Sound", {
		Name = "BattleMusic",
		Volume = 0.25,
		Parent = workspace,
	})
	self:loop(self._battleMusic, MusicDefinitions.Battle)
end

function MusicService:loop(sound: Sound, ids: { number })
	Promise.each(Sift.Array.shuffle(ids), function(id)
		sound.SoundId = `rbxassetid://{id}`
		sound.TimePosition = 0
		return Promise.try(function()
			while not sound.IsLoaded do
				task.wait()
			end
		end)
			:andThen(function()
				sound:Play()
				return Promise.fromEvent(sound.Ended)
			end)
			:andThenCall(Promise.delay, 0.5)
	end):andThen(function()
		self:loop(sound, ids)
	end)
end

return Loader:registerSingleton(MusicService)
