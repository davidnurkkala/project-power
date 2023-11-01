local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KillLabel = require(ReplicatedStorage.Shared.React.Components.KillFeed.KillLabel)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

export type KillFeedProps = {
	killSignal: Signal.Signal<Player, Player>,
}

local KillFeed: React.FC<KillFeedProps> = function(props)
	local killSignal = props.killSignal

	local kills, setKills = React.useState({})

	React.useEffect(function()
		local connection = killSignal:Connect(function(killer, victim)
			setKills(function(oldKills)
				return Sift.Set.add(oldKills, {
					killer = killer,
					victim = victim,
					timestamp = tick(),
				})
			end)
		end)

		return function()
			connection:Disconnect()
		end
	end, {
		killSignal,
	})

	local killsArray = Sift.Set.toArray(kills)
	local sortedKills = Sift.Array.sort(killsArray, function(a, b)
		return a.timestamp > b.timestamp
	end)

	local killComponents = {}
	for i, kill in sortedKills do
		killComponents[kill.timestamp] = React.createElement(KillLabel, {
			killer = kill.killer,
			victim = kill.victim,
			layoutOrder = i,
			destructor = function()
				setKills(function(oldKills)
					return Sift.Set.delete(oldKills, kill)
				end)
			end,
		})
	end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 4),
		}),
		React.createElement(React.Fragment, nil, killComponents),
	})
end

return KillFeed
