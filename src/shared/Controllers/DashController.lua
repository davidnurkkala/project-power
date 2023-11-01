local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local CooldownCharges = require(ReplicatedStorage.Shared.Classes.CooldownCharges)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local ForcedRotationHelper = require(ReplicatedStorage.Shared.Util.ForcedRotationHelper)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Trove = require(ReplicatedStorage.Packages.Trove)

local StunHelper = require(ReplicatedStorage.Shared.Util.StunHelper)

local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

-- constants
local DASH_COOLDOWN = 1.25
local DASH_IMPULSE_TIME = 0.25
local DASH_SPEED = 80

local DashController = {}
DashController.className = "DashController"
DashController.priority = 0

function DashController:init()
	self._cooldown = CooldownCharges.new(1, DASH_COOLDOWN, DASH_IMPULSE_TIME)

	self._disabledValue = 0

	Players.LocalPlayer.CharacterAdded:Connect(function(char)
		self._cooldown:setMaxCharges(1)
		char:GetAttributeChangedSignal("HasDoubleDash"):Connect(function()
			if char:GetAttribute("HasDoubleDash") then self._cooldown:setMaxCharges(2) end
		end)
	end)
end

function DashController:start() end

function DashController:setDisabled(disabled)
	self._disabledValue += if disabled then 1 else -1
end

function DashController:disable()
	self:setDisabled(true)
	return function()
		self:setDisabled(false)
	end
end

function DashController:dash(argsIn: {
	cooldown: number?,
	soundDisabled: boolean?,
	animationDisabled: boolean?,
}?): (() -> ())?
	local args = argsIn or {}

	if self._disabledValue > 0 then return end

	if StunHelper.isStunned(Players.LocalPlayer) then return end
	if not self._cooldown:isReady() then return end

	local humanoid = WeaponUtil.getHuman()
	local root = WeaponUtil.getRoot()
	if not (root and humanoid and humanoid.Health > 0) then return end

	-- dash in the direction of humanoid movement
	local direction = humanoid.MoveDirection
	if direction.Magnitude == 0 then direction = root.CFrame.LookVector end

	local trove = Trove.new()
	local start = tick()
	self._cooldown:use(args.cooldown)

	if not args.animationDisabled then
		local track = humanoid:LoadAnimation(Animations.Dash)
		track:Play(0)
		trove:Add(track, "Stop")
	end

	EffectController:replicate(EffectUtil.dash({
		root = root,
		duration = DASH_IMPULSE_TIME,
		soundDisabled = args.soundDisabled,
	}))

	local isDashing = true
	trove:Add(function()
		isDashing = false
	end)

	local mover = ForcedMovementHelper.register(root)
	trove:Add(mover, "destroy")

	local rotator = ForcedRotationHelper.register(root, humanoid)
	trove:Add(rotator, "destroy")

	trove:Add(RunService.Stepped:Connect(function(_, _deltaTime)
		-- apply dash as impulse over time to prevent friction on ground
		if self._cooldown:isReady() or tick() - start > DASH_IMPULSE_TIME then
			trove:Clean()
			return
		end
		mover:update(direction.X * DASH_SPEED, if root.AssemblyLinearVelocity.Y < 0 then 0 else nil, direction.Z * DASH_SPEED)
		rotator:update(CFrame.lookAt(root.Position, root.Position + Vector3.new(direction.X, 0, direction.Z)))
	end))

	return function(onDashCompletion)
		assert(isDashing, "onDashCompletion callback must be called before dash is completed")
		trove:Add(onDashCompletion)
	end
end

function DashController:getCooldown()
	return self._cooldown
end

return Loader:registerSingleton(DashController)
