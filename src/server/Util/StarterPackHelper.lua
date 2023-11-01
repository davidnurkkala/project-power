local ServerScriptService = game:GetService("ServerScriptService")

local StarterPackHelper = {}

StarterPackHelper.Product = { kind = "other", id = "StarterPack" }

local function getProductService()
	local name = "ProductService"
	local moduleScript = ServerScriptService.Server.Services[name]
	return require(moduleScript)
end

function StarterPackHelper.isOwned(player)
	return getProductService():isOwned(player, StarterPackHelper.Product)
end

return StarterPackHelper
