local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local DragonSlayerClient = {}
DragonSlayerClient.__index = DragonSlayerClient

function DragonSlayerClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, DragonSlayerClient)
	return self
end

function DragonSlayerClient:destroy() end

function DragonSlayerClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("DragonSlayerIdle")
end

function DragonSlayerClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 15

	local function slash(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = "BigSwordSlash" .. math.random(1, 4),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
			partName = "Slash2",
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
					soundName = "BigSwordHit" .. math.random(1, 3),
				}))

				request(target)
			end,
		})
	end

	self._animator:stopHard("DragonSlayerAttack1")
	self._animator:stopHard("DragonSlayerAttack2")

	if self._attackRight then
		self._animator:play("DragonSlayerAttack1", 0)
		slash(CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(-175)))
	else
		self._animator:play("DragonSlayerAttack2", 0)
		slash(CFrame.Angles(0, 0, math.rad(-5)))
	end

	self._attackRight = not self._attackRight

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function DragonSlayerClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end
	local char = WeaponUtil.getChar()
	if not char then return end
	local weapon = char:FindFirstChild("DragonSlayer")
	if not weapon then return end
	local emitter = weapon.Root.EmitterAttachment.Emitter

	local radius = 16
	local cframe = CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.pi)

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid,
		name = "BigSwordClang1",
		parent = root,
	}))

	EffectController:replicate(EffectUtil.emit({
		emitter = emitter,
		particleCount = 1,
	}))

	self._animator:stopHard("DragonSlayerAttack1")
	self._animator:stopHard("DragonSlayerAttack2")
	self._animator:play("DragonSlayerCharge", 0)

	WeaponUtil.channel({
		duration = self.definition.chargeDuration,
		onFinished = function(success)
			self._animator:stopHard("DragonSlayerCharge")

			if success then
				self._animator:play("DragonSlayerSpin", 0, nil, 1.5)

				EffectController:replicate(EffectUtil.sound({
					name = "BigSwordSlash" .. math.random(1, 4),
					parent = root,
				}))

				EffectController:replicate(EffectUtil.slash1({
					radius = radius,
					duration = 0.2,
					cframe = cframe * CFrame.Angles(0, math.rad(45), 0),
					rotation = math.rad(-450),
					root = root,
					partName = "Slash2",
				}))

				WeaponUtil.hitboxLingering({
					hitbox = function()
						return WeaponUtil.hitbox({
							cframe = root.CFrame * cframe,
							size = Vector3.new(radius * 2, 3, radius * 2),
						})
					end,
					callback = function(target)
						local targetRoot = WeaponUtil.getTargetRoot(target)

						EffectController:replicate(EffectUtil.hitEffect({
							part = targetRoot,
							emitterName = "Impact1",
							particleCount = 2,
							soundName = "BigSwordHit" .. math.random(1, 3),
						}))

						local delta = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)
						request({
							target = target,
							direction = delta.Unit + Vector3.new(0, 1, 0),
						})
					end,
				})
			else
				EffectController:cancel(soundGuid)
				WeaponController:useGlobalCooldown()
			end
		end,
	})

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(self.definition.chargeDuration + 0.2)
end

return DragonSlayerClient
