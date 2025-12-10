-- WateringCan.client.luau
-- LocalScript for WateringCan tool

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local tool = script.Parent

-- Wait for ToolAction RemoteEvent
local toolActionEvent = ReplicatedStorage:WaitForChild("ToolAction", 20)
if not toolActionEvent then
	warn("[WateringCan] ToolAction RemoteEvent not found; tool disabled")
	return
end

-- Handle tool activation
tool.Activated:Connect(function()
	local target = mouse.Target
	
	if target then
		-- Send to server
		toolActionEvent:FireServer("WateringCan", target, mouse.Hit.Position)
	end
	end)
