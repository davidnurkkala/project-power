local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerStorage = game:GetService("ServerStorage")

local getSelection = require(ServerStorage.MACRO_PLUGIN.CustomUtil.getSelection)

return {
	Init = function() end,
	Items = {
		{ Type = "Title", Text = "Attachments ➡️ Weapon Motor" },
		{
			Type = "Button",
			Text = "Convert",
			Activate = function()
				local s = getSelection()

				local characterAttachment = s[1]
				if (not characterAttachment) or (not characterAttachment:IsA("Attachment")) then
					warn("The first selected object must be an Attachment in a Roblox character.")
					return
				end

				local weaponAttachment = s[2]
				if (not weaponAttachment) or (not weaponAttachment:IsA("Attachment")) then
					warn("The second selected object must be an Attachment in a Project Power weapon.")
					return
				end

				local motor = Instance.new("Motor6D")
				motor.Part0 = characterAttachment.Parent
				motor.Part1 = weaponAttachment.Parent
				motor.C0 = characterAttachment.CFrame
				motor.C1 = weaponAttachment.CFrame
				motor.Parent = motor.Part1

				print(
					`Successfully generated a motor parented to {motor.Part1}. This should be a part in the weapon. If not, undo and make your selection in reverse order.`
				)

				ChangeHistoryService:SetWaypoint("Converted attachments to motor")
			end,
		},
	},
}
