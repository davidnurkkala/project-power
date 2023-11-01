local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionController = require(ReplicatedStorage.Shared.Controllers.ActionController)
local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local DhorakAxeClient = {}
DhorakAxeClient.__index = DhorakAxeClient

function DhorakAxeClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, DhorakAxeClient)
	return self
end

function DhorakAxeClient:destroy()
	self._animator:stop("DhorakIdle")
end

function DhorakAxeClient:equip()
	self._animator = WeaponUtil.createAnimator()
	self._animator:play("DhorakIdle")
end

function DhorakAxeClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._animator:stopHard("DhorakVengeance")
	self._animator:play("DhorakChargeUp", 0)

	local function smash()
		self._animator:play("DhorakOverheadSmash", 0)

		EffectController:replicate(EffectUtil.sound({
			name = "AxeSwing1",
			parent = root,
		}))

		local cframe = CFrame.new(0.5, 0, 0) * CFrame.Angles(0, 0, math.rad(-100))
		local radius = 10

		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(200), 0),
			rotation = math.rad(-180),
			root = root,
			partName = "SlashBash1",
		}))

		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(radius * 2, 4, radius),
					offset = cframe,
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "AxeHit" .. math.random(1, 4),
				}))

				request("smash", target)
			end,
		})
	end

	local function strike()
		self._animator:play("DhorakPommelStrike")

		local cframe = CFrame.new(0.5, 1, -1) * CFrame.Angles(0, math.rad(10), 0) * CFrame.Angles(math.rad(-25), 0, 0)

		EffectController:replicate(EffectUtil.sound({
			name = "BluntWhoosh" .. math.random(1, 6),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.punch({
			width = 4,
			length = 10,
			duration = 0.2,
			startOffset = cframe,
			endOffset = cframe * CFrame.new(0, 0, -4),
			root = root,
		}))

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
					soundName = "StaffHit" .. math.random(1, 4),
				}))

				request("strike", target)
			end,
		})
	end

	Promise.race({
		WeaponUtil.channelPromise(self.definition.attackChargeDuration):andThen(smash),
		Promise.fromEvent(ActionController.actionStopped, function(action)
			return action == "attack"
		end):andThen(strike),
	})
		:finally(function()
			self._attackCooldown:use()
			WeaponController:useGlobalCooldown()

			self._animator:stopHard("DhorakChargeUp")
		end)
		:catch(function()
			-- do nothing
		end)

	self._attackCooldown:use(self.definition.attackChargeDuration + self.definition.attackCooldown)
	WeaponController:useGlobalCooldown(self.definition.attackChargeDuration + self.definition.attackCooldown)
end

function DhorakAxeClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	EffectController:replicate(EffectUtil.sound({
		name = "DharokVengeance",
		parent = root,
	}))

	self._animator:stopHard("DhorakOverheadSmash")
	self._animator:stopHard("DhorakPommelStrike")
	self._animator:play("DhorakVengeance", 0, nil, 1.7)

	EffectController:replicate(EffectUtil.dhorakVengeanceSkull({ root = root }))

	request()

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(0.25)
end

return DhorakAxeClient
