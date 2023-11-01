local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local React = require(ReplicatedStorage.Packages.React)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

return function(props: {
	def: WeaponDefinitions.WeaponDefinition,
	burstDisabled: boolean?,
})
	local frameRef = React.useRef(nil)
	local fadeBinding, fadeMotor = useMotor(1)
	local rotBinding, setRotBinding = React.useBinding(0)

	React.useEffect(function()
		local frame: ViewportFrame = frameRef.current
		if not frame then return end

		local trove = Trove.new()

		local model: Model = trove:Clone(props.def.model)
		model:PivotTo(CFrame.Angles(0, math.pi, math.pi / 4))
		model.Parent = frame

		local root = Instance.new("Part")
		root.Size = Vector3.new()
		root.Transparency = 1
		root.CFrame = CFrame.new()
		root.Parent = model
		model.PrimaryPart = root

		local _, size = model:GetBoundingBox()
		local width = math.max(size.X, size.Y, size.Z)

		local camera: Camera = trove:Construct(Instance, "Camera")
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 15

		local zoom = width / (2 * math.tan(math.rad(camera.FieldOfView) / 2)) + 2
		camera.CFrame = CFrame.new(0, 0, zoom)

		camera.Parent = frame
		frame.CurrentCamera = camera

		fadeMotor:setGoal(Flipper.Spring.new(0))
		trove:Add(function()
			fadeMotor:setGoal(Flipper.Instant.new(1))
		end)

		trove:Connect(RunService.Heartbeat, function()
			local clock = (tick() % 4) / 4
			setRotBinding(360 * clock)

			camera.CFrame = CFrame.Angles(0, math.pi * 2 * clock, 0) * CFrame.new(0, 0, zoom)
		end)

		return function()
			trove:Clean()
		end
	end, { frameRef.current, props.def })

	return React.createElement(React.Fragment, nil, {
		Preview = React.createElement("ViewportFrame", {
			ref = frameRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Ambient = Color3.new(1, 1, 1),
			LightColor = Color3.new(1, 1, 1),
			LightDirection = Vector3.new(0, 0, -1),
			ImageTransparency = fadeBinding,
		}),

		Burst = (not props.burstDisabled) and React.createElement("ImageLabel", {
			ZIndex = -1024,
			BackgroundTransparency = 1,
			Image = "rbxassetid://14339274308",
			ImageTransparency = 0.5,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = fadeBinding:map(function(value)
				return UDim2.fromScale(0, 0):Lerp(UDim2.fromScale(1.5, 1.5), 1 - value)
			end),
			Rotation = rotBinding,
		}),
	})
end
