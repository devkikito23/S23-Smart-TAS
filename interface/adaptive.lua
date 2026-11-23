local Adaptive = {}
Adaptive.__index = Adaptive

function Adaptive.new(userInputService, workspace)
	assert(userInputService ~= nil and workspace ~= nil, "Adaptive requiere UserInputService y Workspace")
	return setmetatable({
		_userInputService = userInputService,
		_workspace = workspace,
		_connections = {},
		_viewportConnection = nil,
		_gui = nil,
		_panel = nil,
		_floatingButton = nil,
		_started = false,
	}, Adaptive)
end

function Adaptive.ClassifyViewport(width, touchEnabled)
	if type(width) ~= "number" or width <= 0 then
		return "desktop"
	end
	if touchEnabled == true or width < 640 then
		return "mobile"
	end
	return "desktop"
end

function Adaptive:Bind(gui, panel, floatingButton)
	assert(gui ~= nil and panel ~= nil and floatingButton ~= nil, "Adaptive requiere los elementos de interfaz")
	self._gui = gui
	self._panel = panel
	self._floatingButton = floatingButton
	self:Apply()
end

function Adaptive:Apply()
	if self._gui == nil or self._panel == nil then
		return false
	end

	local camera = self._workspace.CurrentCamera
	local width = camera and camera.ViewportSize.X or 1024
	local mode = Adaptive.ClassifyViewport(width, self._userInputService.TouchEnabled)
	if mode == "mobile" then
		self._panel.AnchorPoint = Vector2.new(0.5, 1)
		self._panel.Position = UDim2.new(0.5, 0, 1, -12)
		self._panel.Size = UDim2.new(1, -24, 0, 390)
		self._floatingButton.Position = UDim2.new(1, -18, 0, 18)
		self._floatingButton.AnchorPoint = Vector2.new(1, 0)
	else
		self._panel.AnchorPoint = Vector2.new(0, 0.5)
		self._panel.Position = UDim2.new(0, 18, 0.5, 0)
		self._panel.Size = UDim2.fromOffset(330, 510)
		self._floatingButton.Position = UDim2.new(0, 18, 0, 18)
		self._floatingButton.AnchorPoint = Vector2.new(0, 0)
	end
	return true
end

function Adaptive:Start()
	if self._started then
		return false, "already_started"
	end
	self._started = true
	local function watchCamera(camera)
		if self._viewportConnection ~= nil then
			self._viewportConnection:Disconnect()
			self._viewportConnection = nil
		end
		if camera ~= nil then
			self._viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				self:Apply()
			end)
		end
	end
	local cameraConnection = self._workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		self:Apply()
		watchCamera(self._workspace.CurrentCamera)
	end)
	table.insert(self._connections, cameraConnection)
	watchCamera(self._workspace.CurrentCamera)
	return true
end

function Adaptive:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._viewportConnection ~= nil then
		self._viewportConnection:Disconnect()
	end
	self._viewportConnection = nil
	self._started = false
end

return Adaptive
