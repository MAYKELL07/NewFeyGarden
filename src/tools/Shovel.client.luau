-- Shovel.client.luau
-- LocalScript for Shovel tool

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local tool = script.Parent

-- Wait for ToolAction RemoteEvent
local toolActionEvent = ReplicatedStorage:WaitForChild("ToolAction", 10)
if not toolActionEvent then
	warn("[Shovel] ToolAction RemoteEvent not found!")
	return
end

-- Handle tool activation
tool.Activated:Connect(function()
	local target = mouse.Target
	
	if target then
		-- Send to server
		toolActionEvent:FireServer("Shovel", target, mouse.Hit.Position)
	end
end)
