local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AllTimeLeaderboards = require(ReplicatedStorage.Shared.Singletons.AllTimeLeaderboards)
local Comm = require(ReplicatedStorage.Packages.Comm)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Trove = require(ReplicatedStorage.Packages.Trove)
local AllTimeLeaderboard = {}
AllTimeLeaderboard.__index = AllTimeLeaderboard

function AllTimeLeaderboard.new(model)
	assert(model, "No model")
	local key = model:GetAttribute("Key")
	assert(key, "No key")
	local leaderboard = AllTimeLeaderboards:getLeaderboard(key)
	assert(leaderboard, `No leaderboard for key {key}`)

	local self = setmetatable({
		_leaderboard = leaderboard,
		_trove = Trove.new(),
	}, AllTimeLeaderboard)

	self._comm = Comm.ServerComm.new(model)
	self._leaderboardProperty = self._comm:CreateProperty("Leaderboard", nil)
	self._trove:Add(self._comm)

	self._trove:Add(task.spawn(function()
		while true do
			local data = leaderboard:get():expect()
			if not Sift.Array.equalsDeep(data, self._leaderboardProperty:Get()) then self._leaderboardProperty:Set(data) end
			task.wait(10)
		end
	end))

	return self
end

function AllTimeLeaderboard:OnRemoved()
	self._trove:Clean()
end

return ComponentService:registerComponentClass(script.Name, AllTimeLeaderboard)
