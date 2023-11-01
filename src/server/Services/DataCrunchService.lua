local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local GameAnalytics = require(ReplicatedStorage.Packages.GameAnalytics)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)

local GAME_KEY = "1e10b5a86a16e860efda20b03e11e835"
local SECRET_KEY = "7f640c7a07f2662f8a369dfe37389fc27a9c404a"

local DataCrunchService = {}
DataCrunchService.className = "DataCrunchService"
DataCrunchService.priority = -8192

function DataCrunchService:init()
	GameAnalytics:initialize({
		gameKey = GAME_KEY,
		secretKey = SECRET_KEY,
		build = Configuration.GameVersion,

		automaticSendBusinessEvents = true,
		reportErrors = true,
		enableInfoLog = false,
		enableDebugLog = false,
		enableVerboseLog = false,

		availableResourceCurrencies = { "power", "premium", "kills" },
		availableResourceItemTypes = { "shop", "robux", "battle" },
	})
end

function DataCrunchService:start() end

function DataCrunchService:processReceipt(info: any)
	Promise.try(function()
		GameAnalytics:ProcessReceiptCallback(info)
	end):catch(function(err)
		warn(`GameAnalytics failed to process receipt {info} for the following reason:\n{err}`)
	end)
end

function DataCrunchService:_resource(player: Player, event: any)
	Promise.try(function()
		GameAnalytics:addResourceEvent(player.UserId, event)
	end):catch(function(err)
		warn(`GameAnalytics failed to send resource event {event} for the following reason:\n{err}`)
	end)
end

function DataCrunchService:resourceSourced(player: Player, event: any)
	self:_resource(player, Sift.Dictionary.set(event, "flowType", GameAnalytics.EGAResourceFlowType.Source))
end

function DataCrunchService:resourceSunk(player: Player, event: any)
	self:_resource(player, Sift.Dictionary.set(event, "flowType", GameAnalytics.EGAResourceFlowType.Sink))
end

function DataCrunchService:custom(player: Player, id: string, value: any)
	local segments = string.split(id, ":")
	assert(#segments <= 5, `Attempted to send custom event to GameAnalytics but segment count was higher than 5: {id}`)
	assert(
		Sift.Array.every(segments, function(segment)
			return #segment <= 32
		end),
		`Attempted to send custome event to GameAnalytics but a segment had a length higher than 32: {id}`
	)

	Promise.try(function()
		GameAnalytics:addDesignEvent(player.UserId, {
			eventId = id,
			value = value,
		})
	end):catch(function(err)
		warn(`GameAnalytics failed to send a custom event {id} {value} for the following reason:\n{err}`)
	end)
end

return Loader:registerSingleton(DataCrunchService)
