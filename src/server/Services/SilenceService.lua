local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InBattleHelper = require(ReplicatedStorage.Shared.Util.InBattleHelper)
local Loader = require(ReplicatedStorage.Shared.Loader)
local SilenceHelper = require(ReplicatedStorage.Shared.Util.SilenceHelper)

local SilenceService = {}
SilenceService.className = "SilenceService"
SilenceService.priority = 0

function SilenceService:init() end

function SilenceService:start() end

function SilenceService:silenceTarget(target: SilenceHelper.SilenceTarget, duration: number)
	if SilenceHelper.isSilenced(target) then return end

	local model = SilenceHelper.parseTarget(target)
	if not model then return end

	if not InBattleHelper.isModelInBattle(model) then return end

	model:SetAttribute(SilenceHelper.attributeName, true)
	task.delay(duration, function()
		model:SetAttribute(SilenceHelper.attributeName, nil)
	end)
end

return Loader:registerSingleton(SilenceService)
