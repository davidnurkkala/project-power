local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local AbyssClient = {}
AbyssClient.__index = AbyssClient

function AbyssClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_attacks = {
			"AbyssSpin",
			"AbyssStab",
			"AbyssSlam",
		},
		_attackIndex = 0,
		_lastAttackTime = 0,
	}, AbyssClient)
	return self
end

function AbyssClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("AbyssIdle")
end

function AbyssClient:destroy()
	self._animator:stop("AbyssIdle")
end

function AbyssClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	for _, attackName in self._attacks do
		self._animator:stopHard(attackName)
	end

	-- TODO: create generic input timing object for button mash combos
	local currentTime = tick()
	if currentTime - self._lastAttackTime > 1 then
		self._attackIndex = 1
	else
		self._attackIndex = (self._attackIndex % #self._attacks) + 1
	end
	self._lastAttackTime = currentTime

	-- Attacks
	local function spin(radius: number)
		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitSphere({
					position = root.Position,
					radius = radius,
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "BigSwordHit" .. math.random(1, 3),
				}))

				local targetRoot = WeaponUtil.getTargetRoot(target)
				if not targetRoot then return end

				local delta = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)

				request({
					target = target,
					direction = delta.Unit,
				})
			end,
		})

		task.delay(0.1, function()
			EffectController:replicate(EffectUtil.slash1({
				radius = radius + 1,
				duration = 0.3,
				cframe = CFrame.new(0, -1, 0) * CFrame.Angles(0, math.rad(45), 0),
				rotation = math.rad(450),
				root = root,
				partName = "Slash2",
				color = Color3.fromRGB(255, 255, 255),
			}))
		end)
	end

	local function stab(range: number, dx: number)
		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(6, 4, range),
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "BigSwordHit" .. math.random(1, 3),
				}))

				local targetRoot = WeaponUtil.getTargetRoot(target)
				if not targetRoot then return end

				local delta = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)

				request({
					target = target,
					direction = delta.Unit,
				})
			end,
		})

		task.delay(0.1, function()
			EffectController:replicate(EffectUtil.punch({
				width = 7,
				length = range + 8,
				duration = 0.15,
				startOffset = CFrame.new(dx, -1, 2),
				endOffset = CFrame.new(dx, -1, -2),
				root = root,
				color = Color3.fromRGB(255, 255, 255),
			}))
		end)
	end

	local function slam(radius: number)
		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(6, 5, radius),
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = "BigSwordHit" .. math.random(1, 3),
				}))

				local targetRoot = WeaponUtil.getTargetRoot(target)
				if not targetRoot then return end

				local delta = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)

				request({
					target = target,
					direction = delta.Unit,
				})
			end,
		})

		task.delay(0.1, function()
			EffectController:replicate(EffectUtil.slash1({
				radius = radius,
				duration = 0.15,
				cframe = CFrame.new(1.5, 0, 0) * CFrame.Angles(0, 0, math.rad(-105)) * CFrame.Angles(0, math.rad(150), 0),
				rotation = math.rad(-110),
				root = root,
				partName = "Slash2",
			}))
		end)
	end

	-- generic effects
	EffectController:replicate(EffectUtil.sound({
		name = "BigSwordSlash" .. math.random(2, 4),
		parent = root,
		pitchRange = NumberRange.new(1, 1.05),
	}))
	self._animator:play(self._attacks[self._attackIndex])

	-- smear and hitbox
	if self._attackIndex == 1 then
		spin(10)
	elseif self._attackIndex == 2 then
		stab(10, 2.5)
	elseif self._attackIndex == 3 then
		slam(10)
	end

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function AbyssClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	local human = WeaponUtil.getHuman()
	if not (root and human) then return end

	local trove = Trove.new()

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(self.definition.specialChargeDuration + 0.2)

	-- start squat
	local horizontalSpeed = 110
	local verticalSpeed = 70
	local abyssJumpDuration = 0.35
	local abyssDropDuration = abyssJumpDuration / 2

	local function handleSquat(soundGuid, chargeGuid)
		self._animator:play("AbyssSquat", 0, nil, 1 / self.definition.specialChargeDuration)
		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "AbyssSpecialEnable",
			guid = soundGuid,
		}))

		EffectController:replicate(EffectUtil.emitter({
			guid = chargeGuid,
			name = "AbyssCharge",
			parent = root,
		}))
		trove:Add(function()
			EffectController:replicate(EffectUtil.cancel({
				guid = chargeGuid,
			}))
		end)
	end

	local function handleJump()
		if not root or not root.Parent then return end

		local mover = ForcedMovementHelper.register(root)
		trove:Add(mover, "destroy")

		trove:Connect(RunService.Stepped, function()
			local direction = ((root.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * horizontalSpeed) + Vector3.new(0, verticalSpeed, 0)
			mover:update(direction.X, direction.Y, direction.Z)

			WeaponController:useGlobalCooldown()
		end)

		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "AbyssJump",
		}))
		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "RockImpact1",
			pitchRange = NumberRange.new(0.95, 1.05),
		}))

		EffectController:replicate(EffectUtil.emitAtCFrame({
			emitterName = "AbyssCircle",
			particleCount = 1,
			cframe = CFrame.new(root.Position),
		}))

		-- Floor impact
		local size = root.Parent:GetExtentsSize()
		local charHeight = size.Y -- good enough

		if human.FloorMaterial ~= Enum.Material.Air or human.FloorMaterial ~= Enum.Material.Water then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { root.Parent }
			local result = workspace:Raycast(root.Position, Vector3.new(0, -charHeight, 0), params)

			if result then
				local cf = CFrame.lookAt(result.Position, result.Position + result.Normal) * CFrame.Angles(math.rad(-90), 0, 0)

				EffectController:replicate(EffectUtil.floorImpact1({
					cframe = cf,
					part = result.Instance,
				}))
			end
		end

		-- speed trail
		local guid = HttpService:GenerateGUID(false)
		EffectController:replicate(EffectUtil.trail({
			guid = guid,
			root = root,
			offset0 = CFrame.new(0, 1.5, 0),
			offset1 = CFrame.new(0, -1.5, 0),
			trailName = "AbyssSmear",
		}))
		trove:Add(function()
			EffectController:cancel(guid)
		end)

		self._animator:play("AbyssJumpLoop", 0)
		trove:Add(function()
			self._animator:stopHard("AbyssJumpLoop")
		end)

		return WeaponUtil.channelPromise(abyssJumpDuration):finally(function()
			trove:Clean()
		end)
	end

	local function handleDrop()
		if not root or not root.Parent then return end

		local mover = ForcedMovementHelper.register(root)
		trove:Add(mover, "destroy")

		trove:Connect(RunService.Stepped, function()
			local direction = ((root.CFrame.LookVector * Vector3.new(1, 0, 1)) * (horizontalSpeed / 2)) + Vector3.new(0, -verticalSpeed * 2, 0)
			mover:update(direction.X, direction.Y, direction.Z)

			WeaponController:useGlobalCooldown()
		end)

		self._animator:play("AbyssDropLoop")
		trove:Add(function()
			self._animator:stopHard("AbyssDropLoop")
		end)

		EffectController:replicate(EffectUtil.sound({
			parent = root,
			name = "AbyssJump",
			pitchRange = NumberRange.new(0.85),
		}))

		return WeaponUtil.channelPromise(abyssDropDuration):finally(function()
			trove:Clean()
		end)
	end

	local soundGuid = HttpService:GenerateGUID(false)
	local chargeGuid = HttpService:GenerateGUID(false)
	handleSquat(soundGuid, chargeGuid)

	WeaponUtil.channelPromise(self.definition.specialChargeDuration)
		:finally(function()
			EffectController:cancel(chargeGuid)
		end)
		:andThen(handleJump)
		:andThen(handleDrop)
		:andThen(function()
			-- Hitbox
			local leapHeight = abyssJumpDuration * verticalSpeed
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { root.Parent }
			local result = workspace:Raycast(root.Position, Vector3.new(0, -1, 0) * leapHeight, params)
			local finalPosition = nil

			if result then
				finalPosition = result.Position
			else
				finalPosition = root.Position + (Vector3.new(0, -1, 0) * leapHeight)
			end

			local targets = WeaponUtil.hitSphere({
				position = finalPosition,
				radius = self.definition.specialRadius,
			})

			local launchDirection = root.CFrame.LookVector * Vector3.new(1, 0, 1)

			local victims = {}
			for _, target in targets do
				local targetRoot = WeaponUtil.getTargetRoot(target)
				if not targetRoot then continue end

				table.insert(victims, {
					target = target,
					direction = launchDirection,
				})
			end
			request(victims)

			-- effect
			EffectController:replicate(EffectUtil.emitAtCFrame({
				emitterName = "AbyssDrop",
				particleCount = 80,
				cframe = CFrame.new(finalPosition),
			}))
			EffectController:replicate(EffectUtil.sound({
				parent = root,
				name = "AbyssDrop",
				duration = abyssDropDuration + 1,
			}))
		end)
		:catch(function()
			EffectController:cancel(soundGuid)
			trove:Clean()

			-- shorter cooldown on failure
			self._specialCooldown:use(self.definition.specialCooldown / 2)
		end)
end

return AbyssClient
