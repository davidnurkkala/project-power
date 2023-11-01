local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local MINIMUM_BUDGET = 10

local LeaderboardQueuer = {}

local Queue = {}
local Running = false
local Updated = Signal.new()
local Id = 0

local function getId()
	local id = Id
	Id += 1
	return id
end

local function waitForBudget(amount)
	return Promise.new(function(resolve, _, onCancel)
		repeat
			local budget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync)
			local pass = budget >= amount
			if not pass then task.wait(1) end
		until pass or onCancel()

		resolve()
	end)
end

local function enqueue(id)
	table.insert(Queue, id)

	if not Running then
		Running = true
		task.spawn(function()
			while Queue[1] do
				Updated:Fire()

				task.wait(5)

				waitForBudget(MINIMUM_BUDGET):await()
			end
			Running = false
		end)
	end
end

function LeaderboardQueuer:request()
	local id = getId()
	local promise = Promise.fromEvent(Updated, function()
		return Queue[1] == id
	end):andThen(function()
		table.remove(Queue, 1)
	end)
	enqueue(id)

	return promise
end

return LeaderboardQueuer
