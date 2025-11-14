-- WeatherController.luau
-- Manages dynamic weather system that affects lighting and plant growth

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local BuffsModule = require(ReplicatedStorage.Shared.BuffsModule)

local WeatherController = {}
WeatherController.CurrentWeather = Constants.WEATHER_TYPES.SUNNY

-- Create RemoteEvent for weather updates
local weatherEvent = Instance.new("RemoteEvent")
weatherEvent.Name = Constants.EVENTS.WEATHER_CHANGED
weatherEvent.Parent = ReplicatedStorage

-- Apply weather settings to lighting with smooth transitions
local function applyWeather(weatherType)
	local config = Constants.WEATHER_CONFIG[weatherType]
	
	if not config then
		warn("Invalid weather type:", weatherType)
		return
	end
	
	WeatherController.CurrentWeather = weatherType
	
	-- Smooth transition for lighting (10 seconds)
	local tweenInfo = TweenInfo.new(
		10, -- Duration
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)
	
	local lightingTween = TweenService:Create(Lighting, tweenInfo, {
		Brightness = config.Brightness,
		ColorShift_Top = config.ColorShift_Top,
		ClockTime = config.ClockTime
	})
	
	lightingTween:Play()
	
	-- Update BuffsModule
	BuffsModule.SetWeather(weatherType)
	
	-- Notify all clients for particle effects
	weatherEvent:FireAllClients(weatherType)
end

-- Initialize weather system
function WeatherController.Initialize()
	-- Set initial weather
	applyWeather(Constants.WEATHER_TYPES.SUNNY)
	
	-- Start weather cycle
	task.spawn(function()
		while task.wait(Constants.WEATHER_CYCLE_TIME) do
			-- Pick random weather
			local weatherTypes = {
				Constants.WEATHER_TYPES.SUNNY,
				Constants.WEATHER_TYPES.RAINY,
				Constants.WEATHER_TYPES.STORMY
			}
			
			local nextWeather = weatherTypes[math.random(1, #weatherTypes)]
			applyWeather(nextWeather)
		end
	end)
end

-- Get current weather
function WeatherController.GetCurrentWeather()
	return WeatherController.CurrentWeather
end

-- Get growth multiplier for current weather
function WeatherController.GetGrowthMultiplier()
	local config = Constants.WEATHER_CONFIG[WeatherController.CurrentWeather]
	return config and config.GrowthMultiplier or 1.0
end

return WeatherController
