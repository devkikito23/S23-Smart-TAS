local Renderer3D = {}
Renderer3D.__index = Renderer3D

local COLORS = {
	platform = Color3.fromRGB(55, 145, 255),
	obstacle = Color3.fromRGB(255, 96, 116),
	checkpoint = Color3.fromRGB(56, 220, 230),
	unknown = Color3.fromRGB(166, 170, 192),
}

function Renderer3D.new(workspace, runService, observer, options)
	assert(workspace ~= nil and runService ~= nil and observer ~= nil, "Renderer3D requiere dependencias")
	options = options or {}
	local maxVisuals = options.maxVisuals or 160
	assert(type(maxVisuals) == "number" and maxVisuals >= 1 and maxVisuals % 1 == 0, "maxVisuals no es válido")
	return setmetatable({
		_workspace = workspace,
		_runService = runService,
		_observer = observer,
		_maxVisuals = maxVisuals,
		_result = nil,
		_enabled = false,
		_folder = nil,
		_playerMarker = nil,
		_connections = {},
		_started = false,
	}, Renderer3D)
end

function Renderer3D:_ensureFolder()
	if self._folder ~= nil and self._folder.Parent ~= nil then
		return true
	end
	local camera = self._workspace.CurrentCamera
	if camera == nil then
		return false
	end
	local folder = Instance.new("Folder")
	folder.Name = "S23SmartTASLocalVisuals"
	folder.Parent = camera
	self._folder = folder
	return true
end

function Renderer3D:_clearDrawings()
	if self._folder ~= nil then
		for _, child in ipairs(self._folder:GetChildren()) do
			child:Destroy()
		end
	end
	self._playerMarker = nil
end

function Renderer3D:_draw()
	if not self._enabled or not self:_ensureFolder() then
		return
	end
	self:_clearDrawings()

	local count = 0
	if self._result ~= nil then
		for _, item in ipairs(self._result.items) do
			if count >= self._maxVisuals then
				break
			end
			if item.instance ~= nil and item.instance:IsA("BasePart") then
				local adornment = Instance.new("BoxHandleAdornment")
				adornment.Name = "ObservedGeometry"
				adornment.Adornee = item.instance
				adornment.Size = item.size
				adornment.Color3 = COLORS[item.kind] or COLORS.unknown
				adornment.Transparency = item.status == "detected" and 0.25
					or (item.status == "estimated" and 0.58 or 0.8)
				adornment.AlwaysOnTop = true
				adornment.ZIndex = item.status == "detected" and 2 or 1
				adornment.Parent = self._folder
				count = count + 1
			end
		end
	end

	local marker = Instance.new("Part")
	marker.Name = "ObservedPlayerPosition"
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.new(0.8, 0.8, 0.8)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Material = Enum.Material.Neon
	marker.Color = Color3.fromRGB(56, 220, 230)
	marker.Transparency = 0.15
	marker.Parent = self._folder
	self._playerMarker = marker
	self:_updatePlayerMarker()
end

function Renderer3D:_updatePlayerMarker()
	if self._playerMarker == nil or self._playerMarker.Parent == nil then
		return
	end
	local player = self._observer:GetLocalPlayer()
	local position = self._observer:GetCharacterPosition(player)
	if position ~= nil then
		self._playerMarker.Position = position
	end
end

function Renderer3D:SetData(result)
	assert(type(result) == "table" and type(result.items) == "table", "Datos visuales no válidos")
	self._result = result
	self:_draw()
end

function Renderer3D:SetEnabled(enabled)
	self._enabled = enabled == true
	if self._enabled then
		self:_draw()
	elseif self._folder ~= nil then
		self._folder:Destroy()
		self._folder = nil
		self._playerMarker = nil
	else
		self:_clearDrawings()
	end
	return self._enabled
end

function Renderer3D:Start()
	if self._started then
		return false, "already_started"
	end
	self._started = true
	table.insert(self._connections, self._runService.Heartbeat:Connect(function()
		self:_updatePlayerMarker()
	end))
	table.insert(self._connections, self._workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if self._folder ~= nil then
			self._folder:Destroy()
			self._folder = nil
			self._playerMarker = nil
		end
		self:_draw()
	end))
	return true
end

function Renderer3D:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._folder ~= nil then
		self._folder:Destroy()
		self._folder = nil
	end
	self._playerMarker = nil
	self._enabled = false
	self._started = false
end

return Renderer3D
