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

-- =============================================================================
-- ROBUX SEED PURCHASES (Developer Products)
-- =============================================================================
-- ProductId is the Developer Product ID from the Roblox Creator Dashboard
-- RobuxPrice is for display purposes (actual price is set on Roblox)
-- SeedAmount is how many seeds the player receives per purchase
-- 
-- To set up:
-- 1. Create Developer Products in Game Settings > Monetization > Developer Products
-- 2. Set the Robux price for each product
-- 3. Copy the Product ID and paste it here
-- 
-- NOTE: ProductIds below are placeholders - replace with your actual IDs!
Constants.SEED_ROBUX_PRODUCTS = {
	-- Tier 1 Starter Seeds (5 Robux = 5 seeds bundle)
	[Constants.PLANT_TYPES.LUMUT] = {
		ProductId = 0, -- TODO: Replace with actual Developer Product ID
		RobuxPrice = 5,
		SeedAmount = 5,
		DisplayName = "Lumut Seed Pack"
	},
	[Constants.PLANT_TYPES.CLOUDCAP] = {
		ProductId = 0,
		RobuxPrice = 5,
		SeedAmount = 5,
		DisplayName = "Cloudcap Seed Pack"
	},
	[Constants.PLANT_TYPES.PUFFOT] = {
		ProductId = 0,
		RobuxPrice = 5,
		SeedAmount = 5,
		DisplayName = "Puffot Seed Pack"
	},
	[Constants.PLANT_TYPES.GLOWBUD] = {
		ProductId = 0,
		RobuxPrice = 5,
		SeedAmount = 5,
		DisplayName = "Glowbud Seed Pack"
	},
	
	-- Tier 2 Mid-Game Seeds (10 Robux = 5 seeds bundle)
	[Constants.PLANT_TYPES.TWINKLELEAF] = {
		ProductId = 0,
		RobuxPrice = 10,
		SeedAmount = 5,
		DisplayName = "Twinkleleaf Seed Pack"
	},
	[Constants.PLANT_TYPES.CHAMELEONBERRI] = {
		ProductId = 0,
		RobuxPrice = 10,
		SeedAmount = 5,
		DisplayName = "Chameleonberri Seed Pack"
	},
	[Constants.PLANT_TYPES.DREAMSHROOM] = {
		ProductId = 0,
		RobuxPrice = 10,
		SeedAmount = 5,
		DisplayName = "Dreamshroom Seed Pack"
	},
	[Constants.PLANT_TYPES.EVERSPRINGACORN] = {
		ProductId = 0,
		RobuxPrice = 10,
		SeedAmount = 5,
		DisplayName = "Everspringacorn Seed Pack"
	},
	
	-- Tier 3 Rare Seeds (25 Robux = 5 seeds bundle)
	[Constants.PLANT_TYPES.STARVINEMELON] = {
		ProductId = 0,
		RobuxPrice = 25,
		SeedAmount = 5,
		DisplayName = "Starvinemelon Seed Pack"
	},
	[Constants.PLANT_TYPES.FROSTMIND] = {
		ProductId = 0,
		RobuxPrice = 25,
		SeedAmount = 5,
		DisplayName = "Frostmind Seed Pack"
	},
	[Constants.PLANT_TYPES.DREAMFRUIT] = {
		ProductId = 0,
		RobuxPrice = 25,
		SeedAmount = 5,
		DisplayName = "Dreamfruit Seed Pack"
	},
	[Constants.PLANT_TYPES.SUNFLAREMANGO] = {
		ProductId = 0,
		RobuxPrice = 25,
		SeedAmount = 5,
		DisplayName = "Sunflaremango Seed Pack"
	},
	[Constants.PLANT_TYPES.STARLILY] = {
		ProductId = 0,
		RobuxPrice = 25,
		SeedAmount = 5,
		DisplayName = "Starlily Seed Pack"
	},
	[Constants.PLANT_TYPES.MOONVINE] = {
		ProductId = 0,
		RobuxPrice = 30,
		SeedAmount = 5,
		DisplayName = "Moonvine Seed Pack"
	},
	[Constants.PLANT_TYPES.WILLOWWHISP] = {
		ProductId = 0,
		RobuxPrice = 35,
		SeedAmount = 5,
		DisplayName = "Willowwhisp Seed Pack"
	}
}

-- Developer product for instant growth of all plants in the player's garden
Constants.GROW_ALL_PRODUCT = {
	ProductId = 0, -- TODO: Replace with actual Developer Product ID
	RobuxPrice = 49,
	DisplayName = "Grow All Plants"
}

-- Helper to get product ID by plant type
function Constants.GetSeedProductId(plantType)
	local product = Constants.SEED_ROBUX_PRODUCTS[plantType]
	return product and product.ProductId or nil
end

function Constants.GetGrowAllProductId()
	return Constants.GROW_ALL_PRODUCT and Constants.GROW_ALL_PRODUCT.ProductId or nil
end

-- Helper to get plant type by product ID
function Constants.GetPlantTypeByProductId(productId)
	for plantType, product in pairs(Constants.SEED_ROBUX_PRODUCTS) do
		if product.ProductId == productId then
			return plantType, product
		end
	end
	return nil, nil
end

-- Economy
-- Starting coins: Enough to buy 5-6 starter plants (Lumut) and have buffer for mistakes
Constants.STARTING_COINS = 100

-- Garden Plot Settings
Constants.PLOT_SIZE = Vector3.new(20, 1, 20)
Constants.PLOT_SPACING = 25
Constants.MAX_PLANTS_PER_PLOT = 9

-- Pet Types (PascalCase to match ReplicatedStorage/Pets folder names)
Constants.PET_TYPES = {
	CRYSTALOWL = "CrystalOwl",
	EMBERCAT = "EmberCat",
	EVERFLAMEGRIFFIN = "EverflameGriffin",
	GLOWBUG = "GlowBug",
	LEAFLING = "Leafling",
	MOONDRAGON = "MoonDragon",
	MOSSYSLIME = "MossySlime",
	PEBBLEPUB = "PebblePup",
	PHANTOMELK = "PhantomElk",
	PUFFSPIRIT = "PuffSpirit",
	SPARKFOX = "SparkFox",
	SPROUTTAIL = "SproutTail",
	STARLIGHTPHOENIX = "StarlightPhoenix",
	THORNBEAK = "Thornbeak",
	WHISPRABBIT = "WispRabbit"
}

-- Pet Movement Types
Constants.PET_MOVEMENT = {
	FLY = "Fly",   -- Floats/hovers in the air
	WALK = "Walk"  -- Walks on the ground
}

-- Pet Configuration
Constants.PET_CONFIG = {
	[Constants.PET_TYPES.CRYSTALOWL] = {
		DisplayName = "CrystalOwl",
		Price = 500,
		FollowDistance = 3,
		WaterBoost = 0.85, -- Makes plants grow 15% faster
		Color = Color3.fromRGB(150, 200, 255),
		MovementType = "Fly" -- Owl flies
	},
	[Constants.PET_TYPES.EMBERCAT] = {
		DisplayName = "EmberCat",
		Price = 400,
		FollowDistance = 2.5,
		WaterBoost = 0.90, -- Makes plants grow 10% faster
		Color = Color3.fromRGB(255, 100, 50),
		MovementType = "Walk" -- Cat walks
	},
	[Constants.PET_TYPES.EVERFLAMEGRIFFIN] = {
		DisplayName = "EverflameGriffin",
		Price = 800,
		FollowDistance = 4,
		WaterBoost = 0.75, -- Makes plants grow 25% faster
		Color = Color3.fromRGB(255, 150, 0),
		MovementType = "Fly" -- Griffin flies
	},
	[Constants.PET_TYPES.GLOWBUG] = {
		DisplayName = "GlowBug",
		Price = 250,
		FollowDistance = 2,
		WaterBoost = 0.95, -- Makes plants grow 5% faster
		Color = Color3.fromRGB(255, 255, 100),
		MovementType = "Fly" -- Bug flies
	},
	[Constants.PET_TYPES.LEAFLING] = {
		DisplayName = "Leafling",
		Price = 350,
		FollowDistance = 3,
		WaterBoost = 0.88, -- Makes plants grow 12% faster
		Color = Color3.fromRGB(100, 255, 100),
		MovementType = "Fly" -- Fairy-like, floats
	},
	[Constants.PET_TYPES.MOONDRAGON] = {
		DisplayName = "MoonDragon",
		Price = 900,
		FollowDistance = 4.5,
		WaterBoost = 0.70, -- Makes plants grow 30% faster
		Color = Color3.fromRGB(200, 200, 255),
		MovementType = "Fly" -- Dragon flies
	},
	[Constants.PET_TYPES.MOSSYSLIME] = {
		DisplayName = "MossySlime",
		Price = 300,
		FollowDistance = 2,
		WaterBoost = 0.92, -- Makes plants grow 8% faster
		Color = Color3.fromRGB(100, 200, 100),
		MovementType = "Walk" -- Slime bounces/walks
	},
	[Constants.PET_TYPES.PEBBLEPUB] = {
		DisplayName = "PebblePup",
		Price = 350,
		FollowDistance = 2.5,
		WaterBoost = 0.90, -- Makes plants grow 10% faster
		Color = Color3.fromRGB(150, 150, 150),
		MovementType = "Walk" -- Puppy walks
	},
	[Constants.PET_TYPES.PHANTOMELK] = {
		DisplayName = "PhantomElk",
		Price = 600,
		FollowDistance = 3.5,
		WaterBoost = 0.82, -- Makes plants grow 18% faster
		Color = Color3.fromRGB(180, 180, 255),
		MovementType = "Walk" -- Elk walks
	},
	[Constants.PET_TYPES.PUFFSPIRIT] = {
		DisplayName = "PuffSpirit",
		Price = 450,
		FollowDistance = 3,
		WaterBoost = 0.87, -- Makes plants grow 13% faster
		Color = Color3.fromRGB(255, 255, 255),
		MovementType = "Fly" -- Spirit floats
	},
	[Constants.PET_TYPES.SPARKFOX] = {
		DisplayName = "SparkFox",
		Price = 550,
		FollowDistance = 3.5,
		WaterBoost = 0.83, -- Makes plants grow 17% faster
		Color = Color3.fromRGB(255, 200, 100),
		MovementType = "Walk" -- Fox walks
	},
	[Constants.PET_TYPES.SPROUTTAIL] = {
		DisplayName = "SproutTail",
		Price = 400,
		FollowDistance = 3,
		WaterBoost = 0.89, -- Makes plants grow 11% faster
		Color = Color3.fromRGB(150, 255, 100),
		MovementType = "Walk" -- Sprout creature walks
	},
	[Constants.PET_TYPES.STARLIGHTPHOENIX] = {
		DisplayName = "StarlightPheonix",
		Price = 1000,
		FollowDistance = 5,
		WaterBoost = 0.65, -- Makes plants grow 35% faster
		Color = Color3.fromRGB(255, 255, 200),
		MovementType = "Fly" -- Phoenix flies
	},
	[Constants.PET_TYPES.THORNBEAK] = {
		DisplayName = "Thornbeak",
		Price = 500,
		FollowDistance = 3,
		WaterBoost = 0.85, -- Makes plants grow 15% faster
		Color = Color3.fromRGB(150, 100, 50),
		MovementType = "Fly" -- Bird-like, flies
	},
	[Constants.PET_TYPES.WHISPRABBIT] = {
		DisplayName = "WispRabbit",
		Price = 350,
		FollowDistance = 2.5,
		WaterBoost = 0.90, -- Makes plants grow 10% faster
		Color = Color3.fromRGB(200, 180, 255),
		MovementType = "Walk" -- Rabbit hops/walks
	}
}

-- ============================================================================
-- RARITY SYSTEM
-- ============================================================================
-- Rarities from lowest to highest tier
Constants.RARITIES = {
	COMMON = "Common",
	UNCOMMON = "Uncommon",
	RARE = "Rare",
	EPIC = "Epic",
	LEGENDARY = "Legendary",
	MYTHIC = "Mythic"
}

-- Rarity colors for UI
Constants.RARITY_COLORS = {
	[Constants.RARITIES.COMMON] = Color3.fromRGB(200, 200, 200),      -- White/Gray
	[Constants.RARITIES.UNCOMMON] = Color3.fromRGB(100, 200, 100),    -- Green
	[Constants.RARITIES.RARE] = Color3.fromRGB(50, 150, 255),         -- Blue
	[Constants.RARITIES.EPIC] = Color3.fromRGB(180, 100, 255),        -- Purple
	[Constants.RARITIES.LEGENDARY] = Color3.fromRGB(255, 200, 50),    -- Yellow/Gold
	[Constants.RARITIES.MYTHIC] = Color3.fromRGB(180, 100, 255)       -- Reuse Epic color (avoid introducing new palette)
}

-- Rarity growth timing (total time from Seed -> Bloom, in seconds)
-- NOTE: The growth system progresses through 2 timed transitions (Seed->Sprout, Sprout->Bloom),
-- so per-stage base time is typically total/2, before buffs.
Constants.RARITY_GROWTH_TOTAL_SECONDS = {
	[Constants.RARITIES.COMMON] = {Min = 2 * 60, Max = 4 * 60},
	[Constants.RARITIES.UNCOMMON] = {Min = 6 * 60, Max = 8 * 60},
	[Constants.RARITIES.RARE] = {Min = 14 * 60, Max = 18 * 60},
	[Constants.RARITIES.EPIC] = {Min = 28 * 60, Max = 36 * 60},
	[Constants.RARITIES.LEGENDARY] = {Min = 55 * 60, Max = 60 * 60},
	[Constants.RARITIES.MYTHIC] = {Min = 2 * 60 * 60, Max = 4 * 60 * 60},
}

local function formatDurationShort(seconds: number): string
	seconds = math.max(0, math.floor(seconds + 0.5))
	if seconds >= 60 * 60 then
		local hours = seconds / (60 * 60)
		-- Prefer whole hours when possible
		if math.abs(hours - math.floor(hours + 0.5)) < 1e-6 then
			return string.format("%dh", math.floor(hours + 0.5))
		end
		return string.format("%.1fh", hours)
	end
	if seconds >= 60 then
		local mins = seconds / 60
		if math.abs(mins - math.floor(mins + 0.5)) < 1e-6 then
			return string.format("%dm", math.floor(mins + 0.5))
		end
		return string.format("%.1fm", mins)
	end
	return string.format("%ds", seconds)
end

function Constants.GetPlantRarity(plantType: string): string
	return Constants.PLANT_RARITIES[plantType] or Constants.RARITIES.COMMON
end

function Constants.GetRarityTotalGrowthRangeSeconds(rarity: string): (number, number)
	local range = Constants.RARITY_GROWTH_TOTAL_SECONDS[rarity]
	if range then
		return range.Min, range.Max
	end
	-- Safe fallback: treat unknown rarity as common
	local commonRange = Constants.RARITY_GROWTH_TOTAL_SECONDS[Constants.RARITIES.COMMON]
	return commonRange.Min, commonRange.Max
end

function Constants.RollTotalGrowthSecondsForPlant(plantType: string): number
	local rarity = Constants.GetPlantRarity(plantType)
	local minSeconds, maxSeconds = Constants.GetRarityTotalGrowthRangeSeconds(rarity)
	if maxSeconds < minSeconds then
		minSeconds, maxSeconds = maxSeconds, minSeconds
	end
	return math.random(minSeconds, maxSeconds)
end

function Constants.GetDefaultTotalGrowthSecondsForPlant(plantType: string): number
	local rarity = Constants.GetPlantRarity(plantType)
	local minSeconds, maxSeconds = Constants.GetRarityTotalGrowthRangeSeconds(rarity)
	return (minSeconds + maxSeconds) * 0.5
end

function Constants.RollBaseStageGrowthSecondsForPlant(plantType: string): number
	local totalSeconds = Constants.RollTotalGrowthSecondsForPlant(plantType)
	return math.max(totalSeconds * 0.5, 0.1)
end

function Constants.GetDefaultBaseStageGrowthSecondsForPlant(plantType: string): number
	local totalSeconds = Constants.GetDefaultTotalGrowthSecondsForPlant(plantType)
	return math.max(totalSeconds * 0.5, 0.1)
end

function Constants.GetGrowthRangeTextForPlant(plantType: string): string
	local rarity = Constants.GetPlantRarity(plantType)
	local minSeconds, maxSeconds = Constants.GetRarityTotalGrowthRangeSeconds(rarity)
	return string.format("%s-%s", formatDurationShort(minSeconds), formatDurationShort(maxSeconds))
end

-- ============================================================================
-- EGG SYSTEM
-- ============================================================================
-- Egg types correspond to rarities - each egg can only drop pets of that rarity or lower
Constants.EGG_TYPES = {
	COMMON = "CommonEgg",
	UNCOMMON = "UncommonEgg",
	RARE = "RareEgg",
	EPIC = "EpicEgg",
	LEGENDARY = "LegendaryEgg"
}

-- Egg configuration with prices and drop chances
-- Drop chances are relative weights within the egg's pool
Constants.EGG_CONFIG = {
	[Constants.EGG_TYPES.COMMON] = {
		DisplayName = "Common Egg",
		Price = 100,
		ImageId = "rbxassetid://105531210825045", -- White egg
		Rarity = Constants.RARITIES.COMMON,
		HatchTimeSeconds = 60,
		-- Only drops common pets (100% common)
		DropChances = {
			[Constants.RARITIES.COMMON] = 100
		}
	},
	[Constants.EGG_TYPES.UNCOMMON] = {
		DisplayName = "Uncommon Egg",
		Price = 250,
		ImageId = "rbxassetid://79842537952035", -- Green egg
		Rarity = Constants.RARITIES.UNCOMMON,
		HatchTimeSeconds = 60,
		-- Drops common or uncommon
		DropChances = {
			[Constants.RARITIES.COMMON] = 60,
			[Constants.RARITIES.UNCOMMON] = 40
		}
	},
	[Constants.EGG_TYPES.RARE] = {
		DisplayName = "Rare Egg",
		Price = 500,
		ImageId = "rbxassetid://75691996912194", -- Blue egg
		Rarity = Constants.RARITIES.RARE,
		HatchTimeSeconds = 60,
		-- Drops common, uncommon, or rare
		DropChances = {
			[Constants.RARITIES.COMMON] = 50,
			[Constants.RARITIES.UNCOMMON] = 35,
			[Constants.RARITIES.RARE] = 15
		}
	},
	[Constants.EGG_TYPES.EPIC] = {
		DisplayName = "Epic Egg",
		Price = 1000,
		ImageId = "rbxassetid://130581371031598", -- Purple egg
		Rarity = Constants.RARITIES.EPIC,
		HatchTimeSeconds = 60,
		-- Drops uncommon, rare, or epic (no common!)
		DropChances = {
			[Constants.RARITIES.UNCOMMON] = 45,
			[Constants.RARITIES.RARE] = 35,
			[Constants.RARITIES.EPIC] = 20
		}
	},
	[Constants.EGG_TYPES.LEGENDARY] = {
		DisplayName = "Legendary Egg",
		Price = 2500,
		ImageId = "rbxassetid://121874536453561", -- Yellow/Gold egg
		Rarity = Constants.RARITIES.LEGENDARY,
		HatchTimeSeconds = 60,
		-- Drops rare, epic, or legendary (no common/uncommon!)
		DropChances = {
			[Constants.RARITIES.RARE] = 50,
			[Constants.RARITIES.EPIC] = 35,
			[Constants.RARITIES.LEGENDARY] = 15
		}
	}
}

-- ============================================================================
-- PET RARITY ASSIGNMENTS
-- ============================================================================
-- Assign each pet to a rarity tier
Constants.PET_RARITIES = {
	-- Common pets (basic, starter-friendly)
	[Constants.PET_TYPES.GLOWBUG] = Constants.RARITIES.COMMON,
	[Constants.PET_TYPES.MOSSYSLIME] = Constants.RARITIES.COMMON,
	[Constants.PET_TYPES.PEBBLEPUB] = Constants.RARITIES.COMMON,
	
	-- Uncommon pets
	[Constants.PET_TYPES.LEAFLING] = Constants.RARITIES.UNCOMMON,
	[Constants.PET_TYPES.WHISPRABBIT] = Constants.RARITIES.UNCOMMON,
	[Constants.PET_TYPES.SPROUTTAIL] = Constants.RARITIES.UNCOMMON,
	
	-- Rare pets
	[Constants.PET_TYPES.EMBERCAT] = Constants.RARITIES.RARE,
	[Constants.PET_TYPES.SPARKFOX] = Constants.RARITIES.RARE,
	[Constants.PET_TYPES.PUFFSPIRIT] = Constants.RARITIES.RARE,
	[Constants.PET_TYPES.THORNBEAK] = Constants.RARITIES.RARE,
	
	-- Epic pets
	[Constants.PET_TYPES.CRYSTALOWL] = Constants.RARITIES.EPIC,
	[Constants.PET_TYPES.PHANTOMELK] = Constants.RARITIES.EPIC,
	[Constants.PET_TYPES.EVERFLAMEGRIFFIN] = Constants.RARITIES.EPIC,
	
	-- Legendary pets (rarest, best boosts)
	[Constants.PET_TYPES.MOONDRAGON] = Constants.RARITIES.LEGENDARY,
	[Constants.PET_TYPES.STARLIGHTPHOENIX] = Constants.RARITIES.LEGENDARY
}

-- ============================================================================
-- PLANT/SEED RARITY ASSIGNMENTS
-- ============================================================================
-- Assign each plant to a rarity tier (based on Tier from PLANT_CONFIG)
Constants.PLANT_RARITIES = {
	-- Common plants (Tier 1 - starter plants)
	[Constants.PLANT_TYPES.LUMUT] = Constants.RARITIES.COMMON,
	[Constants.PLANT_TYPES.CLOUDCAP] = Constants.RARITIES.COMMON,
	[Constants.PLANT_TYPES.PUFFOT] = Constants.RARITIES.COMMON,
	[Constants.PLANT_TYPES.GLOWBUD] = Constants.RARITIES.COMMON,
	
	-- Uncommon plants (early Tier 2)
	[Constants.PLANT_TYPES.TWINKLELEAF] = Constants.RARITIES.UNCOMMON,
	[Constants.PLANT_TYPES.CHAMELEONBERRI] = Constants.RARITIES.UNCOMMON,
	[Constants.PLANT_TYPES.DREAMSHROOM] = Constants.RARITIES.UNCOMMON,
	
	-- Rare plants (late Tier 2)
	[Constants.PLANT_TYPES.EVERSPRINGACORN] = Constants.RARITIES.RARE,
	
	-- Epic plants (early Tier 3)
	[Constants.PLANT_TYPES.STARVINEMELON] = Constants.RARITIES.EPIC,
	[Constants.PLANT_TYPES.FROSTMIND] = Constants.RARITIES.EPIC,
	[Constants.PLANT_TYPES.DREAMFRUIT] = Constants.RARITIES.EPIC,
	
	-- Legendary plants (late Tier 3 - best plants)
	[Constants.PLANT_TYPES.SUNFLAREMANGO] = Constants.RARITIES.LEGENDARY,
	[Constants.PLANT_TYPES.STARLILY] = Constants.RARITIES.LEGENDARY,
	[Constants.PLANT_TYPES.MOONVINE] = Constants.RARITIES.LEGENDARY,
	[Constants.PLANT_TYPES.WILLOWWHISP] = Constants.RARITIES.LEGENDARY
}

-- ============================================================================
-- SEED SHOP CONFIGURATION
-- ============================================================================
Constants.SEED_SHOP_CONFIG = {
	-- How often the shop refreshes (in seconds) - 12 hours
	RefreshInterval = 12 * 60 * 60, -- 43200 seconds = 12 hours
	
	-- How many seed types to show per rarity (randomly selected)
	SlotsPerRarity = {
		[Constants.RARITIES.COMMON] = 3,      -- Always show 3 common seeds
		[Constants.RARITIES.UNCOMMON] = 2,    -- Show 2 uncommon seeds
		[Constants.RARITIES.RARE] = 1,        -- Show 1 rare seed
		[Constants.RARITIES.EPIC] = 1,        -- Show 1 epic seed (may be empty)
		[Constants.RARITIES.LEGENDARY] = 1    -- Show 1 legendary seed (rare appearance)
	},
	
	-- Chance for each rarity slot to actually appear (0-1)
	AppearanceChance = {
		[Constants.RARITIES.COMMON] = 1.0,     -- 100% - always appears
		[Constants.RARITIES.UNCOMMON] = 1.0,   -- 100% - always appears
		[Constants.RARITIES.RARE] = 0.8,       -- 80% chance to appear
		[Constants.RARITIES.EPIC] = 0.5,       -- 50% chance to appear
		[Constants.RARITIES.LEGENDARY] = 0.2   -- 20% chance to appear
	},
	
	-- Stock per seed based on rarity
	StockPerRarity = {
		[Constants.RARITIES.COMMON] = 50,      -- Abundant
		[Constants.RARITIES.UNCOMMON] = 30,    -- Moderate
		[Constants.RARITIES.RARE] = 15,        -- Limited
		[Constants.RARITIES.EPIC] = 8,         -- Scarce
		[Constants.RARITIES.LEGENDARY] = 3     -- Very rare
	}
}

-- ============================================================================
-- SIZE/WEIGHT VARIANCE
-- ============================================================================
-- Random size and weight ranges for pets and plants (makes each instance unique)
Constants.SIZE_WEIGHT_CONFIG = {
	Pet = {
		SizeMin = 0.8,      -- Minimum scale multiplier
		SizeMax = 1.2,      -- Maximum scale multiplier
		WeightMin = 0.7,    -- Minimum weight (affects movement speed slightly)
		WeightMax = 1.3     -- Maximum weight
	},
	Plant = {
		SizeMin = 0.85,     -- Minimum scale multiplier
		SizeMax = 1.15,     -- Maximum scale multiplier
		WeightMin = 0.8,    -- Minimum weight (affects sell price multiplier)
		WeightMax = 1.2     -- Maximum weight (heavier = worth more)
	}
}

-- Pet/Garden caps
Constants.MAX_EQUIPPED_PETS = 3
Constants.MAX_GARDEN_PETS = 7

-- ============================================================================
-- GEAR/TOOL SYSTEM
-- ============================================================================
-- Gear types that can be purchased from the Gear Shop
Constants.GEAR_TYPES = {
	WATERING_CAN = "WateringCan",
	SHOVEL = "Shovel",
	GOLDEN_WATERING_CAN = "GoldenWateringCan",
	ENCHANTED_SHOVEL = "EnchantedShovel"
}

-- Gear configuration: pricing, stats, and abilities
Constants.GEAR_CONFIG = {
	[Constants.GEAR_TYPES.WATERING_CAN] = {
		DisplayName = "Watering Can",
		Description = "Waters up to 5 plants at once to speed growth",
		Price = 50,
		Icon = "💧",
		MaxPlantsPerUse = 5,       -- Maximum plants that can be boosted per use
		WaterDuration = 90,        -- Seconds the water buff lasts
		Cooldown = 1.5,
		Tier = 1
	},
	[Constants.GEAR_TYPES.SHOVEL] = {
		DisplayName = "Shovel",
		Description = "Dig up plants to clear space",
		Price = 30,
		Icon = "🪓",
		Cooldown = 1.0,
		Tier = 1
	},
	[Constants.GEAR_TYPES.GOLDEN_WATERING_CAN] = {
		DisplayName = "Golden Watering Can",
		Description = "Waters up to 10 plants with extended duration",
		Price = 500,
		Icon = "✨💧",
		MaxPlantsPerUse = 10,
		WaterDuration = 180,       -- 3 minutes
		Cooldown = 1.0,
		Tier = 2
	},
	[Constants.GEAR_TYPES.ENCHANTED_SHOVEL] = {
		DisplayName = "Enchanted Shovel",
		Description = "Instantly clears plants and returns seeds",
		Price = 400,
		Icon = "✨🪓",
		ReturnSeeds = true,        -- Returns seeds when digging up plants
		Cooldown = 0.5,
		Tier = 2
	}
}

-- Player starting gear (free tools)
Constants.STARTING_GEAR = {
	Constants.GEAR_TYPES.WATERING_CAN,
	Constants.GEAR_TYPES.SHOVEL
}

-- ============================================================================
-- FRUIT CONFIGURATION
-- ============================================================================
-- Settings for fruit spawning on plants at bloom stage
Constants.FRUIT_CONFIG = {
	-- Min/max fruits per plant (random within range)
	MinFruitsPerPlant = 2,
	MaxFruitsPerPlant = 4,
	
	-- Fruit spawn positions relative to plant (offsets from plant center)
	-- These create a natural "hanging" look around the plant
	SpawnOffsets = {
		Vector3.new(0.8, 0, 0.3),
		Vector3.new(-0.7, 0.2, 0.5),
		Vector3.new(0.3, -0.1, -0.8),
		Vector3.new(-0.5, 0.1, -0.6),
		Vector3.new(0.6, 0.15, 0.7),
		Vector3.new(-0.4, -0.05, 0.4),
		Vector3.new(0.2, 0.1, -0.5),
	},
	
	-- Vertical offset from plant top (fruits hang below/around bloom)
	HeightOffset = -0.3,
	
	-- Fruit model size relative to plant
	FruitScale = 0.4,
	
	-- ProximityPrompt settings
	PromptHoldDuration = 0.3,
	PromptMaxDistance = 12,
	PromptActionText = "Collect",
	PromptObjectText = "Fruit",
	
	-- Respawn settings (0 = no respawn, fruits only spawn once per bloom)
	RespawnTime = 0,
	
	-- Fruit reveal settings (fruits spawn invisible and reveal one by one)
	-- If plant has 0-1 fruits, harvesting removes the whole plant (plant IS the fruit)
	-- If plant has 2+ fruits, they reveal one at a time over this interval
	FruitRevealTimeSeconds = 20, -- Time between each fruit becoming visible
	FruitRevealScale = true, -- If true, fruits scale up; if false, just fade in
	FruitRevealDuration = 1.5, -- How long the scale-up/fade-in animation takes
}

-- ============================================================================
-- FREE PLANTING CONFIGURATION
-- ============================================================================
-- Settings for free-form planting anywhere on plots
Constants.FREE_PLANTING = {
	-- Enable/disable free-form planting (vs anchor-based)
	Enabled = true,
	
	-- Minimum distance between plants (studs)
	MinPlantSpacing = 3.0,
	
	-- Maximum plants per garden (replaces SlotsPerGarden when free planting)
	MaxPlantsPerGarden = 20,
	
	-- Y offset above plot surface for planting
	PlantHeightOffset = 0.1,
}

-- ============================================================================
-- TRADING CONFIGURATION
-- ============================================================================
Constants.TRADING_CONFIG = {
	-- Maximum items per side of trade
	MaxItemsPerTrade = 10,
	-- Trade request timeout (seconds)
	RequestTimeout = 30,
	-- Trade confirmation timeout (seconds)
	ConfirmTimeout = 60,
	-- Minimum distance to trade (studs) - 0 means no limit
	MaxTradeDistance = 50,
	-- Cooldown between trade requests to same player (seconds)
	RequestCooldown = 10
}

-- RemoteEvent Names
Constants.EVENTS = {
	WEATHER_CHANGED = "WeatherChanged",
	PLANT_SEED = "PlantSeed",
	PLANT_SEED_AT_POSITION = "PlantSeedAtPosition", -- Free-form planting
	HARVEST_PLANT = "HarvestPlant",
	HARVEST_FRUIT = "HarvestFruit",
	BUY_SEED = "BuySeed",
	BUY_SEED_ROBUX = "BuySeedRobux", -- Robux purchase for seeds
	BUY_PET = "BuyPet",
	BUY_EGG = "BuyEgg",
	BUY_GEAR = "BuyGear", -- Gear shop purchase
	OPEN_EGG = "OpenEgg",
	EGG_OPENED = "EggOpened", -- Server to client: egg result
	EQUIP_PET = "EquipPet",
	UNEQUIP_PET = "UnequipPet",
	ADD_GARDEN_PET = "AddGardenPet",
	REMOVE_GARDEN_PET = "RemoveGardenPet",
	SELL_FRUIT = "SellFruit",
	UPDATE_CURRENCY = "UpdateCurrency",
	UPDATE_INVENTORY = "UpdateInventory",
	-- Shop events
	GET_SHOP_INVENTORY = "GetShopInventory",
	SHOP_INVENTORY_UPDATE = "ShopInventoryUpdate",
	-- Trading events
	TRADE_REQUEST = "TradeRequest",           -- Client requests trade with player
	TRADE_RESPONSE = "TradeResponse",         -- Accept/decline trade request
	TRADE_UPDATE = "TradeUpdate",             -- Update trade offer (add/remove items)
	TRADE_CONFIRM = "TradeConfirm",           -- Confirm trade ready
	TRADE_CANCEL = "TradeCancel",             -- Cancel trade
	TRADE_COMPLETE = "TradeComplete",         -- Trade completed successfully
	TRADE_INCOMING = "TradeIncoming"          -- Server notifies of incoming trade request
}

-- Helper function to generate unique IDs
function Constants.GenerateUniqueId()
	return game:GetService("HttpService"):GenerateGUID(false)
end

-- Helper function to generate random size/weight for a pet or plant
function Constants.GenerateRandomSizeWeight(entityType)
	local config = Constants.SIZE_WEIGHT_CONFIG[entityType]
	if not config then
		return { Size = 1, Weight = 1 }
	end
	
	local size = config.SizeMin + math.random() * (config.SizeMax - config.SizeMin)
	local weight = config.WeightMin + math.random() * (config.WeightMax - config.WeightMin)
	
	-- Round to 2 decimal places
	size = math.floor(size * 100 + 0.5) / 100
	weight = math.floor(weight * 100 + 0.5) / 100
	
	return { Size = size, Weight = weight }
end

return Constants
