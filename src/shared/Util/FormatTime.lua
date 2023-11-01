local function formatTime(seconds)
	local data = DateTime.fromUnixTimestamp(seconds):ToUniversalTime()
	return string.format("%02d:%02d:%02d", data.Hour, data.Minute, data.Second)
end

return formatTime
