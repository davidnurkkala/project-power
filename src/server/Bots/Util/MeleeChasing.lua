local ServerScriptService = game:GetService("ServerScriptService")

local BotBeeliner = require(ServerScriptService.Server.Bots.Util.BotBeeliner)
local BotPath = require(ServerScriptService.Server.Bots.Util.BotPath)

return function(args: {
	bot: any,
	attackRange: number,
	human: Humanoid,
	animator: any,
	visionParts: { BasePart },
	getTarget: () -> any,
	clearTarget: () -> (),
	onChasing: ((any, number) -> string?)?,
})
	return {
		onEntered = function(state)
			state.path = BotPath.new({
				params = {
					Costs = {
						DamageBlock = math.huge,
					},
				},
				getPosition = function()
					return args.bot:getPosition()
				end,
				getFinish = function()
					return args.getTarget():getPosition()
				end,
				getIsValid = function(path)
					local last = path:getLast()
					if not last then return false end

					return args.getTarget():isInRange(last.Position, args.attackRange)
				end,
			})

			state.beeliner = BotBeeliner.new(args.visionParts, args.getTarget())

			args.animator:play("GenericRun")
		end,
		onWillLeave = function(state)
			state.path:destroy()
			state.beeliner:destroy()

			args.animator:stop("GenericRun")
		end,
		onUpdated = function(state, dt)
			if not args.getTarget():isAlive() then
				args.clearTarget()
				return "idling"
			end

			if args.getTarget():isInRange(args.bot:getPosition(), args.attackRange) then return "attacking" end

			if state.beeliner:try(dt) then
				args.human:MoveTo(args.getTarget():getPosition())

				if args.onChasing then
					local nextStateName = args.onChasing(state, dt)
					if nextStateName then return nextStateName end
				end
				return
			end

			if state.path:hasFailed() then return "idling" end

			local waypoint = state.path:getNext()
			if not waypoint then return end

			args.human:MoveTo(waypoint.Position)
			if waypoint.Action == Enum.PathWaypointAction.Jump then args.human.Jump = true end

			if args.onChasing then
				local nextStateName = args.onChasing(state, dt)
				if nextStateName then return nextStateName end
			end

			if state.path:checkReached() then return "idling" end

			return
		end,
	}
end
