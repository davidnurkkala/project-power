local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Sift = require(ReplicatedStorage.Packages.Sift)

local FOLDER
do
	FOLDER = Instance.new("Folder")
	FOLDER.Name = "Leaderboards"
	FOLDER.Parent = workspace
end

local RANGE = 12
local RANGE_SQ = RANGE ^ 2

local function getRangeSq(point)
	local char = Players.LocalPlayer.Character
	if not char then return math.huge end
	if not char.PrimaryPart then return math.huge end
	local delta = point - char.PrimaryPart.Position
	return delta.X ^ 2 + delta.Z ^ 2
end

local function label(props)
	local defaultProps = {
		TextStrokeTransparency = 0,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.Gotham,
		TextSize = 18,
		RichText = true,
		BackgroundTransparency = 1,
	}
	return React.createElement("TextLabel", Sift.Dictionary.merge(defaultProps, props))
end

local function component(props: {
	cframe: CFrame,
	remoteProperty: any,
	icon: string,
	size: Vector3,
	alwaysVisible: boolean,
})
	local data, setData = React.useState(nil)
	local proximate, setProximate = React.useState(false)

	local shouldRender = (data ~= nil) and proximate

	React.useEffect(function()
		local connection = props.remoteProperty:Observe(setData)

		return function()
			connection:Disconnect()
		end
	end, { props.remoteProperty })

	React.useEffect(function()
		if props.alwaysVisible then
			setProximate(true)
			return
		end

		local thread = task.spawn(function()
			while true do
				task.wait(0.1)

				local rangeSq = getRangeSq(props.cframe.Position)
				if proximate and (rangeSq > RANGE_SQ) then
					setProximate(false)
				elseif (not proximate) and (rangeSq <= RANGE_SQ) then
					setProximate(true)
				end
			end
		end)

		return function()
			task.cancel(thread)
		end
	end, { props.cframe, proximate, props.alwaysVisible })

	React.useEffect(function()
		if not data then return end
		if not shouldRender then return end

		local topEntry = data[1]
		if not topEntry then return end

		local model = ReplicatedStorage.RojoAssets.Models.LeaderboardRig:Clone()
		model:SetPrimaryPartCFrame(props.cframe * CFrame.new(0, props.size.Y / 2 + 4, 0))
		model.Parent = ReplicatedStorage

		local promise = Promise.new(function(resolve)
			resolve(Players:GetHumanoidDescriptionFromUserId(topEntry.key), Players:GetNameFromUserIdAsync(topEntry.key))
		end)
			:andThen(function(description, name)
				model.Name = name
				model.Humanoid:ApplyDescription(description)
			end)
			:andThen(function()
				model.Parent = FOLDER
			end)
			:andThen(function()
				local taunt = topEntry.taunt
				if not taunt then return end
				local animation = Animations[`Taunt{taunt}`]
				if not animation then return end
				local track = model.Humanoid:LoadAnimation(animation)
				track:Play()
			end)
			:catch(function() end)

		return function()
			model:Destroy()
			promise:cancel()
		end
	end, { shouldRender, data })

	return shouldRender
		and React.createElement("Model", nil, {
			Part = React.createElement("Part", {
				CFrame = props.cframe,
				Size = props.size,
				Anchored = true,
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
				Transparency = 1,
			}, {
				Gui = React.createElement("SurfaceGui", {
					LightInfluence = 0,
					Brightness = 1,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					PixelsPerStud = 45,
					SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
					Face = Enum.NormalId.Front,
				}, {
					Frame = React.createElement("Frame", {
						Size = UDim2.fromScale(1, 1),
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.new(0, 0, 0),
						BackgroundTransparency = 0.5,
					}, {
						Layout = React.createElement("UIListLayout", {
							Padding = UDim.new(),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),

						Title = React.createElement(label, {
							Font = Enum.Font.GothamBold,
							Text = "LEADERBOARD",
							TextScaled = true,
							TextWrapped = false,
							LayoutOrder = 1,
							Size = UDim2.fromScale(1, 1 / 11),
						}),

						NoEntries = (#data == 0) and React.createElement(label, {
							LayoutOrder = 2,
							Font = Enum.Font.GothamBold,
							Text = "No entries yet!",
							TextScaled = true,
							TextWrapped = false,
							Size = UDim2.fromScale(1, 1 / 11),
							Position = UDim2.fromScale(0, 0.5),
						}),

						Entries = (#data > 0) and React.createElement(
							React.Fragment,
							nil,
							Sift.Array.map(data, function(entry, index)
								return React.createElement("Frame", {
									BackgroundTransparency = 1,
									LayoutOrder = index + 1,
									Size = UDim2.fromScale(1, 1 / 11),
								}, {
									Padding = React.createElement("UIPadding", {
										PaddingLeft = UDim.new(0.1, 0),
										PaddingRight = UDim.new(0.1, 0),
									}),

									Name = React.createElement(label, {
										Size = UDim2.fromScale(0.65, 0.7),
										Position = UDim2.fromScale(0, 0.15),
										TextXAlignment = Enum.TextXAlignment.Left,
										Text = entry.name,
										TextScaled = true,
										TextWrapped = false,
									}),

									Score = React.createElement(label, {
										Size = UDim2.fromScale(0.2, 0.7),
										Position = UDim2.fromScale(0.7, 0.15),
										TextXAlignment = Enum.TextXAlignment.Right,
										Text = entry.value,
										TextScaled = true,
										TextWrapped = false,
									}),

									Icon = React.createElement("ImageLabel", {
										BackgroundTransparency = 1,
										ScaleType = Enum.ScaleType.Fit,
										Size = UDim2.fromScale(0.1, 1),
										Position = UDim2.fromScale(0.9, 0),
										Image = props.icon,
									}),
								})
							end)
						),
					}),
				}),
			}),
		})
end

local GenericLeaderboard = {}
GenericLeaderboard.__index = GenericLeaderboard

function GenericLeaderboard.new(args: {
	cframe: CFrame,
	remoteProperty: any,
	icon: string,
	alwaysVisible: boolean?,
	size: Vector3?,
})
	local cframe = args.cframe
	local remoteProperty = args.remoteProperty
	local icon = args.icon
	local alwaysVisible = if args.alwaysVisible == nil then false else args.alwaysVisible
	local size = args.size or Vector3.new(8, 10, 0)

	local self = setmetatable({}, GenericLeaderboard)

	self._root = ReactRoblox.createRoot(FOLDER)
	self._root:render(React.createElement(component, {
		cframe = cframe,
		remoteProperty = remoteProperty,
		icon = icon,
		size = size,
		alwaysVisible = alwaysVisible,
	}))

	return self
end

function GenericLeaderboard:destroy()
	self._root:unmount()
end

return GenericLeaderboard
