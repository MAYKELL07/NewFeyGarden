-- EconomyService.luau
-- Manages player currency, inventory, and transactions with persistent storage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(ServerScriptService.Server.Persistence.DataService)

local EconomyService = {}
EconomyService.PlayerData = {} -- Legacy cache, now backed by DataService

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

-- Initialize player data (now loads from DataService)
function EconomyService.InitializePlayerData(player)
	-- Wait for DataService to load profile with retry
	local profile = nil
	local attempts = 0
	local maxAttempts = 20
	
	while not profile and attempts < maxAttempts do
		task.wait(0.5)
		attempts = attempts + 1
		profile = DataService.GetProfile(player.UserId)
		
		if not profile then
			if attempts % 4 == 0 then
				print(string.format("EconomyService: Waiting for profile to load for %s (attempt %d/%d)", player.Name, attempts, maxAttempts))
			end
		end
	end
	
	if not profile then
		warn(string.format("EconomyService: No profile loaded for %s after %d attempts", player.Name, attempts))
		return
	end
	
	print(string.format("EconomyService: Profile loaded for %s after %d attempts", player.Name, attempts))
	
	-- Create legacy cache reference for compatibility
	EconomyService.PlayerData[player.UserId] = {
		Coins = profile.Coins,
		Inventory = profile.Inventory
	}
	
	-- Give starting items if new player (only if they have default starting coins)
	if profile.Coins == 100 and not next(profile.Inventory.Seeds) then
		print(string.format("EconomyService: New player detected - giving starting items to %s", player.Name))
		DataService.AddSeed(player.UserId, Constants.PLANT_TYPES.GLOWBUD, 2)
		DataService.AddSeed(player.UserId, Constants.PLANT_TYPES.DEWLEAF, 3)
		
		-- Update cache
		local updatedProfile = DataService.GetProfile(player.UserId)
		if updatedProfile then
			EconomyService.PlayerData[player.UserId].Inventory = updatedProfile.Inventory
		end
	end
	
	print(string.format("EconomyService: ✓ Initialized data for %s - Coins: %d, Seeds: %d types", 
		player.Name, 
		profile.Coins,
		(function()
			local count = 0
			for _ in pairs(profile.Inventory.Seeds) do count = count + 1 end
			return count
		end)()
	))
	
	EconomyService.SyncPlayerData(player)
end

-- Sync player data to client
function EconomyService.SyncPlayerData(player)
	local profile = DataService.GetProfile(player.UserId)
	if not profile then return end
	
	-- Update cache
	EconomyService.PlayerData[player.UserId] = {
		Coins = profile.Coins,
		Inventory = profile.Inventory
	}
	
	-- Update currency
	updateCurrencyEvent:FireClient(player, profile.Coins, true)
	
	-- Update inventory
	updateInventoryEvent:FireClient(player, profile.Inventory)
end

-- Add coins to player
function EconomyService.AddCoins(player, amount)
	local success = DataService.AddCoins(player.UserId, amount)
	if not success then return false end
	
	-- Update cache
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Coins = profile.Coins
	end
	
	updateCurrencyEvent:FireClient(player, amount, false)
	print(player.Name .. " earned " .. amount .. " coins (Total:", profile.Coins, ")")
	return true
end

-- Remove coins from player
function EconomyService.RemoveCoins(player, amount)
	local success = DataService.RemoveCoins(player.UserId, amount)
	if not success then return false end
	
	-- Update cache
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Coins = profile.Coins
	end
	
	updateCurrencyEvent:FireClient(player, -amount, false)
	print(player.Name .. " spent " .. amount .. " coins (Remaining:", profile.Coins, ")")
	return true
end

-- Get player coins
function EconomyService.GetCoins(player)
	return DataService.GetCoins(player.UserId)
end

-- Add seed to inventory
function EconomyService.AddSeed(player, plantType, amount)
	amount = amount or 1
	local success = DataService.AddSeed(player.UserId, plantType, amount)
	if not success then return false end
	
	-- Update cache
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Inventory = profile.Inventory
	end
	
	EconomyService.SyncPlayerData(player)
	return true
end

-- Remove seed from inventory
function EconomyService.RemoveSeed(player, plantType)
	local success = DataService.RemoveSeed(player.UserId, plantType)
	if not success then return false end
	
	-- Update cache
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Inventory = profile.Inventory
	end
	
	EconomyService.SyncPlayerData(player)
	return true
end

-- Get seed count
function EconomyService.GetSeedCount(player, plantType)
	return DataService.GetSeedCount(player.UserId, plantType)
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
	
	-- Check if player already has this pet
	if DataService.HasPet(player.UserId, petType) then
		warn(player.Name .. " already owns this pet")
		return false
	end
	
	if not EconomyService.RemoveCoins(player, config.Price) then
		warn(player.Name .. " doesn't have enough coins")
		return false
	end
	
	DataService.AddPet(player.UserId, petType)
	
	-- Update cache
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Inventory = profile.Inventory
	end
	
	EconomyService.SyncPlayerData(player)
	
	print(player.Name .. " bought " .. petType .. " pet")
	return true
end

-- Initialize Economy Service
function EconomyService.Initialize()
	print("EconomyService: Initializing...")
	
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
	
	-- Initialize new players (async to not block)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			EconomyService.InitializePlayerData(player)
		end)
	end)
	
	-- Initialize existing players (async)
	task.spawn(function()
		task.wait(1) -- Give DataService time to initialize
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				EconomyService.InitializePlayerData(player)
			end)
		end
	end)
	
	-- Cleanup when player leaves
	Players.PlayerRemoving:Connect(function(player)
		EconomyService.PlayerData[player.UserId] = nil
	end)
	
	print("EconomyService: ✓ Initialized")
end

return EconomyService
