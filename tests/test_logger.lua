local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage:WaitForChild("S23SmartTAS"):WaitForChild("core"):WaitForChild("logger"))

return function()
	local clockValue = 123
	local logger = Logger.new({
		maxEntries = 2,
		clock = function()
			return clockValue
		end,
	})
	local observed = {}
	local unsubscribe = logger:Subscribe(function(entry)
		table.insert(observed, entry)
	end)

	logger:Info("uno")
	clockValue = 124
	logger:Warn("dos")
	logger:Error("tres")
	assert(#logger:GetHistory() == 2, "El historial debe respetar el límite")
	assert(logger:GetHistory()[1].message == "dos", "El historial debe descartar la entrada más antigua")
	assert(#observed == 3, "Los eventos deben notificarse")
	assert(observed[3].time == 124, "El reloj inyectado debe usarse")

	unsubscribe()
	logger:Info("cuatro")
	assert(#observed == 3, "La suscripción debe poder cancelarse")
	logger:Clear()
	assert(#logger:GetHistory() == 0, "Clear debe vaciar el historial")

	local ok = pcall(Logger.new, { maxEntries = 0 })
	assert(not ok, "Un límite inválido debe producir un error explícito")
	ok = pcall(function()
		logger:GetHistory("all")
	end)
	assert(not ok, "Un límite de consulta inválido debe producir un error explícito")
	local invalidLevel = pcall(Logger.new, { minLevel = "VERBOSE" })
	assert(not invalidLevel, "Un nivel mínimo desconocido debe producir un error explícito")
end
