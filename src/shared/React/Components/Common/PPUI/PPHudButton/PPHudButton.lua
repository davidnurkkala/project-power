-- stylized frame with an optional close button
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local React = require(ReplicatedStorage.Packages.React)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

export type PPHudButtonProps = {
	active: boolean?,
	anchorPoint: Vector2?,
	backgroundColor: Color3?,
	size: UDim2?,
	position: UDim2?,
	layoutOrder: number?,
	zIndex: number?,

	onActivated: () -> ()?,
	onPressed: () -> ()?,
	onReleased: () -> ()?,
	onEntered: () -> ()?,
	onExited: () -> ()?,
	onHovered: () -> ()?,
	onHoverEnded: () -> ()?,
}

local VALID_INPUT = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}

local BUTTON_9_SLICE_IMG = "rbxassetid://14975440114"
local DEPTH_SLICE_IMG = "rbxassetid://14975543656"
local BACKGROUND_TILE_IMG = "rbxassetid://14975987457"

local SLICE_CENTER = Rect.new(128, 128, 128, 128)
local TILE_SIZE = UDim2.fromOffset(256, 256)

local BUTTON_DEPTH = 0.1 -- percent of height
local CLICK_SPRING = {
	frequency = 6,
	dampingRatio = 1,
}

local defaultProps: PPHudButtonProps = {
	active = true,
	anchorPoint = Vector2.new(0, 0),
	backgroundColor = Color3.fromRGB(0, 0, 0),
	position = UDim2.fromScale(0, 0),
	size = UDim2.fromScale(1, 1),
	layoutOrder = 0,
}

local PPHudButton: React.FC<PPHudButtonProps> = function(props)
	local active = if props.active == nil then defaultProps.active else props.active
	local depthBinding, depthMotor = useMotor(0)

	local children = {
		background = React.createElement("ImageLabel", {
			Active = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 0,
			BackgroundColor3 = props.backgroundColor or defaultProps.backgroundColor,

			Image = BACKGROUND_TILE_IMG,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = TILE_SIZE,

			ZIndex = 1,
		}, {
			uiCorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
		border = React.createElement("ImageLabel", {
			Active = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			LayoutOrder = props.layoutOrder or defaultProps.layoutOrder,

			Image = BUTTON_9_SLICE_IMG,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = SLICE_CENTER,

			ZIndex = 2,
		}),
		contents = React.createElement("Frame", {
			Active = false,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 4,
		}, props.children),

		uiCorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
	}

	return React.createElement("Frame", {
		AnchorPoint = props.anchorPoint or defaultProps.anchorPoint,
		BackgroundTransparency = 1,
		Position = props.position or defaultProps.position,
		Size = props.size or defaultProps.size,
		LayoutOrder = props.layoutOrder or defaultProps.layoutOrder,
		ZIndex = props.zIndex or defaultProps.zIndex,
	}, {
		depthImg = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0, 1),
			Active = false,
			BackgroundTransparency = 1,

			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
			LayoutOrder = props.layoutOrder or defaultProps.layoutOrder,

			Image = DEPTH_SLICE_IMG,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = SLICE_CENTER,

			ZIndex = 0,
		}, {
			bridge = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BorderSizePixel = 0,
				Size = depthBinding:map(function(depth)
					return UDim2.new(1, 0, BUTTON_DEPTH * (1 - depth), 0)
				end),
				Position = UDim2.new(0, 0, 0.5, 0),
				ZIndex = 1,
			}),
		}),

		button = React.createElement("ImageButton", {
			Active = active,
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = depthBinding:map(function(depth)
				return UDim2.new(0, 0, 1 - BUTTON_DEPTH * (1 - depth), 0)
			end),

			ImageTransparency = 0.5,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = SLICE_CENTER,

			LayoutOrder = props.layoutOrder or defaultProps.layoutOrder,
			ZIndex = 2,

			--event handlers
			[React.Event.Activated] = function()
				if not active then return end
				if props.onActivated then props.onActivated() end
			end,
			[React.Event.InputBegan] = function(ref, inputObject)
				if not active then return end
				if not VALID_INPUT[inputObject.UserInputType] then return end

				depthMotor:setGoal(Flipper.Spring.new(1, CLICK_SPRING))
				if props.onPressed then props.onPressed() end
			end,
			[React.Event.InputEnded] = function(ref, inputObject)
				if not VALID_INPUT[inputObject.UserInputType] then return end

				depthMotor:setGoal(Flipper.Spring.new(0, CLICK_SPRING))
				if props.onReleased then props.onReleased() end
			end,
			[React.Event.MouseEnter] = function()
				if not active then return end
				if props.onHovered then props.onHovered() end
			end,
			[React.Event.MouseLeave] = function()
				if not active then return end
				if props.onHoverEnded then props.onHoverEnded() end
			end,
		}, children),
	})
end

return PPHudButton
