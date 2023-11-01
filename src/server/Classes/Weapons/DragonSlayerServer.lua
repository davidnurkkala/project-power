local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local DragonSlayerServer = {}
DragonSlayerServer.__index = DragonSlayerServer

function DragonSlayerServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),
	}, DragonSlayerServer)

	self._model = self.definition.model:Clone()

	return self
end

function DragonSlayerServer:destroy() end

function DragonSlayerServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Root.GripAttachment, "RightGripAttachment", true)
end

function DragonSlayerServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 20,
	})
end

function DragonSlayerServer:special(victim)
	local target = victim.target
	local direction = victim.direction :: Vector3
	if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end
	direction = direction.Unit

	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange * 2) then return end
	if self._specialLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 20,
	})

	StunService:stunTarget(target, 1, direction * 512)
end

return DragonSlayerServer
