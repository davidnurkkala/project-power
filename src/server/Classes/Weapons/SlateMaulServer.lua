local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local SlateMaulServer = {}
SlateMaulServer.__index = SlateMaulServer

function SlateMaulServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),
	}, SlateMaulServer)

	self._model = self.definition.model:Clone()

	return self
end

function SlateMaulServer:destroy() end

function SlateMaulServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Root.GripAttachment, "RightGripAttachment", true)
end

function SlateMaulServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = self.definition.attackDamage,
	})
end

function SlateMaulServer:special(victims)
	for _, victim in victims do
		local target = victim.target
		local direction = victim.direction :: Vector3
		if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end

		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange * 2) then continue end
		if self._specialLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = self.definition.specialDamage,
		})

		StunService:stunTarget(target, 0.5, direction.Unit * self.definition.launchSpeed)
	end
end

return SlateMaulServer
