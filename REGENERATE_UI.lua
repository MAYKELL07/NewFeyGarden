-- ============================================================================
-- UI REGENERATION SCRIPT
-- ============================================================================
-- INSTRUCTIONS:
-- 1. Open your game in Roblox Studio
-- 2. Open the Command Bar (View > Command Bar)
-- 3. Copy and paste the code below into the Command Bar
-- 4. Press Enter to run it
-- ============================================================================

-- First, delete the old UI
local StarterGui = game:GetService("StarterGui")
local oldUI = StarterGui:FindFirstChild("GardenUI")
if oldUI then
	oldUI:Destroy()
	print("✅ Deleted old UI")
end

-- Wait a moment
task.wait(0.1)

-- Create the new UI
local UISetup = require(game.ReplicatedStorage.Setup.UISetup)
UISetup.CreateUI()

print("✅ UI REGENERATED! Check StarterGui > GardenUI")
print("✅ You should now see the new 2-column layout!")
