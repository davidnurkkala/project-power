local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local CooldownCharges = require(ReplicatedStorage.Shared.Classes.CooldownCharges)
local Loader = require(ReplicatedStorage.Shared.Loader)

local JumpController = {}
JumpController.className = "JumpController"
JumpController.priority = 0

function JumpController:init()
	self._char = nil
	self._human = nil
	self._lastFreefall = nil
	self._available = true
	self._animationTrack = nil
	self._forcedJump = false

	self._cooldown = CooldownCharges.new(3, 2, 0)
	self._cooldown.used:Connect(function()
		if self._cooldown:getCharges() == 0 then self:setJumpingEnabled(false) end
	end)
	self._cooldown.completed:Connect(function()
		if self._cooldown:getCharges() > 0 then self:setJumpingEnabled(true) end
	end)
end

function JumpController:getCooldown()
	return self._cooldown
end

function JumpController:setJumpingEnabled(enabled)
	if not self._human then return end

	self._human:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
end

function JumpController:canJump()
	if not self._human then return false end

	local state = self._human:GetState()
	if not self._human:GetStateEnabled(Enum.HumanoidStateType.Jumping) then return false end
	if state == Enum.HumanoidStateType.Jumping then return false end
	if state == Enum.HumanoidStateType.Freefall then return false end
	if state == Enum.HumanoidStateType.FallingDown then return false end

	return true
end

function JumpController:start()
	local function onCharacterAdded(char)
		self._cooldown:reset()
		self._char = char
		self._human = char:WaitForChild("Humanoid") :: Humanoid
		self._animationTrack = self._human:LoadAnimation(Animations.DoubleJump)

		self._human.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Freefall then
				self._lastFreefall = tick()
			elseif newState == Enum.HumanoidStateType.Landed then
				if not self._available then self._available = true end
			end
		end)

		self._human.Jumping:Connect(function(started)
			if not started then return end
			if self._forcedJump then
				self._forcedJump = false
				return
			end
			self._cooldown:use()
		end)
	end
	Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	if Players.LocalPlayer.Character then onCharacterAdded(Players.LocalPlayer.Character) end

	Players.LocalPlayer.CharacterRemoving:Connect(function()
		self._char = nil
		self._human = nil
		self._lastFreefall = nil
		self._available = true
	end)

	UserInputService.JumpRequest:Connect(function()
		if not self._available then return end
		if not (self._char and self._human and self._lastFreefall) then return end
		if not self._char:GetAttribute("CanDoubleJump") then return end
		if (tick() - self._lastFreefall) < 0.2 then return end
		if self._human:GetState() ~= Enum.HumanoidStateType.Freefall then return end

		self._cooldown:recooldown()
		self:forceJump()
		self._animationTrack:Play(0, nil, 0.66)
		self._available = false
	end)
end

function JumpController:forceJump()
	if not self._human then return end

	self._forcedJump = true
	self._human:ChangeState(Enum.HumanoidStateType.Jumping)
end

function JumpController:normalJump()
	if not self._human then return end
	if not self:canJump() then return end

	self._human:ChangeState(Enum.HumanoidStateType.Jumping)
end

return Loader:registerSingleton(JumpController)
