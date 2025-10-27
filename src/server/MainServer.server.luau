-- MainServer.server.luau
-- Main server initialization script for FeyGarden

print("🌿 FeyGarden Server Initializing...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for shared modules to load
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Load persistence first
local DataService = require(script.Parent.Persistence.DataService)

-- Load server modules (these create RemoteEvents on require)
local WeatherController = require(script.Parent.WeatherController)
local EconomyService = require(script.Parent.EconomyService)
local ToolServer = require(script.Parent.ToolServer)
local GardenManager = require(script.Parent.GardenManager)

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
print("🔧 Initializing server systems...")
WeatherController.Initialize()
print("  ✓ WeatherController initialized")
EconomyService.Initialize()
print("  ✓ EconomyService initialized")
GardenManager.Initialize()
print("  ✓ GardenManager initialized")
-- ToolServer initializes itself on require
print("  ✓ ToolServer initialized")

print("✨ FeyGarden Server Ready!")
print("📡 RemoteEvents status:")
print("  - PlantSeed:", ReplicatedStorage:FindFirstChild(Constants.EVENTS.PLANT_SEED) and "✓" or "✗")
print("  - HarvestPlant:", ReplicatedStorage:FindFirstChild(Constants.EVENTS.HARVEST_PLANT) and "✓" or "✗")
print("  - WeatherChanged:", ReplicatedStorage:FindFirstChild(Constants.EVENTS.WEATHER_CHANGED) and "✓" or "✗")
print("  - UpdateCurrency:", ReplicatedStorage:FindFirstChild(Constants.EVENTS.UPDATE_CURRENCY) and "✓" or "✗")
print("  - UpdateInventory:", ReplicatedStorage:FindFirstChild(Constants.EVENTS.UPDATE_INVENTORY) and "✓" or "✗")
print("  - BuySeed:", ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_SEED) and "✓" or "✗")
print("  - BuyPet:", ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_PET) and "✓" or "✗")
print("  - ToolAction:", ReplicatedStorage:FindFirstChild("ToolAction") and "✓" or "✗")
