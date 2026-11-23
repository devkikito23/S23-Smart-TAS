local Logger = {}
Logger.__index = Logger

local LEVELS = {
	DEBUG = 10,
	INFO = 20,
	WARN = 30,
	ERROR = 40,
}

local function isPositiveInteger(value)
	return type(value) == "number" and value >= 1 and value % 1 == 0
end

function Logger.new(options)
	options = options or {}
	local limit = options.maxEntries or 100
	assert(isPositiveInteger(limit), "maxEntries debe ser un entero positivo")
	local minLevel = options.minLevel or "DEBUG"
	assert(LEVELS[minLevel] ~= nil, "minLevel no es válido")

	return setmetatable({
		_limit = limit,
		_history = {},
		_listeners = {},
		_clock = options.clock or os.time,
		_minLevel = minLevel,
	}, Logger)
end

function Logger:_emit(level, message, context)
	assert(LEVELS[level] ~= nil, "Nivel de registro desconocido")
	assert(type(message) == "string", "El mensaje debe ser texto")

	if LEVELS[level] < LEVELS[self._minLevel] then
		return nil
	end

	local entry = {
		time = self._clock(),
		level = level,
		message = message,
		context = context,
	}
	table.insert(self._history, entry)
	while #self._history > self._limit do
		table.remove(self._history, 1)
	end

	for id, listener in pairs(self._listeners) do
		local ok, err = pcall(listener, entry)
		if not ok then
			self._listeners[id] = nil
			warn("S23 Smart TAS: se quitó un suscriptor de logger que falló: " .. tostring(err))
		end
	end

	return entry
end

function Logger:Debug(message, context)
	return self:_emit("DEBUG", message, context)
end

function Logger:Info(message, context)
	return self:_emit("INFO", message, context)
end

function Logger:Warn(message, context)
	return self:_emit("WARN", message, context)
end

function Logger:Error(message, context)
	return self:_emit("ERROR", message, context)
end

function Logger:GetHistory(limit)
	assert(
		limit == nil or (type(limit) == "number" and limit >= 0 and limit % 1 == 0),
		"limit debe ser un entero no negativo"
	)
	local result = {}
	local startIndex = 1
	if limit ~= nil then
		startIndex = math.max(1, #self._history - math.floor(limit) + 1)
	end
	for index = startIndex, #self._history do
		table.insert(result, self._history[index])
	end
	return result
end

function Logger:Subscribe(listener)
	assert(type(listener) == "function", "listener debe ser una función")
	local id = {}
	self._listeners[id] = listener
	local connected = true
	return function()
		if connected then
			connected = false
			self._listeners[id] = nil
		end
	end
end

function Logger:Clear()
	table.clear(self._history)
end

return Logger
