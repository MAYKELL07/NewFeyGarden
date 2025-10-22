-- EconomyService.luau
-- Manages player currency, inventory, and transactions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Constants = require(ReplicatedStorage.Shared.Constants)

local EconomyService = {}
EconomyService.PlayerData = {}

-- Create RemoteEvents
local buySeedEvent = Instance.new("RemoteEvent")
buySeedEvent.Name = Constants.EVENTS.BUY_SEED
buySeedEvent.Parent = ReplicatedStorage

local buyPetEvent = Instance.new("RemoteEvent")
buyPetEvent.Name = Constants.EVENTS.BUY_PET
buyPetEvent.Parent = ReplicatedStorage

local updateCurrencyEvent = Instance.new("RemoteEvent")
updateCurrencyEvent.Name = Constants.EVENTS.UPDATE_CURRENCY
updateCurrencyEvent.Parent = ReplicatedStorage

local updateInventoryEvent = Instance.new("RemoteEvent")
updateInventoryEvent.Name = Constants.EVENTS.UPDATE_INVENTORY
updateInventoryEvent.Parent = ReplicatedStorage

-- Initialize player data
function EconomyService.InitializePlayerData(player)
	EconomyService.PlayerData[player.UserId] = {
		Coins = Constants.STARTING_COINS,
		Inventory = {
			Seeds = {
				[Constants.PLANT_TYPES.GLOWBUD] = 2,
				[Constants.PLANT_TYPES.DEWLEAF] = 3
			},
			Pets = {}
		}
	}
	
	print("Initialized data for", player.Name)
	EconomyService.SyncPlayerData(player)
end

-- Sync player data to client
function EconomyService.SyncPlayerData(player)
	local data = EconomyService.PlayerData[player.UserId]
	if not data then return end
	
	-- Update currency
	updateCurrencyEvent:FireClient(player, data.Coins, true)
	
	-- Update inventory
	updateInventoryEvent:FireClient(player, data.Inventory)
end

-- Add coins to player
function EconomyService.AddCoins(player, amount)
	local data = EconomyService.PlayerData[player.UserId]
	if not data then return false end
	
	data.Coins = data.Coins + amount
	updateCurrencyEvent:FireClient(player, amount, false)
	
	print(player.Name .. " earned " .. amount .. " coins")
	return true
end

-- Remove coins from player
function EconomyService.RemoveCoins(player, amount)
	local data = EconomyService.PlayerData[player.UserId]
	if not data then return false end
	
	if data.Coins < amount then
		return false
	end
	
	data.Coins = data.Coins - amount
	updateCurrencyEvent:FireClient(player, -amount, false)
	
	print(player.Name .. " spent " .. amount .. " coins")
	return true
end

-- Get player coins
function EconomyService.GetCoins(player)
	local data = EconomyService.PlayerData[player.UserId]
	return data and data.Coins or 0
end

-- Add seed to inventory
function EconomyService.AddSeed(player, plantType, amount)
	local data = EconomyService.PlayerData[player.UserId]
	if not data then return false end
	
	amount = amount or 1
	
	if not data.Inventory.Seeds[plantType] then
		data.Inventory.Seeds[plantType] = 0
	end
	
	data.Inventory.Seeds[plantType] = data.Inventory.Seeds[plantType] + amount
	EconomyService.SyncPlayerData(player)
	
	return true
end

-- Remove seed from inventory
function EconomyService.RemoveSeed(player, plantType)
	local data = EconomyService.PlayerData[player.UserId]
	if not data then return false end
	
	if not data.Inventory.Seeds[plantType] or data.Inventory.Seeds[plantType] <= 0 then
		return false
	end
	
	data.Inventory.Seeds[plantType] = data.Inventory.Seeds[plantType] - 1
	EconomyService.SyncPlayerData(player)
	
	return true
end

-- Get seed count
function EconomyService.GetSeedCount(player, plantType)
	local data = EconomyService.PlayerData[player.UserId]
	if not data then return 0 end
	
	return data.Inventory.Seeds[plantType] or 0
end

-- Buy seed
function EconomyService.BuySeed(player, plantType, amount)
	local config = Constants.PLANT_CONFIG[plantType]
	if not config then
		warn("Invalid plant type:", plantType)
		return false
	end
	
	amount = amount or 1
	local totalCost = config.SeedPrice * amount
	
	if not EconomyService.RemoveCoins(player, totalCost) then
		warn(player.Name .. " doesn't have enough coins")
		return false
	end
	
	EconomyService.AddSeed(player, plantType, amount)
	print(player.Name .. " bought " .. amount .. "x " .. plantType .. " seeds")
	
	return true
end

-- Buy pet
function EconomyService.BuyPet(player, petType)
	local config = Constants.PET_CONFIG[petType]
	if not config then
		warn("Invalid pet type:", petType)
		return false
	end
	
	local data = EconomyService.PlayerData[player.UserId]
	if not data then return false end
	
	-- Check if player already has this pet
	if data.Inventory.Pets[petType] then
		warn(player.Name .. " already owns this pet")
		return false
	end
	
	if not EconomyService.RemoveCoins(player, config.Price) then
		warn(player.Name .. " doesn't have enough coins")
		return false
	end
	
	data.Inventory.Pets[petType] = true
	EconomyService.SyncPlayerData(player)
	
	print(player.Name .. " bought " .. petType .. " pet")
	return true
end

-- Initialize Economy Service
function EconomyService.Initialize()
	print("EconomyService initialized")
	
	-- Handle buy seed requests
	buySeedEvent.OnServerEvent:Connect(function(player, plantType, amount)
		EconomyService.BuySeed(player, plantType, amount)
	end)
	
	-- Handle buy pet requests
	buyPetEvent.OnServerEvent:Connect(function(player, petType)
		EconomyService.BuyPet(player, petType)
	end)
	
	-- Handle harvest rewards (listen for update currency from GardenManager)
	updateCurrencyEvent.OnServerEvent:Connect(function(player, amount)
		if amount > 0 then
			EconomyService.AddCoins(player, amount)
		end
	end)
	
	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		EconomyService.InitializePlayerData(player)
	end
	
	-- Initialize new players
	Players.PlayerAdded:Connect(function(player)
		EconomyService.InitializePlayerData(player)
	end)
	
	-- Cleanup when player leaves
	Players.PlayerRemoving:Connect(function(player)
		-- In production, save to DataStore here
		EconomyService.PlayerData[player.UserId] = nil
	end)
end

return EconomyService
