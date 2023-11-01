local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local BattleService = require(ServerScriptService.Server.Services.BattleService)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

local PracticeService = {}
PracticeService.className = "PracticeService"
PracticeService.priority = 0

local function getCFrameFromSlotNumber(number)
	local step = 80
	local steps = number - math.ceil(Players.MaxPlayers / 2)

	return CFrame.new(steps * step, 900, -500)
end

function PracticeService:init()
	self._slots = {}
	self._promisesByPlayer = {}
end

function PracticeService:start() end

function PracticeService:_getFirstAvailableSlot()
	local number = 1
	while self._slots[tostring(number)] do
		number += 1
	end
	return number
end

function PracticeService:_reserveSlot(slotNumber)
	self._slots[tostring(slotNumber)] = true
end

function PracticeService:_freeSlot(slotNumber)
	self._slots[tostring(slotNumber)] = nil
end

function PracticeService:addPlayer(player: Player)
	if self._promisesByPlayer[player] then return end

	local trove = Trove.new()
	trove:Add(function()
		self._promisesByPlayer[player] = nil
	end)

	local promise = Promise.try(function()
		return player.Character, (player.Character :: any).Humanoid
	end)
		:andThen(function(char, human)
			local slotNumber = self:_getFirstAvailableSlot()
			self:_reserveSlot(slotNumber)
			trove:Add(function()
				self:_freeSlot(slotNumber)
			end)

			local model = trove:Clone(ReplicatedStorage.Assets.Models.PracticeZone)
			model:PivotTo(getCFrameFromSlotNumber(slotNumber))
			model.Parent = workspace

			BattleService:setUpForBattle(char, human, "InPractice")

			char:PivotTo(model.SpawnPoint:GetPivot() + Vector3.new(0, 6, 0))

			WeaponService:equipWeapon(player)

			local weaponId = WeaponService:getSelectedWeapon(player)
			local weaponDef = WeaponDefinitions[weaponId]
			local gui = model.Description.Gui.Background
			gui.Parent.Title.Text = weaponDef.name
			gui.Description.Text = weaponDef.info.description
			gui.Attack.Text = `<b>Attack:</b> {weaponDef.info.attack}`
			gui.Special.Text = `<b>Special:</b> {weaponDef.info.special}`
			gui.Other.Text = weaponDef.info.other

			local dummy = trove:Clone(ServerStorage.TargetDummy)

			local dummyHuman = dummy.Humanoid
			dummyHuman.MaxHealth = 1000000
			dummyHuman.Health = dummy.Humanoid.MaxHealth

			dummy.Name = "Target Dummy"
			dummy:PivotTo(model:GetPivot())
			dummy.Parent = model

			trove:Add(task.spawn(function()
				local timeAway = 0

				local dt = 0
				while true do
					dummyHuman.Health = dummyHuman.MaxHealth

					local distance = (dummy:GetPivot().Position - model:GetPivot().Position).Magnitude
					if distance > 6 then
						timeAway += dt
						if timeAway > 3 then
							dummy:PivotTo(model:GetPivot())
							timeAway = 0
						end
					else
						timeAway = 0
					end

					dt = task.wait()
				end
			end))

			return Promise.fromEvent(char.AncestryChanged, function()
				return not char:IsDescendantOf(game)
			end)
		end)
		:finally(function()
			trove:Clean()
		end)

	self._promisesByPlayer[player] = promise
	return promise
end

return Loader:registerSingleton(PracticeService)
