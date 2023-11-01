local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AutoRotateHelper = require(ReplicatedStorage.Shared.Util.AutoRotateHelper)
local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

local SlateMaulClient = {}
SlateMaulClient.__index = SlateMaulClient

function SlateMaulClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
	}, SlateMaulClient)
	return self
end

function SlateMaulClient:destroy()
	self._animator:stop("MaulIdle")
end

function SlateMaulClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
	self._animator:play("MaulIdle")
end

function SlateMaulClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 10

	local function slash(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = pickRandom(self.definition.attackSounds),
			parent = root,
		}))

		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.2,
			cframe = cframe * CFrame.Angles(0, math.rad(135), 0),
			rotation = math.rad(-180),
			root = root,
			partName = "SlashBash1",
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
					soundName = pickRandom(self.definition.hitSounds),
				}))

				request(target)
			end,
		})
	end

	self._animator:stopHard("MaulAttack1")
	self._animator:stopHard("MaulAttack2")

	if self._attackRight then
		self._animator:play("MaulAttack1", 0)
		slash(CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(-175)))
	else
		self._animator:play("MaulAttack2", 0)
		slash(CFrame.Angles(0, 0, math.rad(-5)))
	end

	self._attackRight = not self._attackRight

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function SlateMaulClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	local human = WeaponUtil.getHuman()
	if not (root and human) then return end

	self._specialCooldown:use()

	local maxHeight = -math.huge
	local radiusPerHeight = 1 / 8

	WeaponUtil.forceJump():andThen(function()
		local trove = Trove.new()

		AutoRotateHelper.disable(human)

		self._animator:stopHard("MaulAttack1")
		self._animator:stopHard("MaulAttack2")

		self._animator:play("MaulLeapLoop", 0)
		trove:Add(function()
			self._animator:stopHard("MaulLeapLoop")
		end)

		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1, 0)
		a0.Parent = root

		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1, 0)
		a1.Parent = root

		local trail = ReplicatedStorage.Assets.Trails.DashTrail:Clone()
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Parent = root

		trove:Add(function()
			trail.Enabled = false
			task.delay(trail.Lifetime, function()
				a0:Destroy()
				a1:Destroy()
				trail:Destroy()
			end)
		end)

		local speed = 32

		local mover = ForcedMovementHelper.register(root)
		trove:Add(mover, "destroy")

		trove:Connect(RunService.Stepped, function()
			local direction = (root.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
			mover:update(direction.X * speed, nil, direction.Z * speed)
			maxHeight = math.max(maxHeight, root.Position.Y)

			WeaponController:useGlobalCooldown()
		end)

		EffectController:replicate(EffectUtil.sound({
			name = "Whoosh1",
			parent = root,
		}))

		Promise.fromEvent(human.StateChanged, function(_, state)
			local isInAir = (state == Enum.HumanoidStateType.Jumping) or (state == Enum.HumanoidStateType.Freefall)
			return not isInAir
		end):andThen(function()
			trove:Clean()

			local function cancel()
				AutoRotateHelper.enable(human)
			end

			if human:GetState() ~= Enum.HumanoidStateType.Landed then
				cancel()
				return
			end

			local params = RaycastParams.new()
			params.FilterDescendantsInstances = { WeaponUtil.getChar() }
			params.FilterType = Enum.RaycastFilterType.Exclude
			local origin = root.Position + root.CFrame.LookVector * 8
			local result = workspace:Raycast(origin, Vector3.new(0, -16, 0), params)
			if not result then
				cancel()
				return
			end

			local height = maxHeight - root.Position.Y
			local radius = 12 + radiusPerHeight * height

			self._animator:play("MaulSlam", 0)

			local cframe = CFrame.lookAt(result.Position, result.Position + result.Normal) * CFrame.Angles(-math.pi / 2, 0, 0)

			EffectController:replicate(EffectUtil.sound({
				name = pickRandom(self.definition.impactSounds),
				position = cframe.Position,
			}))

			EffectController:replicate(EffectUtil.impact1({
				cframe = cframe,
				radius = radius,
				duration = 2,
				color = Color3.new(0, 0, 0),
			}))

			EffectController:replicate(EffectUtil.burst1({
				cframe = cframe,
				radius = radius,
				duration = 0.5,
			}))

			EffectController:replicate(EffectUtil.debris1({
				cframe = cframe,
				radius = radius,
				particleCount = 16,
			}))

			EffectController:replicate(EffectUtil.slash1({
				radius = 10,
				duration = 0.15,
				cframe = CFrame.Angles(0, 0, -math.rad(90)) * CFrame.Angles(0, math.rad(200), 0),
				rotation = math.rad(-180),
				root = root,
				partName = "SlashBash1",
			}))

			task.delay(0.3, function()
				AutoRotateHelper.enable(human)
			end)

			local targets = WeaponUtil.hitSphere({
				position = cframe.Position,
				radius = radius,
			})

			local victims = {}
			for _, target in targets do
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 2,
					soundName = pickRandom(self.definition.hitSounds),
				}))

				local targetRoot = WeaponUtil.getTargetRoot(target)
				if not targetRoot then continue end

				local delta = (targetRoot.Position - cframe.Position) * Vector3.new(1, 0, 1)

				table.insert(victims, {
					target = target,
					direction = delta.Unit + Vector3.new(0, 1, 0),
				})
			end

			request(victims)
		end)
	end)
end

return SlateMaulClient
