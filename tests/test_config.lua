local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("S23SmartTAS"):WaitForChild("config"))

return function()
	local valid, reason = Config.Validate()
	assert(valid, reason)
	assert(Config.VERSION == "0.1.0", "La versión del proyecto no coincide")
	assert(Config.AUTHORIZATION_REQUIRED == true, "El análisis debe requerir autorización")
	assert(Config.SCAN_MAX_INSTANCES > 0, "El presupuesto del escáner debe ser positivo")
end
