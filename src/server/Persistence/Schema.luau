-- Schema.luau
-- Defines the data structure version and migration paths for player save data

local Schema = {}

Schema.CurrentVersion = 1

-- Returns a fresh default profile
function Schema.Default()
	return {
		Version = Schema.CurrentVersion,
		Coins = 1000000000, -- Starting coins
		Inventory = {
			Seeds = {}, -- {PlantType = count}
			Pets = {}, -- {PetType = owned}
			Fruits = {} -- {FruitName = count}
		},
		EquippedPets = {}, -- Array of up to 2 pets equipped to player (follow player)
		GardenPets = {}, -- Array of up to 5 pets in garden (roam in garden)
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
	data.Coins = data.Coins or 10000000000
	data.Inventory = data.Inventory or {Seeds = {}, Pets = {}, Fruits = {}}
	data.Inventory.Seeds = data.Inventory.Seeds or {}
	data.Inventory.Pets = data.Inventory.Pets or {}
	data.Inventory.Fruits = data.Inventory.Fruits or {}
	
	-- Migrate old EquippedPet to new EquippedPets array
	if data.EquippedPet and type(data.EquippedPet) == "string" then
		data.EquippedPets = {data.EquippedPet}
		data.EquippedPet = nil
	end
	
	data.EquippedPets = data.EquippedPets or {}
	data.GardenPets = data.GardenPets or {}
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
