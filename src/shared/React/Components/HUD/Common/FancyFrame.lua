local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

export type FancyFrameProps = {
	headerTitle: string?,
	frameProps: any,
} & React.ElementProps<Frame>

local FancyFrame: React.FC<FancyFrameProps> = function(props)
	return React.createElement("Frame", props.frameProps, {
		UICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 16),
		}),
		Header = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 0.15),
			BackgroundTransparency = 0,
		}, {
			Text = React.createElement("TextLabel", {
				Text = props.headerTitle,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.8, 0.6),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Font = Enum.Font.GothamBold,
				TextScaled = true,
			}),
			BlockFrame = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				BorderSizePixel = 0,
			}),
			UICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 16),
			}),
		}),
		Content = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 0.85),
			Position = UDim2.fromScale(0, 0.15),
			BackgroundTransparency = 1,
		}, props.children),
	})
end

return FancyFrame
