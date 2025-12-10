-- WeatherEffects.client.luau
-- Shows visual effects when weather changes and affects plants

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[WeatherEffects] Shared folder missing; aborting weather VFX")
	return
end

local function safeRequire(name)
	local ok, mod = pcall(function()
		return require(sharedFolder:WaitForChild(name, 5))
	end)
	if not ok then
		warn(string.format("[WeatherEffects] Failed to load %s: %s", name, tostring(mod)))
		return nil
	end
	return mod
end

local Constants = safeRequire("Constants")
local Config = safeRequire("Config")
local VFXModule = safeRequire("VFXModule")

if not Constants or not Config or not VFXModule then
	warn("[WeatherEffects] Missing shared modules; aborting weather VFX")
	return
end

local player = Players.LocalPlayer

-- Find the Particles part in Workspace
local particlesPart = Workspace:WaitForChild("Particles", 10)
if not particlesPart then
	warn("Particles part not found in Workspace!")
	return
end

-- Get particle emitters
local glowEmitter = particlesPart:FindFirstChild("Glow")
local rainEmitter = particlesPart:FindFirstChild("Rain")
local stormEmitter = particlesPart:FindFirstChild("Storm")

if not glowEmitter or not rainEmitter or not stormEmitter then
	warn("Weather particle emitters not found! Expected: Glow, Rain, Storm")
	return
end

-- Function to smoothly transition particle emitters
local function setParticleEnabled(emitter, enabled, fadeTime)
	fadeTime = fadeTime or 3
	
	if enabled then
		-- Fade in
		emitter.Enabled = true
		local startRate = emitter.Rate
		emitter.Rate = 0
		
		local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local tween = TweenService:Create(emitter, tweenInfo, {Rate = startRate})
		tween:Play()
	else
		-- Fade out
		local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		local tween = TweenService:Create(emitter, tweenInfo, {Rate = 0})
		tween:Play()
		
		task.delay(fadeTime, function()
			emitter.Enabled = false
		end)
	end
end

-- Store original rates for restoring
local originalGlowRate = glowEmitter.Rate
local originalRainRate = rainEmitter.Rate
local originalStormRate = stormEmitter.Rate

-- Show plant boost indicators when weather benefits them
local function showPlantBoostEffects(weatherType)
	local config = Constants.WEATHER_CONFIG[weatherType]
	if not config or config.GrowthMultiplier <= 1.0 then return end
	
	-- Find plots folder directly in workspace
	local plotsFolder = Workspace:FindFirstChild(Config.World.PlotsFolder)
	if not plotsFolder then return end
	
	-- Find player's plot
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("Owner") == player.UserId then
			-- Show effects on all plants in the plot
			for _, child in ipairs(plot:GetChildren()) do
				if child:IsA("Model") and child:GetAttribute("PlantType") then
					-- Create a weather boost indicator
					task.spawn(function()
						for i = 1, 3 do
							task.wait(i * 0.3)
							VFXModule.TryEmitGrowth(child)
						end
					end)
				end
			end
			break
		end
	end
end

-- Apply weather particle effects
local function applyWeatherEffects(weatherType)
	local fadeTime = 5 -- 5 second smooth transition
	
	if weatherType == Constants.WEATHER_TYPES.SUNNY then
		-- Sunny: Enable Glow, disable Rain and Storm
		setParticleEnabled(glowEmitter, true, fadeTime)
		setParticleEnabled(rainEmitter, false, fadeTime)
		setParticleEnabled(stormEmitter, false, fadeTime)
		
		-- Restore original rates
		glowEmitter.Rate = originalGlowRate
		
	elseif weatherType == Constants.WEATHER_TYPES.RAINY then
		-- Rainy: Enable Rain, disable Glow and Storm
		setParticleEnabled(glowEmitter, false, fadeTime)
		setParticleEnabled(rainEmitter, true, fadeTime)
		setParticleEnabled(stormEmitter, false, fadeTime)
		
		-- Restore original rates
		rainEmitter.Rate = originalRainRate
		
	elseif weatherType == Constants.WEATHER_TYPES.STORMY then
		-- Stormy: Enable both Rain and Storm, disable Glow
		setParticleEnabled(glowEmitter, false, fadeTime)
		setParticleEnabled(rainEmitter, true, fadeTime)
		setParticleEnabled(stormEmitter, true, fadeTime)
		
		-- Restore original rates
		rainEmitter.Rate = originalRainRate
		stormEmitter.Rate = originalStormRate
	end
end

-- Listen for weather changes
local weatherEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED, 10)
if not weatherEvent then
	warn("WeatherChanged RemoteEvent not found - weather effects disabled!")
	return
end

weatherEvent.OnClientEvent:Connect(function(weatherType)
	-- Apply smooth particle transition
	applyWeatherEffects(weatherType)
	
	-- Show boost effects on plants
	task.wait(0.5) -- Small delay for dramatic effect
	showPlantBoostEffects(weatherType)
end)

-- Initialize with sunny weather
applyWeatherEffects(Constants.WEATHER_TYPES.SUNNY)

-- print("WeatherEffects client initialized")
