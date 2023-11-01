local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local RocketLauncherServer = {}
RocketLauncherServer.__index = RocketLauncherServer

function RocketLauncherServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),
	}, RocketLauncherServer)

	self._model = definition.model:Clone()

	return self
end

function RocketLauncherServer:destroy() end

function RocketLauncherServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Weapon.GripAttachment, "RightGripAttachment", true)
end

function RocketLauncherServer:attack(victims)
	for _, victim in victims do
		local target = victim.target
		local direction = victim.direction :: Vector3
		if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end

		if self._attackLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 25,
		})

		StunService:pushbackTarget(target, 0.25, direction.Unit * 128)
	end
end

function RocketLauncherServer:special(victims)
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

		StunService:stunTarget(target, 0.75, direction.Unit * 256)
	end
end

function RocketLauncherServer:custom(message)
	if message == "SelfDamage" then
		local human = WeaponUtil.getHuman(self.player)
		if not human then return end

		DamageService:damage({
			target = human,
			amount = 30,
		})
	end
end

return RocketLauncherServer
