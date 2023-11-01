local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BoosterService = require(ServerScriptService.Server.Services.BoosterService)
local Comm = require(ReplicatedStorage.Packages.Comm)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Observers = require(ReplicatedStorage.Packages.Observers)
local SessionRewardDefinitions = require(ReplicatedStorage.Shared.Data.SessionRewardDefinitions)
local SessionRewardSession = require(ServerScriptService.Server.Classes.SessionRewardSession)

local SessionRewardService = {}
SessionRewardService.className = "SessionRewardService"
SessionRewardService.priority = 0

function SessionRewardService:init()
	self._sessionsByPlayer = {}

	self._comm = Comm.ServerComm.new(ReplicatedStorage, "SessionRewardService")
	self._infoRemote = self._comm:CreateProperty("Info")
	self._awardBecameAvailable = self._comm:CreateSignal("AwardBecameAvailable")
	self._awarded = self._comm:CreateSignal("Awarded")
	self._claim = self._comm:BindFunction("Claim", function(player, index)
		local session = self._sessionsByPlayer[player]
		if not session then return end

		if not session:isAvailable(index) then return end

		self:_giveRewards(player, SessionRewardDefinitions[index].rewards)
		session:claim(index)
		self._infoRemote:SetFor(player, session:getInfo())
	end)
end

function SessionRewardService:_giveRewards(player, rewardList)
	self._awarded:Fire(player, rewardList)

	for _, reward in rewardList do
		if reward.type == "power" then
			CurrencyService:addCurrency(player, "power", reward.amount)
		elseif reward.type == "premium" then
			CurrencyService:addCurrency(player, "premium", reward.amount)
		elseif reward.type == "booster" then
			BoosterService:boostPlayer(player, reward.minutes)
		end
	end
end

function SessionRewardService:start()
	Observers.observePlayer(function(player)
		local session = SessionRewardSession.new(player)
		self._sessionsByPlayer[player] = session

		self._infoRemote:SetFor(player, session:getInfo())

		session.rewardReached:Connect(function(index)
			self._infoRemote:SetFor(player, session:getInfo())
			self._awardBecameAvailable:Fire(player, index)
		end)

		return function()
			session:destroy()
			self._sessionsByPlayer[player] = nil
		end
	end)
end

return Loader:registerSingleton(SessionRewardService)
