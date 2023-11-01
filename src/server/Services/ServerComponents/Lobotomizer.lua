--:OnCrack:

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Lobotomizer = {}
Lobotomizer.__index = Lobotomizer

local VALID_STATE = Enum.HumanoidStateType.None

function Lobotomizer.new(humanoid: Humanoid)
	local self = setmetatable({
		_trove = Trove.new(),
	}, Lobotomizer)

	local disabledStates = {}
	for _, enum in Enum.HumanoidStateType:GetEnumItems() do
		if enum == VALID_STATE then continue end
		if not humanoid:GetStateEnabled(enum) then continue end
		humanoid:SetStateEnabled(enum, false)
		disabledStates[enum] = true
	end

	self._trove:Add(function()
		for enum, _ in disabledStates do
			humanoid:SetStateEnabled(enum, true)
		end
	end)

	return self
end

function Lobotomizer:OnRemoved()
	self._trove:Clean()
end

return ComponentService:registerComponentClass(script.Name, Lobotomizer)
