local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local Trove = require(ReplicatedStorage.Packages.Trove)

return function(cooldown, onCompleted)
	local cooldownBinding, setCooldownBinding = React.useBinding(0)
	local chargesBinding, setChargesBinding = React.useBinding(1)
	local chargesVisibleBinding, setChargesVisibleBinding = React.useBinding(false)

	React.useEffect(function()
		if not cooldown then return end

		setCooldownBinding(cooldown:getPercentage())
		setChargesBinding(cooldown:getCharges())
		setChargesVisibleBinding(cooldown:hasMultipleCharges())

		local trove = Trove.new()

		trove:Connect(RunService.Heartbeat, function()
			setCooldownBinding(cooldown:getPercentage())
		end)

		if onCompleted then trove:Connect(cooldown.completed, function()
			onCompleted()
		end) end

		trove:Connect(cooldown.chargesChanged, function()
			setChargesBinding(cooldown:getCharges())
			setChargesVisibleBinding(cooldown:hasMultipleCharges())
		end)

		return function()
			trove:Clean()
		end
	end, {
		cooldown,
		onCompleted,
	})

	return cooldownBinding, chargesBinding, chargesVisibleBinding
end
