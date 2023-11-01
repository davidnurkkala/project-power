local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TryNow = require(ReplicatedStorage.Shared.Util.TryNow)
export type SilenceTarget = Model | Humanoid | Player

local SilenceHelper = {}

SilenceHelper.attributeName = "IsSilenced"

function SilenceHelper.parseTarget(target: SilenceTarget): Model?
	return TryNow(function()
		if target:IsA("Model") then
			return target
		elseif target:IsA("Humanoid") then
			return target.Parent :: Model
		elseif target:IsA("Player") then
			return target.Character
		end

		return nil
	end, nil)
end

function SilenceHelper.isSilenced(target: SilenceTarget): boolean
	local model = SilenceHelper.parseTarget(target)
	if not model then return false end

	return model:GetAttribute(SilenceHelper.attributeName) == true
end

return SilenceHelper
