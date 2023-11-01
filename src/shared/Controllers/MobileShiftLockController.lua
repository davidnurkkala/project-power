local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoRotateHelper = require(ReplicatedStorage.Shared.Util.AutoRotateHelper)
local ForcedRotationHelper = require(ReplicatedStorage.Shared.Util.ForcedRotationHelper)
local InBattleHelper = require(ReplicatedStorage.Shared.Util.InBattleHelper)
local Loader = require(ReplicatedStorage.Shared.Loader)
local PlatformHelper = require(ReplicatedStorage.Shared.Util.PlatformHelper)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local MobileShiftLockController = {}
MobileShiftLockController.className = "MobileShiftLockController"
MobileShiftLockController.priority = 0

function MobileShiftLockController:init() end

function MobileShiftLockController:start()
	local trove = Trove.new()

	local function onCharacterAdded(char: Model)
		trove:Clean()

		local function onInBattleChanged()
			if not PlatformHelper.isMobile() then
				trove:Clean()
				return
			end

			local root = WeaponUtil.getRoot()
			local human = WeaponUtil.getHuman()
			if not (root and human) then
				trove:Clean()
				return
			end
			if not InBattleHelper.isPlayerInBattle(Players.LocalPlayer) then
				trove:Clean()
				return
			end

			trove:Connect(human.Died, function()
				trove:Clean()
			end)

			trove:BindToRenderStep("MobileShiftLock", Enum.RenderPriority.Camera.Value + 1, function()
				if human:GetState() == Enum.HumanoidStateType.FallingDown then return end
				if ForcedRotationHelper.getIsActive() then return end
				if AutoRotateHelper.isDisabled(human) then return end

				local direction = workspace.CurrentCamera.CFrame.LookVector
				local y = Vector3.yAxis
				local x = direction:Cross(y).Unit
				local z = x:Cross(y).Unit
				local position = root.Position
				root.CFrame = CFrame.fromMatrix(position, x, y, z)
			end)
		end

		char:GetAttributeChangedSignal("InBattle"):Connect(onInBattleChanged)
		char:GetAttributeChangedSignal("InPractice"):Connect(onInBattleChanged)
		onInBattleChanged()
	end

	Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	if Players.LocalPlayer.Character then onCharacterAdded(Players.LocalPlayer.Character) end
end

return Loader:registerSingleton(MobileShiftLockController)
