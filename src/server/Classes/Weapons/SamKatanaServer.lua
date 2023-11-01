local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local Promise = require(ReplicatedStorage.Packages.Promise)
local StunService = require(ServerScriptService.Server.Services.StunService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local SamKatanaServer = {}
SamKatanaServer.__index = SamKatanaServer

function SamKatanaServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown, definition.dashBuffCount),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),

		_dashBuffCooldown = Cooldown.new(1),
		_dashBuffActive = false,
		_dashBuffPromise = nil,
	}, SamKatanaServer)

	self._model = definition.model:Clone()

	return self
end

function SamKatanaServer:destroy() end

function SamKatanaServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Root.SwordAttachment, "RightGripAttachment", true)
	WeaponUtil.attachWeapon(self.player, self._model.Sheath.Handle.SheathAttachment, "LeftGripAttachment", true)
end

function SamKatanaServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	local damage = 15
	if self._dashBuffActive then
		damage /= 3
	end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = damage,
	})
end

function SamKatanaServer:special(victim)
	local target = victim.target
	local direction = victim.direction :: Vector3
	if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end
	direction = direction.Unit

	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange * 2) then return end
	if self._specialLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 40,
	})

	StunService:stunTarget(target, 1, direction * 512)
end

function SamKatanaServer:dash() end

function SamKatanaServer:custom(message)
	if message == "StartDashBuff" then
		if not self._dashBuffCooldown:isReady() then return end
		self._dashBuffCooldown:use()

		self._dashBuffActive = true
		self._attackLimiter:reset()
		self._dashBuffPromise = Promise.delay(self.definition.dashBuffDuration):andThen(function()
			self:_deactivateDashBuff()
		end)
	elseif message == "StopDashBuff" then
		if not self._dashBuffActive then return end
		self:_deactivateDashBuff()
	end
end

function SamKatanaServer:_deactivateDashBuff()
	self._dashBuffActive = false
	if self._dashBuffPromise then
		self._dashBuffPromise:cancel()
		self._dashBuffPromise = nil
	end
end

return SamKatanaServer
