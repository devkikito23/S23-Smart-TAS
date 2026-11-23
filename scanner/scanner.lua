local MapAnalyzer = require(script.Parent.map_analyzer)

local Scanner = {}
Scanner.__index = Scanner

function Scanner.new(observer, options)
	assert(observer ~= nil, "Scanner requiere Observer")
	options = options or {}
	local maxInstances = options.maxInstances or 800
	assert(type(maxInstances) == "number" and maxInstances >= 1 and maxInstances % 1 == 0, "maxInstances no es válido")

	return setmetatable({
		_observer = observer,
		_maxInstances = maxInstances,
		_lastResult = nil,
	}, Scanner)
end

function Scanner:SetMaxInstances(value)
	assert(type(value) == "number" and value >= 1 and value % 1 == 0, "maxInstances debe ser un entero positivo")
	self._maxInstances = value
end

function Scanner:GetLastResult()
	return self._lastResult
end

function Scanner:Scan()
	local descendants = self._observer:GetWorkspaceDescendants()
	local items = {}
	local summary = {
		total = 0,
		detected = 0,
		estimated = 0,
		unknown = 0,
		platforms = 0,
		obstacles = 0,
		checkpoints = 0,
	}
	local inspected = 0
	local truncated = false

	for _, instance in ipairs(descendants) do
		inspected = inspected + 1
		if inspected > self._maxInstances then
			truncated = true
			break
		end

		if instance:IsA("BasePart") then
			local item = MapAnalyzer.AnalyzePart(instance)
			if item ~= nil then
				table.insert(items, item)
				summary.total = summary.total + 1
				summary[item.status] = summary[item.status] + 1
				if item.kind == "platform" then
					summary.platforms = summary.platforms + 1
				elseif item.kind == "obstacle" then
					summary.obstacles = summary.obstacles + 1
				elseif item.kind == "checkpoint" then
					summary.checkpoints = summary.checkpoints + 1
				end
			end
		end
	end

	summary.truncated = truncated
	local result = {
		observedAt = os.time(),
		items = items,
		summary = summary,
		timeEstimate = {
			status = "unknown",
			reason = "v0.1.0 no calcula duración ni dispone de una ruta verificada.",
		},
		route = {
			status = "not_implemented",
			reason = "Route Intelligence está planificado para v0.5.0.",
		},
	}
	self._lastResult = result
	return result
end

return Scanner
