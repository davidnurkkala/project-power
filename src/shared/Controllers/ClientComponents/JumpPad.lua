local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedMovementHelper = require(ReplicatedStorage.Shared.Util.ForcedMovementHelper)
local JumpController = require(ReplicatedStorage.Shared.Controllers.JumpController)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- consts
local BASE_JUMP_POWER = 1500
local JUMP_COOLDOWN = 5
local RECHARGE_COLOR = Color3.new(1, 0, 0)

local JumpPad = {}
JumpPad.__index = JumpPad

local function getCharacterFromPart(obj: Instance): Model?
	if obj == game then return end

	local parent = obj.Parent
	local humanoid = parent:FindFirstChildOfClass("Humanoid")
	if humanoid then return parent end

	return getCharacterFromPart(parent)
end

function JumpPad:_waitForPrimaryPart()
	if self._model.PrimaryPart then return Promise.resolve() end
	return Promise.fromEvent(self._model:GetPropertyChangedSignal("PrimaryPart"), function()
		return self._model.PrimaryPart ~= nil
	end)
end

function JumpPad:_initRechargeEffect()
	local colorables = {}
	local function onDescendantAdded(object)
		local acceptedPart = object:IsA("BasePart") and object.Material == Enum.Material.Neon
		local acceptedLight = object:IsA("Light")

		if acceptedPart or acceptedLight then
			object:SetAttribute("OriginalColor", object.Color)
			table.insert(colorables, object)
		end
	end
	self._model.DescendantAdded:Connect(onDescendantAdded)
	for _, object in self._model:GetDescendants() do
		onDescendantAdded(object)
	end

	local recharge = nil

	local cooldown = self._cooldown
	cooldown.used:Connect(function()
		if recharge then return end

		recharge = Trove.new()

		recharge:Add(function()
			recharge = nil

			for _, colorable in colorables do
				colorable.Color = colorable:GetAttribute("OriginalColor")
			end
		end)

		recharge:Connect(RunService.Heartbeat, function()
			local alpha = math.pow(cooldown:getPercentage(), 4)

			for _, colorable in colorables do
				colorable.Color = RECHARGE_COLOR:Lerp(colorable:GetAttribute("OriginalColor"), alpha)
			end
		end)

		recharge:Connect(cooldown.completed, function()
			recharge:Clean()
		end)
	end)
end

function JumpPad.new(model: Model)
	local self = setmetatable({
		_active = true,
		_model = model,
		_cooldown = Cooldown.new(JUMP_COOLDOWN),
	}, JumpPad)

	self:_initRechargeEffect()

	self._loadedPromise = self:_waitForPrimaryPart()
	self._loadedPromise:andThen(function()
		local root = model.PrimaryPart
		self._touchedConnection = root.Touched:Connect(function(part: BasePart)
			local character = getCharacterFromPart(part)
			if not character then return end

			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end
			if player ~= Players.LocalPlayer then return end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			if not self._cooldown:isReady() then return end
			self._cooldown:use()

			local track = humanoid:LoadAnimation(Animations.UpwardDash)
			track:Play(0)

			local guid = EffectUtil.guid()
			EffectController:replicate(EffectUtil.trail({
				guid = guid,
				offset0 = CFrame.new(1, 0, 0),
				offset1 = CFrame.new(-1, 0, 0),
				root = character.PrimaryPart,
				trailName = "DashTrail",
			}))

			EffectController:replicate(EffectUtil.sound({
				parent = root,
				name = "JumpPad",
			}))

			JumpController:forceJump()

			local assemblyRoot = part.AssemblyRootPart

			-- set velocity
			local velocity = root.CFrame.UpVector * (model:GetAttribute("JumpPower") or BASE_JUMP_POWER)
			ForcedMovementHelper.instant(assemblyRoot, velocity.X, velocity.Y, velocity.Z)

			Promise.fromEvent(RunService.Stepped, function()
				return assemblyRoot.AssemblyLinearVelocity.Y > 0
			end)
				:timeout(0.1)
				:andThen(function()
					return Promise.fromEvent(RunService.Stepped, function()
						if humanoid.Health <= 0 then return true end
						if not character.Parent then return true end
						return assemblyRoot.AssemblyLinearVelocity.Y <= 0
					end)
				end)
				:finally(function()
					track:Stop()
					track:Destroy()
					EffectController:cancel(guid)
				end)
		end)
	end)

	return self
end

function JumpPad:OnRemoved()
	self._active = false

	self._cooldown = nil

	if self._loadedPromise then self._loadedPromise:cancel() end
	if self._touchedConnection then self._touchedConnection:Disconnect() end
end

return ComponentService:registerComponentClass(script.Name, JumpPad)
