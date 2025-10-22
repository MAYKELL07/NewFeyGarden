-- MainServer.server.luau
-- Main server initialization script for FeyGarden

print("🌿 FeyGarden Server Initializing...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to load
local Constants = require(ReplicatedStorage.Shared.Constants)

-- Load server modules
local WeatherController = require(script.Parent.WeatherController)
local GardenManager = require(script.Parent.GardenManager)
local EconomyService = require(script.Parent.EconomyService)

-- Initialize all systems
WeatherController.Initialize()
EconomyService.Initialize()
GardenManager.Initialize()

print("✨ FeyGarden Server Ready!")
