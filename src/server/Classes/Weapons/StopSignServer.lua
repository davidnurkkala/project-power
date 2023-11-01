local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ComboTracker = require(ServerScriptService.Server.Classes.ComboTracker)
local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local StopSignServer = {}
StopSignServer.__index = StopSignServer

function StopSignServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown, definition.specialHitCount),
		_specialCombo = ComboTracker.new(2),
		_dashLimiter = HitLimiter.new(definition.dashCooldown),
	}, StopSignServer)

	self._model = self.definition.model:Clone()

	return self
end

function StopSignServer:destroy() end

function StopSignServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Root.GripAttachment, "RightGripAttachment", true)
end

function StopSignServer:attack(targets)
	for _, target in targets do
		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then continue end
		if self._attackLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 15,
		})
	end
end

function StopSignServer:special(victims)
	for _, victim in victims do
		local target = victim.target
		local direction = victim.direction
		direction = direction.Unit

		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then continue end
		if self._specialLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 7.5,
		})

		if self._specialCombo:track(target) >= 3 then StunService:stunTarget(target, 1.5, direction * 256) end
	end
end

function StopSignServer:dash(target, direction)
	direction = direction.Unit

	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._dashLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 10,
	})

	StunService:stunTarget(target, 1.25, direction * 256)
end

return StopSignServer
