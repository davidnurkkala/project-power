local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayRounds = require(ReplicatedStorage.Shared.Data.Conditions.PlayRounds)

local AMOUNT = 3

local Challenge = {}

local function build(player)
	return {
		condition = PlayRounds(player, AMOUNT),
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
	local power = data.condition.rounds
	return `Play {power}/{AMOUNT} rounds`
end

function Challenge.getHash()
	return `{script.Name}`
end

return Challenge
