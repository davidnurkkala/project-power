local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Extras = require(ReplicatedStorage.Shared.React.Components.Shop.Extras)
local Flipper = require(ReplicatedStorage.Packages.Flipper)
local HudButtons = require(ReplicatedStorage.Shared.React.Components.HUD.HudButtons.HudButtons)
local ProductController = require(ReplicatedStorage.Shared.Controllers.ProductController)
local React = require(ReplicatedStorage.Packages.React)
local SessionRewardController = require(ReplicatedStorage.Shared.Controllers.SessionRewardController)
local Shop = require(ReplicatedStorage.Shared.React.Components.Shop.Shop)
local Signal = require(ReplicatedStorage.Packages.Signal)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

local BUTTON_SIZES = {
	small = 80,
	large = 130,
}

type MenuType = ("Shop" | "Extras")?

export type ShopBridgeProps = {
	visible: boolean,
}

local ShopBridge: React.FC<ShopBridgeProps> = function(props: ShopBridgeProps)
	local active, setActive = React.useState(nil)

	local menusVisible = props.visible

	local notificationAdded = React.useRef(Signal.new()).current

	React.useEffect(function()
		local connection = ProductController.shopOpened:Connect(function()
			setActive("Shop")
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return React.createElement(React.Fragment, nil, {
		HudButtons = menusVisible and React.createElement(HudButtons, {
			buttonSelected = function(buttonName: string?)
				if active == buttonName then
					setActive(nil)
					return
				end
				setActive(buttonName)
			end,
			notificationAdded = notificationAdded,
		}),

		Extras = React.createElement(Extras, {
			visible = menusVisible and active == "Extras",
			exit = function()
				if active == "Extras" then setActive(nil) end
			end,

			notify = function()
				notificationAdded:Fire("Extras")
			end,
			-- quick session api
			awarded = SessionRewardController.awarded,
			awardBecameAvailable = SessionRewardController.awardBecameAvailable,
			observeInfo = function(callback)
				return SessionRewardController:observeInfo(callback)
			end,
			promiseClaim = function(index)
				return SessionRewardController:claim(index)
			end,
		}),
		Shop = React.createElement(Shop, {
			visible = menusVisible and active == "Shop",
			exit = function()
				if active == "Shop" then setActive(nil) end
			end,
			notify = function()
				notificationAdded:Fire("Shop")
			end,

			getIsPurchased = function(productable)
				return ProductController:isPurchased(productable)
			end,
			getIsEquipped = function(productable)
				return ProductController:isEquipped(productable)
			end,
			setEquipped = function(productable, equipped)
				if equipped then
					return ProductController.equipProduct(productable)
				else
					return ProductController.unequipProduct(productable)
				end
			end,
			purchase = function(productable)
				return ProductController.purchaseProduct(productable)
			end,
		}),
	})
end

return ShopBridge
