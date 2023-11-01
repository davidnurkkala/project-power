local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = require(ServerScriptService.ServerPackages.Cmdr)

local Loader = require(ReplicatedStorage.Shared.Loader)

local CmdrService = {}
CmdrService.className = "CmdrService"
CmdrService.priority = 0

function CmdrService:init()
	Cmdr:RegisterDefaultCommands()
	Cmdr:RegisterCommandsIn(ServerScriptService.Server.Cmdr.Commands)
	Cmdr:RegisterTypesIn(ServerScriptService.Server.Cmdr.Types)
	Cmdr:RegisterHooksIn(ServerScriptService.Server.Cmdr.Hooks)
end

function CmdrService:start() end

return Loader:registerSingleton(CmdrService)
