local ServerStorage = game:GetService("ServerStorage")
return {
	Init = function() end,
	Items = {
		{
			Type = "Button",
			Text = "Refresh Macros",
			Activate = function()
				ServerStorage.MACRO_PLUGIN.CheckMeToRefreshMacros.Value = true
			end,
		},
	},
}
