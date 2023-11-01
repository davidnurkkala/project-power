local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelUpDefinitions = require(ReplicatedStorage.Shared.Data.LevelUpDefinitions)
local PlatformContext = require(ReplicatedStorage.Shared.React.Contexts.PlatformContext)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local useCharacter = require(ReplicatedStorage.Shared.React.Hooks.useCharacter)

local TICKER_SPEED = 1 / 30

export type LevelUpPerksLabel = {
	player: Player,
	position: UDim2,
}

local function createLine(message: string)
	local line = {}
	line.message = message
	line.changed = Signal.new()
	line.cursor = 0

	function line:get()
		return self.message:sub(1, self.cursor)
	end

	function line:start()
		return Promise.new(function(resolve)
			for _, index in utf8.graphemes(self.message) do
				self.cursor = index
				self.changed:Fire()
				task.wait(TICKER_SPEED)
			end
			resolve()
		end)
	end

	function line:destroy()
		return Promise.new(function(resolve)
			while self.cursor > 0 do
				self.cursor -= 1
				self.changed:Fire()
				task.wait(TICKER_SPEED)
			end
			resolve()
		end)
	end

	return line
end

local function createTicker()
	local ticker = {}
	ticker.lines = {}
	ticker.queue = {}
	ticker.changed = Signal.new()
	ticker.removing = false

	function ticker:next()
		local message = self.queue[1]
		local line = createLine(message)
		table.insert(self.lines, line)
		line.changed:Connect(function()
			self.changed:Fire()
		end)
		line:start():andThen(function()
			table.remove(self.queue, 1)
			if #self.queue > 0 then self:next() end
			task.wait(5)
			line:destroy():andThen(function()
				table.remove(self.lines, table.find(self.lines, line))
			end)
		end)
	end

	function ticker:addLine(message)
		table.insert(self.queue, message)
		if #self.queue == 1 then self:next() end
	end

	function ticker:get()
		local messages = {}
		for _, line in self.lines do
			table.insert(messages, line:get())
		end
		return table.concat(messages, "\n")
	end

	return ticker
end

local LevelUpPerksLabel: React.FC<LevelUpPerksLabel> = function(props: LevelUpPerksLabel)
	local platform = React.useContext(PlatformContext)
	local isMobile = platform == "Mobile"

	local player = props.player
	local char = useCharacter(player)

	local level = React.useRef(1)
	local tickerRef = React.useRef(createTicker())
	local ref = React.useRef(nil)

	React.useEffect(function()
		local label: TextLabel = ref.current
		local ticker = tickerRef.current

		if not char then return end
		if not label then return end
		if not ticker then return end

		level.current = char:GetAttribute("Level") or 1

		local trove = Trove.new()

		trove:Add(function()
			label.Text = ""
		end)

		trove:Connect(char:GetAttributeChangedSignal("Level"), function()
			local newLevel = char:GetAttribute("Level")
			level.current = newLevel

			ticker:addLine(`Leveled up to {newLevel}!`)
			for _, perk in LevelUpDefinitions.perksByLevel[newLevel] do
				ticker:addLine(LevelUpDefinitions.descriptionsByPerk[perk])
			end
		end)

		trove:Connect(ticker.changed, function()
			label.Text = ticker:get()
		end)

		return function()
			trove:Clean()
		end
	end)

	return React.createElement("TextLabel", {
		ref = ref,
		Position = props.position,
		AnchorPoint = Vector2.new(1, 1),
		Font = Enum.Font.GothamBold,
		BackgroundTransparency = 1,
		TextSize = if isMobile then 12 else 16,
		TextStrokeTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "",
	})
end

return LevelUpPerksLabel
