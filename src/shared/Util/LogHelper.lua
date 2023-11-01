local LogHelper = {
	_lines = {},
}

function LogHelper:log(line)
	table.insert(self._lines, line)
end

function LogHelper:getLines()
	return self._lines
end

function LogHelper:printAll()
	print(table.concat(self._lines, "\n"))
end

return LogHelper
