local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetPower = require(ReplicatedStorage.Shared.Data.Conditions.GetPower)

local AMOUNT = 350

local Challenge = {}

local function build(player)
	return {
		condition = GetPower(player, AMOUNT),
	}
end

function Challenge.new(player)
	return build(player)
end

function Challenge.load(player, data)
	local challenge = build(player)
	challenge.condition:load(data.condition)
	return challenge
end

function Challenge.save(challenge)
	return {
		condition = challenge.condition:save(),
	}
end

function Challenge.getDescription(_player, data)
	local power = data.condition.power
	return `Get {power}/{AMOUNT} power`
end

function Challenge.getHash()
	return `{script.Name}`
end

return Challenge
