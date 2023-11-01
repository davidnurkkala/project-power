local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local BatServer = {}
BatServer.__index = BatServer

function BatServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown, 2),
		_dashLimiter = HitLimiter.new(definition.dashCooldown),

		_lastSpecialHit = 0,
		_rageActive = false,
	}, BatServer)

	self._trove = Trove.new()
	self._model = self._trove:Clone(self.definition.model)

	return self
end

function BatServer:destroy()
	self._model:Destroy()
	self._trove:Clean()
end

function BatServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Root.RightGripAttachment, "RightGripAttachment")
	local batSpecialEmitter = ReplicatedStorage.Assets.Emitters["BatSpecialEmitter"]:Clone()
	batSpecialEmitter.Parent = self._model.Root.WeaponTip
	self._trove:Add(function()
		batSpecialEmitter:Destroy()
	end)

	self._rageEmitter = ReplicatedStorage.Assets.Emitters["BatRage"]:Clone()
	self._rageEmitter.Enabled = false
	self._rageEmitter.Parent = self._model.Root
	self._trove:Add(function()
		self._rageEmitter:Destroy()
		self._rageEmitter = nil

		self._rageSound:Destroy()
		self._rageSound = nil
	end)

	self._trove:Connect(RunService.Heartbeat, function()
		local currentTime = tick()
		if currentTime - self._lastSpecialHit > self.definition.rageDuration and self._rageActive then
			self._rageActive = false
			self._rageEmitter.Enabled = false
			self._rageSound:Stop()

			self._rageEnableSound:Stop()
			self._rageDisableSound:Play()
		end
	end)

	self._rageSound = ReplicatedStorage.Assets.Sounds["BatRage"]:Clone()
	self._rageSound.Parent = self._model.Root

	self._rageEnableSound = ReplicatedStorage.Assets.Sounds["BatRageEnable"]:Clone()
	self._rageEnableSound.Parent = self._model.Root

	self._rageDisableSound = ReplicatedStorage.Assets.Sounds["BatRageDisable"]:Clone()
	self._rageDisableSound.Parent = self._model.Root
end

function BatServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	local damage = self.definition.attackDamage
	if self._rageActive then damage = self.definition.attackDamageRage end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = damage,
	})
end

function BatServer:special(target, direction)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._specialLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 10,
	})

	StunService:stunTarget(target, 1, direction.Unit * 512)

	if target:IsA("Humanoid") then
		self._lastSpecialHit = tick()
		if not self._rageActive then
			self._rageActive = true
			self._rageEmitter.Enabled = true
			self._rageDisableSound:Stop()
			self._rageEnableSound:Play()
			task.delay(1.4, self._rageSound.Play, self._rageSound)
		end
	end
end

return BatServer
