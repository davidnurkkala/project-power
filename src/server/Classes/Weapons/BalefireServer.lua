local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local BalefireServer = {}
BalefireServer.__index = BalefireServer

function BalefireServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),
		_dashLimiter = HitLimiter.new(definition.dashCooldown),
	}, BalefireServer)
	return self
end

function BalefireServer:destroy() end

function BalefireServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	local emitter = ReplicatedStorage.Assets.Emitters.FlameEmitter1
	emitter:Clone().Parent = char.RightHand.RightGripAttachment
	emitter:Clone().Parent = char.LeftHand.LeftGripAttachment
end

function BalefireServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 15,
	})
end

function BalefireServer:special(targets)
	for _, target in targets do
		if self._specialLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 35,
		})
	end
end

function BalefireServer:dash(victims)
	for _, victim in victims do
		local target = victim.target

		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then continue end
		if self._dashLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 20,
		})
	end
end

return BalefireServer
