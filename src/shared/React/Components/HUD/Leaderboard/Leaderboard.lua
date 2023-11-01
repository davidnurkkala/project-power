local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local FancyFrame = require(ReplicatedStorage.Shared.React.Components.HUD.Common.FancyFrame)
local LeaderboardController = require(ReplicatedStorage.Shared.Controllers.LeaderboardController)
local React = require(ReplicatedStorage.Packages.React)

local Leaderboard: React.FC<nil> = function()
	local contents, setContents = React.useState(nil)

	React.useEffect(function()
		local connection = LeaderboardController.roundEnded:Connect(function(stats)
			if not stats then
				setContents(nil)
				return
			end

			local newContents = {}

			for i = 1, math.min(3, #stats) do
				table.insert(
					newContents,
					React.createElement("Frame", {
						Size = UDim2.fromScale(1, 0.2),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
					}, {
						UIListLayout = React.createElement("UIListLayout", {
							SortOrder = Enum.SortOrder.LayoutOrder,
							FillDirection = Enum.FillDirection.Horizontal,
						}),
						Icon = React.createElement("ImageLabel", {
							Size = UDim2.fromScale(0.1, 1),
							BackgroundTransparency = 1,
							Image = CurrencyDefinitions["power" :: any].iconId,
							ImageColor3 = Color3.fromRGB(255, 255, 255),
							ScaleType = Enum.ScaleType.Fit,
						}),
						PlayerName = React.createElement("TextLabel", {
							Size = UDim2.fromScale(0.7, 1),
							BackgroundTransparency = 1,
							Text = stats[i].name,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 24,
							Font = Enum.Font.GothamBold,
							TextXAlignment = Enum.TextXAlignment.Center,
						}),
						Amount = React.createElement("TextLabel", {
							Position = UDim2.fromScale(1, 0),
							AnchorPoint = Vector2.new(1, 0),
							Size = UDim2.fromScale(0.2, 1),
							BackgroundTransparency = 1,
							Text = tostring(stats[i].power),
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 24,
							Font = Enum.Font.GothamBold,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
					})
				)
			end

			setContents(newContents)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	if not contents then return end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
	}, {
		FancyFrame = React.createElement(FancyFrame, {
			headerTitle = "Leaderboard",
			frameProps = {
				Size = UDim2.fromScale(0.8, 0.6),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundColor3 = Color3.fromRGB(48, 44, 39),
				BackgroundTransparency = 0.1,
			},
		}, {
			UIListLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			Contents = React.createElement(React.Fragment, nil, contents),
		}),
	})
end

return Leaderboard
