local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEFAULT_COLLISION_GROUP = "Default"
local PLAYER_COLLISION_GROUP = "Players"

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)

local InBattle = {}
InBattle.__index = InBattle

local function setCollisionGroup(descendant, group)
	if descendant:IsA("BasePart") then descendant.CollisionGroup = group end
end

function InBattle.new(character: Model)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		warn("InBattle.new() | Can only tag Characters with humanoids as InBattle.")
		return
	end

	for _, descendant in character:GetDescendants() do
		setCollisionGroup(descendant, PLAYER_COLLISION_GROUP)
	end

	local self = setmetatable({
		_character = character,
		_descendantAddedConnection = character.DescendantAdded:Connect(function(descendant)
			setCollisionGroup(descendant, PLAYER_COLLISION_GROUP)
		end),
	}, InBattle)

	return self
end

function InBattle:OnRemoved()
	if self._descendantAddedConnection then
		self._descendantAddedConnection:Disconnect()
		self._descendantAddedConnection = nil
	end

	if self._character and self._character.Parent then
		for _, descendant in self._character:GetDescendants() do
			setCollisionGroup(descendant, DEFAULT_COLLISION_GROUP)
		end
	end
	self._character = nil
end

return ComponentService:registerComponentClass(script.Name, InBattle)
