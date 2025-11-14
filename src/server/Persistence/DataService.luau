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
	return profile and profile.Inventory or {Seeds = {}, Pets = {}}
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

-- Add pet to inventory
function DataService.AddPet(userId, petType)
	local profile = Profiles[userId]
	if not profile then return false end
	
	profile.Inventory.Pets[petType] = true
	return true
end

-- Check if player owns a pet
function DataService.HasPet(userId, petType)
	local profile = Profiles[userId]
	if not profile then return false end
	
	return profile.Inventory.Pets[petType] == true
end

-- Equip a pet
function DataService.EquipPet(userId, petType)
	local profile = Profiles[userId]
	if not profile then return false end
	
	-- Check if player owns this pet
	if not profile.Inventory.Pets[petType] then
		warn("Player doesn't own pet:", petType)
		return false
	end
	
	profile.EquippedPet = petType
	-- print(string.format("[DataService] Player %d equipped pet: %s", userId, petType))
	return true
end

-- Get equipped pet
function DataService.GetEquippedPet(userId)
	local profile = Profiles[userId]
	if not profile then return nil end
	
	return profile.EquippedPet
end

-- Add fruit to inventory
function DataService.AddFruit(userId, fruitName, amount)
	local profile = Profiles[userId]
	if not profile then return false end
	
	amount = amount or 1
	profile.Inventory.Fruits[fruitName] = (profile.Inventory.Fruits[fruitName] or 0) + amount
	-- print(string.format("[DataService] Player %d received %dx %s (Total: %d)", userId, amount, fruitName, profile.Inventory.Fruits[fruitName]))
	return true
end

-- Get fruit count
function DataService.GetFruitCount(userId, fruitName)
	local profile = Profiles[userId]
	if not profile then return 0 end
	
	return profile.Inventory.Fruits[fruitName] or 0
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
