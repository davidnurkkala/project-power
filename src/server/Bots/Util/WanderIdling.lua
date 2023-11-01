local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local BattleService = require(ServerScriptService.Server.Services.BattleService)

local TAU = math.pi * 2
local ARRIVAL_RANGE = 6

return function(args: {
	visionPart: BasePart,
	human: Humanoid,
	animator: any,
	onIdling: ((any, number) -> string?)?,
})
	local visionPart = args.visionPart
	local human = args.human
	local onIdling = args.onIdling or function() end
	local animator = args.animator

	return {
		onEntered = function(state)
			state.goal = nil
			state.nextWanderTimestamp = tick()
		end,
		onUpdated = function(state, dt)
			if state.goal then
				human:MoveTo(state.goal)

				local distance = (state.goal - visionPart.Position).Magnitude
				if distance < ARRIVAL_RANGE then
					state.goal = nil
					animator:stop("GenericRun")

					state.nextWanderTimestamp = tick() + 2 * math.random()
				end
			else
				local passed = tick() - state.nextWanderTimestamp
				if passed > 0 then
					if passed > 2.5 then return "resetting" end

					local spin = CFrame.Angles(0, TAU * math.random(), 0)
					local tilt = CFrame.Angles(math.rad(-20), 0, 0)
					local cframe = CFrame.new(visionPart.Position) * spin * tilt

					local origin = cframe.Position
					local direction = cframe.LookVector * 32

					local params = RaycastParams.new()
					params.FilterDescendantsInstances = { BattleService:getArena() }
					params.FilterType = Enum.RaycastFilterType.Include

					local result = workspace:Raycast(origin, direction, params)

					if result then
						local slopeScalar = result.Normal:Dot(Vector3.yAxis)
						if slopeScalar > 0.8 then
							local isDamageBlock = result.Instance and CollectionService:HasTag(result.Instance, "DamageBlock")
							if not isDamageBlock then
								state.goal = result.Position
								animator:play("GenericRun", 0)
							end
						end
					end
				end
			end

			return onIdling(state, dt)
		end,
		onWillLeave = function(state)
			state.goal = nil
			animator:stop("GenericRun")
		end,
	}
end
