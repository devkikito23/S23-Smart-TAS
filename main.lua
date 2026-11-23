local Config = require(script.Parent.config)
local Core = require(script.Parent.core.init)
local Logger = require(script.Parent.core.logger)
local Observer = require(script.Parent.core.observer)
local Session = require(script.Parent.data.session)
local Techniques = require(script.Parent.data.techniques)
local Scanner = require(script.Parent.scanner.scanner)
local Adaptive = require(script.Parent.interface.adaptive)
local Menu = require(script.Parent.interface.menu)
local Notifications = require(script.Parent.interface.notifications)
local Renderer3D = require(script.Parent.visuals.renderer_3d)
local Minimap2D = require(script.Parent.visuals.minimap_2d)

local Main = {}

local function getServices(overrides)
	overrides = overrides or {}
	return {
		Players = overrides.Players or game:GetService("Players"),
		Workspace = overrides.Workspace or game:GetService("Workspace"),
		RunService = overrides.RunService or game:GetService("RunService"),
		UserInputService = overrides.UserInputService or game:GetService("UserInputService"),
	}
end

function Main.Init(options)
	options = options or {}
	local configOk, configError = Config.Validate()
	assert(configOk, configError)

	local services = getServices(options.services)
	local player = options.player or services.Players.LocalPlayer
	assert(player ~= nil, "S23 Smart TAS debe inicializarse desde un cliente Roblox.")
	local playerGui = options.playerGui or player:WaitForChild("PlayerGui")

	local logger = Logger.new({ maxEntries = Config.LOGGER_HISTORY_LIMIT })
	local observer = Observer.new(services.Players, services.Workspace)
	local session = Session.new({
		historyLimit = Config.SESSION_HISTORY_LIMIT,
		authorized = options.sessionPersistenceAuthorized == true,
		store = options.sessionStore,
	})
	local scanner = Scanner.new(observer, { maxInstances = Config.SCAN_MAX_INSTANCES })
	local adaptive = Adaptive.new(services.UserInputService, services.Workspace)
	local notifications = Notifications.new(playerGui, Config.THEME)
	local renderer = Renderer3D.new(services.Workspace, services.RunService, observer, {
		maxVisuals = Config.SCAN_MAX_VISUALS,
	})
	local minimap = Minimap2D.new(playerGui, services.RunService, observer, {
		radius = Config.MINIMAP_RADIUS_STUDS,
		refreshSeconds = Config.MINIMAP_REFRESH_SECONDS,
		maxVisuals = Config.SCAN_MAX_VISUALS,
	})

	local scanLimit = Config.SCAN_MAX_INSTANCES
	local compactScanLimit = math.max(1, math.floor(Config.SCAN_MAX_INSTANCES / 3))
	local visualEnabled = false
	local core = Core.new(logger)
	local menu

	menu = Menu.new({
		playerGui = playerGui,
		config = Config,
		adaptive = adaptive,
		onScan = function()
			local ok, result = pcall(scanner.Scan, scanner)
			if not ok then
				logger:Error("Auto Scan falló", tostring(result))
				notifications:Show("No se pudo completar el escaneo: " .. tostring(result), 6, "error")
				return
			end
			session:RecordScan(result)
			renderer:SetData(result)
			minimap:SetData(result)
			menu:ShowResults(result)
			local summary = result.summary
			notifications:Show(string.format(
				"Escaneo observacional: %d elementos; %d detectados, %d estimados, %d desconocidos.",
				summary.total,
				summary.detected,
				summary.estimated,
				summary.unknown
			), 6, "success")
		end,
		onToggleVisuals = function()
			visualEnabled = not visualEnabled
			renderer:SetEnabled(visualEnabled)
			minimap:SetEnabled(visualEnabled)
			notifications:Show(
				visualEnabled
					and (scanner:GetLastResult() ~= nil
						and "Visualización 3D + minimapa activados."
						or "Visualizaciones activadas; el minimapa se centra en el jugador hasta el primer escaneo.")
					or "Visualizaciones desactivadas.",
				4,
				"info"
			)
			return visualEnabled
		end,
		onToggleBudget = function()
			if scanLimit == Config.SCAN_MAX_INSTANCES then
				scanLimit = compactScanLimit
			else
				scanLimit = Config.SCAN_MAX_INSTANCES
			end
			scanner:SetMaxInstances(scanLimit)
			logger:Info("Límite de Auto Scan actualizado", scanLimit)
			return scanLimit
		end,
		getStatistics = function()
			local statistics = session:GetStatistics()
			local velocity = observer:GetCharacterVelocity(player)
			statistics.player = velocity ~= nil and { velocity = velocity.Magnitude } or nil
			return statistics
		end,
		getLogs = function(limit)
			return logger:GetHistory(limit)
		end,
		getStatuses = function()
			return core:GetStatuses()
		end,
		getTechniques = function()
			return Techniques.items
		end,
		onError = function(message, context)
			logger:Error(message, context)
			notifications:Show(message .. ": " .. context, 5, "error")
		end,
	})

	core:Register("logger", logger)
	core:Register("session", session)
	core:Register("technique-library", Techniques)
	core:Register("observer", observer)
	core:Register("scanner", scanner)
	core:Register("adaptive-ui", adaptive)
	core:Register("notifications", notifications)
	core:Register("renderer-3d", renderer)
	core:Register("minimap-2d", minimap)
	core:Register("menu", menu)

	local started, statuses = core:Start()
	for name, status in pairs(statuses) do
		if status == "failed" then
			logger:Warn("La aplicación se inició con un módulo no disponible", name)
		end
	end
	menu:RefreshStatuses()
	if notifications._started then
		notifications:Show(
			"Versión experimental. Usa solo en experiencias propias o autorizadas; el escaneo requiere confirmación.",
			7,
			"warning"
		)
	end
	if not started then
		logger:Warn("Inicio parcial: revisa el estado de los módulos.")
	end

	local app = {
		core = core,
		logger = logger,
		observer = observer,
		scanner = scanner,
		session = session,
	}
	local destroyed = false
	function app:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		if session:GetPersistenceStatus() == "available" then
			local saved, saveError = session:Save()
			if not saved then
				logger:Error("No se pudo guardar la sesión autorizada", saveError)
			end
		end
		core:Stop()
	end
	return app
end

return Main
