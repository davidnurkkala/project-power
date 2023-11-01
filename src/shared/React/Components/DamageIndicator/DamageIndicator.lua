local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IndicatorIcon = require(ReplicatedStorage.Shared.React.Components.DamageIndicator.IndicatorIcon)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

export type DamageIndicatorProps = {
	damage: number,
	lifetime: number,
	target: BasePart,
	unmount: () -> (),
}

-- consts
local INDICATOR_RANDOM = Random.new(os.time())

local ACCELERATION = Vector3.new(0, -workspace.Gravity / 4, 0)
local PARTICLE_SPEED = 30

local function position(v0, x0, t)
	return 0.5 * ACCELERATION * (t ^ 2) + (v0 * t) + x0
end

local DamageIndicator: React.FC<DamageIndicatorProps> = function(props)
	-- create a portal to terrain for attachment
	local ref = React.useRef(nil)

	React.useEffect(function()
		local target = props.target
		if not target then return end

		local targetPosition = target.Position

		local theta = INDICATOR_RANDOM:NextNumber() * math.pi * 2
		local radius = INDICATOR_RANDOM:NextNumber() * 8
		local randomDirection = (Vector3.new(math.cos(theta), radius, math.sin(theta))).Unit

		local startTime = tick()
		local renderSteppedConnection = RunService.RenderStepped:Connect(function(_delta)
			local attachment = ref.current
			if not attachment then return end

			attachment.WorldPosition = position(PARTICLE_SPEED * randomDirection, targetPosition, tick() - startTime)
		end)

		return function()
			renderSteppedConnection:Disconnect()
		end
	end, {
		ref.current,
	})

	return ReactRoblox.createPortal({
		Attachment = React.createElement("Attachment", {
			ref = ref,
		}, {
			BillboardGui = React.createElement("BillboardGui", {
				Adornee = ref.current,
				AlwaysOnTop = true,
				LightInfluence = 0,
				Size = UDim2.fromOffset(32, 32),
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			}, {
				IndicatorIcon = React.createElement(IndicatorIcon, {
					damage = props.damage,
					lifetime = props.lifetime,
					unmount = props.unmount,
				}),
			}),
		}),
	}, workspace.Terrain)
end

return DamageIndicator
