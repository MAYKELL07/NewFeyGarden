-- WateringCan.client.luau
-- LocalScript for WateringCan tool

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local tool = script.Parent

-- Wait for ToolAction RemoteEvent
local toolActionEvent = ReplicatedStorage:WaitForChild("ToolAction", 10)
if not toolActionEvent then
	warn("[WateringCan] ToolAction RemoteEvent not found!")
	return
end

print("[WateringCan] LocalScript loaded")

-- Handle tool activation
tool.Activated:Connect(function()
	local target = mouse.Target
	
	if target then
		print(string.format("[WateringCan] Activated - Target: %s", target:GetFullName()))
		
		-- Send to server
		toolActionEvent:FireServer("WateringCan", target, mouse.Hit.Position)
	else
		print("[WateringCan] Activated but no target")
	end
end)

print("[WateringCan] ✓ Ready to use")
