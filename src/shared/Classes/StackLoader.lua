-- Class meant to be used in conjunction with singletons to load things on top of one another, overriding the previous one while newer things are active.
-- When something is added to the stack, a Symbol token is returned that can be used to mark for removal from stack when processing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Symbol = require(ReplicatedStorage.Packages.Symbol)

export type LoaderScheme = {
	onLoad: () -> nil,
	onUnload: () -> nil,
}

type LoaderNode = {
	active: boolean,
	scheme: LoaderScheme,
	loadingThread: thread?,
}

local StackLoader = {}
StackLoader.__index = StackLoader

function StackLoader.new()
	local self = setmetatable({}, StackLoader)
	self._tokenMap = {}
	self._stack = {}

	return self
end

function StackLoader:_unloadNode(node: LoaderNode)
	-- if loading thread is still running, cancel it
	if node.loadingThread then
		task.cancel(node.loadingThread)
		node.loadingThread = nil
	end
	task.spawn(function()
		local didUnload, errmsg = pcall(function()
			node.scheme.onUnload()
		end)
		if not didUnload then warn("StackLoader._unloadNode() | Failed to unload scheme: " .. errmsg) end
	end)
end

function StackLoader:_loadNode(node: LoaderNode)
	-- if thread yields for whatever reason, we want to be able to cancel it when a new scheme is loaded
	node.loadingThread = task.spawn(function()
		local didLoad, errmsg = pcall(function()
			node.scheme.onLoad()
		end)
		if not didLoad then warn("StackLoader._loadNode() | Failed to load scheme: " .. errmsg) end
		node.loadingThread = nil
	end)
end

function StackLoader:_pushStack(node: LoaderNode)
	local stack = self._stack

	local size = #stack
	local top = stack[size]

	table.insert(stack, node)

	if top then self:_unloadNode(top) end
	self:_loadNode(node)
end

function StackLoader:_processStack()
	-- if top marked as unloaded, pop stack until top is active
	local stack = self._stack

	local top = stack[#stack]

	-- if top is inactive, unload it
	if top.active then return end
	self:_unloadNode(top)

	-- remove inactive schemes from stack
	while stack[1] and not stack[#stack].active do
		stack[#stack] = nil
	end

	if #stack == 0 then return end

	-- reload top scheme
	self:_loadNode(stack[#stack])
end

function StackLoader:load(scheme: LoaderScheme)
	local token = Symbol("StackLoaderToken")
	local node: LoaderNode = {
		active = true,
		scheme = scheme,
	}
	self._tokenMap[token] = node
	self:_pushStack(node)

	return token
end

function StackLoader:unload(token)
	local node = self._tokenMap[token]
	if not node then return end
	self._tokenMap[token] = nil

	node.active = false
	self:_processStack()
end

return StackLoader
