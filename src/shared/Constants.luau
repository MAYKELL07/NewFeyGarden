-- Constants.luau
-- Global constants for FeyGarden game

local Constants = {}

-- Weather Types
Constants.WEATHER_TYPES = {
	SUNNY = "Sunny",
	RAINY = "Rainy",
	STORMY = "Stormy"
}

-- Weather Configuration
Constants.WEATHER_CONFIG = {
	[Constants.WEATHER_TYPES.SUNNY] = {
		Brightness = 2,
		ColorShift_Top = Color3.fromRGB(255, 255, 255),
		GrowthMultiplier = 1.0,
		ClockTime = 14
	},
	[Constants.WEATHER_TYPES.RAINY] = {
		Brightness = 1,
		ColorShift_Top = Color3.fromRGB(180, 180, 255),
		GrowthMultiplier = 0.8, -- Faster growth in rain
		ClockTime = 12
	},
	[Constants.WEATHER_TYPES.STORMY] = {
		Brightness = 0.5,
		ColorShift_Top = Color3.fromRGB(100, 100, 120),
		GrowthMultiplier = 1.2, -- Even faster in storm
		ClockTime = 6
	}
}

-- Weather cycle time (seconds)
Constants.WEATHER_CYCLE_TIME = 60

-- Plant Types
Constants.PLANT_TYPES = {
	GLOWBUD = "Glowbud",
	DEWLEAF = "Dewleaf"
}

-- Plant Growth Stages
Constants.GROWTH_STAGES = {
	SEED = "Seed",
	SPROUT = "Sprout",
	BLOOM = "Bloom"
}

-- Plant Configuration
Constants.PLANT_CONFIG = {
	[Constants.PLANT_TYPES.GLOWBUD] = {
		SeedPrice = 50,
		SellPrice = 150,
		GrowthTime = 60, -- seconds per stage
		Color = Color3.fromRGB(255, 255, 100),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.DEWLEAF] = {
		SeedPrice = 30,
		SellPrice = 80,
		GrowthTime = 45,
		Color = Color3.fromRGB(100, 255, 150),
		EmitsLight = false
	}
}

-- Economy
Constants.STARTING_COINS = 200

-- Garden Plot Settings
Constants.PLOT_SIZE = Vector3.new(20, 1, 20)
Constants.PLOT_SPACING = 25
Constants.MAX_PLANTS_PER_PLOT = 9

-- Pet Types
Constants.PET_TYPES = {
	SPRIG = "Sprig"
}

-- Pet Configuration
Constants.PET_CONFIG = {
	[Constants.PET_TYPES.SPRIG] = {
		Price = 300,
		FollowDistance = 3,
		WaterBoost = 0.9, -- Makes plants grow 10% faster
		Color = Color3.fromRGB(100, 255, 100)
	}
}

-- RemoteEvent Names
Constants.EVENTS = {
	WEATHER_CHANGED = "WeatherChanged",
	PLANT_SEED = "PlantSeed",
	HARVEST_PLANT = "HarvestPlant",
	BUY_SEED = "BuySeed",
	BUY_PET = "BuyPet",
	EQUIP_PET = "EquipPet",
	UPDATE_CURRENCY = "UpdateCurrency",
	UPDATE_INVENTORY = "UpdateInventory"
}

return Constants
