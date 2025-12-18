-- Shovel.client.luau
-- DEPRECATED: Tools are now handled by ToolController.luau
-- Kept for compatibility; guard against old Backpack scripts throwing errors

local parent = script.Parent
if not parent or not parent:IsA("Tool") then
	warn("[Shovel] Legacy script parented to " .. (parent and parent.ClassName or "nil") .. "; skipping")
	return
end

-- No-op listener prevents "Activated is not a valid member of Backpack" when mis-parented
parent.Activated:Connect(function() end)

print("[Shovel] This script is deprecated - tools now use ToolController")
