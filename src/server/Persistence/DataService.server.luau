-- DataService.server.luau
-- Handles persistent player data using DataStoreService with autosave and retry logic

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schema = require(script.Parent.Schema)

local DataService = {}

-- Configuration
local STORE_NAME = "FeyGarden_Player_v1"
local SAVE_INTERVAL = 60 -- seconds between autosaves
local MAX_RETRIES = 5

-- Storage
local PlayerStore = DataStoreService:GetDataStore(STORE_NAME)
local Profiles = {} -- [UserId] = profile data table
local LastSave = {} -- [UserId] = os.clock() timestamp

-- Helper: Generate key for a user
local function keyFor(userId)
	return "p:" .. tostring(userId)
end

-- Helper: Retry a function with exponential backoff
local function retry(fn)
	local tries = 0
	local lastErr = nil
	
	while tries < MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then 
			return true, result 
		end
		
		tries = tries + 1
		lastErr = result
		task.wait(0.5 * tries) -- exponential backoff
		warn("DataStore retry", tries, "/", MAX_RETRIES, "Error:", lastErr)
	end
	
	warn("DataStore retries exceeded:", lastErr)
	return false, lastErr
end

-- Load profile from DataStore
local function LoadProfile(userId)
	print("DataService: Loading profile for UserId", userId)
	
	local ok, data = retry(function()
		return PlayerStore:GetAsync(keyFor(userId))
	end)
	
	if not ok then
		warn("DataService: Failed to load, using default profile for", userId)
		return Schema.Default()
	end
	
	if not data then
		print("DataService: No existing data, creating new profile for", userId)
		return Schema.Default()
	end
	
	print("DataService: Successfully loaded profile for", userId)
	return Schema.Migrate(data)
end

-- Save profile to DataStore
local function SaveProfile(userId)
	local profile = Profiles[userId]
	if not profile then 
		warn("DataService: No profile to save for", userId)
		return false
	end
	
	profile.Version = Schema.CurrentVersion
	
	print("DataService: Saving profile for UserId", userId)
	
	local ok = retry(function()
		return PlayerStore:UpdateAsync(keyFor(userId), function(old)
			-- Last write wins (single-writer per user per server)
			return profile
		end)
	end)
	
	if ok then
		print("DataService: Successfully saved profile for", userId)
	else
		warn("DataService: Failed to save profile for", userId)
	end
	
	return ok
end

-- Autosave loop
local function AutosaveLoop()
	while true do
		task.wait(SAVE_INTERVAL)
		
		for userId, profile in pairs(Profiles) do
			local last = LastSave[userId] or 0
			
			if os.clock() - last >= SAVE_INTERVAL then
				local ok = SaveProfile(userId)
				if ok then 
					LastSave[userId] = os.clock()
					print("DataService: Autosaved profile for", userId)
				end
			end
		end
	end
end

-- Start autosave loop
task.spawn(AutosaveLoop)

-- Player join: Load profile
Players.PlayerAdded:Connect(function(player)
	print("DataService: Player joined:", player.Name, "UserId:", player.UserId)
	
	local profile = LoadProfile(player.UserId)
	Profiles[player.UserId] = profile
	LastSave[player.UserId] = os.clock()
	
	print("DataService: Profile loaded - Coins:", profile.Coins, "OwnedPlots:", #profile.OwnedPlots)
end)

-- Player leave: Save profile
Players.PlayerRemoving:Connect(function(player)
	print("DataService: Player leaving:", player.Name)
	SaveProfile(player.UserId)
	
	Profiles[player.UserId] = nil
	LastSave[player.UserId] = nil
end)

-- Shutdown: Save all profiles
game:BindToClose(function()
	print("DataService: Server shutting down, saving all profiles...")
	
	for userId, _ in pairs(Profiles) do
		SaveProfile(userId)
	end
	
	print("DataService: All profiles saved on shutdown")
	
	-- Give a moment for the last saves to complete
	task.wait(3)
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

-- Get plant state for a specific plot
function DataService.GetPlantState(userId, plotName)
	local profile = Profiles[userId]
	if not profile then return nil end
	
	profile.Garden[plotName] = profile.Garden[plotName] or {}
	return profile.Garden[plotName]
end

-- Set plant state for a specific plot
function DataService.SetPlantState(userId, plotName, stateTable)
	local profile = Profiles[userId]
	if not profile then return false end
	
	profile.Garden[plotName] = stateTable
	return true
end

-- Add an owned plot
function DataService.AddOwnedPlot(userId, plotName)
	local profile = Profiles[userId]
	if not profile then return false end
	
	local owned = profile.OwnedPlots
	
	-- Check if already owned
	for _, name in ipairs(owned) do
		if name == plotName then return true end
	end
	
	table.insert(owned, plotName)
	print("DataService: Added owned plot", plotName, "to user", userId)
	return true
end

-- Remove an owned plot
function DataService.RemoveOwnedPlot(userId, plotName)
	local profile = Profiles[userId]
	if not profile then return false end
	
	local owned = profile.OwnedPlots
	
	for i, name in ipairs(owned) do
		if name == plotName then
			table.remove(owned, i)
			print("DataService: Removed owned plot", plotName, "from user", userId)
			return true
		end
	end
	
	return false
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

print("💾 DataService initialized")

return DataService
