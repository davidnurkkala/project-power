local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local getSelection = require(ServerStorage.MACRO_PLUGIN.CustomUtil.getSelection)

return {
	Init = function() end,
	Items = {
		{ Type = "Title", Text = "Attach Weapon" },
		{
			Type = "Button",
			Text = "Attach",
			Activate = function()
				local s = getSelection()

				local characterAttachment = s[1]
				if not characterAttachment or not characterAttachment:IsA("Attachment") then
					warn("First selection should be a character attachment.")
					return
				end

				local part = s[2]
				if not part or not part:IsA("BasePart") then
					warn("Second selection should be the root part of a weapon.")
					return
				end

				local attachment = Instance.new("Attachment")
				attachment.Name = "GripAttachment"
				attachment.Parent = part
				attachment.WorldCFrame = characterAttachment.WorldCFrame

				Selection:Set({ characterAttachment, attachment })

				print(`Successfully created a grip attachment in {part} corresponding to {attachment}.`)

				ChangeHistoryService:SetWaypoint("Created weapon attachment")
			end,
		},
	},
}
