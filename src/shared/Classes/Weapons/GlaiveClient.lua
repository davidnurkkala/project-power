local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local GlaiveClient = {}
GlaiveClient.__index = GlaiveClient

function GlaiveClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, GlaiveClient)
	return self
end

function GlaiveClient:destroy() end

function GlaiveClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("MaulIdle")
end

function GlaiveClient:attack(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	if not self._attackCooldown:isReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 13

	local function slash(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = "GlaiveSlash" .. math.random(1, 4),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
		}))

		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(radius * 2, 3, radius),
					offset = cframe,
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "SwordHit" .. math.random(1, 4),
				}))

				request(target)
			end,
		})
	end

	self._animator:stopHard("MaulAttack1")
	self._animator:stopHard("MaulAttack2")

	if self._attackRight then
		self._animator:play("MaulAttack1", 0)
		slash(CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(-175)))
	else
		self._animator:play("MaulAttack2", 0)
		slash(CFrame.Angles(0, 0, math.rad(-5)))
	end

	self._attackRight = not self._attackRight

	self._attackCooldown:use()
end

function GlaiveClient:special(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	if not self._specialCooldown:isReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local model = char.Glaive
	local duration = 2
	local radius = 8
	local rotationSpeed = 8 * math.pi
	local offset = CFrame.new(0, 2.5, 0)

	self._animator:play("GlaiveSpin", 0)

	local spinGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.spinModel({
		guid = spinGuid,
		root = root,
		model = model,
		duration = duration,
		rotationSpeed = rotationSpeed,
		offset = offset,
	}))

	local slashGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.slash1({
		guid = slashGuid,
		radius = radius,
		duration = duration,
		cframe = offset * CFrame.Angles(0, -math.pi / 2, math.pi),
		rotation = -rotationSpeed * duration,
		root = root,
	}))

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid,
		parent = root,
		name = "Helicopter",
		duration = duration,
	}))

	local hideGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.hideModel({
		guid = hideGuid,
		model = model,
	}))

	local trove = Trove.new()

	local mover = ForcedMovementHelper.register(root)
	trove:Add(mover, "destroy")

	trove:Connect(RunService.Stepped, function()
		mover:update(nil, 6, nil)
	end)

	trove:Add(task.spawn(function()
		local stepTime = duration / self.definition.specialHitCount
		while true do
			local targets = WeaponUtil.hitSphere({
				position = root.Position,
				radius = radius,
			})

			for _, target in targets do
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "SwordHit" .. math.random(1, 4),
				}))
			end

			request(targets)

			task.wait(stepTime)
		end
	end))

	WeaponUtil.channel({
		duration = duration,
		onFinished = function(success)
			trove:Clean()
			self._animator:stop("GlaiveSpin")
			EffectController:cancel(hideGuid, spinGuid)

			if success then return end

			EffectController:cancel(soundGuid, slashGuid)
			WeaponController:useGlobalCooldown()
		end,
	})

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(duration)
end

return GlaiveClient
