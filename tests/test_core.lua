local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Root = ReplicatedStorage:WaitForChild("S23SmartTAS")
local Core = require(Root:WaitForChild("core"):WaitForChild("init"))
local Logger = require(Root:WaitForChild("core"):WaitForChild("logger"))
local Scanner = require(Root:WaitForChild("scanner"):WaitForChild("scanner"))
local Adaptive = require(Root:WaitForChild("interface"):WaitForChild("adaptive"))

local function makePart(name, className, size, canCollide, marker, transparency)
	return {
		Name = name,
		Size = size,
		Position = Vector3.new(0, 0, 0),
		CanCollide = canCollide,
		Transparency = transparency or 0,
		LocalTransparencyModifier = 0,
		IsA = function(_, requestedClass)
			return requestedClass == "BasePart" or className == requestedClass
		end,
		GetAttribute = function(_, attribute)
			if attribute == "SmartTAS_Type" then
				return marker
			end
			return nil
		end,
	}
end

return function()
	local logger = Logger.new({ maxEntries = 20 })
	local lifecycle = {}
	local core = Core.new(logger)
	core:Register("first", {
		Start = function()
			table.insert(lifecycle, "start-first")
		end,
		Stop = function()
			table.insert(lifecycle, "stop-first")
		end,
	})
	core:Register("second", {
		Start = function()
			table.insert(lifecycle, "start-second")
		end,
		Stop = function()
			table.insert(lifecycle, "stop-second")
		end,
	})
	local started = core:Start()
	assert(started, "Los módulos válidos deben iniciar")
	assert(core:GetStatuses().first == "started", "El estado inicializado debe ser visible")
	local duplicateStart = core:Start()
	assert(not duplicateStart, "No deben duplicarse inicializaciones")
	core:Stop()
	assert(lifecycle[3] == "stop-second" and lifecycle[4] == "stop-first", "La limpieza debe ser inversa al inicio")
	assert(core:GetStatuses().first == "stopped", "El estado de limpieza debe ser visible")

	local cleanupAfterFailure = false
	local failingCore = Core.new(logger)
	failingCore:Register("broken", {
		Start = function()
			error("fallo controlado")
		end,
		Stop = function()
			cleanupAfterFailure = true
		end,
	})
	local failureHandled, failureStatuses = failingCore:Start()
	assert(not failureHandled, "Un fallo de inicio debe reportarse")
	assert(cleanupAfterFailure, "Un módulo con fallo debe recibir limpieza")
	assert(failureStatuses.broken == "failed", "El fallo debe quedar en estado observable")

	local parts = {
		makePart("AuthoredPlatform", "Part", Vector3.new(10, 1, 10), true, "platform"),
		makePart("WidePart", "Part", Vector3.new(12, 1, 12), true),
		makePart("Checkpoint_1", "Part", Vector3.new(2, 1, 2), true),
		makePart("Unclassified", "Part", Vector3.new(1, 1, 1), false),
		makePart("Invisible", "Part", Vector3.new(10, 1, 10), true, nil, 1),
	}
	local scanner = Scanner.new({
		GetWorkspaceDescendants = function()
			return parts
		end,
	}, { maxInstances = 10 })
	local result = scanner:Scan()
	assert(result.summary.detected == 1, "Las marcas explícitas deben clasificarse como detected")
	assert(result.summary.estimated == 2, "Las heurísticas deben clasificarse como estimated")
	assert(result.summary.unknown == 1, "La geometría ambigua debe permanecer unknown")
	assert(result.summary.total == 4, "Los elementos invisibles deben excluirse")
	assert(result.timeEstimate.status == "unknown", "No se debe inventar una estimación de tiempo")

	local boundedScanner = Scanner.new({
		GetWorkspaceDescendants = function()
			return parts
		end,
	}, { maxInstances = 2 })
	assert(boundedScanner:Scan().summary.truncated, "El presupuesto debe limitar el escaneo")
	assert(Adaptive.ClassifyViewport(390, true) == "mobile", "La UI debe reconocer pantallas táctiles")
	assert(Adaptive.ClassifyViewport(1280, false) == "desktop", "La UI debe reconocer escritorio")

	local camera = { ViewportSize = Vector2.new(390, 844) }
	local adaptive = Adaptive.new(
		{ TouchEnabled = true },
		{ CurrentCamera = camera }
	)
	local panel = {}
	local floatingButton = {}
	adaptive:Bind({}, panel, floatingButton)
	assert(panel.Size.Y.Offset == 390, "El panel táctil debe usar el layout compacto")
	assert(panel.AnchorPoint.X == 0.5, "El panel táctil debe centrarse")
	camera.ViewportSize = Vector2.new(1280, 720)
	adaptive._userInputService.TouchEnabled = false
	adaptive:Apply()
	assert(panel.Size.X.Offset == 330, "El panel de escritorio debe usar ancho lateral")
	adaptive:Stop()
end
