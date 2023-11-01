-- stylized frame with an optional close button
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PPHudButton = require(ReplicatedStorage.Shared.React.Components.Common.PPUI.PPHudButton.PPHudButton)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)

export type PPFrameProps = {
	anchorPoint: Vector2?,
	backgroundColor: Color3?,
	size: UDim2?,
	position: UDim2?,

	headerText: string?,
	layoutOrder: number?,
	transparency: number?,
	onClosed: () -> ()?,
}

local FRAME_9_SLICE_IMG = "rbxassetid://14975168855"
local HEADER_9_SLICE_IMG = "rbxassetid://14976509742"
local CLOSE_BUTTON_IMG = "rbxassetid://14975310403"
local BACKGROUND_TILE_IMG = "rbxassetid://14975987457"
local MIN_SIZE = 256
local SLICE_CENTER = Rect.new(128, 128, 128, 128)
local HEADER_SLICE_CENTER = Rect.new(128, 0, 128, 0)

local TILE_SIZE = UDim2.fromOffset(512, 512)

local defaultProps: PPFrameProps = {
	anchorPoint = Vector2.new(0, 0),
	backgroundColor = Color3.fromRGB(0, 0, 0),
	position = UDim2.fromScale(0, 0),
	size = UDim2.fromScale(1, 1),

	layoutOrder = 0,
}

local PPFrame: React.FC<PPFrameProps> = function(props)
	React.useEffect(function()
		return function()
			-- cleanup
		end
	end, {})

	local children = {
		background = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -24, 1, -24),
			BackgroundTransparency = 0,
			BackgroundColor3 = props.backgroundColor or defaultProps.backgroundColor,

			Image = BACKGROUND_TILE_IMG,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = TILE_SIZE,
			ZIndex = 1,
		}),

		header = props.headerText and React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0, 1),
			Size = UDim2.new(0, 96, 0, 60),
			Position = UDim2.new(0, 32, 0, 4),

			AutomaticSize = Enum.AutomaticSize.X,

			BackgroundTransparency = 1,
			Image = HEADER_9_SLICE_IMG,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = HEADER_SLICE_CENTER,
			ZIndex = 3,
		}, {
			text = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0.65, 0),
				Position = UDim2.new(0, 64, 1, 0),
				Font = Enum.Font.Bangers,
				Text = props.headerText,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 36,

				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 4,
			}),
		}),

		border = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			LayoutOrder = props.layoutOrder or defaultProps.layoutOrder,

			Image = FRAME_9_SLICE_IMG,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = SLICE_CENTER,

			ZIndex = 2,
		}),

		contents = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -24, 1, -24),
			BackgroundTransparency = 1,
			ZIndex = 3,
		}, props.children),

		closeButton = props.onClosed and React.createElement(PPHudButton, {
			anchorPoint = Vector2.new(1, 0),
			position = UDim2.new(1, 16, 0, -16),
			size = UDim2.fromOffset(64, 64),
			zIndex = 4,
			onActivated = props.onClosed,
		}, {
			image = React.createElement("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Image = CLOSE_BUTTON_IMG,
				ImageColor3 = Color3.fromRGB(255, 255, 255),
			}),
		}),
		sizeConstraint = React.createElement("UISizeConstraint", {
			MinSize = Vector2.new(MIN_SIZE, MIN_SIZE),
		}),
	}

	return React.createElement("Frame", {
		AnchorPoint = props.anchorPoint or defaultProps.anchorPoint,
		BackgroundTransparency = 1,
		Size = props.size or defaultProps.size,
		Position = props.position or defaultProps.position,
		LayoutOrder = props.layoutOrder or defaultProps.layoutOrder,
	}, children)
end

return PPFrame
