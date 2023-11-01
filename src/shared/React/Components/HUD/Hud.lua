local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattleHudDesktop = require(ReplicatedStorage.Shared.React.Components.HUD.BattleHudDesktop)
local BattleHudMobile = require(ReplicatedStorage.Shared.React.Components.HUD.BattleHudMobile)
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local CurrencyDisplay = require(ReplicatedStorage.Shared.React.Components.HUD.CurrencyDisplay.CurrencyDisplay)
local PlatformContext = require(ReplicatedStorage.Shared.React.Contexts.PlatformContext)
local PowerDisplay = require(ReplicatedStorage.Shared.React.Components.HUD.CurrencyDisplay.PowerDisplay)
local ProductController = require(ReplicatedStorage.Shared.Controllers.ProductController)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local useCurrency = require(ReplicatedStorage.Shared.React.Hooks.useCurrency)

local COLORS = {
	background = Color3.new(1, 1, 1),
	border = Color3.new(0.6, 0.6, 0.6),
	borderDim = Color3.new(0.3, 0.3, 0.3),
	text = Color3.new(1, 1, 1),
	textDim = Color3.new(0.3, 0.3, 0.3),
	textStroke = Color3.new(0, 0, 0),
}

local function label(props)
	props = Sift.Dictionary.merge({
		Font = Enum.Font.Gotham,
		TextColor3 = COLORS.text,
		TextStrokeColor3 = COLORS.textStroke,
		TextStrokeTransparency = 0,
		TextScaled = true,
		BackgroundTransparency = 1,
	}, props)

	return React.createElement("TextLabel", props)
end

local function crystalsButton(props: {
	position: UDim2,
	anchorPoint: Vector2,
	size: UDim2,
})
	local currency = useCurrency("premium")

	return React.createElement("ImageButton", {
		Image = "",
		BackgroundTransparency = 0.5,
		Size = props.size,
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		BackgroundColor3 = CurrencyDefinitions.premium.textColor,
		ClipsDescendants = false,
		[React.Event.Activated] = function()
			ProductController.shopOpened:Fire("currency")
		end,
	}, {
		Image = React.createElement("ImageLabel", {
			Size = UDim2.fromScale(0.4, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(-0.25, 0.3),
			Image = CurrencyDefinitions.premium.iconId,
			ScaleType = Enum.ScaleType.Fit,
		}),

		Amount = React.createElement(label, {
			Size = UDim2.fromScale(0.65, 1),
			Position = UDim2.fromScale(0.15, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextStrokeTransparency = 1,
			TextColor3 = Color3.fromHex("dfe6e9"),
			TextScaled = true,
			Text = `{currency}`,
			Font = Enum.Font.GothamBold,
		}),

		Plus = React.createElement(label, {
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Position = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(1, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextStrokeTransparency = 1,
			TextColor3 = Color3.fromHex("dfe6e9"),
			TextScaled = true,
			Text = "+",
			Font = Enum.Font.GothamBold,
		}),

		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0.5, 0),
		}),
	})
end

return function(props)
	local platform = React.useContext(PlatformContext)
	local isMobile = platform == "Mobile"
	isMobile = true

	if isMobile then
		return React.createElement("Frame", {
			Size = UDim2.fromScale(0.8, 0.4),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Position = UDim2.new(1, -16, 1, -16),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
		}, {
			Constraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(720, 360),
				MinSize = Vector2.new(360, 180),
			}),
			CurrencyPower = React.createElement(PowerDisplay, {
				position = UDim2.fromScale(0.3, 1),
				anchorPoint = Vector2.new(0.5, 1),
				size = UDim2.fromScale(0.25, 0.15),
			}),
			CurrencyKills = React.createElement(CurrencyDisplay, {
				currencyType = "kills",
				position = UDim2.fromScale(0.6, 1),
				anchorPoint = Vector2.new(0.5, 1),
				size = UDim2.fromScale(0.25, 0.15),
			}),
			Crystals = (not props.isInBattle) and React.createElement(crystalsButton, {
				position = UDim2.fromScale(-0.2, 1),
				anchorPoint = Vector2.new(0.5, 1),
				size = UDim2.fromScale(0.25, 0.125),
			}),
			BattleHud = props.isInBattle and React.createElement(BattleHudMobile, props),
		})
	else
		return React.createElement(BattleHudDesktop, props)
	end
end
