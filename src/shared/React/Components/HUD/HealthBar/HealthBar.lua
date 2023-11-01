local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FillBar = require(ReplicatedStorage.Shared.React.Components.Common.FillBar)
local React = require(ReplicatedStorage.Packages.React)
local useCharacter = require(ReplicatedStorage.Shared.React.Hooks.useCharacter)

export type HealthBarProps = {
	player: Player,
}

local HealthBar: React.FC<HealthBarProps> = function(props)
	local player = props.player
	local character = useCharacter(player)

	local maxHealth, setMaxHealth = React.useState(0)
	local health, setHealth = React.useState(0)

	React.useEffect(function()
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		setMaxHealth(humanoid.MaxHealth)
		setHealth(humanoid.Health)

		local maxHealthChanged = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
			setMaxHealth(humanoid.MaxHealth)
		end)

		local healthChanged = humanoid.HealthChanged:Connect(function(newHealth)
			setHealth(newHealth)
		end)

		return function()
			maxHealthChanged:Disconnect()
			healthChanged:Disconnect()
		end
	end, {
		player,
		character,
	})

	if not character then return end

	return React.createElement(FillBar, {
		maxValue = maxHealth,
		value = health,
		fillColor = Color3.fromRGB(238, 89, 90),
		backgroundColor = Color3.new(0, 0, 0),
		roundingUDim = UDim.new(0.2, 0),
		gradientRotation = 45,
	})
end

return HealthBar
