local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local PPFrame = require(ReplicatedStorage.Shared.React.Components.Common.PPUI.PPFrame.PPFrame)
local PPHudButton = require(ReplicatedStorage.Shared.React.Components.Common.PPUI.PPHudButton.PPHudButton)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)
local useViewportSize = require(ReplicatedStorage.Shared.React.Hooks.useViewportSize)

export type ExtrasProps = {
	visible: boolean,
	exit: () -> (),
	notify: () -> (),

	-- quick session api
	awarded: Signal.Signal<any>,
	awardBecameAvailable: Signal.Signal<any>,
	observeInfo: (callback: (info: any) -> ()) -> (),
	promiseClaim: (index: number) -> any,
}

type RewardInfo = {
	timestamp: number,
	rewards: { { [string]: any } },
	available: boolean,
}

local MIN_SCALE = 0.5
local BASE_SCALE = 900

local function formatTimer(t)
	if t < 0 then return "00:00" end

	local m = math.floor(t / 60)
	local s = math.floor(t % 60 + 0.5)

	local stringM = m < 10 and "0" .. tostring(m) or tostring(m)
	local stringS = s < 10 and "0" .. tostring(s) or tostring(s)

	return stringM .. ":" .. stringS
end

local function rewards(props) end

local Extras: React.FC<ExtrasProps> = function(props)
	local viewportSize = useViewportSize()

	local isClaiming, setIsClaiming = React.useState(0)
	local rewardInfo, setRewardInfo = React.useState({})
	local timeBinding, updateTimeBinding = React.useBinding(os.time())

	React.useEffect(function()
		local observeInfoConnection = props.observeInfo(function(info)
			setRewardInfo(info)
		end)

		local awardBecameAvailableConnection = props.awardBecameAvailable:Connect(function(index)
			if props.visible then return end
			props.notify()
		end)

		local heartbeatConnection
		if props.visible then
			heartbeatConnection = RunService.Heartbeat:Connect(function()
				local t = os.time()
				if t == timeBinding:getValue() then return end
				updateTimeBinding(t)
			end)
		end

		return function()
			observeInfoConnection:Disconnect()
			awardBecameAvailableConnection:Disconnect()
			if heartbeatConnection then heartbeatConnection:Disconnect() end
		end
	end, { props.visible, rewardInfo })

	local rewardContents = {
		GridLayout = React.createElement("UIGridLayout", {
			CellPadding = UDim2.new(0, 8, 0, 12),
			CellSize = UDim2.new(0, 156, 0, 88),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		UIPadding = React.createElement("UIPadding", {
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
		}),
		UICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
	}

	for index, reward: RewardInfo in rewardInfo do
		local claiming = isClaiming == index
		local claimable = reward.timestamp <= os.time() and reward.available
		local claimed = not reward.available and reward.timestamp <= os.time()

		local rewards = {
			ListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
			UICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}

		for index, rewardData in reward.rewards do
			local rewardType = rewardData.type
			local currency = CurrencyDefinitions[rewardType]

			if rewardType == "booster" then
				rewards[rewardType] = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, 0, 1, 0),
				}, {
					BoosterText = React.createElement("TextLabel", {
						Size = UDim2.fromScale(1, 0.6),
						Text = `x2 Boost`,
						TextSize = 16,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						Font = Enum.Font.GothamBlack,
						TextColor3 = Color3.new(1.000000, 0.368627, 0.000000),
					}, {
						Stroke = React.createElement("UIStroke", {
							Color = Color3.new(0, 0, 0),
							Thickness = 1.75,
						}),
					}),
					BoosterDuration = React.createElement("TextLabel", {
						Size = UDim2.fromScale(1, 0.4),
						Position = UDim2.fromScale(0, 0.6),
						Text = rewardData.minutes .. "m",
						TextSize = 14,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.new(1.000000, 0.7, 0.7),
					}, {
						Stroke = React.createElement("UIStroke", {
							Color = Color3.new(0, 0, 0),
							Thickness = 1.75,
						}),
					}),
				})
			elseif currency then
				rewards[rewardType] = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, 0, 1, 0),
				}, {
					ListLayout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 4),
					}),
					Icon = React.createElement("ImageLabel", {
						BackgroundTransparency = 1,
						Image = currency.iconId,
						ImageTransparency = timeBinding:map(function(a0: number)
							return (claimed and 0.65 or 0)
						end),
						LayoutOrder = 1,
						Size = UDim2.new(0, 32, 0, 32),
					}),
					Amt = React.createElement("TextLabel", {
						LayoutOrder = 2,
						Size = UDim2.fromScale(0.5, 1),
						Text = rewardData.amount,
						TextSize = 18,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						Font = Enum.Font.GothamBlack,
						TextColor3 = currency.textColor or Color3.new(1, 1, 1),
						TextTransparency = timeBinding:map(function(a0: number)
							return (claimed and 0.65 or 0)
						end),
					}, {
						Stroke = React.createElement("UIStroke", {
							Color = Color3.new(0, 0, 0),
							Thickness = timeBinding:map(function(a0: number)
								return (claimed and 0 or 1.75)
							end),
						}),
					}),
				})
			end
		end

		rewardContents[tostring(index)] = React.createElement(PPHudButton, {
			active = not claimed and claimable and not claiming,
			onActivated = function()
				if claiming then return end
				setIsClaiming(index)
				props.promiseClaim(index):andThen(function(result)
					setIsClaiming(0)
				end)
			end,
			layoutOrder = index,
		}, {
			Action = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBlack,
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(1, 0, 0, 32),
				Text = timeBinding:map(function(time)
					if claiming then return "Claiming..." end
					if claimable then return "Claim" end
					if claimed then return "Claimed" end
					return formatTimer(reward.timestamp - time)
				end),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = timeBinding:map(function(time)
					if claimable then return 0 end
					if claimed then return 0.65 end
					return 0
				end),
				TextSize = 18,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
			Rewards = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = timeBinding:map(function(a0: number)
					return claimable and Color3.new(0, 0.65, 0) or Color3.new(1, 1, 1)
				end),
				BackgroundTransparency = timeBinding:map(function(a0: number)
					return claimable and 0.25 or (claimed and 0.85 or 0.35)
				end),
				Position = UDim2.new(0.5, 0, 0, 16),
				Size = UDim2.new(1, -48, 1, -54),
			}, rewards),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Visible = props.visible,
	}, {
		UIScale = React.createElement("UIScale", {
			Scale = math.clamp((viewportSize.Y / BASE_SCALE) ^ 2, MIN_SCALE, 1),
		}),

		ExtrasFrame = React.createElement(PPFrame, {
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.new(0.5, 0, 0.5, 0),
			size = UDim2.new(0, 720, 0, 440),
			headerText = "Playtime Rewards!",
			onClosed = props.exit,
		}, {
			Description = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBlack,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 64),
				Text = "Earn rewards for staying in game!",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 24,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 32),
					PaddingTop = UDim.new(0, 32),
				}),
			}),
			Rewards = React.createElement("Frame", {
				BackgroundColor3 = Color3.new(0.75, 0.75, 0.75),
				BackgroundTransparency = 0.2,
				AnchorPoint = Vector2.new(0.5, 1),
				Size = UDim2.new(1, -32, 1, -96),
				Position = UDim2.new(0.5, 0, 1, -16),
			}, rewardContents),
		}),
	})
end

return Extras
