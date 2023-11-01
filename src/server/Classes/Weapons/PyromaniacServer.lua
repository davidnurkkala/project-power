local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local PyromaniacServer = {}
PyromaniacServer.__index = PyromaniacServer

function PyromaniacServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown, 3),

		_lastSpecialHit = 0,
		_rageActive = false,
	}, PyromaniacServer)

	self._trove = Trove.new()
	self._model = self._trove:Clone(self.definition.model)

	return self
end

function PyromaniacServer:destroy()
	self._trove:Clean()
end

function PyromaniacServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	local head = char:FindFirstChild("Head")
	if not head then return end

	local faceCenterAttachment = head:FindFirstChild("FaceCenterAttachment")
	if not faceCenterAttachment then return end

	local breathLight = self._trove:Clone(ReplicatedStorage.Assets.Lights.FireBreath)
	breathLight.Enabled = false
	breathLight.Parent = faceCenterAttachment

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.PrimaryPart.RightGripAttachment, "RightGripAttachment", true)
end

function PyromaniacServer:_applyBurn(target)
	local burnGuid = HttpService:GenerateGUID(false)

	local root = WeaponUtil.getTargetRoot(target)
	EffectService:effect("emitter", {
		guid = burnGuid,
		name = "FireBurn",
		parent = root,
	})

	-- TODO: make a full generic status effect system
	task.spawn(function()
		for _ = 1, self.definition.burnAmount do
			task.wait(self.definition.burnInterval)
			if not target or not target.Parent then return end

			DamageService:damage({
				source = WeaponUtil.getHuman(self.player),
				target = target,
				amount = self.definition.burnDamage,
			})

			EffectService:effect("sound", {
				parent = root,
				name = "PyromaniacTick",
			})
		end

		EffectService:effect("cancel", { guid = burnGuid })
	end)
end

function PyromaniacServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = self.definition.attackDamage,
	})
end

function PyromaniacServer:special(kind, target, direction)
	if self._specialLimiter:limitTarget(target) then return end
	if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end

	local root = WeaponUtil.getRoot(self.player)
	if not root then return end

	local damage = 0
	local stun = 0
	local launchSpeed = 0
	if kind == "fireBreath" then
		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.fireBreathRange) then return end

		damage = self.definition.fireBreathDamage
		stun = self.definition.fireBreathStun
		launchSpeed = self.definition.fireBreathLaunchSpeed
	elseif kind == "throw" then
		damage = self.definition.throwDamage
		stun = 0
		launchSpeed = self.definition.throwLaunchSpeed
	end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = damage,
	})
	if stun > 0 then StunService:stunTarget(target, stun, direction.Unit * launchSpeed) end

	if target:IsA("Humanoid") then self:_applyBurn(target) end
end

return PyromaniacServer
