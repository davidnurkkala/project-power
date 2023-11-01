local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BattleService = require(ServerScriptService.Server.Services.BattleService)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)

local LobbyLauncher = {}
LobbyLauncher.__index = LobbyLauncher

function LobbyLauncher.new(model: Model)
	local self = setmetatable({}, LobbyLauncher)

	local launcher = model:FindFirstChild("Launcher")
	local catcher = model:FindFirstChild("Catcher")

	for _, part in { launcher, catcher } do
		part.Touched:Connect(function(other)
			local player = Players:GetPlayerFromCharacter(other.Parent)
			if not player then return end

			BattleService:launchPlayer(player, launcher)
		end)
	end

	return self
end

function LobbyLauncher:OnRemoved()
	-- will never be removed
end

return ComponentService:registerComponentClass(script.Name, LobbyLauncher)
