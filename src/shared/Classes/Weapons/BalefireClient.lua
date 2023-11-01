local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local ForcedRotationHelper = require(ReplicatedStorage.Shared.Util.ForcedRotationHelper)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local FIRE_SEQUENCE = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
	ColorSequenceKeypoint.new(0.6, Color3.new(1, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.new(1, 1, 0)),
})

local BalefireClient = {}
BalefireClient.__index = BalefireClient

function BalefireClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, BalefireClient)
	return self
end

function BalefireClient:destroy() end

function BalefireClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("PowerStance")
end

function BalefireClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 6

	local function slash(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = "FireSwing" .. math.random(1, 6),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.slash2({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(180), 0),
			rotation = math.rad(-360),
			root = root,
			partName = "FireSlash1",
		}))

		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(radius * 2, 1, radius),
					offset = cframe,
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "FirePunch" .. math.random(1, 4),
					color = FIRE_SEQUENCE,
				}))

				request(target)
			end,
		})
	end

	self._animator:stopHard("HaymakerRight")
	self._animator:stopHard("HaymakerLeft")

	if self._attackRight then
		self._animator:play("HaymakerRight", 0)
		slash(CFrame.Angles(0, 0, math.rad(-175)))
	else
		self._animator:play("HaymakerLeft", 0)
		slash(CFrame.Angles(0, 0, math.rad(-5)))
	end

	self._attackRight = not self._attackRight

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function BalefireClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local chargeDuration = 0.75
	local range = 128
	local width = 6

	local root = WeaponUtil.getRoot()
	if not root then return end

	local human = WeaponUtil.getHuman()
	if not human then return end

	self._animator:play("BalefireCharge", 0, nil, 1 / chargeDuration)

	local trove = Trove.new()

	root.Anchored = true
	trove:Add(function()
		root.Anchored = false
	end)

	local rootReplicator = EffectController:getRapidReplicator()

	local mover = ForcedMovementHelper.register(root)
	local rotator = ForcedRotationHelper.register(root, human)

	trove:Connect(RunService.Stepped, function()
		local raycast = MouseUtil.raycast()
		local cframe = CFrame.lookAt(root.Position, raycast.position)
		rootReplicator(EffectUtil.setRootCFrame({
			root = root,
			cframe = cframe,
		}))
		mover:update(0, 0, 0)
		rotator:update(cframe)
	end)

	local guid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.balefire({
		guid = guid,
		root = root,
		duration = chargeDuration,
		range = range,
	}))

	WeaponUtil.channel({
		duration = chargeDuration,
		onFinished = function(success)
			mover:destroy()
			rotator:destroy()

			if success then
				self._animator:play("BalefireRelease", 0)

				local targets = WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(width, width, range),
				})

				for _, target in targets do
					EffectController:replicate(EffectUtil.hitEffect({
						part = WeaponUtil.getTargetRoot(target),
						emitterName = "Impact1",
						particleCount = 2,
						soundName = "FirePunch" .. math.random(1, 4),
						color = FIRE_SEQUENCE,
					}))
				end

				request(targets, root.CFrame.LookVector)

				task.delay(0.2, trove.Clean, trove)
			else
				trove:Clean()
				self._animator:stopHard("BalefireCharge")
				EffectController:cancel(guid)
				WeaponController:useGlobalCooldown()
			end
		end,
	})

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(chargeDuration + 0.2)
end

function BalefireClient:dash(request)
	if not DashController:getCooldown():isReady() then return end

	local root = WeaponUtil.getRoot()
	local human = WeaponUtil.getHuman()
	if not (root and human) then return end

	local cframe = root.CFrame * CFrame.new(0, -2, 0)
	local radius = 12

	local trove = Trove.new()

	self._animator:play("UpwardDash", 0)
	trove:Add(function()
		self._animator:stop("UpwardDash")
	end)

	local guid = HttpService:GenerateGUID(false)
	EffectController:replicate(EffectUtil.trail({
		guid = guid,
		root = root,
		offset0 = CFrame.new(-1, 0, 0),
		offset1 = CFrame.new(1, 0, 0),
		trailName = "FireTrail",
	}))
	trove:Add(function()
		EffectController:cancel(guid)
	end)

	trove:Connect(RunService.Stepped, function()
		if root.AssemblyLinearVelocity.Y <= 0 then trove:Clean() end
	end)

	EffectController:replicate(EffectUtil.burst1({
		cframe = cframe,
		radius = radius,
		duration = 0.5,
		partName = "BurstFire1",
		power = 0.4,
	}))

	EffectController:replicate(EffectUtil.sound({
		name = "FireSpell1",
		position = cframe.Position,
	}))

	local targets = WeaponUtil.hitSphere({
		position = cframe.Position,
		radius = radius,
	})

	local victims = {}

	for _, target in targets do
		local targetRoot = WeaponUtil.getTargetRoot(target)

		EffectController:replicate(EffectUtil.hitEffect({
			part = targetRoot,
			emitterName = "Impact1",
			particleCount = 2,
			soundName = "FirePunch" .. math.random(1, 4),
			color = FIRE_SEQUENCE,
		}))

		local delta = (targetRoot.Position - cframe.Position)

		table.insert(victims, {
			target = target,
			direction = delta.Unit,
		})
	end

	request(victims)

	WeaponUtil.forceJump():andThen(function()
		ForcedMovementHelper.instant(root, nil, 96, nil)
	end)

	DashController:getCooldown():use(self.definition.dashCooldown)
end

return BalefireClient
