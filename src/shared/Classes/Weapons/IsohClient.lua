local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local IsohClient = {}
IsohClient.__index = IsohClient

function IsohClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_upward = true,
	}, IsohClient)
	return self
end

function IsohClient:destroy() end

function IsohClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
end

function IsohClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 6
	local cframe
	if self._upward then
		self._animator:play("DaggerSlash1", 0)
		cframe = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(150))
		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
		}))
	else
		self._animator:play("DaggerSlash2", 0)
		cframe = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(30))
		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
		}))
	end

	EffectController:replicate(EffectUtil.sound({
		name = "DaggerSlash" .. math.random(1, 3),
		parent = root,
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
				soundName = "DaggerHit" .. math.random(1, 4),
			}))

			request(target)
		end,
	})

	self._upward = not self._upward

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function IsohClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	self._animator:stopHard("DaggerSlash1")
	self._animator:stopHard("DaggerSlash2")
	self._animator:play("IsohSpecial", 0)

	local soundGuid = EffectUtil.guid()
	EffectController:replicate(EffectUtil.sound({
		guid = soundGuid,
		name = "DaggerScrape1",
		parent = root,
	}))

	Promise.try(function()
		EffectController:replicate(EffectUtil.emit({
			emitter = (WeaponUtil.getChar() :: any).Isoh.Weapon.EmitterAttachment.Emitter,
			particleCount = 1,
		}))
	end):catch(function() end)

	WeaponUtil.channelPromise(0.5)
		:andThen(function()
			local cframe = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(10), 0, 0) * CFrame.new(0, 0, -1)

			EffectController:replicate(EffectUtil.stab({
				width = 8,
				length = 8,
				duration = 0.15,
				startOffset = cframe,
				endOffset = cframe * CFrame.new(0, 0, -2),
				root = root,
			}))

			EffectController:replicate(EffectUtil.sound({
				parent = root,
				name = "DaggerSlash" .. math.random(1, 3),
			}))

			local launchCFrame = root.CFrame * CFrame.Angles(math.rad(60), 0, 0)

			WeaponUtil.hitboxLingering({
				hitbox = function()
					return WeaponUtil.hitboxMelee({
						root = root,
						size = Vector3.new(6, 6, 10),
					})
				end,
				callback = function(target)
					EffectController:replicate(EffectUtil.hitEffect({
						part = WeaponUtil.getTargetRoot(target),
						emitterName = "Impact1",
						particleCount = 2,
						soundName = "DaggerStab" .. math.random(1, 4),
					}))

					request(target, launchCFrame.LookVector)
				end,
			})
		end, function()
			EffectController:cancel(soundGuid)
		end)
		:finally(function()
			WeaponController:useGlobalCooldown()
		end)

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(1)
end

return IsohClient
