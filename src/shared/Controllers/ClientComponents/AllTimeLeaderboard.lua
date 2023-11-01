local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local GenericLeaderboard = require(ReplicatedStorage.Shared.Classes.GenericLeaderboard)
local Trove = require(ReplicatedStorage.Packages.Trove)
local AllTimeLeaderboard = {}
AllTimeLeaderboard.__index = AllTimeLeaderboard

function AllTimeLeaderboard.new(model)
	assert(model, "Missing model")
	local key = model:GetAttribute("Key")
	assert(key, "Missing key")

	local self = setmetatable({
		_trove = Trove.new(),
	}, AllTimeLeaderboard)

	self._comm = self._trove:Construct(Comm.ClientComm, model, true)

	self._trove:Add(
		GenericLeaderboard.new({
			cframe = model.Screen.CFrame * CFrame.new(0, 0, -model.Screen.Size.Z / 2),
			size = model.Screen.Size * Vector3.new(1, 1, 0),
			alwaysVisible = true,
			remoteProperty = self._comm:GetProperty("Leaderboard"),
			icon = CurrencyDefinitions[key].iconId,
		}),
		"destroy"
	)

	return self
end

function AllTimeLeaderboard:destroy() end

return ComponentService:registerComponentClass(script.Name, AllTimeLeaderboard)
