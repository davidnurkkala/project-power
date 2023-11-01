local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ChangeLog = require(ReplicatedStorage.Shared.Data.ChangeLog)
local Comm = require(ReplicatedStorage.Packages.Comm)
local CurrencyController = require(ReplicatedStorage.Shared.Controllers.CurrencyController)
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local DailyChallenges = require(ReplicatedStorage.Shared.React.Components.DailyChallenges)
local Hud = require(ReplicatedStorage.Shared.React.Components.HUD.Hud)
local KillController = require(ReplicatedStorage.Shared.Controllers.KillController)
local KillFeed = require(ReplicatedStorage.Shared.React.Components.KillFeed.KillFeed)
local KillImage = require(ReplicatedStorage.Shared.React.Components.HUD.KillImage.KillImage)
local KillIndicator = require(ReplicatedStorage.Shared.React.Components.HUD.KillIndicator.KillIndicator)
local Leaderboard = require(ReplicatedStorage.Shared.React.Components.HUD.Leaderboard.Leaderboard)
local MusicController = require(ReplicatedStorage.Shared.Controllers.MusicController)
local PlatformManager = require(ReplicatedStorage.Shared.React.Components.PlatformManager)
local PlaytimeRewardsPopup = require(ReplicatedStorage.Shared.React.Components.PlaytimeRewards.PlaytimeRewardsPopup)
local Popup = require(ReplicatedStorage.Shared.React.Components.Common.Popup)
local Popups = require(ReplicatedStorage.Shared.React.Components.HUD.Popups.Popups)
local PowerGainIndicator = require(ReplicatedStorage.Shared.React.Components.PowerGainIndicator.PowerGainIndicator)
local ProductController = require(ReplicatedStorage.Shared.Controllers.ProductController)
local ProductDefinitions = require(ReplicatedStorage.Shared.Data.ProductDefinitions)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local ShopBridge = require(ReplicatedStorage.Shared.React.Components.Shop.ShopBridge)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)
local StarterPack = require(ReplicatedStorage.Shared.React.Components.StarterPack.StarterPack)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponProgress = require(ReplicatedStorage.Shared.React.Components.HUD.WeaponProgress.WeaponProgress)
local useIsInBattle = require(ReplicatedStorage.Shared.React.Hooks.useIsInBattle)

local function weaponProgressBridge(props: {
	visible: boolean,
})
	local weaponProgress, setWeaponProgress = React.useState(nil)

	React.useEffect(function()
		if not props.visible then
			setWeaponProgress(nil)
			return
		end

		local trove = Trove.new()
		trove
			:AddPromise(Promise.new(function(resolve)
				resolve(trove:Construct(Comm.ClientComm, ReplicatedStorage, true, "ProgressionService"))
			end))
			:andThen(function(comm)
				trove:Add(comm:GetProperty("WeaponProgress"):Observe(setWeaponProgress))
			end)

		return function()
			trove:Clean()
		end
	end, { props.visible })

	return (weaponProgress ~= nil)
		and React.createElement(WeaponProgress, {
			weaponDefinition = WeaponDefinitions[weaponProgress.weaponId],
			percent = weaponProgress.percent,
		})
end

local function starterPackBridge(props: {
	visible: boolean,
})
	local comm, setComm = React.useState(nil)
	local expireTimestamp, setExpireTimestamp = React.useState(nil)

	React.useEffect(function()
		local trove = Trove.new()

		trove
			:AddPromise(Promise.new(function(resolve)
				resolve(Comm.ClientComm.new(ReplicatedStorage, true, "StarterPackService"))
			end))
			:andThen(function(newComm)
				setComm(newComm)
				trove:Add(newComm:GetProperty("ExpireTimestamp"):Observe(setExpireTimestamp))
			end)

		return function()
			trove:Clean()
		end
	end, {})

	if (comm == nil) or (expireTimestamp == nil) then return end

	return React.createElement(StarterPack, {
		visible = props.visible,
		expireTimestamp = expireTimestamp,
		buy = function()
			return comm:GetFunction("Buy")()
		end,
	})
end

local function playtimeRewardsBridge()
	local data, setData = React.useState(nil)

	React.useEffect(function()
		local trove = Trove.new()
		trove
			:AddPromise(Promise.new(function(resolve)
				resolve(trove:Construct(Comm.ClientComm, ReplicatedStorage, true, "PlaytimeRewardsService"))
			end))
			:andThen(function(comm)
				trove:Connect(comm:GetSignal("Notified"), setData)
			end)
	end, {})

	return (data ~= nil)
		and React.createElement(PlaytimeRewardsPopup, {
			count = data.count,
			timestamp = data.timestamp,
			finish = function()
				setData(nil)
			end,
		})
end

local function dailyChallengePopup()
	local popup, setPopup = React.useState(nil)
	local rotBinding, setRotBinding = React.useBinding(0)

	React.useEffect(function()
		local trove = Trove.new()

		trove
			:AddPromise(Promise.try(function()
				return trove:Add(Comm.ClientComm.new(ReplicatedStorage, true, "ChallengeService"))
			end))
			:andThen(function(comm)
				trove:Connect(comm:GetSignal("Completed"), setPopup)
			end)

		return function()
			trove:Clean()
		end
	end, {})

	React.useEffect(function()
		if not popup then return end

		local connection = RunService.Heartbeat:Connect(function()
			local clock = (tick() % 3) / 3
			setRotBinding(clock * 360)
		end)

		return function()
			connection:Disconnect()
		end
	end, { popup })

	return (popup ~= nil)
		and React.createElement(Popup, {
			anchorPoint = Vector2.new(0.5, 0),
			size = UDim2.fromOffset(0, 30),
			position = UDim2.new(0.5, 0, 0, -50),
			targetPosition = UDim2.new(0.5, 0, 0, 60),
			tweenInInfo = TweenInfo.new(1, Enum.EasingStyle.Elastic),
			tweenOutInfo = TweenInfo.new(0.25),
			lifeTime = 5,
			onTweenOut = function()
				setPopup(nil)
			end,
		}, {
			Layout = React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 5),
			}),

			Text = React.createElement("TextLabel", {
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				TextSize = 25,
				AutomaticSize = Enum.AutomaticSize.X,
				Text = `Daily challenge complete! You got {popup.Amount}`,
			}, {
				Stroke = React.createElement("UIStroke", {
					Thickness = 2,
					Color = Color3.new(0, 0, 0),
				}),
			}),

			IconFrame = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				LayoutOrder = 2,
			}, {
				React.createElement("ImageLabel", {
					ZIndex = -1024,
					BackgroundTransparency = 1,
					ImageColor3 = Color3.new(0.556863, 0.333333, 1.000000),
					Image = "rbxassetid://14339274308",
					ImageTransparency = 0.5,
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(2.5, 2.5),
					Rotation = rotBinding,
				}),

				Icon = React.createElement("ImageLabel", {
					Size = UDim2.fromScale(1, 1.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = CurrencyDefinitions[popup.Currency].iconId,
					ScaleType = Enum.ScaleType.Fit,
				}),
			}),
		})
end

local function muteButton()
	local muted, setMuted = React.useState(false)

	React.useEffect(function()
		local function update()
			setMuted(MusicController.muted)
		end
		local connection = MusicController.changed:Connect(update)

		return function()
			connection:Disconnect()
		end
	end, {})

	return React.createElement("ImageButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromOffset(200, 4),
		Image = "rbxassetid://3687981512",
		[React.Event.Activated] = function()
			MusicController:toggleMute()
		end,
	}, {
		Cross = React.createElement("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 0, 0),
			Rotation = 45,
			Visible = muted,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
		}),
	})
end

local function changeLog()
	local lines = {}
	local function process(list, depth)
		depth = depth or 0
		for _, entry in list do
			if typeof(entry) == "table" then
				process(entry, depth + 1)
			else
				table.insert(lines, {
					content = entry,
					depth = depth,
				})
			end
		end
	end
	process(ChangeLog)

	return React.createElement("SurfaceGui", {
		Adornee = workspace.Lobby.UpdateLog,
		ResetOnSpawn = false,
		PixelsPerStud = 64,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
	}, {
		Title = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 0.1),
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.Bangers,
			Text = "Update Log",
			BackgroundTransparency = 1,
		}, {
			Stroke = React.createElement("UIStroke", {
				Thickness = 3,
				Color = Color3.new(0, 0, 0),
			}),
		}),

		Background = React.createElement("ImageLabel", {
			Size = UDim2.fromScale(1, 0.9),
			Position = UDim2.fromScale(0, 0.1),
			BackgroundTransparency = 1,
			Image = "rbxassetid://14663594778",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(32, 32, 224, 224),
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 32),
				PaddingBottom = UDim.new(0, 32),
				PaddingRight = UDim.new(0, 32),
				PaddingLeft = UDim.new(0, 32),
			}),

			Content = React.createElement("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 20,
				Size = UDim2.fromScale(1, 1),
				VerticalScrollBarInset = Enum.ScrollBarInset.Always,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 20),
				}),

				Lines = React.createElement(
					React.Fragment,
					nil,
					Sift.Array.map(lines, function(line, index)
						return React.createElement("TextLabel", {
							BackgroundTransparency = 1,
							TextSize = 45,
							Text = line.content,
							Font = Enum.Font.Gotham,
							LineHeight = 1.1,
							TextColor3 = Color3.new(1, 1, 1),
							Size = UDim2.fromScale(1 - (0.025 * line.depth), 0),
							LayoutOrder = index,
							AutomaticSize = Enum.AutomaticSize.Y,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextWrapped = true,
						})
					end)
				),
			}),
		}),
	})
end

local App: React.FC<{}> = function()
	local isInBattle = useIsInBattle()
	local isTauntEquipped, setIsTauntEquipped = React.useState(false)

	local powerAdded = React.useRef(Signal.new()).current

	React.useEffect(function()
		local trove = Trove.new()

		trove:AddPromise(Promise.new(function(resolve)
			while not CurrencyController:getCurrency("power") do
				CurrencyController.currencyUpdated:Wait()
			end
			resolve(CurrencyController:getCurrency("power"))
		end):andThen(function(lastPower)
			trove:Connect(CurrencyController.currencyUpdated, function(currency, amount)
				if currency ~= "power" then return end

				local amountAdded = amount - lastPower
				lastPower = amount
				if amountAdded <= 0 then return end

				powerAdded:Fire(amountAdded)
			end)
		end))

		return function()
			trove:Clean()
		end
	end, {})

	local killAdded = React.useRef(Signal.new()).current

	React.useEffect(function()
		local connection = KillController.playerKilled:Connect(function(killer, victim)
			if killer ~= Players.LocalPlayer then return end
			killAdded:Fire(victim.Name)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	local killImage, setKillImage = React.useState(nil)

	React.useEffect(function()
		local trove = Trove.new()
		trove:AddPromise(Promise.new(function()
			local comm = trove:Construct(Comm.ClientComm, ReplicatedStorage, true, "DamageService")
			local signal = trove:Add(comm:GetSignal("KillImageRequested"))
			trove:Connect(signal, function(productId)
				setKillImage(if productId == "DEFAULT" then "rbxassetid://14968149876" else ProductDefinitions.killImage.products[productId].image)
			end)
		end))
		return function()
			trove:Clean()
		end
	end, {})

	React.useEffect(function()
		local function onChanged()
			ProductController:isKindEquipped("taunt"):andThen(setIsTauntEquipped)
		end
		local connection = ProductController.productData.Changed:Connect(onChanged)
		onChanged()
		return function()
			connection:Disconnect()
		end
	end)

	React.useEffect(function()
		local playerModuleSource = Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 5)
		if not playerModuleSource then return end
		local playerModule = require(playerModuleSource) :: any
		local controller = playerModule:GetControls().touchJumpController
		if not controller then return end
		controller:Enable(not isInBattle)
	end, { isInBattle })

	return React.createElement(React.Fragment, nil, {
		ChangeLog = React.createElement(changeLog),
		ScreenGui = React.createElement("ScreenGui", {
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
		}, {
			Platform = React.createElement(PlatformManager, nil, {
				MuteButton = React.createElement(muteButton),
				Popups = React.createElement(Popups),
				DailyChallengePopup = React.createElement(dailyChallengePopup),
				PlaytimeRewardsPopup = React.createElement(playtimeRewardsBridge),
				Leaderboard = isInBattle and React.createElement(Leaderboard),
				Hud = React.createElement(Hud, {
					player = Players.LocalPlayer,
					isTauntEquipped = isTauntEquipped,
					isInBattle = isInBattle,
				}),
				PowerGainIndicator = isInBattle and React.createElement(PowerGainIndicator, {
					PowerAdded = powerAdded,
				}),
				KillIndicator = isInBattle and React.createElement(KillIndicator, {
					KillAdded = killAdded,
				}),
				Shop = React.createElement(ShopBridge, {
					visible = not isInBattle,
				}),
				KillImage = React.createElement(KillImage, {
					image = killImage,
					finish = function()
						setKillImage(nil)
					end,
				}),
				KillFeed = isInBattle and React.createElement("Frame", {
					Size = UDim2.fromScale(0.3, 0.2),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Position = UDim2.fromScale(0, 0.4),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,
				}, {
					React.createElement(KillFeed, {
						killSignal = KillController.playerKilled,
					}),
				}),
				BottomLeft = React.createElement("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 30, 1, -30),
					Size = UDim2.fromScale(0.3, 1),
				}, {
					Layout = React.createElement("UIListLayout", {
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 30),
					}),

					DailyChallenges = React.createElement(DailyChallenges),

					WeaponProgress = React.createElement(weaponProgressBridge, {
						visible = true,
					}),
				}),
				StarterPack = React.createElement(starterPackBridge, {
					visible = not isInBattle,
				}),
			}),
		}),
	})
end

return App
