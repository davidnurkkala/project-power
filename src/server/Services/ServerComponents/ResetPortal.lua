local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)

local ResetPortal = {}
ResetPortal.__index = ResetPortal

function ResetPortal.new(model)
	local self = setmetatable({
		_model = model,
	}, ResetPortal)

	local active = true

	model.Trigger.Touched:Connect(function(part)
		if not active then return end

		local player = Players:GetPlayerFromCharacter(part.Parent)
		if player == nil then return end

		active = false
		task.delay(5, function()
			active = true
		end)

		player:LoadCharacter()
	end)

	return self
end

function ResetPortal:OnRemoved()
	-- no cleanup required since the prompt will be destroyed along with the model
end

return ComponentService:registerComponentClass(script.Name, ResetPortal)
