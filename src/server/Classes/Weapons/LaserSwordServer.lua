local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local LaserSwordServer = {}
LaserSwordServer.__index = LaserSwordServer

function LaserSwordServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),
	}, LaserSwordServer)

	self._model = definition.model:Clone()

	return self
end

function LaserSwordServer:destroy() end

function LaserSwordServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Weapon.GripAttachment, "RightGripAttachment", true)

	local attachment = Instance.new("Attachment")
	attachment.Name = "LaserSwordEffects"

	local emitter = ReplicatedStorage.Assets.Emitters.LaserSwordForceCharge:Clone()
	emitter.Name = "Emitter"
	emitter.Parent = attachment

	attachment.Parent = char.LeftHand

	local sound = ReplicatedStorage.Assets.Sounds.LaserSwordLoop1:Clone()
	sound.Parent = self._model.Weapon
	sound:Play()
end

function LaserSwordServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 15,
	})
end

function LaserSwordServer:special(targets, direction)
	if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end
	direction = direction.Unit

	for _, target in targets do
		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange * 2) then return end
		if self._specialLimiter:limitTarget(target) then return end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 25,
		})

		StunService:stunTarget(target, 1, direction * 512)
	end
end

return LaserSwordServer
