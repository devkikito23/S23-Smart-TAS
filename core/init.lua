local Core = {}
Core.__index = Core

function Core.new(logger)
	assert(logger ~= nil, "Se requiere un logger")
	return setmetatable({
		_logger = logger,
		_components = {},
		_order = {},
		_status = {},
		_started = false,
	}, Core)
end

function Core:Register(name, component)
	assert(not self._started, "No se pueden registrar módulos después del inicio")
	assert(type(name) == "string" and name ~= "", "El nombre del módulo no es válido")
	assert(type(component) == "table", "El módulo debe ser una tabla")
	assert(self._components[name] == nil, "El módulo ya está registrado: " .. name)

	self._components[name] = component
	table.insert(self._order, name)
	self._status[name] = "registered"
end

function Core:Start()
	if self._started then
		return false, "already_started"
	end

	self._started = true
	local allStarted = true
	for _, name in ipairs(self._order) do
		local component = self._components[name]
		local ok, err = true, nil
		if type(component.Start) == "function" then
			ok, err = pcall(component.Start, component)
		end

		if ok then
			self._status[name] = "started"
			self._logger:Info("Módulo iniciado: " .. name)
		else
			allStarted = false
			self._status[name] = "failed"
			self._logger:Error("No se pudo iniciar el módulo: " .. name, tostring(err))
			if type(component.Stop) == "function" then
				local stopOk, stopErr = pcall(component.Stop, component)
				if not stopOk then
					self._logger:Error("Falló la limpieza del módulo: " .. name, tostring(stopErr))
				end
			end
		end
	end

	return allStarted, self:GetStatuses()
end

function Core:Stop()
	if not self._started then
		return true
	end

	for index = #self._order, 1, -1 do
		local name = self._order[index]
		local component = self._components[name]
		if self._status[name] == "started" and type(component.Stop) == "function" then
			local ok, err = pcall(component.Stop, component)
			if ok then
				self._status[name] = "stopped"
			else
				self._status[name] = "failed"
				self._logger:Error("Falló la limpieza del módulo: " .. name, tostring(err))
			end
		elseif self._status[name] == "started" then
			self._status[name] = "stopped"
		end
	end

	self._started = false
	return true
end

function Core:GetStatuses()
	local result = {}
	for name, status in pairs(self._status) do
		result[name] = status
	end
	return result
end

return Core
