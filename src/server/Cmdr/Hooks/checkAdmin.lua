local RunService = game:GetService("RunService")
return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		if RunService:IsStudio() then return end
		if context.Executor:GetRankInGroup(32515689) < 245 then return "You don't have permission to use this command." end

		return nil
	end)
end
