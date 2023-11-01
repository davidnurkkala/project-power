local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ComboTracker = require(ServerScriptService.Server.Classes.ComboTracker)
local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local UncannyServer = {}
UncannyServer.__index = UncannyServer

function UncannyServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown, definition.specialHitCount),
		_specialCombo = ComboTracker.new(2),
	}, UncannyServer)

	self._model = definition.model:Clone()

	return self
end

function UncannyServer:destroy() end

function UncannyServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char

	local weld = Instance.new("Weld")
	weld.Part0 = char.Head
	weld.Part1 = self._model.Weapon
	weld.C0 = CFrame.new(0, -0.5 + weld.Part1.Size.Y / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	weld.Parent = weld.Part1
end

function UncannyServer:attack(targets)
	for _, target in targets do
		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then continue end
		if self._attackLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 25,
		})
	end
end

function UncannyServer:special(victims)
	for _, victim in victims do
		local target = victim.target
		local direction = victim.direction
		direction = direction.Unit

		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then continue end
		if self._specialLimiter:limitTarget(target) then continue end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 10,
		})

		if self._specialCombo:track(target) >= 3 then StunService:stunTarget(target, 0.75, direction * 256) end
	end
end

return UncannyServer
