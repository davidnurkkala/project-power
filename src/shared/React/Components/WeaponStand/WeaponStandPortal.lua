local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local WeaponStandDisplay = require(ReplicatedStorage.Shared.React.Components.WeaponStand.WeaponStandDisplay)

export type WeaponStandPortalProps = {
	target: Instance,
	weaponDefinition: WeaponDefinitions.WeaponDefinition,
	owned: boolean,
	ownershipChanged: any,
}

local WeaponStandPortal: React.FC<WeaponStandPortalProps> = function(props)
	return ReactRoblox.createPortal({
		SurfaceGui = React.createElement("SurfaceGui", {
			Adornee = props.target,
			Enabled = true,
			LightInfluence = 0,
			Face = Enum.NormalId.Front,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			WeaponStandDisplay = React.createElement(WeaponStandDisplay, {
				weaponDefinition = props.weaponDefinition,
				owned = false,
				ownershipChanged = props.ownershipChanged,
			}),
		}),
	}, props.target)
end

return WeaponStandPortal
