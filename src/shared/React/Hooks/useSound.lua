local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local React = require(ReplicatedStorage.Packages.React)

export type SoundParameters = {
	soundId: string,
	volume: number?,
	playbackSpeed: number?,
	parent: any?, -- React.Ref
}

local function createSound(soundParameters: SoundParameters)
	local sound = Instance.new("Sound")
	sound.SoundId = soundParameters.soundId
	sound.Volume = soundParameters.volume or 1
	sound.PlaybackSpeed = soundParameters.playbackSpeed or 1
	sound.Parent = if soundParameters.parent then soundParameters.parent.current else SoundService

	return sound
end

return function(initSoundParameters: SoundParameters)
	local soundRef = React.useRef(createSound(initSoundParameters))

	React.useEffect(function()
		return function()
			soundRef.current:Destroy()
		end
	end, {})

	return soundRef.current
end
