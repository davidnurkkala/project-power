local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local SilenceService = require(ServerScriptService.Server.Services.SilenceService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local IsohServer = {}
IsohServer.__index = IsohServer

function IsohServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown, 2),
	}, IsohServer)

	self._model = self.definition.model:Clone()

	return self
end

function IsohServer:destroy() end

function IsohServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Weapon.GripAttachment, "RightGripAttachment")
end

function IsohServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 12.5,
	})
end

function IsohServer:special(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._specialLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 20,
	})

	SilenceService:silenceTarget(target, 5)
end

return IsohServer
