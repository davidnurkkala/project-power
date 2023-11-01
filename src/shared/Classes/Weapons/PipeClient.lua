local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local PipeClient = {}
PipeClient.__index = PipeClient

function PipeClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),

		_trove = Trove.new(),
	}, PipeClient)

	return self
end

function PipeClient:destroy()
	self._animator:stop("BatIdle")
	self._trove:Clean()
end

function PipeClient:equip()
	self._animator = WeaponUtil.createAnimator()
	self._animator:play("BatIdle")

	local character = WeaponUtil.getChar()
	if not character then return end

	self._model = character.Pipe
	self._trove:Add(function()
		self._model = nil
	end)

	self._pipeSpecialEmitter = self._model.Handle.RightGripAttachment:WaitForChild("PipeSpecialEmitter")
end

function PipeClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 8

	local function swing(cframe)
		EffectController:replicate(EffectUtil.sound({
			name = "Whoosh1",
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
					size = Vector3.new(radius * 2, 4, radius),
					offset = cframe,
				})
			end,

			callback = function(target)
				EffectController:replicate(EffectUtil.hitEffect({
					part = WeaponUtil.getTargetRoot(target),
					emitterName = "Impact1",
					particleCount = 1,
					soundName = "HammerHit" .. tostring(math.random(4)),
				}))

				EffectController:replicate(EffectUtil.sound({
					parent = WeaponUtil.getTargetRoot(target),
					name = "PipeClink" .. tostring(math.random(5)),
					pitchRange = NumberRange.new(0.95, 1),
				}))

				request(target)
			end,
		})
	end

	self._animator:stopHard("BatRightSwing")
	self._animator:stopHard("BatLeftSwing")
	if self._attackRight then
		self._animator:play("BatRightSwing", 0)
		swing(CFrame.Angles(0, 0, math.rad(10)))
	else
		self._animator:play("BatLeftSwing", 0)
		swing(CFrame.Angles(0, 0, math.rad(-160)))
	end

	self._attackRight = not self._attackRight

	self._attackCooldown:use()
	WeaponController:useGlobalCooldown()
end

function PipeClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local char = WeaponUtil.getChar()
	if not char then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 14

	self._animator:play("PipeThrowCharge", nil, nil, 1 / self.definition.specialChargeDuration)
	EffectController:replicate(EffectUtil.emit({ emitter = self._pipeSpecialEmitter, particleCount = 2 }))
	EffectController:replicate(EffectUtil.sound({
		parent = root,
		name = "PipeCharge",
	}))

	WeaponUtil.channelPromise(self.definition.specialChargeDuration)
		:andThen(function()
			-- Throw effect
			self._animator:play("PipeThrow", 0, nil, 1 / 0.5)
			EffectController:replicate(EffectUtil.sound({
				parent = root,
				name = "PipeThrow",
			}))

			-- Projectile
			local here = root.Position
			local there = MouseUtil.raycast().position
			local cframe = CFrame.new(here, there) * CFrame.new(0, 0.5, 0) * CFrame.Angles(math.rad(30), 0, 0)

			local guid = EffectUtil.guid()
			EffectController:replicate(EffectUtil.projectile({
				guid = guid,
				name = "ThrownPipe",
				cframe = cframe,
				speed = 110,
				owner = Players.LocalPlayer,
				gravity = 1.65,
				onTouched = function(part)
					local target = WeaponUtil.findDamageTarget(part)
					if not target then return part.Anchored and part.CanCollide end
					if WeaponUtil.isTargetMe(target) then return false end
					return true
				end,

				onFinished = function(part)
					EffectController:replicate(EffectUtil.sound({
						position = part.Position,
						name = "PipeDrop",
					}))

					EffectController:replicate(EffectUtil.burst1({
						cframe = CFrame.new(part.Position),
						radius = radius,
						duration = 0.3,
						partName = "PipeBurst",
						power = 0.4,
					}))

					local targets = WeaponUtil.hitSphere({
						position = part.Position,
						radius = radius,
						filter = function()
							return true
						end,
					})

					local victims = {}

					for _, target in targets do
						local targetRoot = WeaponUtil.getTargetRoot(target)
						local delta = (targetRoot.Position - cframe.Position)

						if WeaponUtil.isTargetMe(target) then continue end

						EffectController:replicate(EffectUtil.hitEffect({
							part = WeaponUtil.getTargetRoot(target),
							emitterName = "Impact1",
							particleCount = 2,
						}))

						table.insert(victims, {
							target = target,
							direction = delta.Unit,
						})
					end

					request(victims)
				end,
			}))
		end)
		:catch(function()
			-- shorter cooldown on failure
			self._specialCooldown:use(self.definition.specialCooldown / 2)
		end)

	self._specialCooldown:use()
	WeaponController:useGlobalCooldown(self.definition.specialChargeDuration + self.definition.attackCooldown)
end

return PipeClient
