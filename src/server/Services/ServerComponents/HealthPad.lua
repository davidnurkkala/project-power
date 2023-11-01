local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BasePowerUpPad = require(ServerScriptService.Server.Classes.BasePowerUpPad)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)

local HealthPad = {}
HealthPad.__index = HealthPad

function HealthPad.new(model)
	return BasePowerUpPad.new(model, { "Heal" })
end

return ComponentService:registerComponentClass(script.Name, HealthPad)
