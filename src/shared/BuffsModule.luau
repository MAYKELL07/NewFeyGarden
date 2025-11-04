-- BuffsModule.luau
-- Handles weather, watering, and pet proximity buffs for plant growth

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local BuffsModule = {}

-- Current weather value (set by WeatherController)
BuffsModule.CurrentWeather = "Sunny"

-- Set the current weather
function BuffsModule.SetWeather(weatherType)
	BuffsModule.CurrentWeather = weatherType
end

-- Get the current weather
function BuffsModule.GetWeather()
	return BuffsModule.CurrentWeather
end

-- Calculate the total growth multiplier for a plant
function BuffsModule.GetGrowthMultiplier(plantModel)
	local multiplier = 1.0
	
	-- Weather buff
	local weatherMult = Config.Buffs.Weather[BuffsModule.CurrentWeather] or 1.0
	multiplier = multiplier * weatherMult
	
	-- Watering buff
	local now = os.time()
	local wateredUntil = plantModel:GetAttribute("WateredUntil")
	if wateredUntil and wateredUntil > now then
		multiplier = multiplier * (Config.Buffs.Watered or 1.0)
	end
	
	-- Pet proximity buff
	if plantModel:GetAttribute("PetBoost") then
		multiplier = multiplier * (Config.Buffs.PetBoost or 1.0)
	end
	
	return multiplier
end

-- Check if plant is watered
function BuffsModule.IsWatered(plantModel)
	local now = os.time()
	local wateredUntil = plantModel:GetAttribute("WateredUntil")
	return wateredUntil and wateredUntil > now
end

-- Water a plant
function BuffsModule.WaterPlant(plantModel, duration)
	duration = duration or Config.Tools.WateringCan.WaterSeconds
	plantModel:SetAttribute("WateredUntil", os.time() + duration)
end

-- Set pet boost on a plant
function BuffsModule.SetPetBoost(plantModel, enabled)
	plantModel:SetAttribute("PetBoost", enabled)
end

-- Get buff status string for debugging
function BuffsModule.GetBuffStatus(plantModel)
	local status = {
		Weather = BuffsModule.CurrentWeather,
		Watered = BuffsModule.IsWatered(plantModel),
		PetBoost = plantModel:GetAttribute("PetBoost") or false,
		TotalMultiplier = BuffsModule.GetGrowthMultiplier(plantModel)
	}
	return status
end

return BuffsModule
