local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local LinkedSwordClient = require(ReplicatedStorage.Shared.Classes.Weapons.LinkedSwordClient)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local EarthBladeClient = {}
EarthBladeClient.__index = EarthBladeClient

function EarthBladeClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_attackRight = true,
	}, EarthBladeClient)
	return self
end

function EarthBladeClient:destroy()
	self._animator:stop("SwordIdle")
end

function EarthBladeClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("SwordIdle")
end

function EarthBladeClient:attack(...)
	LinkedSwordClient.attack(self, ...)
end

function EarthBladeClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local char = WeaponUtil.getChar()
	local model = char and char:FindFirstChild("EarthBlade")
	local weapon = model and model:FindFirstChild("Weapon")
	if not weapon then return end

	self._animator:play("EarthBladeThrow", 0)

	WeaponUtil.channelPromise(0.2)
		:andThen(function()
			local radius = 6
			local duration = self.definition.specialDuration
			local offset = CFrame.new(0.35, 0.75, -6.25) * CFrame.Angles(0, 0, -math.pi / 2)
			local rotationSpeed = 720

			local slashGuid = EffectUtil.guid()
			EffectController:replicate(EffectUtil.slash1({
				guid = slashGuid,
				radius = radius,
				duration = duration,
				cframe = offset,
				rotation = rotationSpeed * duration,
				root = root,
			}))

			local soundGuid = EffectUtil.guid()
			EffectController:replicate(EffectUtil.sound({
				guid = soundGuid,
				parent = weapon,
				name = "Helicopter",
				duration = duration,
			}))

			local thread = task.spawn(function()
				local hitCount = self.definition.specialHitCount
				local waitTime = duration / hitCount

				for _ = 1, hitCount do
					local targets = WeaponUtil.hitbox({
						cframe = root.CFrame * offset,
						size = Vector3.new(radius * 2, 3, radius * 2),
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

					task.wait(waitTime)
				end
			end)

			self._animator:play("EarthBladeSpin", 0.2)
			return WeaponUtil.channelPromise(duration):finally(function()
				task.cancel(thread)
				self._animator:stop("EarthBladeSpin", 0.2)
				EffectController:cancel(slashGuid)
				EffectController:cancel(soundGuid)
			end)
		end)
		:finally(function()
			self._specialCooldown:use()
			WeaponController:useGlobalCooldown()
		end)

	self._specialCooldown:use(10)
	WeaponController:useGlobalCooldown(10)
end

return EarthBladeClient
