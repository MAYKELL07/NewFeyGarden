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

-- Growth Stage Position Offsets (Y offset from PlantAnchor)
Constants.STAGE_OFFSETS = {
	[Constants.GROWTH_STAGES.SEED] = Vector3.new(0, 0.5, 0),    -- Small, low to ground
	[Constants.GROWTH_STAGES.SPROUT] = Vector3.new(0, 1.5, 0),  -- Medium height
	[Constants.GROWTH_STAGES.BLOOM] = Vector3.new(0, 2.5, 0)    -- Tall, fully grown
}

-- Plant Configuration
-- Economy Breakdown:
-- - SeedPrice: Cost to buy the seed
-- - FruitSellPrice: How much you get for selling 1 fruit (players only get 1 fruit per harvest)
-- - GrowthTime: Base time in seconds to grow from seed to bloom
-- 
-- Profit Formula: FruitSellPrice - SeedPrice = Net Profit per harvest
-- ROI (Return on Investment): (Profit / SeedPrice) * 100 = % return
-- Profit per Second: Profit / GrowthTime = efficiency rating
--
-- Balancing Strategy:
-- - STARTER PLANTS (Tier 1): Fast growth, low cost, quick returns to hook new players
-- - MID-TIER PLANTS (Tier 2): Better ROI but longer growth times, scaling rewards
-- - RARE PLANTS (Tier 3): Expensive, slow growth, but massive profits for late game

Constants.PLANT_CONFIG = {
	-- === TIER 1: STARTER PLANTS (Fast pace, quick hooks) ===
	
	[Constants.PLANT_TYPES.LUMUT] = {
		SeedPrice = 10,           -- Very cheap starter
		FruitSellPrice = 25,      -- Profit: 15 coins (150% ROI)
		GrowthTime = 30,          -- Fast! 0.5 coins/second
		Color = Color3.fromRGB(200, 255, 150),
		EmitsLight = true,
		Tier = 1
	},
	[Constants.PLANT_TYPES.CLOUDCAP] = {
		SeedPrice = 15,           -- Cheap starter
		FruitSellPrice = 35,      -- Profit: 20 coins (133% ROI)
		GrowthTime = 35,          -- 0.57 coins/second
		Color = Color3.fromRGB(220, 220, 255),
		EmitsLight = false,
		Tier = 1
	},
	[Constants.PLANT_TYPES.PUFFOT] = {
		SeedPrice = 20,           -- Early game
		FruitSellPrice = 45,      -- Profit: 25 coins (125% ROI)
		GrowthTime = 40,          -- 0.625 coins/second
		Color = Color3.fromRGB(255, 200, 150),
		EmitsLight = false,
		Tier = 1
	},
	[Constants.PLANT_TYPES.GLOWBUD] = {
		SeedPrice = 25,           -- Still affordable
		FruitSellPrice = 55,      -- Profit: 30 coins (120% ROI)
		GrowthTime = 45,          -- 0.67 coins/second (best T1 efficiency!)
		Color = Color3.fromRGB(255, 255, 100),
		EmitsLight = true,
		Tier = 1
	},
	
	-- === TIER 2: MID-GAME PLANTS (Better profits, longer commitment) ===
	
	[Constants.PLANT_TYPES.TWINKLELEAF] = {
		SeedPrice = 40,           -- Entry to mid-tier
		FruitSellPrice = 80,      -- Profit: 40 coins (100% ROI)
		GrowthTime = 50,          -- 0.8 coins/second
		Color = Color3.fromRGB(150, 255, 200),
		EmitsLight = true,
		Tier = 2
	},
	[Constants.PLANT_TYPES.CHAMELEONBERRI] = {
		SeedPrice = 50,           -- Mid-tier investment
		FruitSellPrice = 105,     -- Profit: 55 coins (110% ROI)
		GrowthTime = 55,          -- 1.0 coins/second
		Color = Color3.fromRGB(200, 100, 255),
		EmitsLight = false,
		Tier = 2
	},
	[Constants.PLANT_TYPES.DREAMSHROOM] = {
		SeedPrice = 60,           -- Higher investment
		FruitSellPrice = 130,     -- Profit: 70 coins (117% ROI)
		GrowthTime = 60,          -- 1.17 coins/second
		Color = Color3.fromRGB(150, 100, 200),
		EmitsLight = true,
		Tier = 2
	},
	[Constants.PLANT_TYPES.EVERSPRINGACORN] = {
		SeedPrice = 70,           -- Solid mid-tier
		FruitSellPrice = 155,     -- Profit: 85 coins (121% ROI)
		GrowthTime = 65,          -- 1.31 coins/second
		Color = Color3.fromRGB(100, 200, 100),
		EmitsLight = false,
		Tier = 2
	},
	[Constants.PLANT_TYPES.GLOWBUD] = {
		SeedPrice = 80,           -- Getting expensive
		FruitSellPrice = 180,     -- Profit: 100 coins (125% ROI)
		GrowthTime = 70,          -- 1.43 coins/second
		Color = Color3.fromRGB(255, 255, 100),
		EmitsLight = true,
		Tier = 2
	},
	
	-- === TIER 3: RARE/LATE GAME PLANTS (Big investments, massive returns) ===
	
	[Constants.PLANT_TYPES.STARVINEMELON] = {
		SeedPrice = 100,          -- Entry to rare tier
		FruitSellPrice = 240,     -- Profit: 140 coins (140% ROI)
		GrowthTime = 80,          -- 1.75 coins/second
		Color = Color3.fromRGB(255, 200, 100),
		EmitsLight = true,
		Tier = 3
	},
	[Constants.PLANT_TYPES.FROSTMIND] = {
		SeedPrice = 125,          -- Rare plant
		FruitSellPrice = 310,     -- Profit: 185 coins (148% ROI)
		GrowthTime = 90,          -- 2.06 coins/second
		Color = Color3.fromRGB(150, 200, 255),
		EmitsLight = true,
		Tier = 3
	},
	[Constants.PLANT_TYPES.DREAMFRUIT] = {
		SeedPrice = 150,          -- Very rare
		FruitSellPrice = 385,     -- Profit: 235 coins (157% ROI)
		GrowthTime = 100,         -- 2.35 coins/second
		Color = Color3.fromRGB(180, 150, 255),
		EmitsLight = true,
		Tier = 3
	},
	[Constants.PLANT_TYPES.SUNFLAREMANGO] = {
		SeedPrice = 175,          -- Premium plant
		FruitSellPrice = 465,     -- Profit: 290 coins (166% ROI)
		GrowthTime = 110,         -- 2.64 coins/second
		Color = Color3.fromRGB(255, 150, 50),
		EmitsLight = true,
		Tier = 3
	},
	[Constants.PLANT_TYPES.STARLILY] = {
		SeedPrice = 200,          -- Legendary tier
		FruitSellPrice = 550,     -- Profit: 350 coins (175% ROI)
		GrowthTime = 120,         -- 2.92 coins/second
		Color = Color3.fromRGB(255, 255, 255),
		EmitsLight = true,
		Tier = 3
	},
	[Constants.PLANT_TYPES.MOONVINE] = {
		SeedPrice = 250,          -- Ultra rare
		FruitSellPrice = 700,     -- Profit: 450 coins (180% ROI)
		GrowthTime = 135,         -- 3.33 coins/second
		Color = Color3.fromRGB(200, 200, 255),
		EmitsLight = true,
		Tier = 3
	},
	[Constants.PLANT_TYPES.WILLOWWHISP] = {
		SeedPrice = 300,          -- RAREST PLANT - Late game goal
		FruitSellPrice = 900,     -- Profit: 600 coins (200% ROI!)
		GrowthTime = 150,         -- 4.0 coins/second (BEST!)
		Color = Color3.fromRGB(200, 255, 255),
		EmitsLight = true,
		Tier = 3
	}
}

-- Economy
-- Starting coins: Enough to buy 5-6 starter plants (Lumut) and have buffer for mistakes
Constants.STARTING_COINS = 100

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
	UNEQUIP_PET = "UnequipPet",
	ADD_GARDEN_PET = "AddGardenPet",
	REMOVE_GARDEN_PET = "RemoveGardenPet",
	SELL_FRUIT = "SellFruit",
	UPDATE_CURRENCY = "UpdateCurrency",
	UPDATE_INVENTORY = "UpdateInventory"
}

return Constants
