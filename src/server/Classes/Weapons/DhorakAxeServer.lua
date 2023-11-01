local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local DhorakAxeServer = {}
DhorakAxeServer.__index = DhorakAxeServer

function DhorakAxeServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, DhorakAxeServer)

	self._model = self.definition.model:Clone()

	return self
end

function DhorakAxeServer:destroy() end

function DhorakAxeServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Weapon.GripAttachment, "RightGripAttachment", true, true)
end

function DhorakAxeServer:_getDamageMultiplier()
	local human = WeaponUtil.getHuman(self.player)
	if not human then return 1 end

	return 1 + (1 - human.Health / human.MaxHealth) * 0.75
end

function DhorakAxeServer:attack(kind, target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	local root = WeaponUtil.getRoot(self.player)
	if not root then return end

	local damage = 0
	if kind == "smash" then
		damage = 40

		StunService:stunTarget(target, 1, root.CFrame.LookVector * 256)
	elseif kind == "strike" then
		damage = 15
	end

	damage *= self:_getDamageMultiplier()
	damage = math.floor(damage * 10) / 10

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = damage,
	})
end

function DhorakAxeServer:special()
	local human = WeaponUtil.getHuman(self.player)
	if not human then return end

	if not self._specialCooldown:isReady() then return end
	self._specialCooldown:use()

	local connection = DamageService.damageDealt:Connect(function(damage)
		if not damage.source then return end
		if damage:hasTag("DhorakAxeVengeance") then return end
		if damage.target ~= human then return end
		if typeof(damage.source) == "table" then return end

		DamageService:damage({
			source = human,
			target = damage.source,
			amount = math.floor(damage.amount * self.definition.specialReflectAmount * 10) / 10,
			tags = { "DhorakAxeVengeance" },
		})
	end)

	task.delay(self.definition.specialDuration, function()
		connection:Disconnect()
	end)
end

return DhorakAxeServer
