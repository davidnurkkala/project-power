local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BattleService = require(ServerScriptService.Server.Services.BattleService)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)

local JoinPrompt = {}
JoinPrompt.__index = JoinPrompt

function JoinPrompt.new(model: Model)
	local root = model.PrimaryPart

	local self = setmetatable({
		_model = model,
	}, JoinPrompt)

	root.Touched:Connect(function(part)
		local player = Players:GetPlayerFromCharacter(part.Parent)
		if not player then return end

		BattleService:addPlayer(player)
	end)

	return self
end

function JoinPrompt:OnRemoved()
	-- no cleanup required since the prompt will be destroyed along with the model
end

return ComponentService:registerComponentClass(script.Name, JoinPrompt)
