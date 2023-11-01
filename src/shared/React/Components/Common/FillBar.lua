local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local BAR_IMAGE = "rbxassetid://13991273698"
local BAR_IMAGE_FLIPPED = "rbxassetid://13991637870"

export type FillBarProps = {
	maxValue: number,
	value: number,
	fillColor: Color3?,
	backgroundColor: Color3?,
	roundingUDim: UDim?,
	gradientRotation: number?,
	flipped: boolean?,
}

local FillBar: React.FC<FillBarProps> = function(props)
	local sizeBinding, setSizeBinding = React.useBinding(Vector2.new())
	local imageSizeBinding, setImageSizeBinding = React.useBinding(Vector2.new())

	local flipped = if props.flipped == nil then false else props.flipped
	local maxValue = props.maxValue
	local value = props.value
	local fillColor = props.fillColor or Color3.new(0, 0, 0)
	local backgroundColor = props.backgroundColor or Color3.new(1, 1, 1)
	local image = if flipped then BAR_IMAGE_FLIPPED else BAR_IMAGE
	local fillPercentage = value / maxValue
	local padding = 1

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[React.Change.AbsoluteSize] = function(object)
			setSizeBinding(object.AbsoluteSize)
		end,
	}, {
		Background = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			ImageColor3 = backgroundColor,
			Image = image,
			ScaleType = Enum.ScaleType.Slice,
			Size = UDim2.fromScale(1, 1),
			SliceCenter = imageSizeBinding:map(function(imageSize)
				return Rect.new(0, 0, 192, if flipped then math.min(64, imageSize.Y) else 64)
			end),
			[React.Change.AbsoluteSize] = function(object)
				setImageSizeBinding(object.AbsoluteSize)
			end,
		}),

		Culler = React.createElement("Frame", {
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Size = UDim2.fromScale(fillPercentage, 1),
			ZIndex = 2,
		}, {
			Bar = React.createElement("ImageLabel", {
				Position = UDim2.fromOffset(padding, padding),
				BackgroundTransparency = 1,
				ImageColor3 = fillColor,
				Image = image,
				ScaleType = Enum.ScaleType.Slice,
				Size = sizeBinding:map(function(size)
					return UDim2.fromOffset(size.X - 1 - (padding * 2), size.Y - (padding * 2))
				end),
				SliceCenter = imageSizeBinding:map(function(imageSize)
					return Rect.new(0, 0, 192, if flipped then math.min(64, imageSize.Y - (padding * 2)) else 64)
				end),
			}),
		}),
	})
end

return FillBar
