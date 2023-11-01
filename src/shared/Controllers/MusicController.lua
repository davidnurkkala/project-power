local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BattleController = require(ReplicatedStorage.Shared.Controllers.BattleController)
local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Linear)

local MusicController = {}
MusicController.className = "MusicController"
MusicController.priority = 0

MusicController.muted = true
MusicController.changed = Signal.new()

MusicController._isInBattle = false

function MusicController:_setMuted(sound: Sound, muted: boolean)
	if self.muted then muted = true end

	if muted then
		TweenService:Create(sound, TWEEN_INFO, { Volume = 0 }):Play()
	else
		TweenService:Create(sound, TWEEN_INFO, { Volume = sound:GetAttribute("OriginalVolume") }):Play()
	end
end

function MusicController:toggleMute()
	self._comm:GetSignal("MutedChanged"):Fire(not self.muted)
end

function MusicController:init() end

function MusicController:start()
	local sounds = Sift.Dictionary.map({ "LobbyMusic", "BattleMusic" }, function(name)
		local sound = workspace:WaitForChild(name)
		sound:SetAttribute("OriginalVolume", sound.Volume)
		sound.Volume = 0
		return sound, name
	end)

	local function setMusic(isInBattle: boolean)
		self._isInBattle = isInBattle

		if isInBattle then
			self:_setMuted(sounds.LobbyMusic, true)
			self:_setMuted(sounds.BattleMusic, false)
		else
			self:_setMuted(sounds.LobbyMusic, false)
			self:_setMuted(sounds.BattleMusic, true)
		end
	end

	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "MusicService")

	self._comm:GetProperty("Muted"):Observe(function(muted)
		self.muted = muted
		self.changed:Fire()
		setMusic(self._isInBattle)
	end)

	BattleController.inBattleChanged:Connect(setMusic)

	setMusic(false)
end

return Loader:registerSingleton(MusicController)
