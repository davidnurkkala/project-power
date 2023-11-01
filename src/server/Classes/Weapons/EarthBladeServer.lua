local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ComboTracker = require(ServerScriptService.Server.Classes.ComboTracker)
local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local LinkedSwordServer = require(ServerScriptService.Server.Classes.Weapons.LinkedSwordServer)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local EarthBladeServer = {}
EarthBladeServer.__index = EarthBladeServer

function EarthBladeServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown + definition.specialDuration, definition.specialHitCount),
		_specialCombo = ComboTracker.new(2),
	}, EarthBladeServer)

	self._model = self.definition.model:Clone()

	return self
end

function EarthBladeServer:destroy() end

function EarthBladeServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Weapon.GripAttachment, "RightGripAttachment", true, true)
end

function EarthBladeServer:attack(...)
	return LinkedSwordServer.attack(self, ...)
end

function EarthBladeServer:special(targets)
	local root = WeaponUtil.getRoot(self.player)
	if not root then return end

	for _, target in targets do
		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then continue end
		if self._specialLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 7.5,
		})

		if self._specialCombo:track(target) >= 3 then StunService:stunTarget(target, 0.75, root.CFrame.LookVector * 256) end
	end
end

return EarthBladeServer
