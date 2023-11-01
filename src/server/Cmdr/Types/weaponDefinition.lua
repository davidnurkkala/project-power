local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local weaponDefinitionType = {
	Validate = function(text)
		return text ~= nil, "A weapon definition is required"
	end,
	Autocomplete = function(text)
		local weaponDefinitions = WeaponUtil.getWeaponDefinitions()
		local list = {}
		for _, weaponDefinition in pairs(weaponDefinitions) do
			if string.sub(weaponDefinition.id, 1, #text) == text then table.insert(list, weaponDefinition.id) end
		end
		return list
	end,
	Parse = function(weaponId: string)
		return WeaponUtil.getWeaponDefinition(weaponId)
	end,
}

return function(registry)
	registry:RegisterType("weaponDefinition", weaponDefinitionType)
end
