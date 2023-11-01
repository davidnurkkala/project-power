local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function useCharacter(player: Player)
	local playerCharacter, setPlayerCharacter = React.useState(if player then player.Character else nil)

	React.useEffect(function()
		if not player then return end

		setPlayerCharacter(player.Character)

		local characterAdded = player.CharacterAdded:Connect(function(character)
			setPlayerCharacter(character)
		end)

		local characterRemoving = player.CharacterRemoving:Connect(function()
			setPlayerCharacter(nil)
		end)

		return function()
			characterAdded:Disconnect()
			characterRemoving:Disconnect()
		end
	end, {
		player,
	})

	return playerCharacter
end

return useCharacter
