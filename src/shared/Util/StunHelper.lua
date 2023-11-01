local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Damage = require(ReplicatedStorage.Shared.Classes.Damage)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Sift = require(ReplicatedStorage.Packages.Sift)

export type StunTarget = Player | Damage.DamageTarget

local StunHelper = {}

StunHelper.stunAttributeName = "IsStunned"
StunHelper.pushAttributeName = "IsBeingPushed"

function StunHelper.getModel(target: StunTarget): Model?
	if target:IsA("Model") and target:FindFirstChildWhichIsA("Humanoid") then return target end

	if target:IsA("Humanoid") then
		return target.Parent :: Model
	elseif target:IsA("Player") then
		return target.Character
	end

	return nil
end

function StunHelper.isInvincible(target: StunTarget): boolean
	local model = StunHelper.getModel(target)
	if not model then return true end -- by implication logic this should evaluate to true (false)
	if model:FindFirstChildOfClass("ForceField") then return true end

	return false
end

function StunHelper.isAlive(target: StunTarget): boolean
	local model = StunHelper.getModel(target)
	if not model then return false end
	local human = model:FindFirstChildWhichIsA("Humanoid")
	if not human then return false end
	return human.Health > 0
end

function StunHelper.isStunned(target: StunTarget)
	local model = StunHelper.getModel(target)
	if not model then return false end

	return model:GetAttribute(StunHelper.stunAttributeName) == true
end

function StunHelper.isStunnedOrPushed(target: StunTarget)
	local model = StunHelper.getModel(target)
	if not model then return false end

	return (model:GetAttribute(StunHelper.stunAttributeName) == true) or (model:GetAttribute(StunHelper.pushAttributeName) == true)
end

function StunHelper.observeStunnedOrPushed(target: StunTarget, callback)
	local model = StunHelper.getModel(target)
	if not model then return function() end end

	local cleanupFunctions = Sift.Array.map({ StunHelper.stunAttributeName, StunHelper.pushAttributeName }, function(attributeName)
		return Observers.observeAttribute(model, attributeName, callback)
	end)

	return function()
		for _, func in cleanupFunctions do
			func()
		end
	end
end

return StunHelper
