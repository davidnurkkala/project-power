local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animation = require(ReplicatedStorage.Shared.Util.Animation)
local Comm = require(ReplicatedStorage.Packages.Comm)
local InBattleHelper = require(ReplicatedStorage.Shared.Util.InBattleHelper)
local LaunchHelper = require(ReplicatedStorage.Shared.Util.LaunchHelper)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

local BattleController = {}
BattleController.className = "BattleController"
BattleController.priority = 0

BattleController.inBattleChanged = Signal.new() :: Signal.Signal<boolean>

function BattleController:init()
	self._inBattle = false

	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "BattleService")
	self._launchRequested = self._comm:GetSignal("LaunchRequested")

	self._launchRequested:Connect(function(launcher, cframe)
		LaunchHelper(Players.LocalPlayer, launcher, cframe)
	end)

	self:_initLobbyObscured()
end

function BattleController:start()
	Observers.observeCharacter(function(player, character)
		if player ~= Players.LocalPlayer then return end

		local cleanupFunctions = Sift.Array.map(InBattleHelper.attributeNames, function(attributeName)
			return Observers.observeAttribute(character, attributeName, function(value)
				if value ~= true then return end

				self._inBattle = true
				self.inBattleChanged:Fire(true)

				return function()
					self._inBattle = false
					self.inBattleChanged:Fire(false)
				end
			end)
		end)

		return function()
			self._inBattle = false
			self.inBattleChanged:Fire(false)

			for _, func in cleanupFunctions do
				func()
			end
		end
	end)
end

function BattleController:_initLobbyObscured()
	CollectionService:GetInstanceAddedSignal("LobbyObscured"):Connect(function(object)
		self:_setLobbyObscured(object, self._inBattle, true)
	end)

	local changePromise = nil

	self.inBattleChanged:Connect(function()
		if changePromise then
			changePromise:cancel()
			changePromise = nil
		end

		changePromise = Promise.all(Sift.Array.map(CollectionService:GetTagged("LobbyObscured"), function(object)
			return self:_setLobbyObscured(object, self._inBattle, false)
		end)):andThen(function()
			changePromise = nil
		end)
	end)
end

function BattleController:_setLobbyObscured(parent, state, isInstant)
	return Promise.all(Sift.Array.map(
		Sift.Array.filter(Sift.Array.append(parent:GetDescendants(), parent), function(object)
			return object:IsA("BasePart")
		end),
		function(object)
			if state then
				if object:GetAttribute("LobbyObscuredOriginalTransparency") then
					local t = object:GetAttribute("LobbyObscuredOriginalTransparency")
					object:SetAttribute("LobbyObscuredOriginalTransparency", nil)
					if isInstant then
						object.Transparency = t
					else
						return Animation(1, function(scalar)
							object.Transparency = 1 + (t - 1) * scalar
						end):finally(function()
							object.Transparency = t
						end)
					end
				end
			else
				if object:GetAttribute("LobbyObscuredOriginalTransparency") == nil then
					local t = object.Transparency
					object:SetAttribute("LobbyObscuredOriginalTransparency", t)
					if isInstant then
						object.Transparency = 1
					else
						return Animation(1, function(scalar)
							object.Transparency = t + (1 - t) * scalar
						end):finally(function()
							object.Transparency = 1
						end)
					end
				end
			end

			return Promise.resolve()
		end
	))
end

function BattleController:isInBattle()
	local character = Players.LocalPlayer.Character
	if not character then return false end

	return character:GetAttribute("InBattle") or false
end

return Loader:registerSingleton(BattleController)
