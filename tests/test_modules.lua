local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Root = ReplicatedStorage:WaitForChild("S23SmartTAS")

return function()
	local modules = {
		require(Root:WaitForChild("main")),
		require(Root:WaitForChild("core"):WaitForChild("init")),
		require(Root:WaitForChild("core"):WaitForChild("logger")),
		require(Root:WaitForChild("core"):WaitForChild("observer")),
		require(Root:WaitForChild("interface"):WaitForChild("menu")),
		require(Root:WaitForChild("interface"):WaitForChild("adaptive")),
		require(Root:WaitForChild("interface"):WaitForChild("notifications")),
		require(Root:WaitForChild("scanner"):WaitForChild("scanner")),
		require(Root:WaitForChild("scanner"):WaitForChild("map_analyzer")),
		require(Root:WaitForChild("visuals"):WaitForChild("renderer_3d")),
		require(Root:WaitForChild("visuals"):WaitForChild("minimap_2d")),
		require(Root:WaitForChild("data"):WaitForChild("session")),
		require(Root:WaitForChild("data"):WaitForChild("techniques")),
	}
	for index, module in ipairs(modules) do
		assert(type(module) == "table", "El módulo número " .. tostring(index) .. " no cargó")
	end
end
