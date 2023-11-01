local RANDOM = Random.new()

return function(list, random)
	random = random or RANDOM
	return list[random:NextInteger(1, #list)]
end
