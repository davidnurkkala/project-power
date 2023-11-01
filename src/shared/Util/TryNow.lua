local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

return function(func, retValOnFail)
	return Promise.try(func)
		:catch(function()
			return retValOnFail
		end)
		:now()
		:expect()
end
