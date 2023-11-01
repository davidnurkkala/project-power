local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local PaddleServer = {}
PaddleServer.__index = PaddleServer

function PaddleServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),
	}, PaddleServer)

	self._model = definition.model:Clone()

	return self
end

function PaddleServer:destroy()
	self._model:Destroy()
end

function PaddleServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Paddle.RightGripAttachment, "RightGripAttachment", true)
	WeaponUtil.attachWeapon(self.player, self._model.Ball.LeftGripAttachment, "LeftGripAttachment", true)
end

function PaddleServer:attack(target)
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = self.definition.attackDamage,
	})
end

function PaddleServer:special(target, direction)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.specialRange) then return end
	if self._specialLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = self.definition.specialDamage,
	})

	StunService:stunTarget(target, 1, direction.Unit * 450)
end

return PaddleServer
