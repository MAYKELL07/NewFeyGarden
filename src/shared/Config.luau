-- Config.luau
-- Centralized configuration for all folder and asset name references

local Config = {}

-- World structure references
Config.World = {
	Root = workspace,
	PlayerSign = "PlayerSign",
	PlotsFolder = "GardenPlots",
	PlantsFolder = "Plants",
	PetsFolder = "Pets",
}

-- Plot configuration
Config.Plot = {
	PlantAnchorName = "PlantAnchor",
	StateAttributes = {"Occupied", "WateredUntil", "Owner", "PlantCount"}
}

-- Tool configuration
Config.Tools = {
	Shovel = {
		Name = "Shovel",
		Cooldown = 1.0
	},
	WateringCan = {
		Name = "WateringCan",
		Cooldown = 1.5,
		WaterSeconds = 90
	},
	MaxUseDistance = 15
}

-- Buff multipliers
Config.Buffs = {
	Weather = {
		Sunny = 1.0,
		Rainy = 0.8,  -- 20% faster (lower multiplier = faster growth)
		Stormy = 0.7  -- 30% faster
	},
	Watered = 0.85,  -- 15% faster when watered
	PetBoost = 0.9   -- 10% faster near pet
}

-- VFX particle configuration
Config.VFX = {
	Enable = true,
	WaterSplashParticleName = "WaterSplash",
	GrowthSparkleParticleName = "GrowthSparkle",
	PetCheerParticleName = "PetCheer"
}

-- Helper functions
Config.functions = {}

-- Get a folder from a parent by name
function Config.functions.GetFolder(root, name)
	if typeof(root) == "Instance" and name and root:FindFirstChild(name) then
		return root[name]
	end
	return nil
end

-- Get a world folder by name
function Config.functions.GetWorldFolder(name)
	return Config.functions.GetFolder(Config.World.Root, name)
end

-- Get player's plot
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
