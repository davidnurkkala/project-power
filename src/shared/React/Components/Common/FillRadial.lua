local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local TRANSPARENCY_GRADIENT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5000, 0),
	NumberSequenceKeypoint.new(0.5001, 1),
	NumberSequenceKeypoint.new(1, 1),
})

export type FillRadialProps = {
	maxValue: number,
	value: number,

	emptyImage: string?,
	fillImage: string?,
	emptyColor: Color3?,
	fillColor: Color3?,
}

local FillRadial: React.FC<FillRadialProps> = function(props)
	local maxValue = props.maxValue
	local value = props.value
	local fillPercentage = value / maxValue

	local emptyImage = props.emptyImage or "rbxassetid://7036402637"
	local fillImage = props.fillImage or "rbxassetid://7036407423"
	local emptyColor = props.emptyColor or Color3.fromRGB(255, 255, 255)
	local fillColor = props.fillColor or Color3.fromRGB(0, 165, 35)

	return React.createElement("ImageLabel", {
		BackgroundTransparency = 1,
		Image = emptyImage,
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ImageColor3 = emptyColor,
	}, {
		Left = React.createElement("Frame", {
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Size = UDim2.fromScale(0.5, 1),
		}, {
			React.createElement("ImageLabel", {
				BackgroundTransparency = 1,
				Image = fillImage,
				Size = UDim2.fromScale(2, 1),
				ImageColor3 = fillColor,
			}, {
				React.createElement("UIGradient", {
					Rotation = math.clamp(fillPercentage * 360, 180, 360),
					Transparency = TRANSPARENCY_GRADIENT,
				}),
			}),
		}),
		Right = React.createElement("Frame", {
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Size = UDim2.fromScale(0.5, 1),
			Position = UDim2.fromScale(0.5, 0),
		}, {
			React.createElement("ImageLabel", {
				BackgroundTransparency = 1,
				Image = fillImage,
				Size = UDim2.fromScale(2, 1),
				Position = UDim2.fromScale(-1, 0),
				ImageColor3 = fillColor,
			}, {
				React.createElement("UIGradient", {
					Rotation = math.clamp(fillPercentage * 360, 0, 180),
					Transparency = TRANSPARENCY_GRADIENT,
				}),
			}),
		}),
		React.createElement(React.Fragment, nil, props.children),
	})
end

return FillRadial
