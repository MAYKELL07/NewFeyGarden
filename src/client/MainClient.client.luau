-- MainClient.client.luau
-- Main client initialization script for FeyGarden

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- Load client modules
local PetController = require(script.Parent.PetController)
local UIHandler = require(script.Parent.UIHandler)
local BuffParticles = require(script.Parent.BuffParticles)
local PlantingHandler = require(script.Parent.PlantingHandler)
local NPCUIHandler = require(script.Parent.NPCUIHandler)
local TutorialUI = require(script.Parent.TutorialUI)

-- Wait for character to load
local player = game.Players.LocalPlayer
player.CharacterAdded:Wait()

-- Initialize client systems
task.wait(1) -- Give server time to set up
UIHandler.Initialize()
NPCUIHandler.Initialize()
TutorialUI.Initialize()
PetController.Initialize()
BuffParticles.Initialize()
PlantingHandler.Initialize()

-- Check if new player and show tutorial
TutorialUI.CheckShowTutorial()
