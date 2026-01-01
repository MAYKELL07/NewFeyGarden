-- Schema.luau
-- Defines the data structure version and migration paths for player save data

local Schema = {}

Schema.CurrentVersion = 3

-- Returns a fresh default profile
function Schema.Default()
	return {
		Version = Schema.CurrentVersion,
		Coins = 1000000000, -- Starting coins
		Inventory = {
			Seeds = {}, -- {PlantType = count}
			Pets = {}, -- Array of pet instances: {Id, PetType, Size, Weight}
			Eggs = {}, -- {EggType = count}
			Fruits = {}, -- Array of fruit instances: {Id, Type, Weight}
			Gear = {} -- {GearType = true} - owned gear
		},
		EquippedPets = {}, -- Array of pet instance IDs (up to 3)
		GardenPets = {}, -- Array of pet instance IDs (up to 7)
		PlantSlots = {}, -- {[slotIndex] = {Id, Type, Stage, PlantTime, WateredUntil, PetBoost, Size, Weight}}
		FreePlants = {}, -- {[plantId] = {Id, Type, Stage, PlantTime, Position, WateredUntil, PetBoost, Size, Weight}}
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
	data.Inventory = data.Inventory or {Seeds = {}, Pets = {}, Eggs = {}, Fruits = {}, Gear = {}}
	data.Inventory.Seeds = data.Inventory.Seeds or {}
	data.Inventory.Eggs = data.Inventory.Eggs or {}
	data.Inventory.Fruits = data.Inventory.Fruits or {}
	data.Inventory.Gear = data.Inventory.Gear or {}
	
	-- Migrate old EquippedPet to new EquippedPets array
	if data.EquippedPet and type(data.EquippedPet) == "string" then
		data.EquippedPets = {data.EquippedPet}
		data.EquippedPet = nil
	end
	
	data.EquippedPets = data.EquippedPets or {}
	data.GardenPets = data.GardenPets or {}
	data.PlantSlots = data.PlantSlots or {}
	data.FreePlants = data.FreePlants or {} -- Free-form planting data
	data.SessionLock = data.SessionLock or nil
	data.SessionLockTime = data.SessionLockTime or 0
	data.LastSaved = data.LastSaved or os.time()
	
	-- Remove old/invalid fields
	data.OwnedPlots = nil
	data.Garden = nil
	
	-- =========================================================================
	-- VERSION 1 -> 2 MIGRATION: Convert pets from boolean map to instance array
	-- =========================================================================
	if data.Version < 2 then
		-- Check if Pets is in old format (boolean map)
		local oldPets = data.Inventory.Pets
		if oldPets and type(oldPets) == "table" then
			local isOldFormat = false
			for petType, value in pairs(oldPets) do
				if type(value) == "boolean" then
					isOldFormat = true
					break
				end
			end
			
			if isOldFormat then
				-- Convert old format {petType = true} to new format [{Id, PetType, Size, Weight}]
				local newPets = {}
				for petType, owned in pairs(oldPets) do
					if owned == true then
						-- Generate random size/weight for migrated pets
						local size = 0.8 + math.random() * 0.4 -- 0.8 to 1.2
						local weight = 0.7 + math.random() * 0.6 -- 0.7 to 1.3
						size = math.floor(size * 100 + 0.5) / 100
						weight = math.floor(weight * 100 + 0.5) / 100
						
						table.insert(newPets, {
							Id = game:GetService("HttpService"):GenerateGUID(false),
							PetType = petType,
							Size = size,
							Weight = weight
						})
					end
				end
				data.Inventory.Pets = newPets
				
				-- Convert EquippedPets from pet types to instance IDs
				if data.EquippedPets and #data.EquippedPets > 0 then
					local newEquipped = {}
					for _, petType in ipairs(data.EquippedPets) do
						-- Find the pet instance with this type
						for _, petInstance in ipairs(newPets) do
							if petInstance.PetType == petType then
								table.insert(newEquipped, petInstance.Id)
								break
							end
						end
					end
					data.EquippedPets = newEquipped
				end
				
				-- Convert GardenPets from pet types to instance IDs
				if data.GardenPets and #data.GardenPets > 0 then
					local newGarden = {}
					for _, petType in ipairs(data.GardenPets) do
						-- Find the pet instance with this type (not already in equipped)
						for _, petInstance in ipairs(newPets) do
							if petInstance.PetType == petType then
								local alreadyUsed = false
								for _, equippedId in ipairs(data.EquippedPets) do
									if petInstance.Id == equippedId then
										alreadyUsed = true
										break
									end
								end
								if not alreadyUsed then
									table.insert(newGarden, petInstance.Id)
									break
								end
							end
						end
					end
					data.GardenPets = newGarden
				end
			end
		end
		
		-- Migrate PlantSlots to include Id, Size, Weight
		if data.PlantSlots and type(data.PlantSlots) == "table" then
			for slotIndex, slotData in pairs(data.PlantSlots) do
				if type(slotData) == "table" then
					if not slotData.Id then
						slotData.Id = game:GetService("HttpService"):GenerateGUID(false)
					end
					if not slotData.Size then
						local size = 0.85 + math.random() * 0.3 -- 0.85 to 1.15
						slotData.Size = math.floor(size * 100 + 0.5) / 100
					end
					if not slotData.Weight then
						local weight = 0.8 + math.random() * 0.4 -- 0.8 to 1.2
						slotData.Weight = math.floor(weight * 100 + 0.5) / 100
					end
				end
			end
		end
	end
	
	-- Validate Pets is now an array
	if data.Inventory.Pets and type(data.Inventory.Pets) == "table" then
		-- Check if it's actually an array (numeric keys)
		local isArray = true
		for k, _ in pairs(data.Inventory.Pets) do
			if type(k) ~= "number" then
				isArray = false
				break
			end
		end
		if not isArray then
			-- Reset to empty array if still not migrated properly
			data.Inventory.Pets = {}
		end
	else
		data.Inventory.Pets = {}
	end
	
	-- Validate PlantSlots structure
	if type(data.PlantSlots) == "table" then
		for slotIndex, slotData in pairs(data.PlantSlots) do
			if type(slotData) ~= "table" or not slotData.Type then
				data.PlantSlots[slotIndex] = nil
			end
		end
	end
	
	-- Future version migrations would go here
	-- =========================================================================
	-- VERSION 2 -> 3 MIGRATION: Convert fruits from count map to instance array
	-- =========================================================================
	if data.Version < 3 then
		local oldFruits = data.Inventory.Fruits
		if oldFruits and type(oldFruits) == "table" then
			-- Check if it's in old format (string key = number count)
			local isOldFormat = false
			for fruitType, value in pairs(oldFruits) do
				if type(fruitType) == "string" and type(value) == "number" then
					isOldFormat = true
					break
				end
			end
			
			if isOldFormat then
				-- Convert old format {fruitType = count} to new format [{Id, Type, Weight}]
				local newFruits = {}
				for fruitType, count in pairs(oldFruits) do
					if type(count) == "number" and count > 0 then
						-- Create individual fruit instances for each count
						-- Use average weight (1.0 lbs) for migrated fruits
						for i = 1, math.min(count, 100) do -- Cap at 100 to prevent lag
							table.insert(newFruits, {
								Id = game:GetService("HttpService"):GenerateGUID(false),
								Type = fruitType,
								Weight = 1.0 -- Default 1.0 lbs for migrated fruits
							})
						end
					end
				end
				data.Inventory.Fruits = newFruits
			end
		end
	end
	
	-- Validate Fruits is now an array
	if data.Inventory.Fruits and type(data.Inventory.Fruits) == "table" then
		local isArray = true
		for k, _ in pairs(data.Inventory.Fruits) do
			if type(k) ~= "number" then
				isArray = false
				break
			end
		end
		if not isArray then
			data.Inventory.Fruits = {}
		end
	else
		data.Inventory.Fruits = {}
	end
	
	data.Version = Schema.CurrentVersion
	return data
end

return Schema
