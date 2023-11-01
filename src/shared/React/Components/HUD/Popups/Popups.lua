local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProgressionController = require(ReplicatedStorage.Shared.Controllers.ProgressionController)
local React = require(ReplicatedStorage.Packages.React)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponUnlockedPopup = require(ReplicatedStorage.Shared.React.Components.HUD.Popups.WeaponUnlockedPopup)

export type PopupsProps = nil

local Popups: React.FC<PopupsProps> = function()
	local weaponPopupData: { weaponDef: WeaponDefinitions.WeaponDefinition }?, setWeaponPopupData = React.useState(nil)

	React.useEffect(function()
		local weaponUnlockedConnection = ProgressionController.weaponUnlocked:Connect(function(weaponDef)
			-- should probably queue these in case you unlock a weapon while the notification is active
			setWeaponPopupData({
				weaponDef = weaponDef,
			})
		end)

		return function()
			weaponUnlockedConnection:Disconnect()
		end
	end, {})

	return React.createElement(React.Fragment, nil, {
		WeaponUnlockedPopup = weaponPopupData and React.createElement(WeaponUnlockedPopup, {
			weaponDef = weaponPopupData.weaponDef,
			onTweenOut = function()
				-- todo check to see if this is the active weapon Popup (but it should be cancelled before it happens anyway)
				setWeaponPopupData(nil)
			end,
		}),
	})
end

return Popups
