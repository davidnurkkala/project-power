local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- const
local IS_SERVER = RunService:IsServer()
local IS_STUDIO = RunService:IsStudio()

local Damage = {}
Damage.__index = Damage

export type DamageSource = Humanoid | { [string]: any }
export type DamageTarget = Humanoid | Model
export type DamageArgs = {
	source: DamageSource?,
	target: DamageTarget,
	amount: number,
	tags: { string }?,
}

local function getPlayerFromHumanoid(humanoid: Humanoid): Player?
	local char = humanoid.Parent :: Model?
	if not char then return end
	return Players:GetPlayerFromCharacter(char)
end

function Damage:getSourcePlayer(): Player?
	if not (typeof(self.source) == "Instance" and self.source:IsA("Humanoid")) then return nil end
	return getPlayerFromHumanoid(self.source)
end

function Damage:getTargetPlayer(): Player?
	if not self.target:IsA("Humanoid") then return nil end
	return getPlayerFromHumanoid(self.target)
end

function Damage:getCurrencyMultiplier(): number
	if self.target:IsA("Humanoid") then
		if IS_STUDIO then
			return 1
		else
			if getPlayerFromHumanoid(self.target) ~= nil then
				return 1
			else
				if self.target:GetAttribute("IsPracticeDummy") then
					return 0.05
				else
					return 0.75
				end
			end
		end
	else
		return 0.05
	end
end

function Damage.new(args: DamageArgs)
	assert(IS_SERVER, "Damage.new() | damage can only instantiated on the server.")

	local self = setmetatable({
		source = args.source,
		target = args.target,
		amount = args.amount,
		didKill = false,
	}, Damage)

	if args.tags then
		for _, tag in args.tags do
			self:addTag(tag)
		end
	end

	return self
end

function Damage:addTag(tag)
	if not self._tags then self._tags = {} end
	self._tags[tag] = true
end

function Damage:hasTag(tag)
	if not self._tags then return false end
	return self._tags[tag]
end

function Damage:destroy() end

return Damage
