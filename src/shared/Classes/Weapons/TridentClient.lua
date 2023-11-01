local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local ProjectileHelper = require(ReplicatedStorage.Shared.Util.ProjectileHelper)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local TridentClient = {}
TridentClient.__index = TridentClient

function TridentClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_attacks = {
			"SpearAttack1",
			"SpearAttack2",
		},
		_attackIndex = 0,
		_lastAttackTime = 0,
	}, TridentClient)
	return self
end

function TridentClient:equip()
	self._trove = Trove.new()
	self.player = Players.LocalPlayer

	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("SpearIdle")

	local char = WeaponUtil.getChar(self.player)
	self._weapon = char:WaitForChild("Trident")
	self._rightGripAttachment = self._weapon.Handle:WaitForChild("RightGripAttachment")
end

function TridentClient:destroy()
	self._animator:stop("SpearIdle")
end

function TridentClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	for _, attackName in self._attacks do
		self._animator:stopHard(attackName)
	end
	self._trove:Clean()

	-- Animation
	-- TODO: create generic input timing object for button mash combos
	local currentTime = tick()
	if currentTime - self._lastAttackTime > 1 then
		self._attackIndex = 1
	else
		self._attackIndex = (self._attackIndex % #self._attacks) + 1
	end
	self._lastAttackTime = currentTime
	self._animator:play(self._attacks[self._attackIndex], 0)

	-- Attack
	WeaponUtil.hitboxLingering({
		hitbox = function()
			return WeaponUtil.hitboxMelee({
				root = root,
				size = Vector3.new(7, 7, self.definition.attackRange),
			})
		end,
		callback = function(target)
			-- Hit effect
			EffectController:replicate(EffectUtil.hitEffect({
				part = WeaponUtil.getTargetRoot(target),
				emitterName = "ElectricHit",
				particleCount = 2,
				soundName = "ElectricHit" .. math.random(1, 6),
			}))
			EffectController:replicate(EffectUtil.sound({
				parent = WeaponUtil.getTargetRoot(target),
				name = "BigSwordHit" .. math.random(1, 3),
			}))
			request(target)
		end,
	})

	-- Effects
	task.delay(0.05, function()
		EffectController:replicate(EffectUtil.punch({
			width = 7,
			length = self.definition.attackRange + 8,
			duration = 0.15,
			startOffset = CFrame.new(1.5, -1, 2),
			endOffset = CFrame.new(1.5, -1, -2),
			root = root,
			color = Color3.fromRGB(255, 255, 255),
		}))

		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "Whoosh1",
			pitchRange = NumberRange.new(1, 1.02),
		}))
	end)

	-- Cooldowns
	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function TridentClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	-- Animation
	self._animator:play("TridentSpecialCharge", 0, nil, 1 / self.definition.specialChargeDuration)
	self._trove:Add(function()
		self._animator:stopHard("TridentSpecialCharge")
	end)

	-- Effects
	local chargeGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.emitter({
		parent = self._rightGripAttachment,
		name = "ElectricCharge",
		duration = self.definition.specialChargeDuration,
		guid = chargeGuid,
	}))
	self._trove:Add(function()
		EffectController:cancel(chargeGuid)
	end)

	-- Sounds
	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		parent = root,
		name = "ElectricCharge",
		guid = soundGuid,
	}))
	self._trove:Add(function()
		EffectController:cancel(soundGuid)
	end)

	local tilter = WeaponUtil.createWaistTilter()
	self._trove:Add(function()
		tilter:destroy()
	end)

	-- Promise
	WeaponUtil.channelPromise(self.definition.specialChargeDuration)
		:finally(function()
			self._trove:Clean()
		end)
		:andThen(function()
			-- Hitbox
			local here = (root.CFrame * CFrame.new(1.5, 1, 0)).Position
			local there = MouseUtil.raycast().position
			local cframe = CFrame.lookAt(here, there)

			local guid = EffectUtil.guid()
			EffectController:replicate(EffectUtil.projectile({
				guid = guid,
				name = "ThrownTrident",
				cframe = cframe,
				speed = 85,
				owner = self.player,
				gravity = 0.05,

				onTouched = function(part)
					local target = WeaponUtil.findDamageTarget(part)
					if not target then return ProjectileHelper.isProjectileCollidable(part) end
					if WeaponUtil.isTargetMe(target) then return false end
					return true
				end,

				onFinished = function(part)
					local targets = WeaponUtil.hitSphere({
						position = part.Position,
						radius = self.definition.specialRadius,
					})

					local victims = {}
					for _, target in targets do
						local targetRoot = WeaponUtil.getTargetRoot(target)
						local delta = (targetRoot.Position - cframe.Position)

						EffectController:replicate(EffectUtil.hitEffect({
							part = WeaponUtil.getTargetRoot(target),
							emitterName = "ElectricHit",
							particleCount = 2,
							soundName = "ElectricHit" .. math.random(1, 6),
						}))

						EffectController:replicate(EffectUtil.sound({
							parent = WeaponUtil.getTargetRoot(target),
							name = "BigSwordHit" .. math.random(1, 3),
						}))

						table.insert(victims, {
							target = target,
							direction = delta.Unit,
						})
					end

					request(victims)

					-- Sounds
					for number = 1, 2 do
						EffectController:replicate(EffectUtil.sound({
							position = part.Position,
							name = "ElectricStrike" .. number,
						}))
					end

					-- Effect
					EffectController:replicate(EffectUtil.burst1({
						cframe = CFrame.new(part.Position),
						radius = self.definition.specialRadius,
						duration = 0.3,
						partName = "ElectricBurst",
						power = 0.4,
					}))

					EffectController:replicate(EffectUtil.emitAtCFrame({
						emitterName = "ElectricBurst",
						particleCount = 30,
						cframe = part.CFrame,
						useAttachmment = true,
					}))

					local cf = CFrame.new(part.Position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)
					EffectController:replicate(EffectUtil.lightningStrike({
						cframe = cf,
						duration = 0.15,
					}))
				end,
			}))

			-- Animations
			self._animator:play("TridentSpecial", 0)

			-- Effects
			EffectController:replicate(EffectUtil.sound({
				name = "Whoosh1",
				parent = root,
				pitchRange = NumberRange.new(1.05, 1.08),
			}))

			-- Sounds
			EffectController:replicate(EffectUtil.sound({
				parent = root,
				name = "ElectricThrow",
				pitchRange = NumberRange.new(1, 1.02),
			}))
		end)
		:catch(function() end)

	-- Cooldowns
	WeaponController:useGlobalCooldown(self.definition.specialChargeDuration + 0.1)
	self._specialCooldown:use()
end

return TridentClient
