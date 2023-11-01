local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local RayGunServer = {}
RayGunServer.__index = RayGunServer

function RayGunServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown, 4),
		_specialLimiter = HitLimiter.new(definition.specialCooldown, 2),
	}, RayGunServer)

	self._model = definition.model:Clone()

	return self
end

function RayGunServer:destroy()
	self._model:Destroy()
end

function RayGunServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Root.GripAttachment, "RightGripAttachment", true)
end

function RayGunServer:attack(target)
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 20,
	})
end

function RayGunServer:special(victims)
	for _, victim in victims do
		local target = victim.target
		local direction = victim.direction :: Vector3
		if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end

		if self._specialLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 30,
		})

		StunService:stunTarget(target, 0.5, direction.Unit * 384)
	end
end

function RayGunServer:custom(message)
	if message == "SelfDamage" then
		local human = WeaponUtil.getHuman(self.player)
		if not human then return end

		DamageService:damage({
			target = human,
			amount = 7.5,
		})
	end
end

return RayGunServer
