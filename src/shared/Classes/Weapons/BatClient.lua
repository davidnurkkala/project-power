local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local BatClient = {}
BatClient.__index = BatClient

function BatClient.new(definition)
	local self = setmetatable({
		definition = definition,

		_attackCooldown = Cooldown.new(definition.attackCooldown),
		_specialCooldown = Cooldown.new(definition.specialCooldown),

		_rageActive = false,
		_trove = Trove.new(),
	}, BatClient)

	return self
end

function BatClient:destroy()
	self._animator:stop("BatIdle")
	self._trove:Clean()
end

function BatClient:equip()
	self._animator = WeaponUtil.createAnimator()
	self._animator:play("BatIdle")

	local root = WeaponUtil.getRoot()
	if not root then return end

	local weapon = root.Parent.Bat
	local weaponTip = weapon.Root.WeaponTip

	self._batSpecialEmitter = weaponTip:WaitForChild("BatSpecialEmitter")
	self._batRageEmitter = weapon.Root:WaitForChild("BatRage")

	--// don't want to make a remote event just to let the client know they are enraged
	self._trove:Connect(self._batRageEmitter:GetPropertyChangedSignal("Enabled"), function()
		self._rageActive = self._batRageEmitter.Enabled
	end)
end

function BatClient:attack(request)
	if not self._attackCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 8
	local color = Color3.new(0.6, 1, 0.7)

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
			color = color,
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
					soundName = "BatHit",
				}))

				if self._rageActive then
					EffectController:replicate(EffectUtil.hitEffect({
						part = WeaponUtil.getTargetRoot(target),
						emitterName = "BatRageHit",
						particleCount = 20,
						soundName = "FirePunch" .. tostring(math.random(1, 4)),
					}))
				else
					EffectController:replicate(EffectUtil.hitEffect({
						part = WeaponUtil.getTargetRoot(target),
						emitterName = "Impact1",
						particleCount = 2,
						soundName = "Slap1",
					}))
				end

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

function BatClient:special(request)
	if not self._specialCooldown:isReady() then return end
	if not WeaponController:isGlobalCooldownReady() then return end

	local root = WeaponUtil.getRoot()
	if not root then return end

	local radius = 8
	local cframe = CFrame.Angles(0, 0, math.rad(160))
	local color = Color3.new(0.600000, 1.000000, 0.694118)

	self._animator:stopHard("BatLeftSwing")
	self._animator:stopHard("BatRightSwing")
	self._animator:play("BatHomerunCharge", 0)
	EffectController:replicate(EffectUtil.sound({
		name = "BatSpecial",
		parent = root,
	}))
	if self._batSpecialEmitter then EffectController:replicate(EffectUtil.emit({ emitter = self._batSpecialEmitter, particleCount = 1 })) end

	WeaponUtil.channel({
		duration = self.definition.specialChargeDuration,
		onFinished = function(success)
			self._animator:stopHard("BatHomerunCharge")

			if success then
				self._animator:play("BatHomerunSwing", 0)

				EffectController:replicate(EffectUtil.sound({
					name = "Whoosh1",
					parent = root,
				}))
				-- smear
				EffectController:replicate(EffectUtil.slash1({
					radius = radius,
					duration = 0.2,
					cframe = cframe * CFrame.Angles(0, math.rad(-130), 0),
					rotation = math.rad(-180),
					root = root,
					color = color,
					partName = "SlashBash1",
				}))

				local launchCFrame = root.CFrame * CFrame.Angles(math.rad(50), 0, 0)

				local cheered = false
				WeaponUtil.hitboxLingering({
					hitbox = function()
						return WeaponUtil.hitboxMelee({
							root = root,
							size = Vector3.new(radius, 12, radius),
						})
					end,
					callback = function(target)
						local targetRoot = WeaponUtil.getTargetRoot(target)

						EffectController:replicate(EffectUtil.hitEffect({
							part = WeaponUtil.getTargetRoot(target),
							emitterName = "Impact1",
							particleCount = 1,
							soundName = "BatHit",
						}))

						if targetRoot then
							EffectController:replicate(EffectUtil.emitAtCFrame({
								emitterName = "BatSpecialShine",
								particleCount = 1,
								cframe = CFrame.new(targetRoot.Position),
							}))
						end

						if target:IsA("Humanoid") and not cheered then
							cheered = true
							EffectController:replicate(EffectUtil.sound({
								name = "BatCheer",
								parent = root,
							}))
							EffectController:replicate(EffectUtil.sound({
								name = "BatHomerun",
								parent = root,
							}))
						end

						request(target, launchCFrame.LookVector)
					end,
				})
			end
		end,
	})

	self._specialCooldown:use()
	self._attackCooldown:use()
	WeaponController:useGlobalCooldown(self.definition.specialChargeDuration + self.definition.attackCooldown)
end

return BatClient
