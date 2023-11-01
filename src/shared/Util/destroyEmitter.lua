local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

return function(emitter: ParticleEmitter)
	emitter.Enabled = false
	return Promise.delay(emitter.Lifetime.Max):andThenCall(emitter.Destroy, emitter)
end
