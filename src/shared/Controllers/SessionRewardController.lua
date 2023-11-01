local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)

local SessionRewardController = {}
SessionRewardController.className = "SessionRewardController"
SessionRewardController.priority = 0

function SessionRewardController:init()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "SessionRewardService")

	self._info = nil
	self._infoChanged = Signal.new()

	self._infoRemote = self._comm:GetProperty("Info")
	self._infoRemote:Observe(function(info)
		self._info = info
		self._infoChanged:Fire(info)
	end)

	self._claim = self._comm:GetFunction("Claim")

	self.awarded = self._comm:GetSignal("Awarded")
	self.awardBecameAvailable = self._comm:GetSignal("AwardBecameAvailable")
end

function SessionRewardController:observeInfo(callback)
	if self._info then callback(self._info) end
	return self._infoChanged:Connect(callback)
end

function SessionRewardController:claim(index)
	return self._claim(index)
end

function SessionRewardController:start() end

return Loader:registerSingleton(SessionRewardController)
