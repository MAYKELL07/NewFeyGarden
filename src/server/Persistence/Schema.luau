-- Schema.luau
-- Defines the data structure version and migration paths for player save data

local Schema = {}

Schema.CurrentVersion = 1

-- Returns a fresh default profile
function Schema.Default()
	return {
		Version = Schema.CurrentVersion,
		Coins = 100, -- Starting coins
		Inventory = {
			Seeds = {}, -- {PlantType = count}
			Pets = {}, -- {PetType = owned}
			Fruits = {} -- {FruitName = count}
		},
		EquippedPet = nil, -- Currently equipped pet type
		PlantSlots = {}, -- {[slotIndex] = {Type, Stage, WateredUntil, PetBoost}}
		SessionLock = nil, -- Session lock for preventing conflicts
		SessionLockTime = 0,
		LastSaved = os.time(),
	}
end

-- Migrates old data to current version
function Schema.Migrate(data)
	if not data or type(data) ~= "table" then
		warn("Schema.Migrate: Invalid data, returning default")
		return Schema.Default()
	end
	
	-- Ensure version exists
	if not data.Version then
		data.Version = 1
	end
	
	-- Add missing fields safely
	data.Coins = data.Coins or 100
	data.Inventory = data.Inventory or {Seeds = {}, Pets = {}, Fruits = {}}
	data.Inventory.Seeds = data.Inventory.Seeds or {}
	data.Inventory.Pets = data.Inventory.Pets or {}
	data.Inventory.Fruits = data.Inventory.Fruits or {}
	data.EquippedPet = data.EquippedPet or nil
	data.PlantSlots = data.PlantSlots or {}
	data.SessionLock = data.SessionLock or nil
	data.SessionLockTime = data.SessionLockTime or 0
	data.LastSaved = data.LastSaved or os.time()
	
	-- Remove old/invalid fields
	data.OwnedPlots = nil
	data.Garden = nil
	
	-- Validate PlantSlots structure
	if type(data.PlantSlots) == "table" then
		for slotIndex, slotData in pairs(data.PlantSlots) do
			if type(slotData) ~= "table" or not slotData.Type then
				data.PlantSlots[slotIndex] = nil
			end
		end
	end
	
	-- Future version migrations would go here
	-- if data.Version < 2 then
	--     -- Upgrade v1 to v2
	-- end
	
	data.Version = Schema.CurrentVersion
	return data
end

return Schema
