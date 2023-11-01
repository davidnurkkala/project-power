local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local FormatTime = require(ReplicatedStorage.Shared.Util.FormatTime)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Trove = require(ReplicatedStorage.Packages.Trove)

local function getText(data, timer)
	local lines = Sift.Array.map(data.descriptions, function(description)
		local text = description.description
		if description.completed then text = `<s>{text}</s>` end
		text = `<stroke thickness="1">- {text}</stroke>`
		return text
	end)
	table.insert(lines, 1, `<stroke thickness="2"><font size="16">Daily Challenges</font></stroke>`)
	table.insert(lines, 2, `<stroke thickness="1">Each challenge gives you <font color="#6c5ce7">15 Crystals!</font></stroke>`)
	table.insert(lines, `<i><stroke thickness="1">Refreshes in {timer}</stroke></i>`)
	return table.concat(lines, "\n")
end

return function()
	local data, setData = React.useState(nil)
	local timer, setTimer = React.useState(nil)

	React.useEffect(function()
		local trove = Trove.new()

		trove
			:AddPromise(Promise.try(function()
				return trove:Add(Comm.ClientComm.new(ReplicatedStorage, true, "ChallengeService"))
			end))
			:andThen(function(comm)
				trove:Add(comm:GetProperty("State"):Observe(setData))
			end)

		return function()
			trove:Clean()
		end
	end, {})

	React.useEffect(function()
		if not data then return end

		local thread = task.spawn(function()
			while true do
				task.wait(0.5)
				local remaining = math.floor(math.max(data.timestamp - DateTime.now().UnixTimestamp, 0))
				setTimer(FormatTime(remaining))
			end
		end)

		return function()
			task.cancel(thread)
		end
	end, { data })

	return React.createElement(React.Fragment, nil, {
		Status = (data ~= nil) and (timer ~= nil) and React.createElement("TextLabel", {
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.25),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Position = UDim2.new(0, 10, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			RichText = true,
			LineHeight = 1.25,
			Text = getText(data, timer),
		}),
	})
end
