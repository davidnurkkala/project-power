local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerStorage = game:GetService("ServerStorage")

local getSelection = require(ServerStorage.MACRO_PLUGIN.CustomUtil.getSelection)

return {
	Init = function() end,
	Items = {
		{
			Type = "Button",
			Text = "Weld All to First",
			Activate = function()
				local s = getSelection()

				local root = table.remove(s, 1)
				for _, part in s do
					local wc = Instance.new("WeldConstraint")
					wc.Part0 = root
					wc.Part1 = part
					wc.Parent = part
				end

				ChangeHistoryService:SetWaypoint("Welded things")
			end,
		},
	},
}
