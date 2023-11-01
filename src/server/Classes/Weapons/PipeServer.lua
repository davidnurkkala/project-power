local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local PipeServer = {}
PipeServer.__index = PipeServer

function PipeServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown, 2),
	}, PipeServer)

	self._trove = Trove.new()
	self._model = self._trove:Clone(self.definition.model)

	return self
end

function PipeServer:destroy()
	self._trove:Clean()
end

function PipeServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Handle.RightGripAttachment, "RightGripAttachment")
end

function PipeServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	local damage = self.definition.attackDamage

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = damage,
	})
end

function PipeServer:special(victims)
	for _, victim in victims do
		local target = victim.target
		local direction = victim.direction :: Vector3
		if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end

		if self._specialLimiter:limitTarget(target) then return end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 18,
		})

		StunService:stunTarget(target, 0.8, direction.Unit * 300)
	end
end

return PipeServer
