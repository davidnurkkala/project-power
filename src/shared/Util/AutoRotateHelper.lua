local KEY_NAME = "AutoRotateHelperValue"

local AutoRotateHelper = {}

function AutoRotateHelper.disable(human: Humanoid)
	local value = human:GetAttribute(KEY_NAME) or 0
	if value == 0 then human.AutoRotate = false end
	human:SetAttribute(KEY_NAME, value + 1)
end

function AutoRotateHelper.enable(human: Humanoid)
	local value = human:GetAttribute(KEY_NAME) or 0
	if value == 0 then return end
	if value == 1 then
		human.AutoRotate = true
		human:SetAttribute(KEY_NAME, nil)
	else
		human:SetAttribute(KEY_NAME, value - 1)
	end
end

function AutoRotateHelper.isDisabled(human: Humanoid)
	return (human:GetAttribute(KEY_NAME) or 0) > 0
end

return AutoRotateHelper
