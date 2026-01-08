-- WeatherController.luau
-- Manages dynamic weather system that affects lighting and plant growth

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[WeatherController] Shared folder missing; weather system disabled")
	return {}
end

local function safeRequire(name)
	local ok, mod = pcall(function()
		return require(sharedFolder:WaitForChild(name, 5))
	end)
	if not ok then
		warn(string.format("[WeatherController] Failed to load %s: %s", name, tostring(mod)))
		return nil
	end
	return mod
end

local Constants = safeRequire("Constants")
local BuffsModule = safeRequire("BuffsModule")
if not (Constants and BuffsModule) then
	return {}
end

local WeatherController = {}
WeatherController.CurrentWeather = Constants.WEATHER_TYPES.SUNNY

-- Create RemoteEvent for weather updates
local weatherEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.WEATHER_CHANGED)
if not (weatherEvent and weatherEvent:IsA("RemoteEvent")) then
	local created = Instance.new("RemoteEvent")
	created.Name = Constants.EVENTS.WEATHER_CHANGED
	created.Parent = ReplicatedStorage
	weatherEvent = created
end
weatherEvent = weatherEvent :: RemoteEvent

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

-- Ensure late joiners receive current weather
Players.PlayerAdded:Connect(function(player)
	weatherEvent:FireClient(player, WeatherController.CurrentWeather)
end)

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
