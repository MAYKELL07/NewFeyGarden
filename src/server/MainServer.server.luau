-- MainServer.server.luau
-- Main server initialization script for FeyGarden

print("🌿 FeyGarden Server Initializing...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for shared modules to load
local Constants = require(ReplicatedStorage.Shared.Constants)
local Config = require(ReplicatedStorage.Shared.Config)

-- Load persistence first
local DataService = require(script.Parent.Persistence.DataService)

-- Load server modules
local WeatherController = require(script.Parent.WeatherController)
local GardenManager = require(script.Parent.GardenManager)
local EconomyService = require(script.Parent.EconomyService)
local ToolServer = require(script.Parent.ToolServer)

-- Create leaderstats for players
Players.PlayerAdded:Connect(function(player)
	print("MainServer: Setting up leaderstats for", player.Name)
	
	-- Wait a moment for DataService to load profile
	task.wait(0.5)
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = Config.Economy.CurrencyName or "Coins"
	coinsValue.Value = DataService.GetCoins(player.UserId)
	coinsValue.Parent = leaderstats
	
	-- Update leaderstats when coins change
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		-- Poll for coin changes every second (simple approach)
		task.spawn(function()
			while player.Parent and profile do
				task.wait(1)
				local currentCoins = DataService.GetCoins(player.UserId)
				if coinsValue.Value ~= currentCoins then
					coinsValue.Value = currentCoins
				end
			end
		end)
	end
end)

-- Initialize all systems
WeatherController.Initialize()
EconomyService.Initialize()
GardenManager.Initialize()
-- ToolServer initializes itself on require

print("✨ FeyGarden Server Ready!")
