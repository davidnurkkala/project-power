local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BattleService = require(ServerScriptService.Server.Services.BattleService)
local Comm = require(ReplicatedStorage.Packages.Comm)
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local Loader = require(ReplicatedStorage.Shared.Loader)

local LeaderboardsService = {}
LeaderboardsService.className = "LeaderboardsService"
LeaderboardsService.priority = 0

function LeaderboardsService:init() end

function LeaderboardsService:start()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "LeaderboardsService")
	self._roundEndedStatsRemote = self._comm:CreateSignal("RoundEndedStats")

	local function onPlayerJoin(player: Player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		for currencyName, currencyDefinition in CurrencyDefinitions do
			if not currencyDefinition.leaderstatTracked then continue end

			local currency = Instance.new("IntValue")
			currency.Name = currencyDefinition.name
			currency.Value = CurrencyService:getCurrency(player, currencyName)
			currency.Parent = leaderstats
		end
	end

	for _, player in Players:GetPlayers() do
		onPlayerJoin(player)
	end
	Players.PlayerAdded:Connect(onPlayerJoin)

	CurrencyService.currencyChanged:Connect(function(player, currency)
		local currencyDefinition = CurrencyDefinitions[currency]
		if not currencyDefinition or not currencyDefinition.leaderstatTracked then return end

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		local currencyValue = leaderstats:FindFirstChild(currencyDefinition.name)
		if not currencyValue then return end

		local amount = CurrencyService:getCurrency(player, currency)
		currencyValue.Value = amount
	end)

	local perRoundStats = {} :: { [Player]: number }
	CurrencyService.currencyAdded:Connect(function(player, currency, amount)
		if currency ~= "power" then return end

		perRoundStats[player] = (perRoundStats[player] or 0) + amount
	end)

	BattleService.arenaChanged:Connect(function()
		local serializedStats = {}
		for player, power in perRoundStats do
			table.insert(serializedStats, { name = player.Name, power = power })
		end
		table.sort(serializedStats, function(a, b)
			return a.power > b.power
		end)
		self._roundEndedStatsRemote:FireAll(serializedStats)

		perRoundStats = {}
	end)
end

return Loader:registerSingleton(LeaderboardsService)
