-- MainClient.client.luau
-- Main client initialization script for FeyGarden

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[MainClient] Shared folder missing; aborting client init")
	return
end

local okConstants, Constants = pcall(function()
	return require(sharedFolder:WaitForChild("Constants", 5))
end)
if not okConstants or not Constants then
	warn("[MainClient] Failed to load Constants; aborting client init")
	return
end

-- Load client modules
local PetController = require(script.Parent.PetController)
local BuffParticles = require(script.Parent.BuffParticles)
local PlantingHandler = require(script.Parent.PlantingHandler)
local NPCUIHandler = require(script.Parent.NPCUIHandler)
local TutorialUI = require(script.Parent.TutorialUI)
local EggOpeningUI = require(script.Parent.EggOpeningUI)
local ToolController = require(script.Parent.ToolController)

-- New modular UI system (falls back to legacy UIHandler inside PlantingHandler if needed)
local UI
local okUI, uiModule = pcall(function()
	return require(script.Parent:WaitForChild("UI"):WaitForChild("init"))
end)
if okUI and uiModule then
	UI = uiModule
end

-- Wait for character to load
local player = game.Players.LocalPlayer
player.CharacterAdded:Wait()

-- Initialize client systems
task.wait(1) -- Give server time to set up

if UI and UI.Controller then
	UI.Initialize()
	UI.Controller.SetToolController(ToolController)
else
	warn("[MainClient] UI module missing; UIHandler fallback used by PlantingHandler")
end

NPCUIHandler.Initialize()
TutorialUI.Initialize()
PetController.Initialize()
BuffParticles.Initialize()
PlantingHandler.Initialize()
EggOpeningUI.Initialize()

-- Check if new player and show tutorial
TutorialUI.CheckShowTutorial()
