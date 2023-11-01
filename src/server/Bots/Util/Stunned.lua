local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BotDash = require(ServerScriptService.Server.Bots.Util.BotDash)
local StunHelper = require(ReplicatedStorage.Shared.Util.StunHelper)

return function(args: {
	root: BasePart,
	animator: any,
	model: Model,
})
	local root = args.root
	local animator = args.animator
	local model = args.model

	return {
		onEntered = function(state)
			state.stage = "waiting"
			state.startPosition = model:GetPivot().Position
		end,
		onUpdated = function(state)
			if state.stage == "waiting" then
				if not StunHelper.isStunnedOrPushed(model) then
					local here = model:GetPivot().Position
					local there = state.startPosition
					local delta = (there - here) * Vector3.new(1, 0, 1)

					if delta.Magnitude < 16 then return "idling" end

					local direction = delta.Unit

					BotDash({
						animator = animator,
						root = root,
						direction = direction,
					}):andThen(function()
						state.stage = "finished"
					end)

					state.stage = "dashing"
				end
				return
			elseif state.stage == "dashing" then
				return
			elseif state.stage == "finished" then
				return "idling"
			end

			return
		end,
	}
end
