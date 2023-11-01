local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KillFeed = require(ReplicatedStorage.Shared.React.Components.KillFeed.KillFeed)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Signal = require(ReplicatedStorage.Packages.Signal)

local controls = {
	csvPlayers = "Player1,Player2,Player3,Player4",
	killRatePerSecond = 1,
	fuzzyRandomRate = true,
	popDelay = 3,
}

type Props = {
	controls: typeof(controls),
}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(props: Props)
		local playerNames = React.useMemo(function()
			return props.controls.csvPlayers:split(",")
		end, { props.controls.csvPlayers })
		local killSignal = React.useRef(Signal.new())
		local lastKill = React.useRef(tick())

		React.useEffect(function()
			local function fireKill()
				local killer = playerNames[math.random(1, #playerNames)]
				local victim = playerNames[math.random(1, #playerNames)]
				killSignal.current:Fire({ Name = killer }, { Name = victim })
			end

			local connection = RunService.Heartbeat:Connect(function(dt)
				if props.controls.fuzzyRandomRate then
					if math.random() < props.controls.killRatePerSecond * dt then fireKill() end
				else
					local now = tick()
					if now - lastKill.current > (1 / props.controls.killRatePerSecond) then
						fireKill()
						lastKill.current = now
					end
				end
			end)

			return function()
				connection:Disconnect()
			end
		end, {
			playerNames,
		})

		return React.createElement("Frame", {
			Size = UDim2.fromScale(0.3, 0.4),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Position = UDim2.fromScale(0.1, 0.9),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 0.5,
		}, {
			React.createElement(KillFeed, {
				killSignal = killSignal.current,
			}),
		})
	end,
}
