local Session = {}
Session.__index = Session

local function copySummary(summary)
	local result = {}
	for _, field in ipairs({ "total", "detected", "estimated", "unknown" }) do
		local value = summary[field]
		assert(type(value) == "number" and value >= 0 and value % 1 == 0, field .. " no es un recuento válido")
		result[field] = value
	end
	return {
		total = result.total,
		detected = result.detected,
		estimated = result.estimated,
		unknown = result.unknown,
		truncated = summary.truncated == true,
	}
end

function Session.new(options)
	options = options or {}
	local limit = options.historyLimit or 40
	assert(type(limit) == "number" and limit >= 1 and limit % 1 == 0, "historyLimit no es válido")

	return setmetatable({
		_historyLimit = limit,
		_authorized = options.authorized == true,
		_store = options.store,
		_scans = {},
		_startedAt = os.time(),
	}, Session)
end

function Session:RecordScan(result)
	assert(type(result) == "table" and type(result.summary) == "table", "Resultado de escaneo no válido")
	local entry = {
		observedAt = result.observedAt or os.time(),
		summary = copySummary(result.summary),
		timeEstimate = "unknown",
	}
	table.insert(self._scans, entry)
	while #self._scans > self._historyLimit do
		table.remove(self._scans, 1)
	end
	return entry
end

function Session:GetStatistics()
	local lastScan = self._scans[#self._scans]
	return {
		scanCount = #self._scans,
		lastScan = lastScan,
		startedAt = self._startedAt,
		persistence = self:GetPersistenceStatus(),
	}
end

function Session:GetPersistenceStatus()
	if not self._authorized then
		return "not_authorized"
	end
	if type(self._store) ~= "table" or type(self._store.Save) ~= "function" then
		return "unavailable"
	end
	return "available"
end

function Session:Save()
	local persistence = self:GetPersistenceStatus()
	if persistence == "not_authorized" then
		return false, "not_authorized"
	end
	if persistence == "unavailable" then
		return false, "storage_unavailable"
	end

	local payload = {
		startedAt = self._startedAt,
		scans = {},
	}
	for _, scan in ipairs(self._scans) do
		table.insert(payload.scans, {
			observedAt = scan.observedAt,
			summary = copySummary(scan.summary),
			timeEstimate = scan.timeEstimate,
		})
	end

	local ok, result, detail = pcall(self._store.Save, self._store, payload)
	if not ok then
		return false, tostring(result)
	end
	if result == false then
		return false, tostring(detail or "storage_rejected")
	end
	return true, result
end

return Session
