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
	CHAMELEONBERRI = "chameleonberri",
	CLOUDCAP = "cloudcap",
	DREAMFRUIT = "dreamfruit",
	DREAMSHROOM = "dreamshroom",
	EVERSPRINGACORN = "everspringacorn",
	FROSTMIND = "frostmind",
	GLOWBUD = "glowbud",
	LUMUT = "lumut",
	MOONVINE = "moonvine",
	PUFFOT = "puffot",
	STARLILY = "starlily",
	STARVINEMELON = "starvinemelon",
	SUNFLAREMANGO = "sunflaremango",
	TWINKLELEAF = "twinkleleaf",
	WILLOWWHISP = "willowwhisp"
}

-- Plant Growth Stages
Constants.GROWTH_STAGES = {
	SEED = "Seed",
	SPROUT = "Sprout",
	BLOOM = "Bloom"
}

-- Plant Configuration
Constants.PLANT_CONFIG = {
	[Constants.PLANT_TYPES.CHAMELEONBERRI] = {
		SeedPrice = 40,
		SellPrice = 120,
		FruitSellPrice = 20,
		GrowthTime = 50,
		Color = Color3.fromRGB(200, 100, 255),
		EmitsLight = false
	},
	[Constants.PLANT_TYPES.CLOUDCAP] = {
		SeedPrice = 35,
		SellPrice = 100,
		FruitSellPrice = 18,
		GrowthTime = 45,
		Color = Color3.fromRGB(220, 220, 255),
		EmitsLight = false
	},
	[Constants.PLANT_TYPES.DREAMFRUIT] = {
		SeedPrice = 60,
		SellPrice = 180,
		FruitSellPrice = 30,
		GrowthTime = 70,
		Color = Color3.fromRGB(180, 150, 255),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.DREAMSHROOM] = {
		SeedPrice = 45,
		SellPrice = 130,
		FruitSellPrice = 22,
		GrowthTime = 55,
		Color = Color3.fromRGB(150, 100, 200),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.EVERSPRINGACORN] = {
		SeedPrice = 50,
		SellPrice = 150,
		FruitSellPrice = 25,
		GrowthTime = 60,
		Color = Color3.fromRGB(100, 200, 100),
		EmitsLight = false
	},
	[Constants.PLANT_TYPES.FROSTMIND] = {
		SeedPrice = 55,
		SellPrice = 160,
		FruitSellPrice = 28,
		GrowthTime = 65,
		Color = Color3.fromRGB(150, 200, 255),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.GLOWBUD] = {
		SeedPrice = 50,
		SellPrice = 150,
		FruitSellPrice = 25,
		GrowthTime = 60,
		Color = Color3.fromRGB(255, 255, 100),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.LUMUT] = {
		SeedPrice = 30,
		SellPrice = 90,
		FruitSellPrice = 15,
		GrowthTime = 40,
		Color = Color3.fromRGB(200, 255, 150),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.MOONVINE] = {
		SeedPrice = 70,
		SellPrice = 200,
		FruitSellPrice = 35,
		GrowthTime = 80,
		Color = Color3.fromRGB(200, 200, 255),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.PUFFOT] = {
		SeedPrice = 35,
		SellPrice = 100,
		FruitSellPrice = 18,
		GrowthTime = 45,
		Color = Color3.fromRGB(255, 200, 150),
		EmitsLight = false
	},
	[Constants.PLANT_TYPES.STARLILY] = {
		SeedPrice = 65,
		SellPrice = 190,
		FruitSellPrice = 32,
		GrowthTime = 75,
		Color = Color3.fromRGB(255, 255, 255),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.STARVINEMELON] = {
		SeedPrice = 55,
		SellPrice = 165,
		FruitSellPrice = 28,
		GrowthTime = 65,
		Color = Color3.fromRGB(255, 200, 100),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.SUNFLAREMANGO] = {
		SeedPrice = 60,
		SellPrice = 175,
		FruitSellPrice = 30,
		GrowthTime = 70,
		Color = Color3.fromRGB(255, 150, 50),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.TWINKLELEAF] = {
		SeedPrice = 40,
		SellPrice = 115,
		FruitSellPrice = 20,
		GrowthTime = 50,
		Color = Color3.fromRGB(150, 255, 200),
		EmitsLight = true
	},
	[Constants.PLANT_TYPES.WILLOWWHISP] = {
		SeedPrice = 75,
		SellPrice = 210,
		FruitSellPrice = 38,
		GrowthTime = 85,
		Color = Color3.fromRGB(200, 255, 255),
		EmitsLight = true
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
	CRYSTALOWL = "crystalowl",
	EMBERCAT = "embercat",
	EVERFLAMEGRIFFIN = "everflamegriffin",
	GLOWBUG = "glowbug",
	LEAFLING = "leafling",
	MOONDRAGON = "moondragon",
	MOSSYSLIME = "mossyslime",
	PEBBLEPUB = "pebblepub",
	PHANTOMELK = "phantomelk",
	PUFFSPIRIT = "puffspirit",
	SPARKFOX = "sparkfox",
	SPROUTTAIL = "sprouttail",
	STARLIGHTPHOENIX = "starlightphoenix",
	THORNBEAK = "thornbeak",
	WHISPRABBIT = "whisprabbit"
}

-- Pet Configuration
Constants.PET_CONFIG = {
	[Constants.PET_TYPES.CRYSTALOWL] = {
		Price = 500,
		FollowDistance = 3,
		WaterBoost = 0.85, -- Makes plants grow 15% faster
		Color = Color3.fromRGB(150, 200, 255)
	},
	[Constants.PET_TYPES.EMBERCAT] = {
		Price = 400,
		FollowDistance = 2.5,
		WaterBoost = 0.90, -- Makes plants grow 10% faster
		Color = Color3.fromRGB(255, 100, 50)
	},
	[Constants.PET_TYPES.EVERFLAMEGRIFFIN] = {
		Price = 800,
		FollowDistance = 4,
		WaterBoost = 0.75, -- Makes plants grow 25% faster
		Color = Color3.fromRGB(255, 150, 0)
	},
	[Constants.PET_TYPES.GLOWBUG] = {
		Price = 250,
		FollowDistance = 2,
		WaterBoost = 0.95, -- Makes plants grow 5% faster
		Color = Color3.fromRGB(255, 255, 100)
	},
	[Constants.PET_TYPES.LEAFLING] = {
		Price = 350,
		FollowDistance = 3,
		WaterBoost = 0.88, -- Makes plants grow 12% faster
		Color = Color3.fromRGB(100, 255, 100)
	},
	[Constants.PET_TYPES.MOONDRAGON] = {
		Price = 900,
		FollowDistance = 4.5,
		WaterBoost = 0.70, -- Makes plants grow 30% faster
		Color = Color3.fromRGB(200, 200, 255)
	},
	[Constants.PET_TYPES.MOSSYSLIME] = {
		Price = 300,
		FollowDistance = 2,
		WaterBoost = 0.92, -- Makes plants grow 8% faster
		Color = Color3.fromRGB(100, 200, 100)
	},
	[Constants.PET_TYPES.PEBBLEPUB] = {
		Price = 350,
		FollowDistance = 2.5,
		WaterBoost = 0.90, -- Makes plants grow 10% faster
		Color = Color3.fromRGB(150, 150, 150)
	},
	[Constants.PET_TYPES.PHANTOMELK] = {
		Price = 600,
		FollowDistance = 3.5,
		WaterBoost = 0.82, -- Makes plants grow 18% faster
		Color = Color3.fromRGB(180, 180, 255)
	},
	[Constants.PET_TYPES.PUFFSPIRIT] = {
		Price = 450,
		FollowDistance = 3,
		WaterBoost = 0.87, -- Makes plants grow 13% faster
		Color = Color3.fromRGB(255, 255, 255)
	},
	[Constants.PET_TYPES.SPARKFOX] = {
		Price = 550,
		FollowDistance = 3.5,
		WaterBoost = 0.83, -- Makes plants grow 17% faster
		Color = Color3.fromRGB(255, 200, 100)
	},
	[Constants.PET_TYPES.SPROUTTAIL] = {
		Price = 400,
		FollowDistance = 3,
		WaterBoost = 0.89, -- Makes plants grow 11% faster
		Color = Color3.fromRGB(150, 255, 100)
	},
	[Constants.PET_TYPES.STARLIGHTPHOENIX] = {
		Price = 1000,
		FollowDistance = 5,
		WaterBoost = 0.65, -- Makes plants grow 35% faster
		Color = Color3.fromRGB(255, 255, 200)
	},
	[Constants.PET_TYPES.THORNBEAK] = {
		Price = 500,
		FollowDistance = 3,
		WaterBoost = 0.85, -- Makes plants grow 15% faster
		Color = Color3.fromRGB(150, 100, 50)
	},
	[Constants.PET_TYPES.WHISPRABBIT] = {
		Price = 350,
		FollowDistance = 2.5,
		WaterBoost = 0.90, -- Makes plants grow 10% faster
		Color = Color3.fromRGB(200, 180, 255)
	}
}

-- RemoteEvent Names
Constants.EVENTS = {
	WEATHER_CHANGED = "WeatherChanged",
	PLANT_SEED = "PlantSeed",
	HARVEST_PLANT = "HarvestPlant",
	HARVEST_FRUIT = "HarvestFruit",
	BUY_SEED = "BuySeed",
	BUY_PET = "BuyPet",
	EQUIP_PET = "EquipPet",
	SELL_FRUIT = "SellFruit",
	UPDATE_CURRENCY = "UpdateCurrency",
	UPDATE_INVENTORY = "UpdateInventory"
}

return Constants
