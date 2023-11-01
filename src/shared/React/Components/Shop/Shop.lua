local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local PPFrame = require(ReplicatedStorage.Shared.React.Components.Common.PPUI.PPFrame.PPFrame)
local PPHudButton = require(ReplicatedStorage.Shared.React.Components.Common.PPUI.PPHudButton.PPHudButton)
local ProductController = require(ReplicatedStorage.Shared.Controllers.ProductController)
local ProductDefinitions = require(ReplicatedStorage.Shared.Data.ProductDefinitions)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Trove = require(ReplicatedStorage.Packages.Trove)
local useCurrency = require(ReplicatedStorage.Shared.React.Hooks.useCurrency)

local COLORS = {
	background = Color3.new(1, 1, 1),
	border = Color3.new(0.6, 0.6, 0.6),
	borderDim = Color3.new(0.3, 0.3, 0.3),
	text = Color3.new(1, 1, 1),
	textDim = Color3.new(0.3, 0.3, 0.3),
	textStroke = Color3.new(0, 0, 0),
}

local TRANSPARENCY = 0.7

type Promise = any
type Productable = { id: string, kind: string }

export type ShopProps = {
	getIsPurchased: (Productable) -> Promise,
	getIsEquipped: (Productable) -> Promise,
	setEquipped: (Productable, boolean) -> Promise,
	purchase: (Productable) -> Promise,
	exit: () -> (),
	visible: boolean,
}

local function inline(func)
	return func()
end

local function usePromise(defaultValue, promiseFunc)
	local state, setState = React.useState(defaultValue)

	React.useEffect(function()
		setState(defaultValue)
		local internalPromise = promiseFunc():andThen(setState)

		return function()
			internalPromise:cancel()
		end
	end, { defaultValue, promiseFunc })

	return state, setState
end

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

local function button(props)
	props = Sift.Dictionary.merge({
		Font = Enum.Font.Gotham,
		TextColor3 = COLORS.text,
		TextStrokeColor3 = COLORS.textStroke,
		TextStrokeTransparency = 0,
		TextScaled = true,
		BackgroundColor3 = COLORS.background,
		BackgroundTransparency = TRANSPARENCY,
	}, props)

	local children = Sift.Dictionary.merge({
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
	}, props.children)

	return React.createElement("TextButton", props, children)
end

local function ppHudButton(props)
	return React.createElement(PPHudButton, props, {
		Text = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.new(0.75, 0, 0.65, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Font = Enum.Font.Gotham,
			TextColor3 = COLORS.text,
			TextStrokeColor3 = COLORS.textStroke,
			TextStrokeTransparency = 0,
			TextScaled = true,
			Text = props.text,
		}),
	})
end

local function scrollingFrame(props)
	local contentSize, setContentSize = React.useBinding(Vector2.new())

	props = Sift.Dictionary.merge({
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		CanvasSize = contentSize:map(function(value)
			return UDim2.fromOffset(value.X, value.Y)
		end),
		BorderSizePixel = 0,
	}, props)

	local children = Sift.Dictionary.merge({
		Layout = props.renderLayout(setContentSize),
	}, props.children)

	props = Sift.Dictionary.removeKeys(props, "renderLayout")

	return React.createElement("ScrollingFrame", props, children)
end

local function paddingAll(props)
	return React.createElement("UIPadding", {
		PaddingTop = props.padding,
		PaddingRight = props.padding,
		PaddingBottom = props.padding,
		PaddingLeft = props.padding,
	})
end

local function productDetails(props)
	local category = ProductDefinitions[props.categoryName]
	local product = category.products[props.productId]

	local hasImage = (product.image ~= nil) and (product.image ~= "")

	local awaitingResponse, setAwaitingResponse = React.useBinding(false)

	local isPurchased, setIsPurchased = usePromise(
		nil,
		React.useCallback(function()
			return props.getIsPurchased(product)
		end, { product })
	)
	local isEquipped, setIsEquipped = usePromise(
		nil,
		React.useCallback(function()
			return props.getIsEquipped(product)
		end, { product })
	)
	local price = usePromise(
		-1,
		React.useCallback(function()
			return product.getPrice()
		end, { product })
	)

	return React.createElement(React.Fragment, nil, {
		Top = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.3),
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 0),
			}),

			Left = React.createElement("Frame", {
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.5, 1),
			}, {
				Title = React.createElement(label, {
					Size = UDim2.fromScale(1, 1 / 3),
					Font = Enum.Font.GothamBold,
					TextStrokeTransparency = 1,
					TextColor3 = Color3.fromHex("dfe6e9"),
					Text = product.name,
					TextScaled = true,
				}, {
					Contraint = React.createElement("UITextSizeConstraint", {
						MaxTextSize = 20,
					}),

					Stroke = React.createElement("UIStroke", {
						Color = Color3.fromHex("2d3436"),
						Thickness = 2,
					}),
				}),
				Type = React.createElement(label, {
					Size = UDim2.fromScale(1, 1 / 3),
					Position = UDim2.fromScale(0, 1 / 3),
					TextScaled = true,
					TextStrokeTransparency = 1,
					TextColor3 = Color3.fromHex("dfe6e9"),
					Font = Enum.Font.GothamBold,
					Text = category.displayNameSingular,
				}, {
					Stroke = React.createElement("UIStroke", {
						Color = Color3.fromHex("2d3436"),
						Thickness = 2,
					}),
				}),
				Price = React.createElement(label, {
					Size = UDim2.fromScale(1, 1 / 3),
					Position = UDim2.fromScale(0, 2 / 3),
					TextScaled = true,
					TextStrokeTransparency = 1,
					Font = Enum.Font.GothamBold,
					TextColor3 = if isPurchased == false then CurrencyDefinitions.premium.textColor else Color3.fromHex("dfe6e9"),
					Text = inline(function()
						if isPurchased == nil then return "..." end

						if isPurchased then
							return if isEquipped then "EQUIPPED" else "OWNED"
						else
							if typeof(price) == "string" then return price end

							if price < 0 then
								return "..."
							elseif price == 0 then
								return "FREE"
							else
								return `{price} Crystals`
							end
						end
					end),
				}, {
					Stroke = React.createElement("UIStroke", {
						Color = if isPurchased == false then CurrencyDefinitions.premium.textColor else Color3.fromHex("2d3436"),
						Thickness = 2,
					}),
				}),
			}),

			Image = hasImage and React.createElement("Frame", {
				LayoutOrder = 2,
				Size = UDim2.fromScale(0.5, 1),
				BackgroundTransparency = 1,
			}, {
				Frame = React.createElement("Frame", {
					BackgroundColor3 = Color3.fromHex("2d3436"),
					Size = UDim2.fromScale(1, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0),
				}, {
					Image = React.createElement("ImageLabel", {
						Size = UDim2.fromScale(1, 1),
						Image = product.image,
						BackgroundTransparency = 1,
						ScaleType = Enum.ScaleType.Fit,
					}),

					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),

					Padding = React.createElement(paddingAll, {
						padding = UDim.new(0, 8),
					}),

					Stroke = React.createElement("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromHex("636e72"),
						Thickness = 2,
					}),
				}),
			}),
		}),

		Description = React.createElement(label, {
			Size = UDim2.fromScale(1, 0.5),
			Position = UDim2.fromScale(0, 0.3),
			Text = inline(function()
				if product.kind == "killSound" then
					return "Players you kill will play one of your equipped kill sounds, chosen randomly."
				elseif product.kind == "killImage" then
					return "Players you kill will have their screen plastered with one of your equipped kill images, chosen randomly."
				end

				return product.description
			end),
			TextStrokeTransparency = 1,
			TextColor3 = Color3.fromHex("#b8c5c9"),
			Font = Enum.Font.GothamBold,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 4),
			}),
		}),

		Buttons = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 0.15),
			Position = UDim2.fromScale(0, 0.85),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),

			Preview = React.createElement(button, {
				LayoutOrder = -4,
				Text = "Preview",
				Font = Enum.Font.GothamBold,
				TextStrokeTransparency = 1,
				TextColor3 = Color3.fromHex("dfe6e9"),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromHex("2d3436"),
				TextScaled = true,
				Size = UDim2.fromScale(1 / 2, 1),
				Visible = (product.kind == "killSound"),
				[React.Event.Activated] = function()
					local sound = Instance.new("Sound")
					sound.PlayOnRemove = true
					sound.SoundId = product.soundId
					sound.Parent = workspace
					task.defer(function()
						sound:Destroy()
					end)
				end,
			}, {
				Padding = React.createElement(paddingAll, {
					padding = UDim.new(0.1, 0),
				}),

				Stroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromHex("636e72"),
					Thickness = 2,
				}),
			}),

			Purchase = React.createElement(button, {
				Text = awaitingResponse:map(function(value)
					return if value then "..." else "Purchase"
				end),
				Font = Enum.Font.GothamBold,
				TextStrokeTransparency = 1,
				TextColor3 = Color3.fromHex("dfe6e9"),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromHex("2d3436"),
				TextScaled = true,
				LayoutOrder = 1,
				Size = UDim2.fromScale(1 / 2, 1),
				Visible = if isPurchased == nil then false else not isPurchased,
				[React.Event.Activated] = function()
					if awaitingResponse:getValue() then return end
					setAwaitingResponse(true)
					props.purchase(product):finally(function()
						setAwaitingResponse(false)
						props.getIsPurchased(product):andThen(setIsPurchased)
					end)
				end,
			}, {
				Padding = React.createElement(paddingAll, {
					padding = UDim.new(0.1, 0),
				}),

				Stroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromHex("636e72"),
					Thickness = 2,
				}),
			}),

			Equip = React.createElement(button, {
				Text = awaitingResponse:map(function(value)
					return if value then "..." else if isEquipped == nil then "..." else if isEquipped then "Unequip" else "Equip"
				end),
				Font = Enum.Font.GothamBold,
				TextStrokeTransparency = 1,
				TextColor3 = Color3.fromHex("dfe6e9"),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromHex("2d3436"),
				TextScaled = true,
				LayoutOrder = 2,
				Size = UDim2.fromScale(1 / 2, 1),
				Visible = if isPurchased == nil then false else isPurchased,
				[React.Event.Activated] = function()
					if isEquipped == nil then return end
					if awaitingResponse:getValue() then return end
					setAwaitingResponse(true)
					props.setEquipped(product, not isEquipped):finally(function()
						setAwaitingResponse(false)
						props.getIsEquipped(product):andThen(setIsEquipped)
					end)
				end,
			}, {
				Stroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromHex("636e72"),
					Thickness = 2,
				}),
			}),
		}),
	})
end

local function currencyButton(props)
	local product = props.product
	local layoutOrder = props.layoutOrder
	local purchase = props.purchase

	local price = usePromise(
		-1,
		React.useCallback(function()
			return product.getPrice()
		end, { product })
	)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
	}, {
		Padding = React.createElement(paddingAll, {
			padding = UDim.new(0, 16),
		}),

		Button = React.createElement(button, {
			Size = UDim2.fromScale(1, 1),
			Text = "",
			BackgroundColor3 = Color3.fromHex("2d3436"),
			BackgroundTransparency = 0,
			[React.Event.Activated] = function()
				purchase()
			end,
		}, {
			Padding = React.createElement(paddingAll, {
				padding = UDim.new(0.1, 0),
			}),
			Text = React.createElement(label, {
				Size = UDim2.fromScale(1, 0.5),
				Text = product.name,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextStrokeTransparency = 1,
				TextColor3 = CurrencyDefinitions.premium.textColor,
			}),
			Price = React.createElement(label, {
				Size = UDim2.fromScale(1, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Text = `{price} R$`,
				TextColor3 = Color3.fromHex("00b894"),
				TextScaled = true,
				Font = Enum.Font.GothamBold,
				TextStrokeTransparency = 1,
			}),
			Stroke = React.createElement("UIStroke", {
				Thickness = 2,
				Color = CurrencyDefinitions.premium.textColor,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}),
	})
end

local function productButton(props)
	local layoutOrder = props.layoutOrder
	local isSelected = props.isSelected
	local awaitingResponse = props.awaitingResponse
	local setSelectedProduct = props.setSelectedProduct
	local product = props.product
	local getIsEquipped = props.getIsEquipped
	local getIsOwned = props.getIsOwned

	local isEquipped, setEquipped = usePromise(
		nil,
		React.useCallback(function()
			return getIsEquipped(product)
		end, { product })
	)

	local isOwned, setOwned = usePromise(
		nil,
		React.useCallback(function()
			return getIsOwned(product)
		end, { product })
	)

	React.useEffect(function()
		local trove = Trove.new()
		trove:Connect(ProductController.productData.Changed, function()
			trove:AddPromise(getIsEquipped(product):andThen(setEquipped))
			trove:AddPromise(getIsOwned(product):andThen(setOwned))
		end)

		return function()
			trove:Clean()
		end
	end, { product })

	return React.createElement("CanvasGroup", {
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
		GroupTransparency = if isOwned then 0 else 0.5,
	}, {
		Padding = React.createElement(paddingAll, {
			padding = UDim.new(0, 4),
		}),

		Button = React.createElement(button, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromHex("2d3436"),
			Text = "",
			TextWrapped = true,
			[React.Event.Activated] = function()
				if awaitingResponse then return end
				setSelectedProduct(product.id)
			end,
		}, {
			Stroke = isSelected and React.createElement("UIStroke", {
				Color = Color3.fromHex("636e72"),
				Thickness = 2,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),

			Padding = React.createElement(paddingAll, {
				padding = UDim.new(0, 4),
			}),

			Text = React.createElement(label, {
				Size = UDim2.fromScale(1, 0.5),
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				Text = product.name,
				Font = Enum.Font.GothamBold,
				TextStrokeTransparency = 0,
				TextColor3 = Color3.fromHex("dfe6e9"),
				TextWrapped = true,
				TextScaled = true,
				TextYAlignment = if product.image then Enum.TextYAlignment.Bottom else Enum.TextYAlignment.Center,
			}, {
				Stroke = React.createElement("UIStroke", {
					Color = Color3.fromHex("2d3436"),
					Thickness = 2,
				}),
			}),

			EquippedText = isEquipped and React.createElement("TextLabel", {
				Size = UDim2.new(),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Top,
				Text = "✅",
			}),

			Image = product.image and React.createElement("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = -2,
				Image = product.image,
				ScaleType = Enum.ScaleType.Fit,
			}),
		}),
	})
end

local function getProducts(categoryName)
	local category = ProductDefinitions[categoryName]
	return Sift.Array.map(Sift.Array.sort(Sift.Dictionary.keys(category.products)), function(productId)
		return category.products[productId]
	end)
end

local function boosterButton(props: {
	order: number,
	purchase: () -> any,
	product: any,
})
	local state, setState = React.useState("normal")
	local promise = React.useRef(nil)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = props.order,
	}, {
		Padding = React.createElement(paddingAll, {
			padding = UDim.new(0, 16),
		}),

		Button = React.createElement(button, {
			Size = UDim2.fromScale(1, 1),
			Text = "",
			BackgroundColor3 = Color3.fromHex("2d3436"),
			BackgroundTransparency = 0,
			[React.Event.Activated] = function()
				if state == "normal" then
					setState("nothing")
					Promise.delay(1):andThenCall(setState, "confirming"):andThen(function()
						promise.current = Promise.delay(2)
							:finally(function()
								promise.current = nil
							end)
							:andThenCall(setState, "normal")
					end)
				elseif state == "confirming" then
					promise.current:cancel()

					setState("nothing")
					props.purchase():finally(function()
						Promise.delay(1):andThenCall(setState, "normal")
					end)
				end
			end,
		}, {
			Padding = React.createElement(paddingAll, {
				padding = UDim.new(0.1, 0),
			}),

			Normal = (state == "normal") and React.createElement(React.Fragment, nil, {
				Text = React.createElement(label, {
					Size = UDim2.fromScale(1, 0.5),
					Text = `{props.product.amount} minutes`,
					Font = Enum.Font.GothamBold,
					TextScaled = true,
					TextStrokeTransparency = 1,
					TextColor3 = Color3.fromHex("#f36868"),
				}),
				Price = React.createElement(label, {
					Size = UDim2.fromScale(1, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Text = `{props.product.pricePremium} Crystals`,
					TextColor3 = CurrencyDefinitions.premium.textColor,
					TextScaled = true,
					Font = Enum.Font.GothamBold,
					TextStrokeTransparency = 1,
				}),
			}),

			Message = (state ~= "normal") and React.createElement(label, {
				Size = UDim2.fromScale(1, 1),
				Text = if state == "nothing" then ". . ." else "Confirm\npurchase?",
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextStrokeTransparency = 1,
				TextColor3 = Color3.fromHex("#f36868"),
			}),

			Stroke = React.createElement("UIStroke", {
				Thickness = 2,
				Color = Color3.fromHex("#f36868"),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}),
	})
end

local Shop: React.FC<ShopProps> = function(props: ShopProps)
	local selectedCategory, setSelectedCategory = React.useState("currency")
	local selectedProduct, setSelectedProduct = React.useState(getProducts(selectedCategory)[1].id)

	local awaitingResponse = React.useRef(false)

	local currency = useCurrency("premium")

	React.useEffect(function()
		local connection = ProductController.shopOpened:Connect(function(category)
			setSelectedCategory(category)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return React.createElement(React.Fragment, nil, {
		ClickOutBackground = props.visible and React.createElement("ImageButton", {
			BackgroundTransparency = 1,
			Image = "",
			Size = UDim2.fromScale(3, 3),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			[React.Event.Activated] = function()
				if awaitingResponse.current then return end
				props.exit()
			end,
			ZIndex = -4,
		}),

		Frame = React.createElement("ImageButton", {
			Visible = props.visible,
			Modal = true,
			BackgroundTransparency = 1,
			Image = "",
			Size = UDim2.fromScale(0.6, 0.36),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			ZIndex = 512,
		}, {
			Crystals = React.createElement("ImageButton", {
				Image = "",
				BackgroundTransparency = 0.5,
				Size = UDim2.fromScale(0.25, 0.1),
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -48, 0, 20),
				BackgroundColor3 = CurrencyDefinitions.premium.textColor,
				ClipsDescendants = false,
				[React.Event.Activated] = function()
					setSelectedCategory("currency")
				end,
			}, {
				Image = React.createElement("ImageLabel", {
					Size = UDim2.fromScale(0.4, 0.6),
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
			}),

			SideBar = React.createElement("Frame", {
				Size = UDim2.new(0.15, -6, 1, -24),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				BackgroundTransparency = 1,
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 6),
				}),

				Padding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 6),
				}),

				CategoryButtons = inline(function()
					local buttons = {}
					for categoryName, category in ProductDefinitions do
						if category.invisible then continue end

						local isSelected = selectedCategory == categoryName
						buttons[categoryName] = React.createElement(ppHudButton, {
							size = UDim2.new(1, 0, 0.15, 0),
							text = category.displayName,
							layoutOrder = category.order,

							onActivated = function()
								if awaitingResponse.current then return end
								setSelectedCategory(categoryName)
								setSelectedProduct(getProducts(categoryName)[1].id)
							end,
						}, {
							Padding = React.createElement(paddingAll, {
								padding = UDim.new(0.1, 0),
							}),

							Stroke = isSelected and React.createElement("UIStroke", {
								Color = Color3.fromHex("2d3436"),
								Thickness = if isSelected then 2 else 1,
							}),

							Stroke2 = React.createElement("UIStroke", {
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
								Color = if isSelected then Color3.fromHex("2d3436") else Color3.fromHex("b2bec3"),
								Thickness = 2,
							}),
						})
					end
					return React.createElement(React.Fragment, nil, buttons)
				end),
			}),

			Content = React.createElement(PPFrame, {
				size = UDim2.new(0.85, 0, 1, -24),
				anchorPoint = Vector2.new(0, 1),
				position = UDim2.fromScale(0.15, 1),

				headerText = "Shop",
				onClosed = props.exit,
			}, {
				Border = inline(function()
					local padding = UDim.new(0, 8)
					return React.createElement(React.Fragment, nil, {
						Corner = React.createElement("UICorner", {
							CornerRadius = padding,
						}),
						Padding = React.createElement(paddingAll, {
							padding = padding,
						}),
					})
				end),

				if selectedCategory == "currency"
					then React.createElement(React.Fragment, nil, {
						Layout = React.createElement("UIGridLayout", {
							CellSize = UDim2.fromScale(0.5, 0.5),
							CellPadding = UDim2.new(),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),

						Buttons = inline(function()
							local buttons = {}
							local products = Sift.Array.sort(Sift.Dictionary.values(ProductDefinitions.currency.products), function(a, b)
								return a.amount < b.amount
							end)
							for index, product in products do
								buttons[`Product{index}`] = React.createElement(currencyButton, {
									product = product,
									layoutOrder = index,
									purchase = function()
										awaitingResponse.current = true
										return props.purchase(product):finally(function()
											awaitingResponse.current = false
										end)
									end,
								})
							end
							return React.createElement(React.Fragment, nil, buttons)
						end),
					})
					else if selectedCategory == "booster"
						then React.createElement(React.Fragment, nil, {
							Title = React.createElement("Frame", {
								Size = UDim2.fromScale(1, 0.1),
								BackgroundTransparency = 1,
							}, {
								Layout = React.createElement("UIListLayout", {
									SortOrder = Enum.SortOrder.LayoutOrder,
									FillDirection = Enum.FillDirection.Horizontal,
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
									VerticalAlignment = Enum.VerticalAlignment.Center,
									Padding = UDim.new(0, 4),
								}),

								Text = React.createElement(label, {
									LayoutOrder = 1,
									Size = UDim2.fromScale(0, 1),
									AutomaticSize = Enum.AutomaticSize.X,
									TextScaled = true,
									Text = `<stroke thickness="2">Use boosters to earn <font color="#f36868">x2</font></stroke>`,
									RichText = true,
									Font = Enum.Font.GothamBold,
								}),

								Image = React.createElement("ImageLabel", {
									BackgroundTransparency = 1,
									Image = CurrencyDefinitions.power.iconId,
									Size = UDim2.fromScale(1.5, 1.5),
									LayoutOrder = 2,
									SizeConstraint = Enum.SizeConstraint.RelativeYY,
								}),
							}),

							Subtitle = React.createElement(label, {
								Size = UDim2.new(1, 0, 0.1, -5),
								Position = UDim2.new(0, 0, 0.1, 5),
								TextScaled = true,
								Font = Enum.Font.GothamBold,
								Text = `Booster time is active immediately and adds up!`,
								RichText = true,
							}),

							Container = React.createElement("Frame", {
								Size = UDim2.fromScale(1, 0.8),
								Position = UDim2.fromScale(0, 0.2),
								BackgroundTransparency = 1,
							}, {
								Layout = React.createElement("UIGridLayout", {
									CellSize = UDim2.fromScale(0.5, 0.5),
									CellPadding = UDim2.new(),
									SortOrder = Enum.SortOrder.LayoutOrder,
								}),

								Buttons = React.createElement(
									React.Fragment,
									nil,
									Sift.Dictionary.map(
										Sift.Array.sort(Sift.Dictionary.values(ProductDefinitions.booster.products), function(a, b)
											return a.amount < b.amount
										end),
										function(product, order)
											local key = product.id
											local element = React.createElement(boosterButton, {
												order = order,
												product = product,
												purchase = function()
													awaitingResponse.current = true
													return props
														.purchase(product)
														:finally(function()
															awaitingResponse.current = false
														end)
														:andThen(function(_, success, reason)
															if not success then
																if reason == "insufficientCurrency" then setSelectedCategory("currency") end
															end
														end)
												end,
											})

											return element, key
										end
									)
								),
							}),
						})
						else React.createElement(React.Fragment, nil, {
							Products = React.createElement(scrollingFrame, {
								ScrollBarImageColor3 = Color3.fromHex("2d3436"),
								Size = UDim2.fromScale(0.5, 1),
								renderLayout = function(setContentSize)
									return React.createElement("UIGridLayout", {
										CellPadding = UDim2.new(),
										CellSize = UDim2.new(1 / 3, 0, 0, 0),
										[React.Change.AbsoluteContentSize] = function(object)
											setContentSize(Vector2.new(0, object.AbsoluteContentSize.y))
										end,
									}, {
										Constraint = React.createElement("UIAspectRatioConstraint", {
											AspectRatio = 1,
											AspectType = Enum.AspectType.ScaleWithParentSize,
										}),
									})
								end,
							}, {
								Buttons = inline(function()
									local buttons = {}
									for index, product in getProducts(selectedCategory) do
										local isSelected = product.id == selectedProduct
										buttons[product.id] = React.createElement(productButton, {
											isSelected = isSelected,
											layoutOrder = index,
											awaitingResponse = awaitingResponse.current,
											setSelectedProduct = setSelectedProduct,
											getIsEquipped = props.getIsEquipped,
											getIsOwned = props.getIsPurchased,
											product = product,
										})
									end
									return React.createElement(React.Fragment, nil, buttons)
								end),
							}),

							Details = React.createElement("Frame", {
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(0.5, 1),
								Position = UDim2.fromScale(0.5, 0),
							}, {
								Padding = React.createElement("UIPadding", {
									PaddingLeft = UDim.new(0, 8),
								}),

								Details = React.createElement(productDetails, {
									categoryName = selectedCategory,
									productId = selectedProduct,
									getIsEquipped = props.getIsEquipped,
									getIsPurchased = props.getIsPurchased,
									setEquipped = function(product, equipped)
										awaitingResponse.current = true
										return props.setEquipped(product, equipped):finally(function()
											awaitingResponse.current = false
										end)
									end,
									purchase = function(product)
										awaitingResponse.current = true
										return props
											.purchase(product)
											:finally(function()
												awaitingResponse.current = false
											end)
											:andThen(function(_, success, reason)
												if not success then
													if reason == "insufficientCurrency" then setSelectedCategory("currency") end
												end
											end)
									end,
								}),
							}),
						}),
			}),
		}),
	})
end

return Shop
