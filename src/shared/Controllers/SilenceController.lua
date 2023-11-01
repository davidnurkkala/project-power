local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SilenceHelper = require(ReplicatedStorage.Shared.Util.SilenceHelper)

local SilenceController = {}
SilenceController.className = "SilenceController"
SilenceController.priority = 0

function SilenceController:init()
	self._silenced = false
	self.silencedChanged = Signal.new()

	Observers.observeCharacter(function(player, char)
		if player ~= Players.LocalPlayer then return end

		local cleanup = Observers.observeAttribute(char, SilenceHelper.attributeName, function(value)
			if value then self:_setSilenced(true) end

			return function()
				self:_setSilenced(false)
			end
		end)

		return function()
			cleanup()
			self:_setSilenced(false)
		end
	end)
end

function SilenceController:_setSilenced(silenced)
	if silenced == self._silenced then return end

	self._silenced = silenced
	self.silencedChanged:Fire(self._silenced)
end

function SilenceController:observeSilenced(callback)
	callback(self._silenced)
	return self.silencedChanged:Connect(callback)
end

function SilenceController:start() end

return Loader:registerSingleton(SilenceController)
