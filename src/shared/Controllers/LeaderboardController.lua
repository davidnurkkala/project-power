local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)

local LEADERBOARD_POPUP_TIME = 5

local LeaderboardController = {}
LeaderboardController.className = "LeaderboardController"
LeaderboardController.priority = 0

LeaderboardController.roundEnded = Signal.new() :: Signal.Signal<{ { name: string, power: number } }>

function LeaderboardController:init() end

function LeaderboardController:start()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "LeaderboardsService")
	self._roundEndedStatsRemote = self._comm:GetSignal("RoundEndedStats")

	self._roundEndedStatsRemote:Connect(function(stats: { { name: string, power: number } })
		self.roundEnded:Fire(stats)
		task.wait(LEADERBOARD_POPUP_TIME)
		self.roundEnded:Fire(nil)
	end)
end

return Loader:registerSingleton(LeaderboardController)
