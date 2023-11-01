local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local GLOBAL_COOLDOWN = 0.1

local WeaponController = {}
WeaponController.className = "WeaponController"
WeaponController.priority = 0

WeaponController._equippedWeapon = nil :: WeaponDefinitions.WeaponClient?

WeaponController.weaponEquipped = Signal.new()

function WeaponController:init() end

function WeaponController:start()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "WeaponService")

	self._attackRequested = self._comm:GetSignal("AttackRequested")
	self._specialRequested = self._comm:GetSignal("SpecialRequested")
	self._dashRequested = self._comm:GetSignal("DashRequested")
	self._customRequested = self._comm:GetSignal("CustomRequested")

	self._weaponUseGlobalCooldown = Cooldown.new(GLOBAL_COOLDOWN)

	self._comm:GetSignal("WeaponEquipped"):Connect(function(weaponId)
		self:equipWeapon(weaponId)
	end)
end

function WeaponController:unequipWeapon()
	if self._equippedWeapon then
		self._equippedWeapon:destroy()
		self._equippedWeapon = nil
	end
end

function WeaponController:equipWeapon(id: string)
	local player = Players.LocalPlayer

	local char = player.Character
	if not char then return end
	local human = char:FindFirstChild("Humanoid")
	if not human then return end

	local definition = WeaponDefinitions[id]

	local className = definition.className or id
	local source = ReplicatedStorage.Shared.Classes.Weapons:FindFirstChild(className .. "Client")
	local class = require(source)
	local instance = class.new(definition) :: WeaponDefinitions.WeaponClient

	self:unequipWeapon()

	self._equippedWeapon = instance

	local function onDied()
		self:unequipWeapon()
	end
	human.Died:Connect(onDied)
	char.AncestryChanged:Connect(function()
		if char:IsDescendantOf(workspace) then return end
		onDied()
	end)

	instance:equip()

	self.weaponEquipped:Fire()
end

function WeaponController:attack()
	if not self._equippedWeapon then return end

	self._equippedWeapon:attack(function(...)
		self._attackRequested:Fire(...)
	end)
end

function WeaponController:special()
	if not self._equippedWeapon then return end

	self._equippedWeapon:special(function(...)
		self._specialRequested:Fire(...)
	end)
end

function WeaponController:dash()
	if not self._equippedWeapon then return end
	if self._equippedWeapon.dash then
		self._equippedWeapon:dash(function(...)
			self._dashRequested:Fire(...)
		end)
		return
	end

	-- call default dash
	DashController:dash()
end

function WeaponController:customRemote(...)
	self._customRequested:Fire(...)
end

function WeaponController:getAttackCooldown()
	if self._equippedWeapon then
		if self._equippedWeapon._attackCooldown then return self._equippedWeapon._attackCooldown end
	end
	return Cooldown.new(1)
end

function WeaponController:getSpecialCooldown()
	if self._equippedWeapon then
		if self._equippedWeapon._specialCooldown then return self._equippedWeapon._specialCooldown end
	end
	return Cooldown.new(1)
end

function WeaponController:useGlobalCooldown(override: number?)
	self._weaponUseGlobalCooldown:use(override)
end

function WeaponController:isGlobalCooldownReady()
	return self._weaponUseGlobalCooldown:isReady()
end

return Loader:registerSingleton(WeaponController)
