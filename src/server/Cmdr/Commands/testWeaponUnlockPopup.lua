local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProgressionController = require(ReplicatedStorage.Shared.Controllers.ProgressionController)

return {
	Name = "testWeaponUnlockPopup",
	Description = "Test weapon unlock popup",
	Args = {
		{
			Type = "weaponDefinition",
			Name = "weapon",
			Description = "The weapon to see",
		},
	},
	ClientRun = function(_, weaponDef)
		ProgressionController.weaponUnlocked:Fire(weaponDef)

		return "Testing..."
	end,
}
