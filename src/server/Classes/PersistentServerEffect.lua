local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EffectService = require(ServerScriptService.Server.Services.EffectService)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PersistentServerEffect = {}
PersistentServerEffect.__index = PersistentServerEffect

function PersistentServerEffect.new(effectName: string, args: any)
	local self = setmetatable({
		_trove = Trove.new(),
	}, PersistentServerEffect)

	local function onPlayerAdded(player)
		EffectService:effectPlayer(player, effectName, args)
	end
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	self._trove:Connect(Players.PlayerAdded, onPlayerAdded)

	return self
end

function PersistentServerEffect:destroy()
	self._trove:Clean()
end

return PersistentServerEffect
