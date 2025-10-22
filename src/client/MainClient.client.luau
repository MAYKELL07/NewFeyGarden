-- MainClient.client.luau
-- Main client initialization script for FeyGarden

print("🌿 FeyGarden Client Initializing...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- Load client modules
local PetController = require(script.Parent.PetController)
local UIHandler = require(script.Parent.UIHandler)

-- Wait for character to load
local player = game.Players.LocalPlayer
player.CharacterAdded:Wait()

-- Initialize client systems
task.wait(1) -- Give server time to set up
UIHandler.Initialize()
PetController.Initialize()

-- Load admin UI (will only show for admins)
task.spawn(function()
	local success, err = pcall(function()
		require(script.Parent.AdminUI)
	end)
	if not success then
		warn("Admin UI failed to load:", err)
	end
end)

print("✨ FeyGarden Client Ready!")
