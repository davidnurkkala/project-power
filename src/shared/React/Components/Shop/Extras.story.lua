local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Extras = require(ReplicatedStorage.Shared.React.Components.Shop.Extras)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

local controls = {}

local fakeRewards = {
	{
		timestamp = os.time() - 5,
		rewards = {
			{ type = "power", amount = 50 },
		},
		available = true,
	},
	{
		timestamp = os.time() + 200,
		rewards = {
			{ type = "premium", amount = 50 },
		},
		available = false,
	},
	{
		timestamp = os.time() + 300,
		rewards = {
			{ type = "power", amount = 50 },
		},
		available = false,
	},
	{
		timestamp = os.time() + 400,
		rewards = {
			{ type = "power", amount = 50 },
		},
		available = false,
	},
	{
		timestamp = os.time() + 500,
		rewards = {
			{ type = "power", amount = 50 },
		},
		available = false,
	},
	{
		timestamp = os.time() + 600,
		rewards = {
			{ type = "power", amount = 50 },
		},
		available = false,
	},

	{
		timestamp = os.time() + 700,
		rewards = {
			{ type = "booster", minutes = 20 },
		},
		available = false,
	},

	{
		timestamp = os.time() + 800,
		rewards = {
			{ type = "booster", minutes = 20 },
		},
		available = false,
	},

	{
		timestamp = os.time() + 900,
		rewards = {
			{ type = "booster", minutes = 20 },
		},
		available = false,
	},

	{
		timestamp = os.time() + 1000,
		rewards = {
			{ type = "booster", minutes = 20 },
		},
		available = false,
	},

	{
		timestamp = os.time() + 1100,
		rewards = {
			{ type = "booster", minutes = 20 },
		},
		available = false,
	},

	{
		timestamp = os.time() + 1200,
		rewards = {
			{ type = "booster", minutes = 20 },
		},
		available = false,
	},
}

return {
	controls = controls,
	react = React,
	reactRoblox = ReactRoblox,
	story = function(_props)
		local awarded = React.useRef(Signal.new()).current
		local awardBecameAvailable = React.useRef(Signal.new()).current
		local fakeUpdateAwardsSignal = React.useRef(Signal.new()).current
		local observeRewards = function(callback)
			callback(fakeRewards)
			return fakeUpdateAwardsSignal:Connect(callback)
		end

		return React.createElement(function()
			local screen = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(0, 0),
				LayoutOrder = 1,
			}, {
				Stroke = React.createElement("UIStroke", {
					Thickness = 2,
				}),

				Element = React.createElement(Extras, {
					exit = function()
						print("exit")
					end,

					visible = true,

					-- quick session api
					awarded = awarded,
					awardBecameAvailable = awardBecameAvailable,
					observeInfo = observeRewards,
					promiseClaim = function(claimedIndex)
						return Promise.new(function(resolve)
							print("claiming", claimedIndex)
							task.wait(1)
							if fakeRewards[claimedIndex].available then
								fakeRewards = Sift.Array.map(fakeRewards, function(value, index)
									if index == claimedIndex then
										return {
											timestamp = value.timestamp,
											rewards = value.rewards,
											available = false,
										}
									else
										return value
									end
								end)
								fakeUpdateAwardsSignal:Fire(fakeRewards)
							end

							print("claim", claimedIndex)
							resolve()
						end)
					end,
				}),
			})

			return screen
		end)
	end,
}
