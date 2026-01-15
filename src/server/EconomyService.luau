-- EconomyService.luau
-- Manages player currency, inventory, and transactions with persistent storage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[EconomyService] Shared folder missing; economy disabled")
	return {}
end

local function safeRequire(name)
	local ok, mod = pcall(function()
		return require(sharedFolder:WaitForChild(name, 5))
	end)
	if not ok then
		warn(string.format("[EconomyService] Failed to load %s: %s", name, tostring(mod)))
		return nil
	end
	return mod
end

local Constants = safeRequire("Constants")
local Config = safeRequire("Config")
if not (Constants and Config) then
	return {}
end

local DataService = require(ServerScriptService.Server.Persistence.DataService)
local ShopService = require(ServerScriptService.Server.ShopService)

local EconomyService = {}
EconomyService.PlayerData = {} -- Legacy cache, now backed by DataService
local growAllRewardHandler

-- Create RemoteEvents
local buySeedEvent = Instance.new("RemoteEvent")
buySeedEvent.Name = Constants.EVENTS.BUY_SEED
buySeedEvent.Parent = ReplicatedStorage

local buyPetEvent = Instance.new("RemoteEvent")
buyPetEvent.Name = Constants.EVENTS.BUY_PET
buyPetEvent.Parent = ReplicatedStorage

local equipPetEvent = Instance.new("RemoteEvent")
equipPetEvent.Name = Constants.EVENTS.EQUIP_PET
equipPetEvent.Parent = ReplicatedStorage

local unequipPetEvent = Instance.new("RemoteEvent")
unequipPetEvent.Name = Constants.EVENTS.UNEQUIP_PET
unequipPetEvent.Parent = ReplicatedStorage

local addGardenPetEvent = Instance.new("RemoteEvent")
addGardenPetEvent.Name = Constants.EVENTS.ADD_GARDEN_PET
addGardenPetEvent.Parent = ReplicatedStorage

local removeGardenPetEvent = Instance.new("RemoteEvent")
removeGardenPetEvent.Name = Constants.EVENTS.REMOVE_GARDEN_PET
removeGardenPetEvent.Parent = ReplicatedStorage

local buyEggEvent = Instance.new("RemoteEvent")
buyEggEvent.Name = Constants.EVENTS.BUY_EGG
buyEggEvent.Parent = ReplicatedStorage

local openEggEvent = Instance.new("RemoteEvent")
openEggEvent.Name = Constants.EVENTS.OPEN_EGG
openEggEvent.Parent = ReplicatedStorage

local eggOpenedEvent = Instance.new("RemoteEvent")
eggOpenedEvent.Name = Constants.EVENTS.EGG_OPENED
eggOpenedEvent.Parent = ReplicatedStorage

local buyGearEvent = Instance.new("RemoteEvent")
buyGearEvent.Name = Constants.EVENTS.BUY_GEAR
buyGearEvent.Parent = ReplicatedStorage

local sellFruitEvent = Instance.new("RemoteEvent")
sellFruitEvent.Name = Constants.EVENTS.SELL_FRUIT
sellFruitEvent.Parent = ReplicatedStorage

-- New instance-based fruit selling events
local sellFruitByIdEvent = Instance.new("RemoteEvent")
sellFruitByIdEvent.Name = "SellFruitById"
sellFruitByIdEvent.Parent = ReplicatedStorage

local sellAllFruitsOfTypeEvent = Instance.new("RemoteEvent")
sellAllFruitsOfTypeEvent.Name = "SellAllFruitsOfType"
sellAllFruitsOfTypeEvent.Parent = ReplicatedStorage

local requestDataEvent = Instance.new("RemoteEvent")
requestDataEvent.Name = "RequestPlayerData"
requestDataEvent.Parent = ReplicatedStorage

local updateCurrencyEvent = Instance.new("RemoteEvent")
updateCurrencyEvent.Name = Constants.EVENTS.UPDATE_CURRENCY
updateCurrencyEvent.Parent = ReplicatedStorage

local updateInventoryEvent = Instance.new("RemoteEvent")
updateInventoryEvent.Name = Constants.EVENTS.UPDATE_INVENTORY
updateInventoryEvent.Parent = ReplicatedStorage

-- Robux purchase event (client requests to buy seeds with Robux)
local buySeedRobuxEvent = Instance.new("RemoteEvent")
buySeedRobuxEvent.Name = Constants.EVENTS.BUY_SEED_ROBUX
buySeedRobuxEvent.Parent = ReplicatedStorage

function EconomyService.SetGrowAllRewardHandler(callback)
	growAllRewardHandler = callback
end

function EconomyService.TriggerGrowAllReward(userId)
	if growAllRewardHandler then
		local ok, result = pcall(growAllRewardHandler, userId)
		if not ok then
			warn("[EconomyService] GrowAll reward handler failed:", result)
			return 0
		end
		return result or 0
	end

	return 0
end

function EconomyService.PromptGrowAllPurchase(player)
	local productId = Constants.GetGrowAllProductId()
	if not productId or productId == 0 then
		warn("[EconomyService] GrowAll product ID not configured")
		return false
	end

	MarketplaceService:PromptProductPurchase(player, productId)
	return true
end

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
		
		-- Intentionally silent until profile loads
	end
	
	if not profile then
		warn(string.format("EconomyService: No profile loaded for %s after %d attempts", player.Name, attempts))
		return
	end
	
	-- print(string.format("EconomyService: Profile loaded for %s after %d attempts", player.Name, attempts))
	
	-- Create legacy cache reference for compatibility
	EconomyService.PlayerData[player.UserId] = {
		Coins = profile.Coins,
		Inventory = profile.Inventory
	}
	
	-- Give starting items if new player (only if they have default starting coins)
	if profile.Coins == 100 and not next(profile.Inventory.Seeds) then
		-- print(string.format("EconomyService: New player detected - giving starting items to %s", player.Name))
		DataService.AddSeed(player.UserId, Constants.PLANT_TYPES.GLOWBUD, 2)
		DataService.AddSeed(player.UserId, Constants.PLANT_TYPES.DEWLEAF, 3)
		
		-- Update cache
		local updatedProfile = DataService.GetProfile(player.UserId)
		if updatedProfile then
			EconomyService.PlayerData[player.UserId].Inventory = updatedProfile.Inventory
		end
	end
	
	-- print(string.format("EconomyService: ✓ Initialized data for %s - Coins: %d, Seeds: %d types", player.Name, profile.Coins, seedCount))

	EconomyService.SyncPlayerData(player, true)
end

-- Sync player data to client
function EconomyService.SyncPlayerData(player, syncPets)
	local profile = DataService.GetProfile(player.UserId)
	if not profile then return end

	local includePets = syncPets == true
	
	local equippedPetInstances
	local gardenPetInstances

	if includePets then
		-- Get equipped and garden pet instances (full data)
		equippedPetInstances = DataService.GetEquippedPetInstances(player.UserId)
		gardenPetInstances = DataService.GetGardenPetInstances(player.UserId)
	end
	
	-- Update cache
	EconomyService.PlayerData[player.UserId] = {
		Coins = profile.Coins,
		Inventory = profile.Inventory,
		EquippedPets = profile.EquippedPets or {},
		GardenPets = profile.GardenPets or {}
	}
	
	-- Update currency
	updateCurrencyEvent:FireClient(player, profile.Coins, true)
	
	-- Update inventory (include pet data only when requested to avoid respawn)
	local inventoryData = {
		Seeds = profile.Inventory.Seeds,
		Pets = profile.Inventory.Pets, -- Full pet instances array [{Id, PetType, Size, Weight}]
		Eggs = profile.Inventory.Eggs or {},
		Fruits = profile.Inventory.Fruits,
		Gear = profile.Inventory.Gear or {},
	}

	if includePets then
		inventoryData.EquippedPets = equippedPetInstances -- Full instances for rendering
		inventoryData.EquippedPetIds = profile.EquippedPets or {} -- Just IDs for quick lookup
		inventoryData.GardenPets = gardenPetInstances -- Full instances for rendering
		inventoryData.GardenPetIds = profile.GardenPets or {} -- Just IDs for quick lookup
	end
	updateInventoryEvent:FireClient(player, inventoryData)
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
	-- print(player.Name .. " earned " .. amount .. " coins (Total:", profile.Coins, ")")
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
	-- print(player.Name .. " spent " .. amount .. " coins (Remaining:", profile.Coins, ")")
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
	
	EconomyService.SyncPlayerData(player, false)
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
	
	EconomyService.SyncPlayerData(player, false)
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

	-- Check rotating shop stock first
	local available, reason = ShopService.IsSeedAvailable(plantType, amount)
	if not available then
		warn(string.format("%s attempted to buy %s but shop unavailable: %s", player.Name, plantType, reason or "unknown"))
		return false
	end
	
	if not EconomyService.RemoveCoins(player, totalCost) then
		warn(player.Name .. " doesn't have enough coins")
		return false
	end
	
	-- Reduce shop stock (will broadcast update)
	local stockSuccess, stockMessage = ShopService.PurchaseSeed(player, plantType, amount)
	if not stockSuccess then
		-- Refund coins on failure
		EconomyService.AddCoins(player, totalCost)
		warn(string.format("Shop purchase failed for %s: %s", player.Name, stockMessage or "unknown"))
		return false
	end

	EconomyService.AddSeed(player, plantType, amount)
	-- print(player.Name .. " bought " .. amount .. "x " .. plantType .. " seeds")
	
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
	
	EconomyService.SyncPlayerData(player, true)
	
	-- print(player.Name .. " bought " .. petType .. " pet")
	return true
end

-- Buy gear
function EconomyService.BuyGear(player, gearType)
	local config = Constants.GEAR_CONFIG[gearType]
	if not config then
		warn("Invalid gear type:", gearType)
		return false
	end
	
	-- Check if player already owns this gear
	if DataService.HasGear(player.UserId, gearType) then
		warn(player.Name .. " already owns this gear")
		return false
	end
	
	if not EconomyService.RemoveCoins(player, config.Price) then
		warn(player.Name .. " doesn't have enough coins")
		return false
	end
	
	DataService.AddGear(player.UserId, gearType)
	
	-- Update cache
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Inventory = profile.Inventory
	end
	
	EconomyService.SyncPlayerData(player, false)
	
	-- print(player.Name .. " bought " .. gearType .. " gear")
	return true
end

-- Equip pet (add to equipped pets by instance ID)
function EconomyService.EquipPet(player, petId)
	-- Validate pet ID
	if not petId or type(petId) ~= "string" then
		warn("Invalid pet ID:", petId)
		return false
	end
	
	-- Equip the pet by instance ID
	local success = DataService.EquipPet(player.UserId, petId)
	if not success then
		return false
	end
	
	-- Update cache and sync
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Inventory = profile.Inventory
		EconomyService.PlayerData[player.UserId].EquippedPets = profile.EquippedPets
	end
	
	EconomyService.SyncPlayerData(player, true)
	return true
end

-- Unequip pet (remove from equipped pets by instance ID)
function EconomyService.UnequipPet(player, petId)
	local success = DataService.UnequipPet(player.UserId, petId)
	if not success then
		return false
	end
	
	-- Update cache and sync
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].EquippedPets = profile.EquippedPets
	end
	
	EconomyService.SyncPlayerData(player, true)
	return true
end

-- Add pet to garden by instance ID
function EconomyService.AddGardenPet(player, petId)
	-- Validate pet ID
	if not petId or type(petId) ~= "string" then
		warn("Invalid pet ID:", petId)
		return false
	end
	
	-- Add to garden by instance ID
	local success = DataService.AddGardenPet(player.UserId, petId)
	if not success then
		return false
	end
	
	-- Update cache and sync
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].GardenPets = profile.GardenPets
	end
	
	EconomyService.SyncPlayerData(player, true)
	return true
end

-- Remove pet from garden
function EconomyService.RemoveGardenPet(player, petId)
	local success = DataService.RemoveGardenPet(player.UserId, petId)
	if not success then
		return false
	end
	
	-- Update cache and sync
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].GardenPets = profile.GardenPets
	end
	
	EconomyService.SyncPlayerData(player, true)
	return true
end

-- ============================================================================
-- EGG GACHA SYSTEM
-- ============================================================================

-- Roll a rarity based on egg's drop chances
local function rollRarity(eggConfig)
	local dropChances = eggConfig.DropChances
	local totalWeight = 0
	
	for _, weight in pairs(dropChances) do
		totalWeight = totalWeight + weight
	end
	
	local roll = math.random() * totalWeight
	local cumulative = 0
	
	for rarity, weight in pairs(dropChances) do
		cumulative = cumulative + weight
		if roll <= cumulative then
			return rarity
		end
	end
	
	-- Fallback to first rarity
	for rarity, _ in pairs(dropChances) do
		return rarity
	end
end

-- Get all pets of a specific rarity
local function getPetsByRarity(rarity)
	local pets = {}
	for petType, petRarity in pairs(Constants.PET_RARITIES) do
		if petRarity == rarity then
			table.insert(pets, petType)
		end
	end
	return pets
end

-- Roll a random pet from a rarity pool
local function rollPet(rarity)
	local pets = getPetsByRarity(rarity)
	if #pets == 0 then
		warn("No pets found for rarity:", rarity)
		return nil
	end
	return pets[math.random(1, #pets)]
end

function EconomyService.RollPetFromEggType(eggType: string): (string?, string?)
	local eggConfig = Constants.EGG_CONFIG[eggType]
	if not eggConfig then
		return nil, nil
	end

	local rolledRarity = rollRarity(eggConfig)
	local rolledPetType = rollPet(rolledRarity)
	return rolledPetType, rolledRarity
end

-- Buy an egg
function EconomyService.BuyEgg(player, eggType, amount)
	local eggConfig = Constants.EGG_CONFIG[eggType]
	if not eggConfig then
		warn("Invalid egg type:", eggType)
		return false
	end
	
	amount = amount or 1
	local totalCost = eggConfig.Price * amount
	
	if not EconomyService.RemoveCoins(player, totalCost) then
		warn(player.Name .. " doesn't have enough coins for eggs")
		return false
	end
	
	DataService.AddEgg(player.UserId, eggType, amount)
	
	-- Update cache
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Inventory = profile.Inventory
	end
	
	EconomyService.SyncPlayerData(player, false)
	
	-- print(string.format("%s bought %dx %s", player.Name, amount, eggConfig.DisplayName))
	return true
end

function EconomyService.RemoveEgg(player: Player, eggType: string, amount: number?): boolean
	amount = amount or 1
	if amount <= 0 then
		return true
	end

	local eggConfig = Constants.EGG_CONFIG[eggType]
	if not eggConfig then
		return false
	end

	local eggCount = DataService.GetEggCount(player.UserId, eggType)
	if eggCount < amount then
		return false
	end

	for _ = 1, amount do
		local removed = DataService.RemoveEgg(player.UserId, eggType)
		if not removed then
			return false
		end
	end

	EconomyService.SyncPlayerData(player, false)
	return true
end

-- Open an egg (gacha roll)
function EconomyService.OpenEgg(player, eggType)
	local eggConfig = Constants.EGG_CONFIG[eggType]
	if not eggConfig then
		warn("Invalid egg type:", eggType)
		eggOpenedEvent:FireClient(player, false, nil, "Invalid egg type")
		return false
	end
	
	-- Check if player has the egg
	local eggCount = DataService.GetEggCount(player.UserId, eggType)
	if eggCount <= 0 then
		warn(player.Name .. " doesn't have any " .. eggType)
		eggOpenedEvent:FireClient(player, false, nil, "You don't have this egg")
		return false
	end
	
	-- Remove the egg
	local removed = DataService.RemoveEgg(player.UserId, eggType)
	if not removed then
		warn("Failed to remove egg from inventory")
		eggOpenedEvent:FireClient(player, false, nil, "Failed to open egg")
		return false
	end
	
	local rolledPetType, rolledRarity = EconomyService.RollPetFromEggType(eggType)
	if not rolledPetType then
		-- Fallback: give back the egg and report error
		DataService.AddEgg(player.UserId, eggType, 1)
		eggOpenedEvent:FireClient(player, false, nil, "No pets available")
		return false
	end
	
	-- Generate random size and weight for the new pet
	local sizeWeight = Constants.GenerateRandomSizeWeight("Pet")
	
	-- Add the pet instance to inventory
	local petInstance = DataService.AddPetInstance(player.UserId, rolledPetType, sizeWeight.Size, sizeWeight.Weight)
	if not petInstance then
		-- Fallback: give back the egg
		DataService.AddEgg(player.UserId, eggType, 1)
		eggOpenedEvent:FireClient(player, false, nil, "Failed to create pet")
		return false
	end
	
	-- Update cache
	local profile = DataService.GetProfile(player.UserId)
	if profile then
		EconomyService.PlayerData[player.UserId].Inventory = profile.Inventory
	end
	
	-- Get pet config for display info
	local petConfig = Constants.PET_CONFIG[rolledPetType]
	
	-- Build result data to send to client
	local resultData = {
		Success = true,
		PetInstance = petInstance,
		PetType = rolledPetType,
		Rarity = rolledRarity,
		DisplayName = petConfig and petConfig.DisplayName or rolledPetType,
		Color = petConfig and petConfig.Color or Color3.fromRGB(255, 255, 255),
		Size = petInstance.Size,
		Weight = petInstance.Weight,
		EggType = eggType
	}
	
	-- print(string.format("%s opened %s and got %s (%s) - Size: %.2f, Weight: %.2f", 
	--     player.Name, eggConfig.DisplayName, resultData.DisplayName, rolledRarity, petInstance.Size, petInstance.Weight))
	
	-- Fire result to client for animation
	eggOpenedEvent:FireClient(player, true, resultData, nil)
	
	-- Sync inventory immediately so UI updates right away (pets included for new hatch)
	EconomyService.SyncPlayerData(player, true)
	
	return true
end

-- Sell fruit
-- Sell a single fruit by ID (for new instance-based system)
function EconomyService.SellFruitById(player, fruitId)
	if not fruitId or type(fruitId) ~= "string" then
		warn("Invalid fruit ID")
		return false
	end
	
	-- Find and get the fruit
	local profile = DataService.GetProfile(player.UserId)
	if not profile then return false end
	
	local fruitInstance = nil
	for _, fruit in ipairs(profile.Inventory.Fruits or {}) do
		if fruit.Id == fruitId then
			fruitInstance = fruit
			break
		end
	end
	
	if not fruitInstance then
		warn("Fruit not found:", fruitId)
		return false
	end
	
	-- Get the plant type from fruit name (remove "Fruit" suffix)
	local plantType = fruitInstance.Type:gsub("Fruit$", "")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config or not config.FruitSellPrice then
		warn("Invalid fruit or no sell price for:", fruitInstance.Type)
		return false
	end
	
	-- Calculate sell price based on weight (heavier = worth more)
	local weight = fruitInstance.Weight or 1.0
	local basePrice = config.FruitSellPrice
	local sellPrice = math.floor(basePrice * weight + 0.5)
	
	-- Remove fruit from inventory
	local success = DataService.RemoveFruitById(player.UserId, fruitId)
	if not success then
		warn("Failed to remove fruit from inventory")
		return false
	end
	
	-- Add coins
	EconomyService.AddCoins(player, sellPrice)
	
	-- Sync inventory to client (no pet changes)
	EconomyService.SyncPlayerData(player, false)
	
	return true, sellPrice, weight
end

-- Sell all fruits of a type
function EconomyService.SellAllFruitsOfType(player, fruitType)
	local profile = DataService.GetProfile(player.UserId)
	if not profile then return false end
	
	-- Get the plant type from fruit name (remove "Fruit" suffix)
	local plantType = fruitType:gsub("Fruit$", "")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config or not config.FruitSellPrice then
		warn("Invalid fruit or no sell price for:", fruitType)
		return false
	end
	
	local totalSold = 0
	local totalCoins = 0
	
	-- Collect all fruit IDs of this type first (to avoid modifying while iterating)
	local fruitsToSell = {}
	for _, fruit in ipairs(profile.Inventory.Fruits or {}) do
		if fruit.Type == fruitType then
			table.insert(fruitsToSell, fruit)
		end
	end
	
	-- Sell each fruit
	for _, fruit in ipairs(fruitsToSell) do
		local weight = fruit.Weight or 1.0
		local sellPrice = math.floor(config.FruitSellPrice * weight + 0.5)
		
		local success = DataService.RemoveFruitById(player.UserId, fruit.Id)
		if success then
			totalSold = totalSold + 1
			totalCoins = totalCoins + sellPrice
		end
	end
	
	if totalSold > 0 then
		EconomyService.AddCoins(player, totalCoins)
		EconomyService.SyncPlayerData(player, false)
	end
	
	return true, totalSold, totalCoins
end

-- Legacy sell function (now sells one fruit at a time with weight consideration)
function EconomyService.SellFruit(player, fruitName, amount)
	amount = amount or 1
	
	-- Check if player has the fruit
	local currentCount = DataService.GetFruitCount(player.UserId, fruitName)
	if currentCount < amount then
		warn(player.Name .. " doesn't have enough " .. fruitName)
		return false
	end
	
	-- Get the plant type from fruit name (remove "Fruit" suffix)
	local plantType = fruitName:gsub("Fruit$", "")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config or not config.FruitSellPrice then
		warn("Invalid fruit or no sell price for:", fruitName)
		return false
	end
	
	-- Get fruits to sell and calculate total based on individual weights
	local profile = DataService.GetProfile(player.UserId)
	local totalPrice = 0
	local sold = 0
	
	for i = #profile.Inventory.Fruits, 1, -1 do
		if sold >= amount then break end
		local fruit = profile.Inventory.Fruits[i]
		if fruit.Type == fruitName then
			local weight = fruit.Weight or 1.0
			totalPrice = totalPrice + math.floor(config.FruitSellPrice * weight + 0.5)
			table.remove(profile.Inventory.Fruits, i)
			sold = sold + 1
		end
	end
	
	if sold == 0 then
		warn("Failed to remove fruits from inventory")
		return false
	end
	
	-- Add coins
	EconomyService.AddCoins(player, totalPrice)
	
	-- Sync inventory to client
	EconomyService.SyncPlayerData(player, false)
	
	return true
end

-- Initialize Economy Service
function EconomyService.Initialize()
	-- print("EconomyService: Initializing...")
	
	-- Handle buy seed requests
	buySeedEvent.OnServerEvent:Connect(function(player, plantType, amount)
		EconomyService.BuySeed(player, plantType, amount)
	end)
	
	-- Handle buy pet requests (legacy - creates new pet instance)
	buyPetEvent.OnServerEvent:Connect(function(player, petType)
		EconomyService.BuyPet(player, petType)
	end)
	
	-- Handle buy egg requests
	buyEggEvent.OnServerEvent:Connect(function(player, eggType, amount)
		EconomyService.BuyEgg(player, eggType, amount)
	end)
	
	-- Handle buy gear requests
	buyGearEvent.OnServerEvent:Connect(function(player, gearType)
		EconomyService.BuyGear(player, gearType)
	end)
	
	-- Handle open egg requests
	openEggEvent.OnServerEvent:Connect(function(player, eggType)
		EconomyService.OpenEgg(player, eggType)
	end)
	
	-- Handle equip pet requests (now uses pet instance ID)
	equipPetEvent.OnServerEvent:Connect(function(player, petId)
		EconomyService.EquipPet(player, petId)
	end)
	
	-- Handle unequip pet requests (now uses pet instance ID)
	unequipPetEvent.OnServerEvent:Connect(function(player, petId)
		EconomyService.UnequipPet(player, petId)
	end)
	
	-- Handle add garden pet requests (now uses pet instance ID)
	addGardenPetEvent.OnServerEvent:Connect(function(player, petId)
		EconomyService.AddGardenPet(player, petId)
	end)
	
	-- Handle remove garden pet requests (now uses pet instance ID)
	removeGardenPetEvent.OnServerEvent:Connect(function(player, petId)
		EconomyService.RemoveGardenPet(player, petId)
	end)
	
	-- Handle sell fruit requests (legacy count-based)
	sellFruitEvent.OnServerEvent:Connect(function(player, fruitName, amount)
		EconomyService.SellFruit(player, fruitName, amount)
	end)
	
	-- Handle sell fruit by ID (instance-based)
	sellFruitByIdEvent.OnServerEvent:Connect(function(player, fruitId)
		EconomyService.SellFruitById(player, fruitId)
	end)
	
	-- Handle sell all fruits of type (instance-based)
	sellAllFruitsOfTypeEvent.OnServerEvent:Connect(function(player, fruitType)
		EconomyService.SellAllFruitsOfType(player, fruitType)
	end)
	
	-- Handle request for player data (client can call this to get initial data)
	requestDataEvent.OnServerEvent:Connect(function(player)
		EconomyService.SyncPlayerData(player, true)
	end)
	
	-- Handle Robux seed purchase requests (prompts the purchase)
	buySeedRobuxEvent.OnServerEvent:Connect(function(player, plantType)
		local product = Constants.SEED_ROBUX_PRODUCTS[plantType]
		if not product then
			warn("[EconomyService] Invalid plant type for Robux purchase:", plantType)
			return
		end
		
		if product.ProductId == 0 then
			warn("[EconomyService] Product ID not configured for:", plantType)
			return
		end
		
		-- Prompt the purchase
		MarketplaceService:PromptProductPurchase(player, product.ProductId)
	end)
	
	-- Handle Developer Product purchases (ProcessReceipt callback)
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local userId = receiptInfo.PlayerId
		local productId = receiptInfo.ProductId
		
		local player = Players:GetPlayerByUserId(userId)
		if not player then
			-- Player left, but we should still grant the purchase
			-- Return NotProcessedYet so it retries when they rejoin
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Grow All product
		local growAllProductId = Constants.GetGrowAllProductId()
		if growAllProductId and productId == growAllProductId then
			local grown = EconomyService.TriggerGrowAllReward(userId)
			if grown > 0 then
				print(string.format("[EconomyService] GrowAll purchase: %s grew %d plants", player.Name, grown))
			else
				warn(string.format("[EconomyService] GrowAll purchase granted but no plants were grown for %s", player.Name))
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		
		-- Find which seed product was purchased
		local plantType, product = Constants.GetPlantTypeByProductId(productId)
		if plantType and product then
			-- Grant the seeds
			local seedAmount = product.SeedAmount or 5
			local success = DataService.AddSeed(userId, plantType, seedAmount)
			
			if success then
				-- Sync inventory to client
				EconomyService.SyncPlayerData(player, false)
				print(string.format("[EconomyService] Robux purchase: %s bought %dx %s seeds", player.Name, seedAmount, plantType))
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				warn("[EconomyService] Failed to grant seeds for Robux purchase:", plantType)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
		
		-- Unknown product - could be from another system
		warn("[EconomyService] Unknown product ID in ProcessReceipt:", productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
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
	
	-- print("EconomyService: ✓ Initialized")
end

return EconomyService
