-- AdminCommands.luau
-- Simple admin commands for testing FeyGarden

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminCommands = {}

-- List of admin user IDs (add your Roblox User ID here)
AdminCommands.AdminUsers = {
	-- Add admin user IDs here, e.g.:
	-- 123456789,
}

-- Check if player is admin
function AdminCommands.IsAdmin(player)
	-- In testing mode, everyone is admin
	if game:GetService("RunService"):IsStudio() then
		return true
	end
	
	for _, userId in ipairs(AdminCommands.AdminUsers) do
		if player.UserId == userId then
			return true
		end
	end
	
	return false
end

-- Add coins to player
function AdminCommands.AddCoins(player, amount)
	local EconomyService = require(script.Parent.Parent.server.EconomyService)
	EconomyService.AddCoins(player, amount)
	return true, "Added " .. amount .. " coins"
end

-- Remove coins from player
function AdminCommands.RemoveCoins(player, amount)
	local EconomyService = require(script.Parent.Parent.server.EconomyService)
	local success = EconomyService.RemoveCoins(player, amount)
	if success then
		return true, "Removed " .. amount .. " coins"
	else
		return false, "Not enough coins"
	end
end

-- Get player coins
function AdminCommands.GetCoins(player)
	local EconomyService = require(script.Parent.Parent.server.EconomyService)
	local coins = EconomyService.GetCoins(player)
	return true, player.Name .. " has " .. coins .. " coins"
end

-- Add seeds to player
function AdminCommands.AddSeeds(player, plantType, amount)
	local Constants = require(ReplicatedStorage.Shared.Constants)
	local EconomyService = require(script.Parent.Parent.server.EconomyService)
	
	amount = amount or 1
	
	if not Constants.PLANT_CONFIG[plantType] then
		return false, "Invalid plant type: " .. plantType
	end
	
	EconomyService.AddSeed(player, plantType, amount)
	return true, "Added " .. amount .. "x " .. plantType .. " seeds"
end

-- Change weather
function AdminCommands.SetWeather(weatherType)
	local Constants = require(ReplicatedStorage.Shared.Constants)
	local Lighting = game:GetService("Lighting")
	
	if not Constants.WEATHER_CONFIG[weatherType] then
		return false, "Invalid weather type: " .. weatherType
	end
	
	local config = Constants.WEATHER_CONFIG[weatherType]
	Lighting.Brightness = config.Brightness
	Lighting.ColorShift_Top = config.ColorShift_Top
	Lighting.ClockTime = config.ClockTime
	
	-- Notify clients
	local weatherEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.WEATHER_CHANGED)
	if weatherEvent then
		weatherEvent:FireAllClients(weatherType)
	end
	
	return true, "Weather set to " .. weatherType
end

-- Speed up plant growth (for testing)
function AdminCommands.GrowAllPlants(player)
	local GardenManager = require(script.Parent.Parent.server.GardenManager)
	local plotModel = GardenManager.PlayerPlots[player.UserId]
	
	if not plotModel then
		return false, "No plot found"
	end
	
	local count = 0
	for _, child in ipairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("PlantType") then
			child:SetAttribute("Stage", "Bloom")
			local PlantModule = require(ReplicatedStorage.Shared.PlantModule)
			PlantModule.UpdatePlantVisual(child)
			count = count + 1
		end
	end
	
	return true, "Instantly grew " .. count .. " plants to Bloom stage"
end

-- Clear player's garden
function AdminCommands.ClearGarden(player)
	local GardenManager = require(script.Parent.Parent.server.GardenManager)
	local plotModel = GardenManager.PlayerPlots[player.UserId]
	
	if not plotModel then
		return false, "No plot found"
	end
	
	local count = 0
	for _, child in ipairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("PlantType") then
			child:Destroy()
			count = count + 1
		end
	end
	
	plotModel:SetAttribute("PlantCount", 0)
	return true, "Cleared " .. count .. " plants from garden"
end

-- Teleport to spawn
function AdminCommands.TeleportToSpawn(player)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
		return true, "Teleported to spawn"
	end
	return false, "Character not found"
end

-- List all commands
function AdminCommands.GetCommandsList()
	return {
		{name = "addcoins", usage = "addcoins <amount>", desc = "Add coins to yourself"},
		{name = "removecoins", usage = "removecoins <amount>", desc = "Remove coins from yourself"},
		{name = "getcoins", usage = "getcoins", desc = "Check your coins"},
		{name = "addseeds", usage = "addseeds <plantType> <amount>", desc = "Add seeds (Glowbud/Dewleaf)"},
		{name = "setweather", usage = "setweather <type>", desc = "Change weather (Sunny/Rainy/Stormy)"},
		{name = "grow", usage = "grow", desc = "Instantly grow all your plants"},
		{name = "clear", usage = "clear", desc = "Clear all plants from your garden"},
		{name = "spawn", usage = "spawn", desc = "Teleport to spawn"},
		{name = "help", usage = "help", desc = "Show this list"},
	}
end

return AdminCommands
