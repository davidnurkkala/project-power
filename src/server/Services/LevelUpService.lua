local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local EventStream = require(ReplicatedStorage.Shared.Singletons.EventStream)
local InBattleHelper = require(ReplicatedStorage.Shared.Util.InBattleHelper)
local LevelUpDefinitions = require(ReplicatedStorage.Shared.Data.LevelUpDefinitions)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local PRACTICE_BUFF = 1 / 0.05

type Input = Player | Model

local LevelUpService = {}
LevelUpService.className = "LevelUpService"
LevelUpService.priority = 0

local function parse(object: Input): Model?
	if object:IsA("Player") then
		return object.Character
	else
		return object
	end
end

function LevelUpService:init() end

function LevelUpService:start()
	CurrencyService.currencyAdded:Connect(function(...)
		self:_onCurrencyAdded(...)
	end)
end

function LevelUpService:_onCurrencyAdded(player: Player, currency: CurrencyDefinitions.CurrencyType, amount: number)
	if currency ~= "power" then return end

	local human = WeaponUtil.getHuman(player)
	if not human then return end
	if human.Health <= 0 then return end

	self:addExperience(player, amount)
end

function LevelUpService:getMaxExperienceFromLevel(level: number)
	return 50 + 20 * (level - 1)
end

function LevelUpService:isSetUp(object: Input)
	local char = parse(object)
	if not char then return false end
	if not char:GetAttribute("Level") then return false end
	if not char:GetAttribute("Experience") then return false end
	if not char:GetAttribute("MaxExperience") then return false end

	return true
end

function LevelUpService:setUp(object: Input)
	local char = parse(object)
	if not char then return end
	if self:isSetUp(char) then return end

	local sourcePlayer = Players:GetPlayerFromCharacter(char)
	if sourcePlayer then EventStream:event("LevelReached", { player = sourcePlayer, level = 1 }) end
	char:SetAttribute("Level", 1)
	char:SetAttribute("Experience", 0)
	char:SetAttribute("MaxExperience", self:getMaxExperienceFromLevel(1))
end

function LevelUpService:getMaxLevel()
	return #LevelUpDefinitions.perksByLevel
end

function LevelUpService:applyPerks(char: Model, perks: { LevelUpDefinitions.PerkType })
	for _, perk: LevelUpDefinitions.PerkType in perks do
		if perk == "fullHeal" then
			local player = Players:GetPlayerFromCharacter(char)
			if not player then return end

			Promise.try(function()
				local human = (char :: Model):FindFirstChild("Humanoid") :: Humanoid
				human.Health = human.MaxHealth
			end):catch(function() end)
		elseif perk == "increaseMaxHealth" then
			local humanoid = char:FindFirstChildWhichIsA("Humanoid")
			if not humanoid then continue end

			humanoid.MaxHealth += 10
			humanoid.Health += 10
		elseif perk == "doubleJump" then
			char:SetAttribute("CanDoubleJump", true)
		elseif perk == "doubleDash" then
			char:SetAttribute("HasDoubleDash", true)
		end
	end
end

function LevelUpService:addExperience(object: Input, amount: number)
	local char = parse(object)
	if not char then return end
	if not self:isSetUp(char) then return end
	if char:GetAttribute("Level") == self:getMaxLevel() then return end

	if InBattleHelper.isCharacterInPractice(char) then
		amount *= PRACTICE_BUFF
	end

	char:SetAttribute("Experience", char:GetAttribute("Experience") + amount)

	local didLevelUp = false
	while char:GetAttribute("Experience") >= char:GetAttribute("MaxExperience") do
		local nextLevel = char:GetAttribute("Level") + 1
		char:SetAttribute("Level", nextLevel)

		local sourcePlayer = Players:GetPlayerFromCharacter(char)
		if sourcePlayer then EventStream:event("LevelReached", { player = sourcePlayer, level = nextLevel }) end

		char:SetAttribute("Experience", char:GetAttribute("Experience") - char:GetAttribute("MaxExperience"))
		char:SetAttribute("MaxExperience", self:getMaxExperienceFromLevel(char:GetAttribute("Level")))

		self:applyPerks(char, LevelUpDefinitions.perksByLevel[char:GetAttribute("Level")])

		didLevelUp = true

		if char:GetAttribute("Level") == self:getMaxLevel() then
			char:SetAttribute("Experience", 1)
			char:SetAttribute("MaxExperience", 1)
			break
		end
	end

	if didLevelUp then
		local human = char:FindFirstChildWhichIsA("Humanoid")
		if not human then return end

		EffectService:effect("levelUp", { human = human })
	end
end

return Loader:registerSingleton(LevelUpService)
