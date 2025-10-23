-- Config.luau
-- Centralized configuration for all folder and asset name references
-- This module provides a single source of truth for all game configuration values

local Config = {}

-- World structure references
-- Defines the hierarchy and naming conventions for game world objects
Config.World = {
	Root = workspace,                    -- Root container for all world objects
	PlayerSign = "PlayerSign",           -- Name of player identification signs (unused currently)
	PlotsFolder = "GardenPlots",         -- Folder containing all player garden plots
	PlantsFolder = "Plants",             -- Folder for plant prefabs/templates (unused currently)
	PetsFolder = "Pets",                 -- Folder for pet prefabs/templates (unused currently)
}

-- Plot configuration
-- Settings related to garden plot structure and data storage
Config.Plot = {
	PlantAnchorName = "PlantAnchor",     -- Name of the part used to position plants in a plot
	StateAttributes = {                  -- List of Attributes stored on plot instances
		"Occupied",                      -- Boolean: whether a plot slot has a plant
		"WateredUntil",                  -- Number: timestamp when watering buff expires
		"Owner",                         -- Number: UserId of the player who owns this plot
		"PlantCount"                     -- Number: current number of plants in the plot
	}
}

-- Tool configuration
-- Settings for player tools like Shovel and Watering Can
Config.Tools = {
	Shovel = {
		Name = "Shovel",                 -- Tool name that must match the Tool object in game
		Cooldown = 1.0                   -- Seconds between uses to prevent spam
	},
	WateringCan = {
		Name = "WateringCan",            -- Tool name that must match the Tool object in game
		Cooldown = 1.5,                  -- Seconds between uses to prevent spam
		WaterSeconds = 90                -- Duration in seconds that the watering buff lasts
	},
	MaxUseDistance = 15                  -- Maximum studs distance for tool raycast interaction
}

-- Buff multipliers
-- Growth rate modifiers that stack multiplicatively (lower = faster growth)
-- Final growth time = BaseTime × WeatherMult × WaterMult × PetMult
Config.Buffs = {
	Weather = {
		Sunny = 1.0,                     -- No boost (normal speed)
		Rainy = 0.8,                     -- 20% faster growth (80% of normal time)
		Stormy = 0.7                     -- 30% faster growth (70% of normal time)
	},
	Watered = 0.85,                      -- 15% faster when recently watered (85% of normal time)
	PetBoost = 0.9                       -- 10% faster when pet is nearby (90% of normal time)
}

-- VFX particle configuration
-- Settings for visual effects system (currently uses fallback sparkles if particles don't exist)
Config.VFX = {
	Enable = true,                       -- Master switch for all VFX (set to false to disable effects)
	WaterSplashParticleName = "WaterSplash",   -- Name of ParticleEmitter to find in plants for water effect
	GrowthSparkleParticleName = "GrowthSparkle", -- Name of ParticleEmitter to find in plants for growth effect
	PetCheerParticleName = "PetCheer"    -- Name of ParticleEmitter to find in pets for cheer effect
}

-- Helper functions
-- Utility functions for retrieving commonly-accessed game objects
Config.functions = {}

-- Get a folder from a parent by name
-- @param root: Instance - The parent to search in
-- @param name: string - The name of the folder to find
-- @return Instance|nil - The folder if found, nil otherwise
function Config.functions.GetFolder(root, name)
	if typeof(root) == "Instance" and name and root:FindFirstChild(name) then
		return root[name]
	end
	return nil
end

-- Get a world folder by name
-- Convenience function to get folders from workspace root
-- @param name: string - The name of the world folder (e.g., "GardenPlots")
-- @return Instance|nil - The folder if found, nil otherwise
function Config.functions.GetWorldFolder(name)
	return Config.functions.GetFolder(Config.World.Root, name)
end

-- Get player's plot by their UserId
-- Searches through all plots to find the one owned by the specified player
-- @param userId: number - The player's UserId
-- @return Instance|nil - The plot Model if found, nil otherwise
function Config.functions.GetPlayerPlot(userId)
	local plotsFolder = Config.functions.GetWorldFolder(Config.World.PlotsFolder)
	if not plotsFolder then return nil end
	
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:IsA("Model") and plot:GetAttribute("Owner") == userId then
			return plot
		end
	end
	
	return nil
end

return Config
