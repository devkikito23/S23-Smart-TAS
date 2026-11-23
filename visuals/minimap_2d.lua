local Minimap2D = {}
Minimap2D.__index = Minimap2D

local COLORS = {
	platform = Color3.fromRGB(55, 145, 255),
	obstacle = Color3.fromRGB(255, 96, 116),
	checkpoint = Color3.fromRGB(56, 220, 230),
	unknown = Color3.fromRGB(166, 170, 192),
}

function Minimap2D.new(playerGui, runService, observer, options)
	assert(playerGui ~= nil and runService ~= nil and observer ~= nil, "Minimap2D requiere dependencias")
	options = options or {}
	local radius = options.radius or 100
	local refreshSeconds = options.refreshSeconds or 0.15
	local maxVisuals = options.maxVisuals or 160
	assert(type(radius) == "number" and radius > 0, "radius debe ser positivo")
	assert(type(refreshSeconds) == "number" and refreshSeconds > 0, "refreshSeconds debe ser positivo")
	assert(type(maxVisuals) == "number" and maxVisuals >= 1 and maxVisuals % 1 == 0, "maxVisuals no es válido")
	return setmetatable({
		_playerGui = playerGui,
		_runService = runService,
		_observer = observer,
		_radius = radius,
		_refreshSeconds = refreshSeconds,
		_maxVisuals = maxVisuals,
		_result = nil,
		_enabled = false,
		_gui = nil,
		_map = nil,
		_playerDot = nil,
		_markers = {},
		_connections = {},
		_elapsed = 0,
		_started = false,
	}, Minimap2D)
end

function Minimap2D:_build()
	if self._gui ~= nil then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "S23SmartTASMinimap"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	gui.Enabled = self._enabled
	gui.Parent = self._playerGui

	local map = Instance.new("Frame")
	map.Name = "Map"
	map.AnchorPoint = Vector2.new(1, 0)
	map.Position = UDim2.new(1, -18, 0, 18)
	map.Size = UDim2.fromOffset(164, 164)
	map.BackgroundColor3 = Color3.fromRGB(17, 18, 30)
	map.BackgroundTransparency = 0.12
	map.BorderSizePixel = 0
	map.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = map
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(56, 220, 230)
	border.Transparency = 0.3
	border.Parent = map

	local center = Instance.new("Frame")
	center.Name = "ObservedPlayer"
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.Position = UDim2.fromScale(0.5, 0.5)
	center.Size = UDim2.fromOffset(10, 10)
	center.BackgroundColor3 = Color3.fromRGB(56, 220, 230)
	center.BorderSizePixel = 0
	center.Parent = map
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = center

	local label = Instance.new("TextLabel")
	label.Name = "Legend"
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 8, 0, 5)
	label.Size = UDim2.new(1, -16, 0, 18)
	label.Font = Enum.Font.Gotham
	label.Text = "Minimapa · X/Z"
	label.TextColor3 = Color3.fromRGB(240, 241, 255)
	label.TextSize = 10
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = map

	self._gui = gui
	self._map = map
	self._playerDot = center
	self:_rebuildMarkers()
end

function Minimap2D:_rebuildMarkers()
	for _, marker in ipairs(self._markers) do
		marker:Destroy()
	end
	table.clear(self._markers)
	if self._map == nil or self._result == nil then
		return
	end

	local count = 0
	for _, item in ipairs(self._result.items) do
		if count >= self._maxVisuals then
			break
		end
		local marker = Instance.new("Frame")
		marker.Name = item.status .. "Marker"
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.Size = item.status == "detected" and UDim2.fromOffset(7, 7)
			or (item.status == "estimated" and UDim2.fromOffset(6, 6) or UDim2.fromOffset(8, 8))
		marker.BackgroundColor3 = COLORS[item.kind] or COLORS.unknown
		marker.BackgroundTransparency = item.status == "detected" and 0
			or (item.status == "estimated" and 0.35 or 0.65)
		marker.BorderSizePixel = 0
		marker.Parent = self._map
		if item.status ~= "unknown" then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = marker
		else
			local outline = Instance.new("UIStroke")
			outline.Color = COLORS.unknown
			outline.Thickness = 1
			outline.Parent = marker
		end
		table.insert(self._markers, marker)
		count = count + 1
	end
end

function Minimap2D:_updatePositions()
	if self._map == nil or self._result == nil then
		return
	end
	local player = self._observer:GetLocalPlayer()
	local origin = self._observer:GetCharacterPosition(player)
	if origin == nil then
		return
	end

	local half = self._map.AbsoluteSize.X / 2
	local usable = half - 12
	for index, item in ipairs(self._result.items) do
		local marker = self._markers[index]
		if marker ~= nil and marker.Parent ~= nil then
			local dx = (item.position.X - origin.X) / self._radius
			local dz = (item.position.Z - origin.Z) / self._radius
			dx = math.clamp(dx, -1, 1)
			dz = math.clamp(dz, -1, 1)
			marker.Position = UDim2.fromOffset(half + dx * usable, half + dz * usable)
		end
	end
end

function Minimap2D:SetData(result)
	assert(type(result) == "table" and type(result.items) == "table", "Datos del minimapa no válidos")
	self._result = result
	if self._map ~= nil then
		self:_rebuildMarkers()
		self:_updatePositions()
	end
end

function Minimap2D:SetEnabled(enabled)
	self._enabled = enabled == true
	if self._enabled then
		self:_build()
	elseif self._gui ~= nil then
		self._gui.Enabled = false
	end
	if self._gui ~= nil then
		self._gui.Enabled = self._enabled
	end
	return self._enabled
end

function Minimap2D:Start()
	if self._started then
		return false, "already_started"
	end
	self._started = true
	table.insert(self._connections, self._runService.Heartbeat:Connect(function(deltaTime)
		self._elapsed = self._elapsed + deltaTime
		if self._elapsed >= self._refreshSeconds then
			self._elapsed = 0
			self:_updatePositions()
		end
	end))
	return true
end

function Minimap2D:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._gui ~= nil then
		self._gui:Destroy()
		self._gui = nil
	end
	self._map = nil
	self._playerDot = nil
	table.clear(self._markers)
	self._started = false
	self._enabled = false
end

return Minimap2D
