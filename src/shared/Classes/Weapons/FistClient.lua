local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local FistClient = {}
FistClient.__index = FistClient

function FistClient.new(definition)
	local self = setmetatable({
		definition = definition,
		_right = true,
		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, FistClient)
	return self
end

function FistClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
end

function FistClient:destroy()
	self._animator:stop("FistsIdle")
end

function FistClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._animator:stopHard("FistsPunchRight", 0)
	self._animator:stopHard("FistsPunchLeft", 0)
	self._animator:play(if self._right then "FistsPunchRight" else "FistsPunchLeft", 0)
	local dx = if self._right then 1 else -1
	EffectController:replicate(EffectUtil.punch({
		width = 4,
		length = 8,
		duration = 0.1,
		startOffset = CFrame.new(dx, -0.5, 2),
		endOffset = CFrame.new(dx, -0.5, -2),
		root = root,
	}))
	self._right = not self._right

	EffectController:replicate(EffectUtil.sound({ parent = root, name = "Swish1" }))

	WeaponUtil.hitboxLingering({
		hitbox = function()
			return WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(4, 4, 8),
			})
		end,
		callback = function(target)
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "Hit1",
			}))

			request(target)
		end,
	})

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function FistClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	ForcedMovementHelper.instant(root, nil, 80, nil)

	self._animator:play("FistsUppercut")

	local rotation = CFrame.Angles(math.pi / 2, 0, 0)
	EffectController:replicate(EffectUtil.punch({
		width = 6,
		length = 12,
		duration = 0.2,
		startOffset = CFrame.new(0, -3, -1) * rotation,
		endOffset = CFrame.new(0, 2, -1) * rotation,
		root = root,
	}))

	EffectController:replicate(EffectUtil.sound({ parent = root, name = "Swish1" }))

	local launchCFrame = root.CFrame * CFrame.Angles(math.rad(60), 0, 0)

	WeaponUtil.hitboxLingering({
		hitbox = function()
			return WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(6, 12, 6),
			})
		end,
		callback = function(target)
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "Copyrighted",
			}))

			request(target, launchCFrame.LookVector)
		end,
	})

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown()
end

function FistClient:dash(request)
	local onDashCompletion = DashController:dash()
	if not onDashCompletion then return end

	self._specialCooldown:reset()

	request(true) -- request server start dash
	onDashCompletion(function()
		request(false) -- request server stop dash
	end)
end

return FistClient
