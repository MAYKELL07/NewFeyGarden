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
	FloorName = "Floor",                 -- Name of the main floor/platform part in each garden
	PlotsFolder = "Plots",               -- Name of the folder containing PlantAnchors within each garden
	TeleportPartName = "TPpart",         -- Name of the part where players spawn in their garden
	ShopPartName = "ShopPart",           -- Name of the part that has the ProximityPrompt for opening shop
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
