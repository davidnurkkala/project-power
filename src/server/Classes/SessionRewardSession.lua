local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local SessionRewardDefinitions = require(ReplicatedStorage.Shared.Data.SessionRewardDefinitions)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

local SessionRewardSession = {}
SessionRewardSession.__index = SessionRewardSession

function SessionRewardSession.new(player: Player)
	local self = setmetatable({
		_player = player,
		_timestamp = DateTime.now().UnixTimestamp,
		_claimed = {} :: { [string]: boolean },
		rewardReached = Signal.new(),
	}, SessionRewardSession)

	self._rewardSequence = Promise.new(function(resolve, _, onCancel)
		local clock = 0
		for index, sessionReward in SessionRewardDefinitions do
			task.wait(sessionReward.time - clock)
			if onCancel() then return end

			clock = sessionReward.time
			self.rewardReached:Fire(index)
		end
		resolve()
	end)

	return self
end

function SessionRewardSession:isAvailable(index)
	if self._claimed[tostring(index)] then return false end
	return DateTime.now().UnixTimestamp >= (self._timestamp + SessionRewardDefinitions[index].time)
end

function SessionRewardSession:getInfo()
	return Sift.Array.map(SessionRewardDefinitions, function(sessionReward, index)
		local timestamp = self._timestamp + sessionReward.time
		local available = self:isAvailable(index)
		local claimed = self._claimed[tostring(index)]

		return {
			timestamp = timestamp,
			rewards = Sift.Dictionary.copyDeep(sessionReward.rewards),
			available = (not claimed) and available,
		}
	end)
end

function SessionRewardSession:claim(index)
	self._claimed[tostring(index)] = true
end

function SessionRewardSession:destroy()
	self._rewardSequence:cancel()
	self.rewardReached:Destroy()
end

return SessionRewardSession
