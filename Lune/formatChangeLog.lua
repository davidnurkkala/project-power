local ChangeLog = require("../src/shared/Data/ChangeLog")
local fs = require("@lune/fs")

local lines = {}

for _, entry in ChangeLog[2] do
	if typeof(entry) == "table" then
		for _, subEntry in entry do
			if typeof(subEntry) == "table" then
				local previousLine = string.gsub(lines[#lines], "- ", "")
				lines[#lines] = `### {previousLine}`

				for _, bottomEntry in subEntry do
					table.insert(lines, `- {bottomEntry}`)
				end
			else
				table.insert(lines, `- {subEntry}`)
			end
		end
	else
		table.insert(lines, `# {entry}`)
	end
end

fs.writeFile("changelog.md", table.concat(lines, "\n"))
