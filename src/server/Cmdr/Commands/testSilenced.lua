local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SilenceController = require(ReplicatedStorage.Shared.Controllers.SilenceController)

return {
	Name = "testSilenced",
	Args = {},
	ClientRun = function()
		SilenceController:_setSilenced(true)
		task.delay(3, function()
			SilenceController:_setSilenced(false)
		end)
		return "Silenced!"
	end,
}
