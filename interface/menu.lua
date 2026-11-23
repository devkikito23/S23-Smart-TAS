local Menu = {}
Menu.__index = Menu

local function makeLabel(parent, text, size, color, fontSize)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color
	label.TextSize = fontSize or 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = parent
	return label
end

function Menu.new(dependencies)
	assert(dependencies ~= nil and dependencies.playerGui ~= nil, "Menu requiere PlayerGui")
	return setmetatable({
		_playerGui = dependencies.playerGui,
		_config = dependencies.config,
		_adaptive = dependencies.adaptive,
		_onScan = dependencies.onScan,
		_onToggleVisuals = dependencies.onToggleVisuals,
		_onToggleBudget = dependencies.onToggleBudget,
		_getStatistics = dependencies.getStatistics,
		_getLogs = dependencies.getLogs,
		_getStatuses = dependencies.getStatuses,
		_getTechniques = dependencies.getTechniques,
		_onError = dependencies.onError,
		_connections = {},
		_gui = nil,
		_panel = nil,
		_body = nil,
		_floatingButton = nil,
		_visualsEnabled = false,
		_scanResult = nil,
		_confirmationOpen = false,
		_started = false,
	}, Menu)
end

function Menu:_connect(button, callback)
	local connection
	connection = button.Activated:Connect(function()
		local ok, err = pcall(callback)
		if not ok and type(self._onError) == "function" then
			self._onError("Error de interfaz", tostring(err))
		end
	end)
	table.insert(self._connections, connection)
	button.Destroying:Once(function()
		connection:Disconnect()
		for index, existing in ipairs(self._connections) do
			if existing == connection then
				table.remove(self._connections, index)
				break
			end
		end
	end)
	return connection
end

function Menu:_disconnect(connection)
	if connection == nil then
		return
	end
	connection:Disconnect()
	for index, existing in ipairs(self._connections) do
		if existing == connection then
			table.remove(self._connections, index)
			break
		end
	end
end

function Menu:_clearBody()
	for _, child in ipairs(self._body:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

function Menu:_addParagraph(text, color)
	local label = makeLabel(self._body, text, UDim2.new(1, -8, 0, 0), color or self._config.THEME.text, 13)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, -8, 0, 24)
	return label
end

function Menu:_showConfirmation()
	if self._confirmationOpen then
		return
	end
	self._confirmationOpen = true
	local overlay = Instance.new("Frame")
	overlay.Name = "ScanConfirmation"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.ZIndex = 5
	overlay.Parent = self._gui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.new(0.85, 0, 0, 190)
	card.BackgroundColor3 = self._config.THEME.panel
	card.BorderSizePixel = 0
	card.ZIndex = 6
	card.Parent = overlay
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local message = makeLabel(
		card,
		"El escaneo leerá partes del Workspace con transparencia menor a 1. Confirma que tienes permiso para analizar esta experiencia. No modifica el mundo.",
		UDim2.new(1, -28, 0, 105),
		self._config.THEME.text,
		14
	)
	message.Position = UDim2.new(0, 14, 0, 14)
	message.ZIndex = 7

	local function makeChoice(text, xScale, color)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0.46, 0, 0, 42)
		button.Position = UDim2.new(xScale, 0, 1, -54)
		button.BackgroundColor3 = color
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.Text = text
		button.TextColor3 = self._config.THEME.text
		button.TextSize = 13
		button.ZIndex = 7
		button.Parent = card
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button
		return button
	end

	local confirm = makeChoice("Confirmar escaneo", 0.03, self._config.THEME.accent)
	local cancel = makeChoice("Cancelar", 0.51, self._config.THEME.blue)
	local confirmConnection
	local cancelConnection
	local function closeConfirmation()
		self:_disconnect(confirmConnection)
		self:_disconnect(cancelConnection)
		self._confirmationOpen = false
		overlay:Destroy()
	end
	confirmConnection = self:_connect(confirm, function()
		closeConfirmation()
		self._onScan()
	end)
	cancelConnection = self:_connect(cancel, function()
		closeConfirmation()
	end)
end

function Menu:_showHome()
	self:_clearBody()
	self:_addParagraph("Estado de módulos", self._config.THEME.cyan)
	local statuses = self._getStatuses()
	for name, status in pairs(statuses) do
		self:_addParagraph(name .. "  ·  " .. status, self._config.THEME.muted)
	end
	self:_addParagraph("")
	self:_addParagraph("Compatibilidad: APIs estándar de Roblox; sin APIs ni cargador de Delta.")
	self:_addParagraph("Permiso: analiza únicamente experiencias propias o autorizadas. Modo experimental.")
end

function Menu:_showStatistics()
	self:_clearBody()
	self:_addParagraph("Estadísticas observadas", self._config.THEME.cyan)
	local statistics = self._getStatistics()
	self:_addParagraph("Escaneos registrados en esta sesión: " .. tostring(statistics.scanCount))
	self:_addParagraph("Persistencia: " .. tostring(statistics.persistence))

	local player = statistics.player
	if player ~= nil and player.velocity ~= nil then
		self:_addParagraph(string.format("Velocidad observada ahora: %.2f studs/s", player.velocity))
	else
		self:_addParagraph("Velocidad observada: desconocida (personaje no disponible).", self._config.THEME.muted)
	end

	local lastScan = statistics.lastScan
	if lastScan ~= nil then
		local summary = lastScan.summary
		self:_addParagraph(string.format(
			"Último escaneo: %d elementos; %d detected, %d estimated, %d unknown.",
			summary.total,
			summary.detected,
			summary.estimated,
			summary.unknown
		))
		self:_addParagraph("Tiempo de recorrido: desconocido; no existe estimador verificado en v0.1.0.", self._config.THEME.warning)
	else
		self:_addParagraph("Todavía no hay resultados. Las estadísticas no se simulan.", self._config.THEME.muted)
	end
end

function Menu:_showSettings()
	self:_clearBody()
	self:_addParagraph("Configuración de recursos", self._config.THEME.cyan)
	self:_addParagraph("El límite controla cuántas instancias inspecciona el próximo Auto Scan. Un límite menor puede omitir geometría.")
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1, -8, 0, 40)
	toggle.BackgroundColor3 = self._config.THEME.blue
	toggle.BorderSizePixel = 0
	toggle.Font = Enum.Font.GothamBold
	toggle.Text = "Alternar límite de escaneo"
	toggle.TextColor3 = self._config.THEME.text
	toggle.TextSize = 12
	toggle.Parent = self._body
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toggle
	self:_connect(toggle, function()
		local value = self._onToggleBudget()
		self:_showSettings()
		self:_addParagraph("Límite aplicado: " .. tostring(value) .. " instancias.", self._config.THEME.success)
	end)
end

function Menu:_showLogs()
	self:_clearBody()
	self:_addParagraph("Registro reciente", self._config.THEME.cyan)
	local entries = self._getLogs(30)
	if #entries == 0 then
		self:_addParagraph("No hay entradas de registro.", self._config.THEME.muted)
		return
	end
	for index = #entries, 1, -1 do
		local entry = entries[index]
		local context = entry.context ~= nil and (" · " .. tostring(entry.context)) or ""
		self:_addParagraph(os.date("%H:%M:%S", entry.time) .. " [" .. entry.level .. "] " .. entry.message .. context)
	end
end

function Menu:_showHelp()
	self:_clearBody()
	self:_addParagraph("Alcance y compatibilidad", self._config.THEME.cyan)
	self:_addParagraph("Observa únicamente Players, Workspace y geometría visible mediante APIs públicas de Roblox.")
	self:_addParagraph("No inyecta código, evita seguridad, altera movimiento ni automatiza controles.")
	self:_addParagraph("El escaneo requiere confirmación explícita. Respeta las reglas y permisos de cada experiencia.")
	self:_addParagraph("La clasificación geométrica es heurística; detected se limita a marcas SmartTAS_Type explícitas.")
	for _, technique in ipairs(self._getTechniques()) do
		self:_addParagraph("Técnica no confirmada: " .. technique.name .. " · " .. technique.status, self._config.THEME.muted)
	end
end

function Menu:ShowResults(result)
	self._scanResult = result
	self:_clearBody()
	local summary = result.summary
	self:_addParagraph("Resultado observacional · " .. os.date("%H:%M:%S", result.observedAt), self._config.THEME.cyan)
	self:_addParagraph(string.format(
		"%d elementos: %d detected, %d estimated, %d unknown.",
		summary.total,
		summary.detected,
		summary.estimated,
		summary.unknown
	))
	self:_addParagraph(string.format(
		"Plataformas: %d · obstáculos: %d · checkpoints: %d",
		summary.platforms,
		summary.obstacles,
		summary.checkpoints
	))
	if summary.truncated then
		self:_addParagraph("Escaneo limitado: se alcanzó el presupuesto de instancias. Puede faltar geometría.", self._config.THEME.warning)
	end
	self:_addParagraph("Estimación de tiempo: desconocida. Ruta óptima: no calculada.", self._config.THEME.warning)
	self:_addParagraph("Los roles inferidos se marcan estimated; los desconocidos no se completan por suposición.")
	local displayLimit = math.min(#result.items, 80)
	for index = 1, displayLimit do
		local item = result.items[index]
		self:_addParagraph(item.status .. " · " .. item.kind .. " · " .. item.name, self._config.THEME.muted)
	end
	if #result.items > displayLimit then
		self:_addParagraph(string.format("Se muestran %d de %d elementos para mantener la interfaz ligera.", displayLimit, #result.items), self._config.THEME.muted)
	end
end

function Menu:Start()
	if self._started then
		return false, "already_started"
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "S23SmartTASMenu"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 40
	gui.Parent = self._playerGui
	self._gui = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = self._config.THEME.background
	panel.BorderSizePixel = 0
	panel.Visible = true
	panel.Parent = gui
	self._panel = panel
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = panel
	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = self._config.THEME.accent
	panelStroke.Transparency = 0.25
	panelStroke.Parent = panel

	local title = makeLabel(panel, "S23 SMART TAS  ·  v" .. self._config.VERSION, UDim2.new(1, -52, 0, 25), self._config.THEME.text, 15)
	title.Position = UDim2.new(0, 14, 0, 10)
	title.Font = Enum.Font.GothamBold
	local subtitle = makeLabel(panel, "EXPERIMENTAL · solo experiencias autorizadas", UDim2.new(1, -24, 0, 20), self._config.THEME.warning, 10)
	subtitle.Position = UDim2.new(0, 14, 0, 38)

	local floating
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(30, 30)
	close.Position = UDim2.new(1, -40, 0, 8)
	close.BackgroundColor3 = self._config.THEME.panel
	close.BorderSizePixel = 0
	close.Font = Enum.Font.GothamBold
	close.Text = "×"
	close.TextColor3 = self._config.THEME.text
	close.TextSize = 20
	close.Parent = panel
	self:_connect(close, function()
		panel.Visible = false
		floating.Visible = true
	end)

	local body = Instance.new("ScrollingFrame")
	body.Name = "Content"
	body.Position = UDim2.new(0, 14, 0, 66)
	body.Size = UDim2.new(1, -28, 1, -190)
	body.BackgroundColor3 = self._config.THEME.panel
	body.BackgroundTransparency = 0.15
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 4
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.CanvasSize = UDim2.new()
	body.Parent = panel
	self._body = body
	local bodyCorner = Instance.new("UICorner")
	bodyCorner.CornerRadius = UDim.new(0, 9)
	bodyCorner.Parent = body
	local bodyPadding = Instance.new("UIPadding")
	bodyPadding.PaddingTop = UDim.new(0, 10)
	bodyPadding.PaddingBottom = UDim.new(0, 10)
	bodyPadding.PaddingLeft = UDim.new(0, 10)
	bodyPadding.PaddingRight = UDim.new(0, 6)
	bodyPadding.Parent = body
	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.Padding = UDim.new(0, 7)
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.Parent = body

	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.BackgroundTransparency = 1
	controls.Position = UDim2.new(0, 14, 1, -116)
	controls.Size = UDim2.new(1, -28, 0, 104)
	controls.Parent = panel
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(8, 7)
	grid.CellSize = UDim2.new(0.5, -4, 0, 30)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = controls

	local function addButton(name, text, color, callback)
		local button = Instance.new("TextButton")
		button.Name = name
		button.BackgroundColor3 = color
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.Text = text
		button.TextColor3 = self._config.THEME.text
		button.TextSize = 11
		button.TextWrapped = true
		button.Parent = controls
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 7)
		corner.Parent = button
		self:_connect(button, callback)
		return button
	end

	floating = Instance.new("TextButton")
	floating.Name = "FloatingToggle"
	floating.Size = UDim2.fromOffset(48, 48)
	floating.BackgroundColor3 = self._config.THEME.accent
	floating.BorderSizePixel = 0
	floating.Font = Enum.Font.GothamBold
	floating.Text = "TAS"
	floating.TextColor3 = self._config.THEME.text
	floating.TextSize = 12
	floating.Visible = false
	floating.Parent = gui
	local floatingCorner = Instance.new("UICorner")
	floatingCorner.CornerRadius = UDim.new(1, 0)
	floatingCorner.Parent = floating
	self:_connect(floating, function()
		panel.Visible = not panel.Visible
		floating.Visible = not panel.Visible
	end)

	self._floatingButton = floating
	self._adaptive:Bind(gui, panel, floating)

	addButton("AutoScan", "Auto Scan", self._config.THEME.accent, function()
		self:_showConfirmation()
	end)
	addButton("Visuals", "Panel visual 3D + 2D", self._config.THEME.blue, function()
		self._visualsEnabled = self._onToggleVisuals()
		self:_showHome()
	end)
	addButton("Statistics", "Estadísticas", self._config.THEME.panel, function()
		self:_showStatistics()
	end)
	addButton("Settings", "Configuración", self._config.THEME.panel, function()
		self:_showSettings()
	end)
	addButton("Logs", "Registro", self._config.THEME.panel, function()
		self:_showLogs()
	end)
	addButton("Help", "Permisos y ayuda", self._config.THEME.panel, function()
		self:_showHelp()
	end)
	self._started = true
	self:_showHome()
	return true
end

function Menu:RefreshStatuses()
	if self._started then
		self:_showHome()
	end
end

function Menu:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._gui ~= nil then
		self._gui:Destroy()
		self._gui = nil
	end
	self._panel = nil
	self._body = nil
	self._floatingButton = nil
	self._confirmationOpen = false
	self._started = false
end

return Menu
