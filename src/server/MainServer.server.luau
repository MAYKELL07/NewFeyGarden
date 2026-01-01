-- MainServer.server.luau
-- Main server initialization script for FeyGarden

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[MainServer] Shared folder missing; aborting server init")
	return
end

local okConstants, Constants = pcall(function()
	return require(sharedFolder:WaitForChild("Constants", 5))
end)
local okConfig, Config = pcall(function()
	return require(sharedFolder:WaitForChild("Config", 5))
end)

if not okConstants or not Constants or not okConfig or not Config then
	warn("[MainServer] Failed to load shared modules; aborting server init")
	return
end

-- Load persistence first
local DataService = require(script.Parent.Persistence.DataService)

-- Load server modules (these create RemoteEvents on require)
local WeatherController = require(script.Parent.WeatherController)
local EconomyService = require(script.Parent.EconomyService)
local ToolServer = require(script.Parent.ToolServer)
local GardenManager = require(script.Parent.GardenManager)
local ShopService = require(script.Parent.ShopService)
local TradingService = require(script.Parent.TradingService)

-- Create leaderstats for players
Players.PlayerAdded:Connect(function(player)
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
ShopService.Initialize() -- Must be before EconomyService so shop inventory is ready
EconomyService.Initialize()
GardenManager.Initialize()
TradingService.Initialize(DataService)
