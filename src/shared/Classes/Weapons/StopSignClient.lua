local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local StopSignClient = {}
StopSignClient.__index = StopSignClient

function StopSignClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, StopSignClient)
	return self
end

function StopSignClient:destroy()
	self._animator:stop("StopSignIdle")
end

function StopSignClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("StopSignIdle")
end

function StopSignClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 8
	local cframe = CFrame.Angles(0, 0, math.rad(-100))
	local color = Color3.new(0.67, 0.67, 0.67)

	self._animator:play("StopSignAttack2", 0)

	EffectController:replicate(EffectUtil.sound({
		name = "Whoosh1",
		parent = root,
	}))

	EffectController:replicate(EffectUtil.slash1({
		radius = radius,
		duration = 0.2,
		cframe = cframe * CFrame.Angles(0, math.rad(150), 0),
		rotation = math.rad(-100),
		root = root,
		color = color,
		partName = "SlashBash1",
	}))

	local targets = WeaponUtil.hitboxMelee({
		root = root,
		size = Vector3.new(radius * 2, 4, radius),
		offset = cframe,
	})

	for _, target in targets do
		EffectController:replicate(EffectUtil.hitEffect({
			part = WeaponUtil.getTargetRoot(target),
			emitterName = "Impact1",
			particleCount = 2,
			soundName = "Slap1",
		}))
	end

	request(targets)

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function StopSignClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	local human = WeaponUtil.getHuman()
	if not (root and human) then return end

	local radius = 8
	local duration = 1.5
	local rotationSpeed = 8 * math.pi
	local offset = CFrame.new(-root.CFrame.UpVector)
	local color = Color3.new(0.67, 0.67, 0.67)

	self._animator:play("StopSignSpin1", 0)

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid,
		parent = root,
		name = "Helicopter",
		duration = duration,
	}))

	local slashGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.slash1({
		guid = slashGuid,
		radius = radius,
		duration = duration,
		cframe = offset * CFrame.Angles(0, -math.pi / 2, math.pi),
		rotation = -rotationSpeed * duration,
		root = root,
		color = color,
		partName = "SlashBash1",
	}))

	local thread = task.spawn(function()
		local stepTime = duration / self.definition.specialHitCount
		while true do
			local targets = WeaponUtil.hitSphere({
				position = root.Position,
				radius = radius,
			})

			local victims = {}

			for _, target in targets do
				local targetRoot = WeaponUtil.getTargetRoot(target)

				EffectController:replicate(EffectUtil.hitEffect({
					part = targetRoot,
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "Slap1",
				}))

				local delta = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)

				table.insert(victims, {
					target = target,
					direction = delta.Unit + Vector3.new(0, 1, 0),
				})
			end

			request(victims)

			task.wait(stepTime)
		end
	end)

	WeaponUtil.channel({
		duration = duration,
		onFinished = function(success)
			self._animator:stop("StopSignSpin1")
			EffectController:cancel(soundGuid)
			task.cancel(thread)

			if success then return end

			EffectController:cancel(slashGuid)
			WeaponController:useGlobalCooldown()
		end,
	})

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(duration)
end

function StopSignClient:dash(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	local onDashCompletion = DashController:dash({
		cooldown = self.definition.dashCooldown,
	})
	if not onDashCompletion then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._animator:play("StopSignDash", 0)

	WeaponUtil.hitboxLingering({
		duration = 0.25,
		hitbox = function()
			return WeaponUtil.hitbox({
				cframe = root.CFrame,
				size = Vector3.new(4, 4, 8),
			})
		end,
		callback = function(target)
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "Impact1",
				particleCount = 2,
				soundName = "Slap1",
			}))

			request(target, root.CFrame.LookVector)
		end,
	})

	WeaponController:useGlobalCooldown()
end

return StopSignClient
