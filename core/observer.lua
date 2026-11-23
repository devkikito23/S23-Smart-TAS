local Observer = {}
Observer.__index = Observer

function Observer.new(players, workspace)
	assert(players ~= nil and workspace ~= nil, "Observer requiere Players y Workspace")
	return setmetatable({
		_players = players,
		_workspace = workspace,
		_connections = {},
		_subscriptions = {},
		_started = false,
	}, Observer)
end

function Observer:Start()
	if self._started then
		return false, "already_started"
	end
	self._started = true
	return true
end

function Observer:GetPlayers()
	return self._players:GetPlayers()
end

function Observer:GetLocalPlayer()
	return self._players.LocalPlayer
end

function Observer:GetCharacter(player)
	if player == nil then
		return nil, "player_missing"
	end
	if player.Character == nil then
		return nil, "character_unavailable"
	end
	return player.Character
end

function Observer:GetWorkspaceDescendants()
	return self._workspace:GetDescendants()
end

function Observer:GetModelParts(model)
	if model == nil or type(model.IsA) ~= "function" or not model:IsA("Model") then
		return nil, "not_model"
	end
	local parts = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

function Observer:GetPartSnapshot(part)
	if part == nil or type(part.IsA) ~= "function" or not part:IsA("BasePart") then
		return nil, "not_basepart"
	end
	return {
		name = part.Name,
		className = part.ClassName,
		position = part.Position,
		size = part.Size,
		canCollide = part.CanCollide,
		transparency = part.Transparency,
	}
end

function Observer:GetCharacterPosition(player)
	local character, characterError = self:GetCharacter(player)
	if character == nil then
		return nil, characterError
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return nil, "root_part_unavailable"
	end
	return root.Position
end

function Observer:GetCharacterVelocity(player)
	if player == nil or player.Character == nil then
		return nil, "character_unavailable"
	end
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return nil, "root_part_unavailable"
	end
	return root.AssemblyLinearVelocity
end

function Observer:ConnectCharacterAdded(player, callback)
	assert(player ~= nil and type(callback) == "function", "Argumentos de conexión no válidos")
	for _, subscription in ipairs(self._subscriptions) do
		if subscription.kind == "character" and subscription.source == player
			and subscription.callback == callback and subscription.connection.Connected then
			return subscription.connection
		end
	end
	local connection = player.CharacterAdded:Connect(callback)
	table.insert(self._connections, connection)
	table.insert(self._subscriptions, {
		kind = "character",
		source = player,
		callback = callback,
		connection = connection,
	})
	return connection
end

function Observer:ConnectWorkspaceDescendantAdded(callback)
	assert(type(callback) == "function", "callback debe ser una función")
	for _, subscription in ipairs(self._subscriptions) do
		if subscription.kind == "workspace" and subscription.callback == callback
			and subscription.connection.Connected then
			return subscription.connection
		end
	end
	local connection = self._workspace.DescendantAdded:Connect(callback)
	table.insert(self._connections, connection)
	table.insert(self._subscriptions, {
		kind = "workspace",
		source = self._workspace,
		callback = callback,
		connection = connection,
	})
	return connection
end

function Observer:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._subscriptions)
	self._started = false
end

return Observer
