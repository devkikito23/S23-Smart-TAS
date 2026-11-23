local ReplicatedStorage = game:GetService("ReplicatedStorage")
local appModule = ReplicatedStorage:WaitForChild("S23SmartTAS"):WaitForChild("main")
local Main = require(appModule)

local ok, appOrError = pcall(Main.Init)
if not ok then
	warn("S23 Smart TAS no pudo inicializarse: " .. tostring(appOrError))
	return
end

local app = appOrError
local destroyingConnection
destroyingConnection = script.Destroying:Connect(function()
	if destroyingConnection ~= nil then
		destroyingConnection:Disconnect()
		destroyingConnection = nil
	end
	app:Destroy()
end)
