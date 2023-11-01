local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BasePowerUpPad = require(ServerScriptService.Server.Classes.BasePowerUpPad)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local PowerUpDefinitions = require(ReplicatedStorage.Shared.Data.PowerUpDefinitions)
local Sift = require(ReplicatedStorage.Packages.Sift)

local PowerUpPad = {}
PowerUpPad.__index = PowerUpPad

function PowerUpPad.new(model)
	return BasePowerUpPad.new(model, Sift.Dictionary.keys(Sift.Dictionary.removeKey(PowerUpDefinitions, "Heal")))
end

return ComponentService:registerComponentClass(script.Name, PowerUpPad)
