local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BattleController = require(ReplicatedStorage.Shared.Controllers.BattleController)
local React = require(ReplicatedStorage.Packages.React)

local function useIsInBattle()
	if not RunService:IsRunning() then return true end

	local isInBattle, setIsInBattle = React.useState(BattleController:isInBattle())

	React.useEffect(function()
		local connection = BattleController.inBattleChanged:Connect(function(inBattle)
			setIsInBattle(inBattle)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return isInBattle
end

return useIsInBattle
