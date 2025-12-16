-- DataService.server.luau
-- Handles persistent player data using DataStoreService with autosave and retry logic

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schema = require(script.Parent.Schema)

local DataService = {}

-- Configuration
local STORE_NAME = "FeyGarden_Player_v2"
local SAVE_INTERVAL = 120 -- seconds between autosaves (increased to reduce API calls)
local MAX_RETRIES = 3
local RETRY_DELAY = 1

-- Storage
local PlayerStore = DataStoreService:GetDataStore(STORE_NAME)
local Profiles = {} -- [UserId] = profile data table
local SessionLocks = {} -- [UserId] = session id to prevent data conflicts
local IsSaving = {} -- [UserId] = boolean to prevent concurrent saves
local DataLoaded = {} -- [UserId] = boolean to track if data loaded successfully

-- Helper: Generate key for a user
local function keyFor(userId)
	return "Player_" .. tostring(userId)
end

-- Helper: Generate unique session ID
local function generateSessionId()
	return game.JobId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- Helper: Retry a function with exponential backoff
local function retryAsync(fn, maxRetries)
	maxRetries = maxRetries or MAX_RETRIES
	local tries = 0
	local lastErr = nil
	
	while tries < maxRetries do
		local success, result = pcall(fn)
		if success then 
			return true, result 
		end
		
		tries = tries + 1
		lastErr = result
		
		if tries < maxRetries then
			local waitTime = RETRY_DELAY * tries
			task.wait(waitTime)
			warn(string.format("[DataService] Retry %d/%d (waiting %.1fs) - Error: %s", tries, maxRetries, waitTime, tostring(lastErr)))
		end
	end
	
	warn(string.format("[DataService] All retries failed: %s", tostring(lastErr)))
	return false, lastErr
end

-- Load profile from DataStore with session locking
local function LoadProfile(userId)
	local sessionId = generateSessionId()
	SessionLocks[userId] = sessionId
	
	local success, data = retryAsync(function()
		return PlayerStore:UpdateAsync(keyFor(userId), function(oldData)
			-- If data exists and has a recent session lock from another server, use default
			if oldData and oldData.SessionLock then
				local lockAge = os.time() - (oldData.SessionLockTime or 0)
				if lockAge < 10 then -- 5 minutes
					warn(string.format("[DataService] Session locked by another server (age: %ds)", lockAge))
					-- Don't overwrite, just return the old data to read it
					return oldData
				end
			end
			
			-- Set our session lock
			local profileData = oldData or Schema.Default()
			profileData.SessionLock = sessionId
			profileData.SessionLockTime = os.time()
			
			return profileData
		end)
	end)
	
	if not success then
		warn(string.format("[DataService] Failed to load profile for UserId %d, using default", userId))
		return Schema.Default(), false
	end
	
	-- Migrate and validate
	local profile = Schema.Migrate(data)
	
	-- Verify session lock is ours (we got the data)
	if profile.SessionLock ~= sessionId then
		warn(string.format("[DataService] Session lock mismatch for UserId %d", userId))
	end
	
	return profile, true
end

-- Save profile to DataStore
local function SaveProfile(userId, isShuttingDown)
	-- Prevent concurrent saves
	if IsSaving[userId] then
		warn(string.format("[DataService] Save already in progress for UserId %d", userId))
		return false
	end
	
	local profile = Profiles[userId]
	if not profile then 
		warn(string.format("[DataService] No profile to save for UserId %d", userId))
		return false
	end
	
	-- Only save if data was successfully loaded
	if not DataLoaded[userId] then
		warn(string.format("[DataService] Skipping save - data was not successfully loaded for UserId %d", userId))
		return false
	end
	
	IsSaving[userId] = true
	profile.Version = Schema.CurrentVersion
	profile.LastSaved = os.time()
	
	-- Deep copy to prevent modification during save
	local profileCopy = {}
	for key, value in pairs(profile) do
		if type(value) == "table" then
			profileCopy[key] = {}
			for k, v in pairs(value) do
				if type(v) == "table" then
					profileCopy[key][k] = {}
					for k2, v2 in pairs(v) do
						profileCopy[key][k][k2] = v2
					end
				else
					profileCopy[key][k] = v
				end
			end
		else
			profileCopy[key] = value
		end
	end
	
	local success = retryAsync(function()
		return PlayerStore:UpdateAsync(keyFor(userId), function(oldData)
			-- Only save if session lock matches (prevent overwriting other server's data)
			if oldData and oldData.SessionLock and oldData.SessionLock ~= SessionLocks[userId] then
				warn(string.format("[DataService] Session lock changed during save for UserId %d", userId))
				return nil -- Don't save
			end
			
			return profileCopy
		end)
	end, isShuttingDown and 5 or MAX_RETRIES)
	
	IsSaving[userId] = false
	
	if success then
		-- print(string.format("[DataService] ✓ Saved profile for UserId %d (Coins: %d, Seeds: %d types, Plants: %d slots)", userId, profile.Coins or 0, seedCount, plantCount))
	else
		warn(string.format("[DataService] ✗ Failed to save profile for UserId %d", userId))
	end
	
	return success
end

-- Autosave loop
local function AutosaveLoop()
	local lastAutosave = {}
	
	while true do
		task.wait(SAVE_INTERVAL)
		
		for userId, profile in pairs(Profiles) do
			local last = lastAutosave[userId] or 0
			
			if os.clock() - last >= SAVE_INTERVAL then
				local success = SaveProfile(userId, false)
				if success then 
					lastAutosave[userId] = os.clock()
				end
			end
		end
	end
end

-- Start autosave loop
task.spawn(AutosaveLoop)

-- Player join: Load profile
Players.PlayerAdded:Connect(function(player)
	local profile, loaded = LoadProfile(player.UserId)
	Profiles[player.UserId] = profile
	DataLoaded[player.UserId] = loaded
	
	if loaded then
		-- print(string.format("[DataService] ✓ Loaded profile for %s (UserId: %d)", player.Name, player.UserId))
	else
		warn(string.format("[DataService] ⚠ Using default profile for %s (UserId: %d)", player.Name, player.UserId))
	end
end)

-- Player leave: Save profile
Players.PlayerRemoving:Connect(function(player)
	local success = SaveProfile(player.UserId, false)
	
	-- Release session lock
	SessionLocks[player.UserId] = nil
	DataLoaded[player.UserId] = nil
	Profiles[player.UserId] = nil
end)

-- Shutdown: Save all profiles
game:BindToClose(function()
	-- print("[DataService] Server shutting down - saving all profiles...")
	
	local savePromises = {}
	for userId, _ in pairs(Profiles) do
		table.insert(savePromises, task.spawn(function()
			SaveProfile(userId, true)
		end))
	end
	
	-- Wait for all saves to complete (with timeout)
	task.wait(5)
	-- print("[DataService] Shutdown save complete")
end)

-- Public API

-- Get a player's profile
function DataService.GetProfile(userId)
	return Profiles[userId]
end

-- Add coins to a player
function DataService.AddCoins(userId, amount)
	local profile = Profiles[userId]
	if not profile then return false end
	
	profile.Coins = math.max(0, (profile.Coins or 0) + math.floor(amount))
	return true
end

-- Remove coins from a player
function DataService.RemoveCoins(userId, amount)
	local profile = Profiles[userId]
	if not profile then return false end
	
	if profile.Coins < amount then return false end
	
	profile.Coins = profile.Coins - math.floor(amount)
	return true
end

-- Get coins
function DataService.GetCoins(userId)
	local profile = Profiles[userId]
	return profile and profile.Coins or 0
end

-- Get plant slot state (for specific slot 1-16)
function DataService.GetPlantSlot(userId, slotIndex)
	local profile = Profiles[userId]
	if not profile then return nil end
	
	return profile.PlantSlots[slotIndex]
end

-- Set plant slot state
function DataService.SetPlantSlot(userId, slotIndex, plantData)
	local profile = Profiles[userId]
	if not profile then return false end
	
	profile.PlantSlots[slotIndex] = plantData
	return true
end

-- Get all plant slots
function DataService.GetAllPlantSlots(userId)
	local profile = Profiles[userId]
	if not profile then return {} end
	
	return profile.PlantSlots or {}
end

-- Clear plant slot
function DataService.ClearPlantSlot(userId, slotIndex)
	local profile = Profiles[userId]
	if not profile then return false end
	
	profile.PlantSlots[slotIndex] = nil
	return true
end

-- Get inventory
function DataService.GetInventory(userId)
	local profile = Profiles[userId]
	return profile and profile.Inventory or {Seeds = {}, Pets = {}, Eggs = {}, Fruits = {}}
end

-- Add seed to inventory
function DataService.AddSeed(userId, plantType, amount)
	local profile = Profiles[userId]
	if not profile then return false end
	
	amount = amount or 1
	profile.Inventory.Seeds[plantType] = (profile.Inventory.Seeds[plantType] or 0) + amount
	return true
end

-- Remove seed from inventory
function DataService.RemoveSeed(userId, plantType)
	local profile = Profiles[userId]
	if not profile then return false end
	
	if not profile.Inventory.Seeds[plantType] or profile.Inventory.Seeds[plantType] <= 0 then
		return false
	end
	
	profile.Inventory.Seeds[plantType] = profile.Inventory.Seeds[plantType] - 1
	return true
end

-- Get seed count
function DataService.GetSeedCount(userId, plantType)
	local profile = Profiles[userId]
	if not profile then return 0 end
	
	return profile.Inventory.Seeds[plantType] or 0
end

-- ============================================================================
-- EGG MANAGEMENT
-- ============================================================================

-- Add egg to inventory
function DataService.AddEgg(userId, eggType, amount)
	local profile = Profiles[userId]
	if not profile then return false end
	
	amount = amount or 1
	profile.Inventory.Eggs = profile.Inventory.Eggs or {}
	profile.Inventory.Eggs[eggType] = (profile.Inventory.Eggs[eggType] or 0) + amount
	return true
end

-- Remove egg from inventory
function DataService.RemoveEgg(userId, eggType)
	local profile = Profiles[userId]
	if not profile then return false end
	
	profile.Inventory.Eggs = profile.Inventory.Eggs or {}
	if not profile.Inventory.Eggs[eggType] or profile.Inventory.Eggs[eggType] <= 0 then
		return false
	end
	
	profile.Inventory.Eggs[eggType] = profile.Inventory.Eggs[eggType] - 1
	return true
end

-- Get egg count
function DataService.GetEggCount(userId, eggType)
	local profile = Profiles[userId]
	if not profile then return 0 end
	
	profile.Inventory.Eggs = profile.Inventory.Eggs or {}
	return profile.Inventory.Eggs[eggType] or 0
end

-- Get all eggs
function DataService.GetAllEggs(userId)
	local profile = Profiles[userId]
	if not profile then return {} end
	
	return profile.Inventory.Eggs or {}
end

-- ============================================================================
-- PET MANAGEMENT (Instance-based with unique IDs)
-- ============================================================================

-- Add a new pet instance to inventory
-- Returns the new pet instance data or nil on failure
function DataService.AddPetInstance(userId, petType, size, weight)
	local profile = Profiles[userId]
	if not profile then return nil end
	
	-- Ensure Pets is an array
	if not profile.Inventory.Pets or type(profile.Inventory.Pets) ~= "table" then
		profile.Inventory.Pets = {}
	end
	
	-- Generate unique ID and random size/weight if not provided
	local HttpService = game:GetService("HttpService")
	local petId = HttpService:GenerateGUID(false)
	
	size = size or (0.8 + math.random() * 0.4)
	weight = weight or (0.7 + math.random() * 0.6)
	size = math.floor(size * 100 + 0.5) / 100
	weight = math.floor(weight * 100 + 0.5) / 100
	
	local petInstance = {
		Id = petId,
		PetType = petType,
		Size = size,
		Weight = weight
	}
	
	table.insert(profile.Inventory.Pets, petInstance)
	return petInstance
end

-- Get a pet instance by ID
function DataService.GetPetInstance(userId, petId)
	local profile = Profiles[userId]
	if not profile or not profile.Inventory.Pets then return nil end
	
	for _, pet in ipairs(profile.Inventory.Pets) do
		if pet.Id == petId then
			return pet
		end
	end
	return nil
end

-- Get all pet instances
function DataService.GetAllPets(userId)
	local profile = Profiles[userId]
	if not profile then return {} end
	
	return profile.Inventory.Pets or {}
end

-- Check if player owns a pet by ID
function DataService.HasPetById(userId, petId)
	return DataService.GetPetInstance(userId, petId) ~= nil
end

-- Check if player owns any pet of a given type (legacy compatibility)
function DataService.HasPet(userId, petType)
	local profile = Profiles[userId]
	if not profile or not profile.Inventory.Pets then return false end
	
	for _, pet in ipairs(profile.Inventory.Pets) do
		if pet.PetType == petType then
			return true
		end
	end
	return false
end

-- Add pet to inventory (legacy compatibility - creates a new instance)
function DataService.AddPet(userId, petType)
	local instance = DataService.AddPetInstance(userId, petType)
	return instance ~= nil
end

-- Equip a pet by instance ID (max 3)
function DataService.EquipPet(userId, petId)
	local profile = Profiles[userId]
	if not profile then return false end
	
	-- Check if player owns this pet instance
	local petInstance = DataService.GetPetInstance(userId, petId)
	if not petInstance then
		warn("Player doesn't own pet instance:", petId)
		return false
	end
	
	-- Initialize EquippedPets if needed
	if not profile.EquippedPets then
		profile.EquippedPets = {}
	end
	
	-- Check if already equipped
	for _, equippedId in ipairs(profile.EquippedPets) do
		if equippedId == petId then
			warn("Pet already equipped:", petId)
			return false
		end
	end
	
	-- Check if pet is in garden (can't be both)
	if profile.GardenPets then
		for _, gardenId in ipairs(profile.GardenPets) do
			if gardenId == petId then
				warn("Pet is in garden, unassign first:", petId)
				return false
			end
		end
	end
	
	-- Check max equipped pets (now 3)
	if #profile.EquippedPets >= 3 then
		warn("Maximum equipped pets reached (3)")
		return false
	end
	
	table.insert(profile.EquippedPets, petId)
	return true
end

-- Unequip a pet by instance ID
function DataService.UnequipPet(userId, petId)
	local profile = Profiles[userId]
	if not profile then return false end
	
	if not profile.EquippedPets then
		profile.EquippedPets = {}
		return false
	end
	
	for i, equippedId in ipairs(profile.EquippedPets) do
		if equippedId == petId then
			table.remove(profile.EquippedPets, i)
			return true
		end
	end
	
	return false
end

-- Add pet to garden by instance ID (max 7)
function DataService.AddGardenPet(userId, petId)
	local profile = Profiles[userId]
	if not profile then return false end
	
	-- Check if player owns this pet instance
	local petInstance = DataService.GetPetInstance(userId, petId)
	if not petInstance then
		warn("Player doesn't own pet instance:", petId)
		return false
	end
	
	-- Initialize GardenPets if needed
	if not profile.GardenPets then
		profile.GardenPets = {}
	end
	
	-- Check if already in garden
	for _, gardenId in ipairs(profile.GardenPets) do
		if gardenId == petId then
			warn("Pet already in garden:", petId)
			return false
		end
	end
	
	-- Check if pet is equipped (can't be both)
	if profile.EquippedPets then
		for _, equippedId in ipairs(profile.EquippedPets) do
			if equippedId == petId then
				warn("Pet is equipped, unequip first:", petId)
				return false
			end
		end
	end
	
	-- Check max garden pets (now 7)
	if #profile.GardenPets >= 7 then
		warn("Maximum garden pets reached (7)")
		return false
	end
	
	table.insert(profile.GardenPets, petId)
	return true
end

-- Remove pet from garden by instance ID
function DataService.RemoveGardenPet(userId, petId)
	local profile = Profiles[userId]
	if not profile then return false end
	
	if not profile.GardenPets then
		profile.GardenPets = {}
		return false
	end
	
	for i, gardenId in ipairs(profile.GardenPets) do
		if gardenId == petId then
			table.remove(profile.GardenPets, i)
			return true
		end
	end
	
	return false
end

-- Get equipped pet IDs
function DataService.GetEquippedPets(userId)
	local profile = Profiles[userId]
	if not profile then return {} end
	
	return profile.EquippedPets or {}
end

-- Get equipped pet instances (full data)
function DataService.GetEquippedPetInstances(userId)
	local profile = Profiles[userId]
	if not profile then return {} end
	
	local instances = {}
	for _, petId in ipairs(profile.EquippedPets or {}) do
		local pet = DataService.GetPetInstance(userId, petId)
		if pet then
			table.insert(instances, pet)
		end
	end
	return instances
end

-- Get garden pet IDs
function DataService.GetGardenPets(userId)
	local profile = Profiles[userId]
	if not profile then return {} end
	
	return profile.GardenPets or {}
end

-- Get garden pet instances (full data)
function DataService.GetGardenPetInstances(userId)
	local profile = Profiles[userId]
	if not profile then return {} end
	
	local instances = {}
	for _, petId in ipairs(profile.GardenPets or {}) do
		local pet = DataService.GetPetInstance(userId, petId)
		if pet then
			table.insert(instances, pet)
		end
	end
	return instances
end

-- Add fruit instance to inventory (with weight based on plant size)
function DataService.AddFruitInstance(userId, fruitType, weight)
	local profile = Profiles[userId]
	if not profile then return false end
	
	weight = weight or 1.0 -- Default weight 1.0 lbs
	
	local fruitInstance = {
		Id = game:GetService("HttpService"):GenerateGUID(false),
		Type = fruitType,
		Weight = math.floor(weight * 100 + 0.5) / 100 -- Round to 2 decimals
	}
	
	table.insert(profile.Inventory.Fruits, fruitInstance)
	return true, fruitInstance
end

-- Remove fruit instance by ID
function DataService.RemoveFruitById(userId, fruitId)
	local profile = Profiles[userId]
	if not profile then return false end
	
	for i, fruit in ipairs(profile.Inventory.Fruits) do
		if fruit.Id == fruitId then
			table.remove(profile.Inventory.Fruits, i)
			return true, fruit
		end
	end
	return false
end

-- Get all fruit instances of a type
function DataService.GetFruitsByType(userId, fruitType)
	local profile = Profiles[userId]
	if not profile then return {} end
	
	local fruits = {}
	for _, fruit in ipairs(profile.Inventory.Fruits) do
		if fruit.Type == fruitType then
			table.insert(fruits, fruit)
		end
	end
	return fruits
end

-- Get total fruit count of a type
function DataService.GetFruitCount(userId, fruitType)
	local profile = Profiles[userId]
	if not profile then return 0 end
	
	local count = 0
	for _, fruit in ipairs(profile.Inventory.Fruits) do
		if fruit.Type == fruitType then
			count = count + 1
		end
	end
	return count
end

-- Legacy function for backward compatibility (deprecated)
function DataService.AddFruit(userId, fruitName, amount)
	local profile = Profiles[userId]
	if not profile then return false end
	
	-- For negative amounts (selling), remove fruits
	if amount and amount < 0 then
		local toRemove = math.abs(amount)
		local removed = 0
		for i = #profile.Inventory.Fruits, 1, -1 do
			if profile.Inventory.Fruits[i].Type == fruitName then
				table.remove(profile.Inventory.Fruits, i)
				removed = removed + 1
				if removed >= toRemove then break end
			end
		end
		return removed >= toRemove
	end
	
	-- For positive amounts, add with default weight (legacy behavior)
	amount = amount or 1
	for i = 1, amount do
		DataService.AddFruitInstance(userId, fruitName, 1.0)
	end
	return true
end

-- Force save a player's profile (useful for important actions)
function DataService.ForceSave(userId)
	return SaveProfile(userId, false)
end

-- Check if player data is loaded
function DataService.IsDataLoaded(userId)
	return DataLoaded[userId] == true
end

print("💾 DataService initialized")

return DataService
