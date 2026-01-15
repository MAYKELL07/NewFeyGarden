-- Config.luau
-- Centralized configuration for all folder and asset name references
-- This module provides a single source of truth for all game configuration values
--
-- ============================================================================
-- GARDEN STRUCTURE DOCUMENTATION
-- ============================================================================
-- Expected workspace hierarchy:
--
-- workspace
--   └─ Gardens (Folder)
--        ├─ Garden1 (Folder)
--        │    ├─ Floor (Part) - Main ground/platform
--        │    ├─ PlayerSign (Model) - Shows assigned player name
--        │    │    └─ Sign (Part with SurfaceGui > TextLabel)
--        │    └─ Plots (Folder) - Contains all plant anchors
--        │         ├─ PlantAnchor1 (Part)
--        │         ├─ PlantAnchor2 (Part)
--        │         └─ ... (up to PlantAnchor16)
--        ├─ Garden2 (Folder)
--        │    └─ ... (same structure)
--        └─ ... (up to Garden10)
--
-- ============================================================================

local Config = {}

-- ============================================================================
-- WORLD STRUCTURE CONFIGURATION
-- ============================================================================
-- Defines the hierarchy and naming conventions for game world objects
Config.World = {
	Root = workspace,                    -- Root container for all world objects
	GardensFolder = "Gardens",           -- Folder containing all pre-made garden folders
	PlayerSignName = "PlayerSign",       -- Name of the Model containing the player sign
	PlayerSignPartName = "Sign",         -- Name of the Part within PlayerSign Model that has the SurfaceGui
	GrowAllSignName = "GrowAll",         -- Name of the Model containing the Grow All purchase sign
	FloorName = "Floor",                 -- Name of the main floor/platform part in each garden
	PlotsFolder = "Plots",               -- Name of the folder containing PlantAnchors within each garden
	TeleportPartName = "TpPart",         -- Name of the part where players spawn in their garden
	ShopPartName = "ShopPart",           -- Name of the part that has the ProximityPrompt for opening shop
	SellPartName = "SellPart",           -- Name of the part that has the ProximityPrompt for opening sell shop
	PetShopPartName = "PetShopPart",     -- Name of the part that has the ProximityPrompt for opening the pet/egg shop
	GearShopPartName = "GearShopPart",   -- Name of the part that has the ProximityPrompt for opening the gear shop (if used)
}

-- ============================================================================
-- PROXIMITY PROMPT TUNING
-- ============================================================================
Config.ProximityPrompts = {
	-- All shop-related prompts are scaled by this factor (user-requested: 2x).
	ShopDistanceMultiplier = 1,
}

-- ============================================================================
-- GARDEN CONFIGURATION
-- ============================================================================
-- Settings for garden assignment and plant slot management
Config.Garden = {
	-- Capacity Settings
	MaxGardens = 10,                     -- Maximum number of gardens available in the world
	SlotsPerGarden = 16,                 -- Number of plant slots per garden (must match PlantAnchor count)
	
	-- Assignment Behavior
	AssignOnJoin = true,                 -- Automatically assign garden to player when they join
	FreeOnLeave = true,                  -- Free garden when player leaves (allow reassignment)
	SavePlantsOnLeave = true,            -- Save plant data when player leaves
	RestorePlantsOnJoin = true,          -- Restore saved plants when player joins and gets assigned garden
	
	-- Naming Conventions
	PlantAnchorPrefix = "PlantAnchor",   -- Prefix for plant anchor parts (e.g., PlantAnchor1, PlantAnchor2)
	GardenPrefix = "Garden",             -- Prefix for garden folders (e.g., Garden1, Garden2)
	
	-- Garden List
	-- List of expected garden folder names in the GardensFolder
	-- These should be Folders (not Models) containing the garden structure
	GardenNames = {
		"Garden1",
		"Garden2",
		"Garden3",
		"Garden4",
		"Garden5",
		"Garden6",
		"Garden7",
		"Garden8",
		"Garden9",
		"Garden10"
	},
	
	-- Plant Anchor Settings
	PlantAnchorSize = Vector3.new(1, 0.5, 1),  -- Default size for plant anchor visualization
	PlantAnchorTransparency = 1,               -- Transparency of anchors (1 = invisible, 0 = visible)
	PlantAnchorColor = Color3.fromRGB(139, 69, 19),  -- Brown color for plant anchors
	ShowAnchorsInGame = false,                 -- Whether to show plant anchors during gameplay
	
	-- PlayerSign Settings
	DefaultSignText = "Available",             -- Text shown when no player is assigned
	SignTextColor = Color3.fromRGB(255, 255, 255),  -- Color of player name text
	SignBackgroundColor = Color3.fromRGB(40, 40, 40), -- Background color of sign
}

-- ============================================================================
-- TOOL CONFIGURATION
-- ============================================================================
-- Settings for player tools like Shovel and Watering Can
Config.Tools = {
	Shovel = {
		Name = "Shovel",                 -- Tool name that must match the Tool object in game
		Cooldown = 1.0,                  -- Seconds between uses to prevent spam
		Description = "Dig up plants",   -- Tool description for UI
		Icon = "🪓"                      -- Emoji icon for visual display
	},
	WateringCan = {
		Name = "WateringCan",            -- Tool name that must match the Tool object in game
		Cooldown = 1.5,                  -- Seconds between uses to prevent spam
		WaterSeconds = 90,               -- Duration in seconds that the watering buff lasts
		Description = "Water plants to speed growth", -- Tool description for UI
		Icon = "💧"                      -- Emoji icon for visual display
	},
	MaxUseDistance = 15,                 -- Maximum studs distance for tool raycast interaction
	ShowToolIndicators = true            -- Whether to show visual indicators when using tools
}

-- ============================================================================
-- BUFF MULTIPLIERS
-- ============================================================================
-- Growth rate modifiers that stack multiplicatively (lower = faster growth)
-- Final growth time = BaseTime × WeatherMult × WaterMult × PetMult
Config.Buffs = {
	Weather = {
		Sunny = 1.0,                     -- No boost (normal speed)
		Rainy = 0.8,                     -- 20% faster growth (80% of normal time)
		Stormy = 0.7                     -- 30% faster growth (70% of normal time)
	},
	Watered = 0.85,                      -- 15% faster when recently watered (85% of normal time)
	PetBoost = 0.9,                      -- 10% faster when pet is nearby (90% of normal time)
	
	-- Buff Display Settings
	ShowBuffIndicators = true,           -- Whether to show buff icons above plants
	BuffIndicatorSize = UDim2.new(0, 40, 0, 40), -- Size of buff indicator icons
	BuffIndicatorOffset = Vector3.new(0, 3, 0)   -- Offset above plant for buff icons
}

-- ============================================================================
-- ECONOMY CONFIGURATION
-- ============================================================================
-- Settings for currency and economic systems
Config.Economy = {
	CurrencyName = "Coins",              -- Name displayed in leaderstats
	StartingCoins = 100,                 -- Coins given to new players
	EnablePersistence = true,            -- Whether to save/load player data
	
	-- Shop Settings
	ShopRefreshInterval = 0,             -- Hours between shop refresh (0 = no refresh)
	EnableDailyRewards = false,          -- Whether to give daily login rewards
	DailyRewardCoins = 50                -- Coins given for daily login
}

-- ============================================================================
-- EGG OPENING ANIMATION CONFIGURATION
-- ============================================================================
-- Settings for the egg opening sequence
Config.EggOpening = {
	-- Animation timings (in seconds)
	ShakeDuration = 2.0,                 -- How long the egg shakes before cracking
	ShakeIntensity = 10,                 -- Pixels of shake offset
	CrackDuration = 0.5,                 -- Time for crack animation
	RevealDuration = 1.5,                -- Time for pet reveal
	
	-- Visual effects
	DarkenBackground = true,             -- Whether to darken background during opening
	BackgroundDarknessAlpha = 0.85,      -- How dark (0-1)
	
	-- Special effects for Epic/Legendary
	EpicEffects = {
		EnableGlow = true,
		GlowColor = Color3.fromRGB(180, 100, 255),  -- Purple glow
		EnableParticles = true,
		ParticleCount = 20
	},
	LegendaryEffects = {
		EnableGlow = true,
		GlowColor = Color3.fromRGB(255, 200, 50),   -- Gold glow
		EnableParticles = true,
		ParticleCount = 40,
		EnableScreenFlash = true,
		EnableRays = true                           -- Light rays effect
	}
}

-- ============================================================================
-- GARDEN PET ROAMING CONFIGURATION
-- ============================================================================
-- Settings for how pets roam within the player's garden
Config.GardenPetRoaming = {
	-- Roaming bounds (box centered on garden floor)
	BoundsHalfWidth = 60,                -- Half-width of roaming box (X axis)
	BoundsHalfLength = 30,               -- Half-length of roaming box (Z axis)
	MinHeight = 2,                       -- Minimum hover height above floor
	MaxHeight = 20,                       -- Maximum hover height above floor
	
	-- Movement behavior (improved timing for realism)
	IdleChance = 0.65,                   -- Chance to stay idle vs moving (0-1) - slightly higher for calmer pets
	MinIdleTime = 4,                     -- Minimum seconds to stay idle (increased)
	MaxIdleTime = 12,                    -- Maximum seconds to stay idle (increased)
	MinMoveTime = 3,                     -- Minimum seconds between movement updates (increased)
	MaxMoveTime = 8,                     -- Maximum seconds between movement updates (increased)
	MoveSpeed = 0.08,                    -- How fast pets move (reduced for smoother movement)
	
	-- Vertical bobbing
	BobAmplitude = 0.3,                  -- Vertical bob height
	BobSpeed = 1.5                       -- Vertical bob frequency
}

-- ============================================================================
-- VFX PARTICLE CONFIGURATION
-- ============================================================================
-- Settings for visual effects system (currently uses fallback sparkles if particles don't exist)
Config.VFX = {
	Enable = true,                       -- Master switch for all VFX (set to false to disable effects)
	
	-- Particle Names
	WaterSplashParticleName = "WaterSplash",     -- Name of ParticleEmitter to find in plants for water effect
	GrowthSparkleParticleName = "GrowthSparkle", -- Name of ParticleEmitter to find in plants for growth effect
	PetCheerParticleName = "PetCheer",           -- Name of ParticleEmitter to find in pets for cheer effect
	
	-- Fallback Sparkle Settings (used when ParticleEmitters don't exist)
	UseFallbackSparkles = true,          -- Use basic Sparkles if ParticleEmitters not found
	SparkleColor = Color3.fromRGB(255, 255, 150), -- Default sparkle color
	SparkleDuration = 2.0                -- How long sparkles last (seconds)
}

-- ============================================================================
-- AUDIO CONFIGURATION
-- ============================================================================
-- Sound effects and music asset IDs and settings
Config.Audio = {
	Enable = true,                       -- Master switch for all audio (set to false to mute game)
	
	-- Music Settings
	Music = {
		Enable = true,                   -- Toggle background music
		Volume = 0.3,                    -- Music volume (0-1)
		Looped = true,                   -- Whether music loops continuously
		
		-- Background Music Asset IDs
		-- Replace these with your actual Roblox audio asset IDs
		Tracks = {
			Ambient = "rbxassetid://128483646982293",      -- Calm mystical ambient music
			Action = "rbxassetid://125486942822550",       -- Upbeat farming music
			Night = "rbxassetid://9045934037"         -- Peaceful night theme
		},
		
		-- Music playback settings
		FadeTime = 2.0,                  -- Seconds to fade in/out when changing tracks
		ShuffleMode = true,             -- Randomly play tracks
		CurrentTrack = "Ambient"         -- Default starting track
	},
	
	-- Sound Effects Settings
	SFX = {
		Enable = true,                   -- Toggle sound effects
		Volume = 0.5,                    -- SFX volume (0-1)
		
		-- Player Actions
		PlantSeed = "rbxassetid://134410500299351",        -- Planting a seed
		WaterPlant = "rbxassetid://2846734837",       -- Watering can splash
		HarvestPlant = "rbxassetid://9113312791",     -- Harvesting/picking fruit
		DigPlant = "rbxassetid://180163752",         -- Shovel digging sound
		
		-- UI Interactions
		ButtonClick = "rbxassetid://6895079853",      -- UI button clicks
		WindowOpen = "rbxassetid://15675059323",       -- Opening shop/sell windows
		WindowClose = "rbxassetid://18755588842",       -- Closing windows
		Purchase = "rbxassetid://87437544236708",         -- Successful purchase sound
		Sell = "rbxassetid://18755588842",              -- Selling items sound
		Error = "rbxassetid://18755588842",             -- Error/cannot do action
		
		-- Plant Growth
		PlantGrow = "rbxassetid://92413337196515",        -- Plant advancing growth stage
		PlantBloom = "rbxassetid://7988065758",       -- Plant reaching bloom stage
		PlantWither = "rbxassetid://3779045779",      -- Plant dying/withering
		
		-- Pets
		PetEquip = "rbxassetid://7988065758",         -- Equipping a pet
		PetUnequip = "rbxassetid://3779045779",       -- Unequipping a pet
		PetFollow = "rbxassetid://87437544236708",        -- Pet following/appearing
		PetCheer = "rbxassetid://90664135987643",         -- Pet cheering/boosting plant
		
		-- Weather
		RainStart = "rbxassetid://125351825026602",        -- Rain weather starting
		StormStart = "rbxassetid://9120557866",       -- Storm weather starting
		SunnyStart = "rbxassetid://9112757357",       -- Sunny weather returning
		Thunder = "rbxassetid://4961240438",          -- Thunder sound for storm
		
		-- Notifications
		NotificationPop = "rbxassetid://87437544236708",  -- Notification appearing
		CoinEarn = "rbxassetid://87437544236708",         -- Earning coins
		
		-- Ambient
		BirdsChirping = "rbxassetid://9118752861",    -- Background bird sounds
		WindBlow = "rbxassetid://9116258071",         -- Wind sound effects
		MagicSparkle = "rbxassetid://9125986205"      -- Magical sparkle sound
	},
	
	-- Audio Playback Settings
	Playback = {
		MaxDistance = 50,                -- Maximum distance to hear sounds (studs)
		RollOffMinDistance = 10,         -- Distance where sound starts to fade
		RollOffMaxDistance = 50,         -- Distance where sound is silent
		DopplerLevel = 0,                -- Doppler effect intensity (0 = disabled)
		Use3DSound = true,               -- Whether to use positional 3D audio
		
		-- Sound pooling (reuse sound instances for performance)
		EnablePooling = true,
		MaxPoolSize = 20                 -- Maximum sounds in pool per type
	}
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
-- Utility functions for retrieving commonly-accessed game objects
Config.functions = {}

-- Get a folder or instance from a parent by name
-- @param root: Instance - The parent to search in
-- @param name: string - The name of the child to find
-- @return Instance|nil - The child if found, nil otherwise
function Config.functions.GetFolder(root, name)
	if typeof(root) == "Instance" and name and root:FindFirstChild(name) then
		return root[name]
	end
	return nil
end

-- Get a world folder by name
-- Convenience function to get folders from workspace root
-- @param name: string - The name of the world folder (e.g., "Gardens")
-- @return Instance|nil - The folder if found, nil otherwise
function Config.functions.GetWorldFolder(name)
	return Config.functions.GetFolder(Config.World.Root, name)
end

-- Get a garden folder by name
-- Retrieves a specific garden from the Gardens folder
-- @param gardenName: string - The name of the garden (e.g., "Garden1")
-- @return Folder|nil - The garden Folder if found, nil otherwise
function Config.functions.GetGarden(gardenName)
	local gardensFolder = Config.functions.GetWorldFolder(Config.World.GardensFolder)
	if not gardensFolder then return nil end
	return gardensFolder:FindFirstChild(gardenName)
end

-- Get the Plots folder within a garden
-- @param garden: Folder - The garden folder
-- @return Folder|nil - The Plots folder if found, nil otherwise
function Config.functions.GetPlotsFolder(garden)
	if typeof(garden) == "Instance" then
		return garden:FindFirstChild(Config.World.PlotsFolder)
	end
	return nil
end

-- Get a specific PlantAnchor from a garden
-- @param garden: Folder - The garden folder
-- @param slotIndex: number - The slot index (1-16)
-- @return Part|nil - The PlantAnchor Part if found, nil otherwise
function Config.functions.GetPlantAnchor(garden, slotIndex)
	local plotsFolder = Config.functions.GetPlotsFolder(garden)
	if not plotsFolder then return nil end
	
	local anchorName = Config.Garden.PlantAnchorPrefix .. tostring(slotIndex)
	return plotsFolder:FindFirstChild(anchorName)
end

-- Get the PlayerSign Model from a garden
-- @param garden: Folder - The garden folder
-- @return Model|nil - The PlayerSign Model if found, nil otherwise
function Config.functions.GetPlayerSign(garden)
	if typeof(garden) == "Instance" then
		return garden:FindFirstChild(Config.World.PlayerSignName)
	end
	return nil
end

-- Get the Sign Part (with SurfaceGui) from a PlayerSign Model
-- @param playerSign: Model - The PlayerSign Model
-- @return Part|nil - The Sign Part if found, nil otherwise
function Config.functions.GetSignPart(playerSign)
	if typeof(playerSign) == "Instance" then
		return playerSign:FindFirstChild(Config.World.PlayerSignPartName)
	end
	return nil
end

return Config
