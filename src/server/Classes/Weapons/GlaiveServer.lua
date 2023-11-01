local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local GlaiveServer = {}
GlaiveServer.__index = GlaiveServer

function GlaiveServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown, definition.specialHitCount),
	}, GlaiveServer)

	self._model = self.definition.model:Clone()

	return self
end

function GlaiveServer:destroy() end

function GlaiveServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Root.GripAttachment, "RightGripAttachment", true)
end

function GlaiveServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 17.5,
	})
end

function GlaiveServer:special(targets)
	for _, target in targets do
		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then continue end
		if self._specialLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 5,
		})
	end
end

return GlaiveServer
