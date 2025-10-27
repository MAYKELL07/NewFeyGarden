-- Schema.luau
-- Defines the data structure version and migration paths for player save data

local Schema = {}

Schema.CurrentVersion = 1

-- Returns a fresh default profile
function Schema.Default()
	return {
		Version = Schema.CurrentVersion,
		Coins = 0,
		Inventory = {
			Seeds = {}, -- {PlantType = count}
			Pets = {}   -- {PetType = owned}
		},
		PlantSlots = {}, -- {[slotIndex] = {Type, Stage, WateredUntil, PetBoost}}
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
	data.Coins = data.Coins or 0
	data.Inventory = data.Inventory or {Seeds = {}, Pets = {}}
	data.Inventory.Seeds = data.Inventory.Seeds or {}
	data.Inventory.Pets = data.Inventory.Pets or {}
	data.PlantSlots = data.PlantSlots or {}
	
	-- Remove old fields if they exist
	data.OwnedPlots = nil
	data.Garden = nil
	data.Garden = data.Garden or {}
	
	-- Future version migrations would go here
	-- if data.Version < 2 then
	--     -- Upgrade v1 to v2
	-- end
	
	data.Version = Schema.CurrentVersion
	return data
end

return Schema
