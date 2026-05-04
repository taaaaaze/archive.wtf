local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

local spawn = task.spawn
local setmetatable = setmetatable
local running = coroutine.running
local yield = coroutine.yield

function Connection.new(signal, fn)
	return setmetatable({
		_signal = signal,
		_fn = fn,
		_next = false,
		_prev = false,
		Connected = true,
	}, Connection)
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false

	if self._prev then
		self._prev._next = self._next
	else
		self._signal._head = self._next
	end

	if self._next then
		self._next._prev = self._prev
	end

	self._signal._count -= 1
	self._fn = nil
	self._next = false
	self._prev = false
end

Connection.Destroy = Connection.Disconnect

function Signal.New()
	return setmetatable({
		_head = false,
		_count = 0,
	}, Signal)
end

function Signal:Connect(fn)
	local conn = Connection.new(self, fn)
	if self._head then
		conn._next = self._head
		self._head._prev = conn
	end
	self._head = conn
	self._count += 1
	return conn
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		if conn.Connected then
			conn:Disconnect()
		end
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	local node = self._head
	while node do
		if node.Connected and node._fn then
			spawn(node._fn, ...)
		end
		node = node._next
	end
end

function Signal:FireDirect(...)
	local node = self._head
	while node do
		if node.Connected and node._fn then
			node._fn(...)
		end
		node = node._next
	end
end

function Signal:Wait()
	local thread = running()
	local conn
	conn = self:Connect(function(...)
		if conn.Connected then
			conn:Disconnect()
		end
		spawn(thread, ...)
	end)
	return yield()
end

function Signal:GetConnectionCount()
	return self._count
end

function Signal:DisconnectAll()
	local node = self._head
	while node do
		local nxt = node._next
		node.Connected = false
		node._fn = nil
		node._next = false
		node._prev = false
		node = nxt
	end
	self._head = false
	self._count = 0
end

function Signal:Destroy()
	self:DisconnectAll()
	setmetatable(self, nil)
end

return Signal
