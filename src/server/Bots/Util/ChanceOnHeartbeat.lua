local RANDOM = Random.new()

return function(n)
	local integer = RANDOM:NextInteger(1, math.floor(n * 60))
	return integer == 1
end
