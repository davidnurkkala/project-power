local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local PracticeService = require(ServerScriptService.Server.Services.PracticeService)

local PracticePortal = {}
PracticePortal.__index = PracticePortal

function PracticePortal.new(model)
	local self = setmetatable({
		_model = model,
	}, PracticePortal)

	model.Trigger.Touched:Connect(function(part)
		local player = Players:GetPlayerFromCharacter(part.Parent)
		if player == nil then return end

		PracticeService:addPlayer(player)
	end)

	return self
end

function PracticePortal:OnRemoved()
	-- no cleanup required since the prompt will be destroyed along with the model
end

return ComponentService:registerComponentClass(script.Name, PracticePortal)
