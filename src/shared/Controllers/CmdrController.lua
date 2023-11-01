local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)

local CmdrController = {}
CmdrController.className = "CmdrController"
CmdrController.priority = 0

function CmdrController:init() end

function CmdrController:start()
	local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript)
	CmdrClient:SetActivationKeys({ Enum.KeyCode.F2 })
end

return Loader:registerSingleton(CmdrController)
