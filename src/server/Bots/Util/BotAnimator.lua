local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local BotAnimator = {}
BotAnimator.__index = BotAnimator

function BotAnimator.new(human: Humanoid)
	local self = setmetatable({
		_human = human,
		_tracks = {},
	}, BotAnimator)

	return self
end

function BotAnimator:play(name, ...)
	if not self._tracks[name] then self._tracks[name] = self._human:LoadAnimation(Animations[name]) end
	self._tracks[name]:Play(...)
end

function BotAnimator:stop(name, ...)
	if not self._tracks[name] then return end
	self._tracks[name]:Stop(...)
end

function BotAnimator:stopHard(...)
	for _, name in { ... } do
		local track = self._tracks[name]
		if not track then continue end
		track:Stop(0)
		track:AdjustWeight(0)
	end
end

function BotAnimator:destroy() end

return BotAnimator
