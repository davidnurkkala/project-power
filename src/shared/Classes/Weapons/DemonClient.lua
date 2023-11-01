local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local DemonClient = {}
DemonClient.__index = DemonClient

function DemonClient.new(definition)
	local self = setmetatable({
		definition = definition,
		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),
		_attackIndex = 0,
		_attacks = {
			"DemonAttack1",
			"DemonAttack2",
			"DemonSpin",
			"DemonAttack3",
		},
		_lastAttackTime = 0,
	}, DemonClient)
	return self
end

function DemonClient:equip()
	self._animator = WeaponUtil.createAnimator(self.player)
end

function DemonClient:destroy() end

function DemonClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local player = Players.LocalPlayer
	if not player then return end

	local character = player.Character
	if not character then return end

	for _, attackName in self._attacks do
		self._animator:stopHard(attackName)
	end

	-- TODO: create generic input timing object for button mash combos
	local currentTime = tick()
	if currentTime - self._lastAttackTime > 0.7 then
		self._attackIndex = 1
	else
		self._attackIndex = (self._attackIndex % #self._attacks) + 1
	end
	self._lastAttackTime = currentTime

	local function punch(range: number, dx: number)
		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(5, 4, range),
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 1,
					soundName = "DemonHit1",
					color = Color3.fromRGB(0, 0, 0),
				}))

				request(target)
			end,
		})

		EffectController:replicate(EffectUtil.punch({
			width = 4,
			length = range + 1,
			duration = 0.1,
			startOffset = CFrame.new(dx, -0.5, 2),
			endOffset = CFrame.new(dx, -0.5, -2),
			root = root,
			color = Color3.fromRGB(200, 0, 0),
		}))
	end

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
					particleCount = 1,
					soundName = "DemonHit1",
					color = Color3.fromRGB(0, 0, 0),
				}))

				request(target)
			end,
		})
		EffectController:replicate(EffectUtil.slash1({
			radius = radius + 1,
			duration = 0.2,
			cframe = CFrame.new(0, -1, 0) * CFrame.Angles(0, math.rad(45), 0),
			rotation = math.rad(-450),
			root = root,
			partName = "Slash2",
			color = Color3.fromRGB(200, 0, 0),
		}))
	end

	local function stomp(radius)
		WeaponUtil.hitboxLingering({
			hitbox = function()
				return WeaponUtil.hitboxMelee({
					root = root,
					size = Vector3.new(5, 4, radius),
				})
			end,
			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 1,
					soundName = "DemonHit1",
					color = Color3.fromRGB(0, 0, 0),
				}))

				request(target)
			end,
		})

		EffectController:replicate(EffectUtil.slash1({
			radius = radius,
			duration = 0.15,
			cframe = CFrame.Angles(0, 0, math.rad(-90)) * CFrame.Angles(0, math.rad(150), 0),
			rotation = math.rad(-110),
			root = root,
			partName = "SlashBash1",
			color = Color3.fromRGB(200, 0, 0),
		}))
	end

	--// Generic effects
	EffectController:replicate(EffectUtil.sound({ parent = root, name = "Swish1" }))
	EffectController:replicate(EffectUtil.demonAttack({ character = character, duration = WeaponDefinitions.Demon.attackCooldown }))
	self._animator:play(self._attacks[self._attackIndex])

	--// smear and hitbox
	if self._attackIndex == 1 then
		punch(9.5, -1.5)
	elseif self._attackIndex == 2 then
		punch(9.5, 1.5)
	elseif self._attackIndex == 3 then
		spin(8.5)
	elseif self._attackIndex == 4 then
		stomp(8.5)
	end

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function DemonClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	local humanoid = WeaponUtil.getHuman()
	if not (root and humanoid) then return end
	local character = root.Parent

	local rootRigAttachment = root:FindFirstChild("RootRigAttachment")
	if not rootRigAttachment then return end

	self._specialCooldown:use()

	-- TODO: create a "jump attack" WeaponUtil function for this, Slate Maul, etc.
	WeaponUtil.forceJump():andThen(function()
		local trove = Trove.new()

		self._animator:play("DemonFlipJump")
		trove:Add(function()
			self._animator:stopHard("DemonFlipJump")
		end)

		trove:Connect(RunService.Stepped, function()
			WeaponController:useGlobalCooldown()
		end)

		EffectController:replicate(EffectUtil.demonFlip({
			character = root.Parent,
		}))

		Promise.fromEvent(humanoid.StateChanged, function(_, state)
			local isInAir = (state == Enum.HumanoidStateType.Jumping) or (state == Enum.HumanoidStateType.Freefall)
			return not isInAir
		end):andThen(function()
			trove:Clean()

			if humanoid:GetState() ~= Enum.HumanoidStateType.Landed then return end

			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { character }
			local rayResult = workspace:Raycast(root.Position, Vector3.new(0, -16, 0), params)
			if not rayResult then return end

			--// drop
			local launchCFrame = CFrame.new(root.Position - Vector3.new(0, 2, 0)) * CFrame.Angles(math.rad(60), 0, 0)

			local targets = WeaponUtil.hitSphere({
				position = rayResult.Position,
				radius = 13,
			})

			local victims = {}
			for _, target in targets do
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 1,
					soundName = "DemonHit1",
					color = Color3.fromRGB(0, 0, 0),
				}))

				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "DemonSymbol",
					particleCount = 1,
					soundName = "Dummy",
					color = Color3.fromRGB(0, 0, 0),
				}))

				local targetRoot = WeaponUtil.getTargetRoot(target)
				if not targetRoot then continue end

				table.insert(victims, {
					target = target,
					direction = (targetRoot.Position - launchCFrame.Position).Unit,
				})
			end
			request(victims)

			EffectController:replicate(EffectUtil.demonDrop({
				character = root.parent,
				rayInstance = rayResult.Instance,
				rayPosition = rayResult.Position,
			}))
			self._animator:play("DemonFlipDrop")

			--// let the animation linger a tiny bit
			task.wait(0.5)
			self._animator:stopHard("DemonFlipDrop", 0)
		end)
	end)
end

function DemonClient:dash(request)
	local onDashCompletion = DashController:dash({
		soundDisabled = true,
		cooldown = self.definition.dashCooldown,
		animationDisabled = true,
	})
	if not onDashCompletion then return end

	local player = Players.LocalPlayer
	if not player then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local root = character.PrimaryPart
	if not root then return end

	--// override dash settings
	--if not humanoid.AutoRotate then humanoid.AutoRotate = true end
	EffectController:replicate(EffectUtil["demonDash"]({
		root = root,
		duration = 0.25,
		soundDisabled = false,
	}))

	self._animator:play("DemonDash", 0, 5)

	request(true) -- request server start dash
	onDashCompletion(function()
		self._animator:stopHard("DemonDash")
		request(false) -- request server stop dash
	end)
end

return DemonClient
