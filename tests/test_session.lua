local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Session = require(ReplicatedStorage:WaitForChild("S23SmartTAS"):WaitForChild("data"):WaitForChild("session"))

local function makeResult(timestamp)
	return {
		observedAt = timestamp,
		summary = {
			total = 3,
			detected = 1,
			estimated = 1,
			unknown = 1,
			truncated = false,
		},
	}
end

return function()
	local unauthorized = Session.new({ historyLimit = 1 })
	unauthorized:RecordScan(makeResult(10))
	local saved, reason = unauthorized:Save()
	assert(not saved and reason == "not_authorized", "La sesión no debe persistir sin autorización")
	assert(unauthorized:GetStatistics().scanCount == 1, "Las observaciones en memoria deben registrarse")

	local unavailable = Session.new({ authorized = true })
	saved, reason = unavailable:Save()
	assert(not saved and reason == "storage_unavailable", "El almacenamiento ausente debe reportarse")

	local receivedPayload
	local persistent = Session.new({
		authorized = true,
		historyLimit = 1,
		store = {
			Save = function(_, payload)
				receivedPayload = payload
				return true
			end,
		},
	})
	persistent:RecordScan(makeResult(11))
	persistent:RecordScan(makeResult(12))
	assert(persistent:GetStatistics().scanCount == 1, "El historial debe respetar su límite")
	saved = persistent:Save()
	assert(saved and receivedPayload.scans[1].observedAt == 12, "El adaptador autorizado debe recibir datos reales")

	local rejected = Session.new({
		authorized = true,
		store = {
			Save = function()
				return false, "storage rejected"
			end,
		},
	})
	saved, reason = rejected:Save()
	assert(not saved and reason == "storage rejected", "Un rechazo del adaptador no debe reportarse como éxito")

	local invalidRecord = pcall(function()
		persistent:RecordScan({ summary = { total = "many" } })
	end)
	assert(not invalidRecord, "Los recuentos inválidos deben rechazarse")
end
