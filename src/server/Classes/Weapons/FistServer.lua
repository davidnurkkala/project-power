local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

-- consts
local ATTACK_DAMAGE = 10
local SPECIAL_DAMAGE = 20
local DASH_MULTIPLIER = 1.5

local FistServer = {}
FistServer.__index = FistServer

function FistServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_isDashing = false,
	}, FistServer)
	return self
end

function FistServer:equip() end

function FistServer:destroy() end

function FistServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = ATTACK_DAMAGE * (if self._isDashing then DASH_MULTIPLIER else 1),
	})
end

function FistServer:special(target, direction)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = SPECIAL_DAMAGE,
	})

	StunService:stunTarget(target, 1, direction * 384)
end

function FistServer:dash(dashEnabled: boolean)
	self._isDashing = dashEnabled
end

return FistServer
