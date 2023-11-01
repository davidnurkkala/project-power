local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerScriptService = game:GetService("ServerScriptService")

local Sift = require(ReplicatedStorage.Packages.Sift)

local BotBuilder = {}
BotBuilder.__index = BotBuilder

function BotBuilder.new()
	local self = setmetatable({
		_bots = {},
	}, BotBuilder)

	return self
end

function BotBuilder:createBot(className, args)
	local moduleScript = ServerScriptService.Server.Bots.Classes:FindFirstChild(className)
	assert(moduleScript, `No bot of class name {className}`)

	local bot = require(moduleScript).new(args)

	self._bots[bot] = true
	bot.destroyed:Connect(function()
		self._bots[bot] = nil
	end)

	return bot
end

function BotBuilder:getBots()
	return Sift.Dictionary.keys(self._bots)
end

function BotBuilder:getBotCount()
	return #self:getBots()
end

function BotBuilder:destroy()
	for bot in self._bots do
		bot:destroy()
	end
	self._bots = {}
end

return BotBuilder
