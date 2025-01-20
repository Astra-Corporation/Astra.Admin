--// Author: 8ch99
--// Date written: 18/01/2025
--// RBXScriptSignal emulation tailored for max performance and cleanliness

--[[

MIT License

Copyright (c) 2025 8ch99

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]

--[[

API:

Signal.new() - Creates a new blank identity signal
Signal:Fire(...: any) - Fires the signal immediately with the given args
Signal:FireDeferred(...: any) - Fires the signal's connections in sync (deferred)
Signal:Connect(Function) - Creates a ConnectionNode with that function, adds it to the signal, and returns the node
Signal:Once(Function) - Same as Signal:Connect(), except the node will disconnect as soon as the signal is fired
Signal:Wait() - Yields the current thread until the signal is fired, and returns the arguments fed via. Signal:Fire() or Signal:FireDeferred()
Signal:DisconnectAll() - Disconnects every connection node in the signal
Signal:Clone() - Creates a new signal with the exact same connection nodes
Signal:Destroy() - Completely disposes the signal. Call this when you no longer need it

]]

--!strict
--!native
--!optimize 2

--// Types

export type ConnectionNode = {
	Connected: boolean,
	Function: (...any) -> (...any),
	Next: ConnectionNode?,
	Disconnect: (ConnectionNode?) -> (),
}

export type Signal = typeof(setmetatable({}, {})) & {
	--// Properties
	__meta: string,
	TopNode: ConnectionNode?,
	--// Functions
	Fire: (Signal, ...any) -> (),
	FireDeferred: (Signal, ...any) -> (),
	Connect: (Signal, (...any) -> (...any)) -> ConnectionNode,
	Once: (Signal, (...any) -> (...any)) -> ConnectionNode,
	Wait: (Signal) -> (...any),
	DisconnectAll: (Signal) -> (),
	Clone: (Signal) -> Signal,
	Destroy: (Signal) -> (),
}

--// Dependencies

local coroutine_running = coroutine.running
local coroutine_yield = coroutine.yield
local coroutine_status = coroutine.status

local task_spawn = task.spawn
local task_defer = task.defer

local table_clear = table.clear

local function DeepCopy(Table: { [any]: any })
	local Clone = {}
	for Index, Value in Table do
		if type(Value) == "table" then
			Value = DeepCopy(Value)
		end
		Clone[Index] = Value
	end
	return Clone
end

--// @class Signal

local Signal = {}
Signal.__index = Signal

--[[
	@TODO Creates a new blank identity signal
	@returns Signal
]]
function Signal.new(): Signal
	local self = setmetatable({} :: Signal, Signal)
	self.__meta = "Signal"
	return self
end

--[[
	@TODO Fires the signal immediately with the given args
	@param VARARG : any - Arguments to give to the connection node functions
]]
function Signal:Fire(...: any)
	local Node: ConnectionNode? = self.TopNode
	while Node do
		task_spawn(Node.Function, ...)
		Node = Node.Next
	end
end

--[[
	@TODO Fires the signal's connections in sync (deferred)
	@param VARARG : any - Arguments to give to the connection node functions
]]
function Signal:FireDeferred(...: any)
	local Node: ConnectionNode? = self.TopNode
	while Node do
		task_defer(Node.Function, ...)
		Node = Node.Next
	end
end


--[[
	@TODO Creates a ConnectionNode with that function, adds it to the signal, and returns the node
	@param Function : any
	@returns ConnectionNode
]]
function Signal:Connect(Function): ConnectionNode
	--// connections are not a seperate class to prevent a ton of cross referencing and slightly decrease memory usage
	--// as much better as it would look as a seperate class this is probably the faster method
	local Node = {}
	Node.Connected = true
	Node.Function = Function
	Node.Next = self.TopNode
	self.TopNode = Node

	function Node.Disconnect()
		if not Node.Connected then
			return
		end
		Node.Connected = false
		local Current: ConnectionNode? = self.TopNode
		if Current == Node then
			self.TopNode = Node.Next
		else
			while Current do
				local Next: ConnectionNode? = Current.Next
				if Next and Next == Node then
					Current.Next = Next.Next
					break
				end
				Current = Next
			end
		end
		table_clear(Node)
	end

	return Node :: ConnectionNode
end

--[[
	@TODO Same as Signal:Connect(), except the node will disconnect as soon as the signal is fired
	@param Function : (...any) -> () - The function to make the new connection node with
	@returns ConnectionNode
]]
function Signal:Once(Function): ConnectionNode
	local Node: ConnectionNode = nil
	Node = self:Connect(function(...)
		Node:Disconnect()
		return Function(...)
	end)
	return Node
end

--[[
	@TODO Yields the current thread until the signal is fired, and returns the arguments fed via. Signal:Fire() or Signal:FireDeferred()
	@param Function : (...any) -> () - The function to make the new connection node with
	@returns ConnectionNode
]]
function Signal:Wait(): (...any)
	local CurrentThread = coroutine_running()
	local ResumerNode: ConnectionNode = nil
	ResumerNode = self:Connect(function(...)
		if coroutine_status(CurrentThread) == "suspended" then
			task_spawn(CurrentThread, ...)
		end
		ResumerNode:Disconnect()
	end)
	return coroutine_yield()
end

--[[
	Disconnects every connection node in the signal
]]
function Signal:DisconnectAll()
	local Node: ConnectionNode? = self.TopNode
	while Node do
		Node.Connected = false
		local Next: ConnectionNode? = Node.Next
		if Next then
			Node.Next = nil
		end
		Node = Next
	end
	self.TopNode = nil
end

--[[
	@TODO Creates a new signal with the exact same connection nodes
	@returns Signal
]]
function Signal:Clone()
	local TopNode = self.TopNode
	local Clone = Signal.new()
	if TopNode then
		Clone.TopNode = DeepCopy(TopNode)
	end
	return Clone
end


--[[
	@TODO Completely disposes the signal. Call this when you no longer need it
]]
function Signal:Destroy()
	self:DisconnectAll()
	table_clear(self)
	setmetatable(self, nil)
end

return Signal
