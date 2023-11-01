local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local InBattle = require(ServerScriptService.Server.Services.ServerComponents.InBattle)

return ComponentService:registerComponentClass(script.Name, InBattle)
