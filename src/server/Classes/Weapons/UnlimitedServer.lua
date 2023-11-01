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

	return self
end

function RayGunServer:destroy() end

function RayGunServer:equip() end

function RayGunServer:attack(target, direction)
	if self._attackLimiter:limitTarget(target) then return end

	local amount = 0

	if direction then
		if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end
		StunService:stunTarget(target, 0.5, direction.Unit * 256)
		amount = 35
	else
		amount = 25
	end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = amount,
	})
end

function RayGunServer:special(target, direction)
	if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end

	if self._specialLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 75,
	})

	StunService:stunTarget(target, 1, direction.Unit * 256)
end

function RayGunServer:custom(message)
	if message == "SelfDamage" then
		local human = WeaponUtil.getHuman(self.player)
		if not human then return end

		DamageService:damage({
			target = human,
			amount = 30,
		})
	end
end

return RayGunServer
