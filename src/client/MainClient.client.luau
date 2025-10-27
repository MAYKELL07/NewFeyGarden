-- MainClient.client.luau
-- Main client initialization script for FeyGarden

print("🌿 FeyGarden Client Initializing...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- Load client modules
local PetController = require(script.Parent.PetController)
local UIHandler = require(script.Parent.UIHandler)
local BuffParticles = require(script.Parent.BuffParticles)

-- Wait for character to load
local player = game.Players.LocalPlayer
player.CharacterAdded:Wait()

-- Initialize client systems
task.wait(1) -- Give server time to set up
UIHandler.Initialize()
PetController.Initialize()
BuffParticles.Initialize()

print("✨ FeyGarden Client Ready!")
