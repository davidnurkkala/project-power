local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GetKills = require(ReplicatedStorage.Shared.Data.Conditions.GetKills)
local HasWeaponEquipped = require(ReplicatedStorage.Shared.Data.Conditions.HasWeaponEquipped)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponService = require(ServerScriptService.Server.Services.WeaponService)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

local AMOUNT = 15

local Challenge = {}

local function build(player, weaponId)
	return {
		weaponId = weaponId,
		condition = GetKills(player, AMOUNT):with({
			HasWeaponEquipped(player, weaponId),
		}),
	}
end

function Challenge.new(player)
	local weaponId = pickRandom(WeaponService:getOwnedWeapons(player))
	return build(player, weaponId)
end

function Challenge.load(player, data)
	local challenge = build(player, data.weaponId)
	challenge.condition:load(data.condition)
	return challenge
end

function Challenge.save(challenge)
	return {
		weaponId = challenge.weaponId,
		condition = challenge.condition:save(),
	}
end

function Challenge.getDescription(_player, data)
	-- should consider using the built-in descriptions for this, but... we want them to be succinct/bespoke?
	local weapon = WeaponDefinitions[data.weaponId]
	local kills = data.condition[1].kills
	return `Get {kills}/{AMOUNT} kills with {weapon.name}`
end

function Challenge.getHash(challenge)
	return `{script.Name}/{challenge.weaponId}`
end

return Challenge
