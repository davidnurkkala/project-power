local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local Loader = require(ReplicatedStorage.Shared.Loader)

local KillFloorService = {}
KillFloorService.className = "KillFloorService"
KillFloorService.priority = 0

function KillFloorService:init() end

function KillFloorService:start()
	local damageSource = {
		Name = "falling out of the arena",
	}

	while true do
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local root = char and char.PrimaryPart
			local human = char and char:FindFirstChildWhichIsA("Humanoid")
			if not (root and human) then continue end
			if root.Position.Y > 0 then continue end

			DamageService:damage({
				source = damageSource,
				target = human,
				amount = 1000000,
			})
		end
		task.wait()
	end
end

return Loader:registerSingleton(KillFloorService)
