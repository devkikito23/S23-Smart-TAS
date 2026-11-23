local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(playerGui, theme)
	assert(playerGui ~= nil, "Notifications requiere PlayerGui")
	return setmetatable({
		_playerGui = playerGui,
		_theme = theme,
		_gui = nil,
		_container = nil,
		_started = false,
		_active = {},
	}, Notifications)
end

function Notifications:Start()
	if self._started then
		return false, "already_started"
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "S23SmartTASNotifications"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 51
	gui.Parent = self._playerGui
	self._gui = gui

	local container = Instance.new("Frame")
	container.Name = "Notifications"
	container.BackgroundTransparency = 1
	container.AnchorPoint = Vector2.new(1, 0)
	container.Position = UDim2.new(1, -18, 0, 70)
	container.Size = UDim2.fromOffset(300, 360)
	container.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	self._container = container
	self._started = true
	return true
end

function Notifications:Show(message, duration, kind)
	assert(type(message) == "string" and message ~= "", "La notificación requiere un mensaje")
	if not self._started then
		return false, "not_started"
	end
	while #self._active >= 5 do
		local oldest = table.remove(self._active, 1)
		if oldest.Parent ~= nil then
			oldest:Destroy()
		end
	end

	local colors = {
		info = self._theme.blue,
		success = self._theme.success,
		warning = self._theme.warning,
		error = self._theme.error,
	}
	local card = Instance.new("TextLabel")
	card.Name = "Notification"
	card.LayoutOrder = #self._active + 1
	card.Size = UDim2.new(1, 0, 0, 56)
	card.BackgroundColor3 = self._theme.panel
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.Font = Enum.Font.Gotham
	card.Text = message
	card.TextColor3 = self._theme.text
	card.TextSize = 13
	card.TextWrapped = true
	card.Parent = self._container

	local stripe = Instance.new("Frame")
	stripe.Name = "Accent"
	stripe.BackgroundColor3 = colors[kind] or colors.info
	stripe.BorderSizePixel = 0
	stripe.Size = UDim2.new(0, 4, 1, 0)
	stripe.Parent = card
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	table.insert(self._active, card)
	local lifetime = type(duration) == "number" and math.max(1, duration) or 4
	task.delay(lifetime, function()
		if card.Parent ~= nil then
			card:Destroy()
		end
		for index, activeCard in ipairs(self._active) do
			if activeCard == card then
				table.remove(self._active, index)
				break
			end
		end
	end)
	return true
end

function Notifications:Stop()
	for _, card in ipairs(self._active) do
		if card.Parent ~= nil then
			card:Destroy()
		end
	end
	table.clear(self._active)
	if self._gui ~= nil then
		self._gui:Destroy()
		self._gui = nil
	end
	self._container = nil
	self._started = false
end

return Notifications
