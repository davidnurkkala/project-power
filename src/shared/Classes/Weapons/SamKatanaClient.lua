local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local SamKatanaClient = {}
SamKatanaClient.__index = SamKatanaClient

local function createDashBuff(count, duration, onActivated, onDeactivated)
	local buff = {
		active = false,
		count = 0,
		thread = nil,
	}

	function buff:activate()
		self.active = true
		self.count = count
		self.promise = Promise.delay(duration):andThen(function()
			self:deactivate()
		end)
		onActivated()
	end

	function buff:use()
		self.count -= 1
		if self.count == 0 then self:deactivate() end
		return self.active
	end

	function buff:deactivate()
		self.active = false
		if self.promise then
			self.promise:cancel()
			self.promise = nil
		end
		onDeactivated()
	end

	return buff
end

function SamKatanaClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),

		_dashBuff = createDashBuff(definition.dashBuffCount, definition.dashBuffDuration, function()
			WeaponController:customRemote("StartDashBuff")
		end, function()
			WeaponController:customRemote("StopDashBuff")
		end),
	}, SamKatanaClient)
	return self
end

function SamKatanaClient:destroy()
	self._animator:stop("SwordIdle")
end

function SamKatanaClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("SamKatanaIdle")
end

function SamKatanaClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 10
	local animationSpeed = if self._dashBuff.active then 2 else 1

	local function slash(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = "GlaiveSlash" .. math.random(1, 4),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2 / animationSpeed,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
			color = Color3.new(1, 0, 0),
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
					color = Color3.new(1, 0, 0),
				}))

				request(target)
			end,
		})
	end

	self._animator:stopHard("SamKatanaSlash1")
	self._animator:stopHard("SamKatanaSlash2")

	if self._attackRight then
		self._animator:play("SamKatanaSlash1", 0, nil, animationSpeed)
		slash(CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(-150)))
	else
		self._animator:play("SamKatanaSlash2", 0, nil, animationSpeed)
		slash(CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(-30)))
	end

	self._attackRight = not self._attackRight

	if self._dashBuff:use() then
		self._attackCooldown:use(0.1)
		WeaponController:useGlobalCooldown(0.1)
	else
		self._attackCooldown:use()
		WeaponController:useGlobalCooldown()
	end
end

function SamKatanaClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end
	local char = WeaponUtil.getChar()
	if not char then return end
	local weapon = char:FindFirstChild("SamKatana")

	local radius = 16
	local cframe = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(30))

	local soundGuid1 = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid1,
		name = "BigSwordClang1",
		parent = root,
	}))

	local soundGuid2 = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid2,
		name = "GunCock1",
		parent = root,
	}))

	local reattachGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.reattach({
		guid = reattachGuid,
		motor = weapon.Root.Motor6D,
		attachment0 = weapon.Sheath.Handle.SwordAttachment,
		attachment1 = weapon.Root.SwordAttachment,
	}))

	self._animator:stopHard("SamKatanaSlash1")
	self._animator:stopHard("SamKatanaSlash2")
	self._animator:play("SamKatanaSheathed", 0)

	WeaponUtil.channel({
		duration = self.definition.chargeDuration,
		onFinished = function(success)
			self._animator:stopHard("SamKatanaSheathed")
			EffectController:cancel(reattachGuid)

			if success then
				self._animator:play("SamKatanaUnsheath", 0)

				EffectController:replicate(EffectUtil.sound({
					name = "GlaiveSlash" .. math.random(1, 4),
					parent = root,
				}))

				EffectController:replicate(EffectUtil.sound({
					name = "Gunshot1",
					parent = root,
				}))

				EffectController:replicate(EffectUtil.emit({
					emitter = weapon.Sheath.Handle.EffectAttachment.Emitter,
					particleCount = 6,
				}))

				EffectController:replicate(EffectUtil.flash({
					light = weapon.Sheath.Handle.EffectAttachment.Light,
					duration = 0.1,
				}))

				EffectController:replicate(EffectUtil.slash1({
					radius = radius,
					duration = 0.15,
					cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
					rotation = math.rad(-180),
					root = root,
					partName = "Slash2",
					color = Color3.new(1, 0, 0),
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
						local targetRoot = WeaponUtil.getTargetRoot(target)

						EffectController:replicate(EffectUtil.hitEffect({
							part = targetRoot,
							emitterName = "Impact1",
							particleCount = 2,
							soundName = "BigSwordHit" .. math.random(1, 3),
							color = Color3.new(1, 0, 0),
						}))

						local delta = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)
						request({
							target = target,
							direction = delta.Unit + Vector3.new(0, 1, 0),
						})
					end,
				})
			else
				EffectController:cancel(soundGuid1)
				EffectController:cancel(soundGuid2)
				WeaponController:useGlobalCooldown()
			end
		end,
	})

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(self.definition.chargeDuration + 0.2)
end

function SamKatanaClient:dash()
	local onDashCompletion = DashController:dash()
	if not onDashCompletion then return end

	self._dashBuff:activate()
end

return SamKatanaClient
