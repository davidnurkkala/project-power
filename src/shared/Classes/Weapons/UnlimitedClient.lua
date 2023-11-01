local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionController = require(ReplicatedStorage.Shared.Controllers.ActionController)
local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local ProjectileHelper = require(ReplicatedStorage.Shared.Util.ProjectileHelper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local StunController = require(ReplicatedStorage.Shared.Controllers.StunController)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local UnlimitedClient = {}
UnlimitedClient.__index = UnlimitedClient

local function quickEmit(part)
	for _, object in part:GetDescendants() do
		if object:IsA("ParticleEmitter") then object:Emit(1) end
	end
end

function UnlimitedClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, UnlimitedClient)
	return self
end

function UnlimitedClient:destroy()
	self._tilter:destroy()
end

function UnlimitedClient:equip()
	self._animator = WeaponUtil.createAnimator()
	self._tilter = WeaponUtil.createWaistTilter()
end

function UnlimitedClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local chargeDuration = 1.5

	self._animator:play("GojoChargeSmall", 0)

	local blueGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.gojoBall({
		part = ReplicatedStorage.Assets.Effects.GojoBlue,
		direction = Vector3.new(0, -1, 0),
		sizeStart = 0.2,
		sizeEnd = 1,
		duration = chargeDuration + 0.2,
		root = char.RightHand,
		guid = blueGuid,
	}))

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		parent = root,
		name = "GojoChargeSmallMedium",
		looping = true,
		fadeIn = chargeDuration,
		guid = soundGuid,
	}))

	Promise.race({
		WeaponUtil.channelPromise(chargeDuration)
			:finally(function()
				self._animator:stopHard("GojoChargeSmall")
			end)
			:andThenReturn("red"),
		Promise.fromEvent(ActionController.actionStopped, function(action)
			return action == "attack"
		end):andThenReturn("blue"),
	})
		:finally(function()
			self._animator:stopHard("GojoChargeSmall")
		end)
		:andThen(function(move)
			if move == "blue" then
				EffectController:cancel(soundGuid)
				return self:_throwBlue(request):finally(function()
					EffectController:cancel(blueGuid)
				end)
			elseif move == "red" then
				EffectController:cancel(blueGuid)
				self._animator:play("GojoChargeMedium", 0)

				EffectController:replicate(EffectUtil.sound({
					parent = root,
					name = "GojoHitLarge",
				}))

				local redGuid = EffectUtil.guid()
				EffectController:replicate(EffectUtil.gojoBall({
					part = ReplicatedStorage.Assets.Effects.GojoRed,
					direction = Vector3.new(-1, 0, 0),
					sizeStart = 1,
					sizeEnd = 2,
					duration = 0.5,
					persistent = true,
					root = char.RightHand,
					guid = redGuid,
				}))

				return Promise.race({
					Promise.fromEvent(ActionController.actionStopped, function(action)
						return action == "attack"
					end):andThenCall(function()
						EffectController:cancel(soundGuid)
						return self:_throwRed(request)
					end),
					Promise.fromEvent(StunController.stunned):andThenCall(Promise.reject),
				}):finally(function()
					self._animator:stopHard("GojoChargeMedium")
					EffectController:cancel(redGuid)
				end)
			else
				error(`Unrecognized move {move}`)
			end
		end)
		:finally(function()
			EffectController:cancel(soundGuid)
			WeaponController:useGlobalCooldown()
			self._attackCooldown:use(self.definition.attackCooldown)
		end)
		:catch(function() end)

	WeaponController:useGlobalCooldown(math.huge)
end

function UnlimitedClient:_throwBlue(request)
	local root = WeaponUtil.getRoot()
	local char = WeaponUtil.getChar()
	if not root and char then return Promise.reject() end

	self._animator:play("GojoThrow", 0)

	return WeaponUtil.channelPromise(0.05):andThen(function()
		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "GojoLaunchSmall",
		}))

		local here = char.RightHand.Position
		local there = MouseUtil.raycast().position
		local cframe = CFrame.lookAt(here, there)

		local guid = EffectUtil.guid()
		EffectController:replicate(EffectUtil.projectile({
			guid = guid,
			name = "GojoBlue",
			cframe = cframe,
			speed = 64,
			owner = Players.LocalPlayer,
			gravity = 0,
			onTouched = function(part)
				local target = WeaponUtil.findDamageTarget(part)
				if not target then return ProjectileHelper.isProjectileCollidable(part) end
				if target:IsDescendantOf(char) then return false end

				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					color = Color3.fromRGB(0, 170, 255),
				}))

				request(target)

				return true
			end,
			onFinished = function(part)
				EffectController:replicate(EffectUtil.sound({
					position = part.Position,
					name = "GojoHitSmall",
				}))
			end,
			onStartedAll = quickEmit,
		}))
	end)
end

function UnlimitedClient:_throwRed(request)
	local root = WeaponUtil.getRoot()
	local char = WeaponUtil.getChar()
	if not root and char then return Promise.reject() end

	self._animator:play("GojoThrow", 0)

	return WeaponUtil.channelPromise(0.05):andThen(function()
		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "GojoLaunchMedium",
		}))

		local here = char.RightHand.Position
		local there = MouseUtil.raycast().position
		local cframe = CFrame.lookAt(here, there)

		local victimSet = {}

		local guid = EffectUtil.guid()
		EffectController:replicate(EffectUtil.projectile({
			guid = guid,
			name = "GojoRed",
			cframe = cframe,
			speed = 64,
			owner = Players.LocalPlayer,
			gravity = 0,
			onTouched = function(part, projectile)
				local target = WeaponUtil.findDamageTarget(part)
				if not target then return false end
				if target:IsDescendantOf(char) then return false end

				if victimSet[target] then return end
				victimSet[target] = true

				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					color = Color3.fromRGB(255, 75, 75),
				}))

				EffectController:replicate(EffectUtil.sound({
					parent = WeaponUtil.getTargetRoot(target),
					name = "GojoHitMedium",
				}))

				request(target, (part.Position - projectile.Position).Unit)

				return false
			end,
			onStartedAll = quickEmit,
		}))
	end)
end

function UnlimitedClient:special(request)
	if not WeaponController:isGlobalCooldownReady() then return end
	if not self._specialCooldown:isReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local chargeDuration = 2

	self._animator:play("GojoChargeLarge", 0)

	local ballGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.gojoBall({
		part = ReplicatedStorage.Assets.Effects.GojoPurple,
		direction = Vector3.new(-1, 0, 0),
		sizeStart = 1,
		sizeEnd = 4.5,
		duration = chargeDuration,
		root = char.RightHand,
		guid = ballGuid,
	}))

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid,
		parent = root,
		name = "GojoChargeBig",
	}))

	WeaponUtil.channelPromise(chargeDuration)
		:finally(function()
			EffectController:cancel(soundGuid)
			EffectController:cancel(ballGuid)
			self._animator:stopHard("GojoChargeLarge")
		end)
		:andThen(function()
			self._animator:play("GojoThrow", 0)

			EffectController:replicate(EffectUtil.sound({
				parent = root,
				name = "GojoLaunchBig",
			}))

			local here = char.RightHand.Position
			local there = MouseUtil.raycast().position
			local cframe = CFrame.lookAt(here, there)

			local victimSet = {}

			local guid = EffectUtil.guid()
			EffectController:replicate(EffectUtil.projectile({
				guid = guid,
				name = "GojoPurple",
				cframe = cframe,
				speed = 24,
				owner = Players.LocalPlayer,
				gravity = 0,
				onTouched = function(part)
					local target = WeaponUtil.findDamageTarget(part)
					if not target then return false end
					if target:IsDescendantOf(char) then return false end

					if victimSet[target] then return false end
					victimSet[target] = true

					EffectController:replicate(EffectUtil.hitEffect({
						part = WeaponUtil.getTargetRoot(target),
						emitterName = "Impact1",
						particleCount = 2,
						color = Color3.new(0, 1, 0),
					}))

					EffectController:replicate(EffectUtil.sound({
						parent = WeaponUtil.getTargetRoot(target),
						name = "GojoHitLarge",
					}))

					request(target, cframe.LookVector)

					return false
				end,
				onStartedAll = quickEmit,
			}))
		end)
		:catch(function() end)

	WeaponController:useGlobalCooldown(chargeDuration + 0.1)
	self._specialCooldown:use()
end

return UnlimitedClient
