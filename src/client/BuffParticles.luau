-- BuffParticles.luau
-- Adds subtle particle effects to plants with buffs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Constants = require(ReplicatedStorage.Shared.Constants)
local BuffsModule = require(ReplicatedStorage.Shared.BuffsModule)

local BuffParticles = {}
local trackedPlants = {} -- [plantModel] = {weather = emitter, watered = emitter, pet = emitter}
local currentWeather = "Sunny" -- Track client-side weather state

-- Create particle emitter for weather buff
local function createWeatherParticle()
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "WeatherBuffParticle"
	
	-- Bright sparkles
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
	emitter.Size = NumberSequence.new(0.4, 0.6) -- Much larger
	emitter.Transparency = NumberSequence.new(0.2, 0.8) -- More visible
	
	-- More noticeable
	emitter.Lifetime = NumberRange.new(2.5, 3.5)
	emitter.Rate = 5 -- Increased rate
	emitter.Speed = NumberRange.new(1, 2)
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.VelocityInheritance = 0
	emitter.Acceleration = Vector3.new(0, 1, 0) -- Float upward
	emitter.Drag = 1
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.LightEmission = 0.8 -- Add glow
	emitter.Enabled = false
	
	return emitter
end

-- Create particle emitter for watered buff
local function createWateredParticle()
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "WateredBuffParticle"
	
	-- Water droplets
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(100, 180, 255))
	emitter.Size = NumberSequence.new(0.3, 0.5) -- Larger droplets
	emitter.Transparency = NumberSequence.new(0.3, 0.9) -- More visible
	
	-- More noticeable drops
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.Rate = 4 -- Increased rate
	emitter.Speed = NumberRange.new(0.5, 1.2)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.VelocityInheritance = 0
	emitter.Acceleration = Vector3.new(0, -1, 0) -- Downward drift
	emitter.Drag = 2
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.LightEmission = 0.5
	emitter.Enabled = false
	
	return emitter
end

-- Create particle emitter for pet buff
local function createPetParticle()
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "PetBuffParticle"
	
	-- Hearts/stars
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 150, 255))
	emitter.Size = NumberSequence.new(0.4, 0.6) -- Larger hearts
	emitter.Transparency = NumberSequence.new(0.2, 0.9) -- More visible
	
	-- Floating hearts
	emitter.Lifetime = NumberRange.new(2.5, 3.5)
	emitter.Rate = 3 -- Increased rate
	emitter.Speed = NumberRange.new(0.8, 1.5)
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.VelocityInheritance = 0
	emitter.Acceleration = Vector3.new(0, 1.2, 0) -- Float upward faster
	emitter.Drag = 1.5
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-30, 30)
	emitter.LightEmission = 0.6
	emitter.Enabled = false
	
	return emitter
end

-- Setup particles for a plant
local function setupPlantParticles(plantModel)
	if trackedPlants[plantModel] then return end
	
	print(string.format("[BuffParticles] Setting up particles for plant: %s", plantModel.Name))
	
	-- Find the main part of the plant to attach particles
	local attachPart = plantModel.PrimaryPart or plantModel:FindFirstChildWhichIsA("BasePart")
	if not attachPart then 
		warn(string.format("[BuffParticles] No attach part found for plant: %s", plantModel.Name))
		return 
	end
	
	print(string.format("[BuffParticles] Attaching particles to: %s", attachPart.Name))
	
	-- Create emitters
	local weatherEmitter = createWeatherParticle()
	weatherEmitter.Parent = attachPart
	
	local wateredEmitter = createWateredParticle()
	wateredEmitter.Parent = attachPart
	
	local petEmitter = createPetParticle()
	petEmitter.Parent = attachPart
	
	trackedPlants[plantModel] = {
		weather = weatherEmitter,
		watered = wateredEmitter,
		pet = petEmitter
	}
	
	print(string.format("[BuffParticles] ✓ Particles created for %s", plantModel.Name))
end

-- Update particle states based on buffs
local function updatePlantParticles(plantModel)
	local emitters = trackedPlants[plantModel]
	if not emitters then return end
	
	-- Check weather buff (only show for Rainy/Stormy)
	local hasWeatherBuff = currentWeather == "Rainy" or currentWeather == "Stormy"
	
	if emitters.weather.Enabled ~= hasWeatherBuff then
		emitters.weather.Enabled = hasWeatherBuff
		if hasWeatherBuff then
			print(string.format("[BuffParticles] Weather particles enabled for %s (Weather: %s)", plantModel.Name, currentWeather))
		else
			print(string.format("[BuffParticles] Weather particles disabled for %s (Weather: %s)", plantModel.Name, currentWeather))
		end
	end
	
	-- Update weather particle color based on weather type
	if currentWeather == "Stormy" then
		emitters.weather.Color = ColorSequence.new(Color3.fromRGB(100, 150, 220)) -- Darker blue for storm
		emitters.weather.Rate = 7 -- More particles in storm
	else
		emitters.weather.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255)) -- Light blue for rain
		emitters.weather.Rate = 5
	end
	
	-- Check watered buff
	local isWatered = BuffsModule.IsWatered(plantModel)
	if emitters.watered.Enabled ~= isWatered then
		emitters.watered.Enabled = isWatered
		if isWatered then
			print(string.format("[BuffParticles] Watered particles enabled for %s", plantModel.Name))
		else
			print(string.format("[BuffParticles] Watered particles disabled for %s", plantModel.Name))
		end
	end
	
	-- Check pet buff
	local hasPetBuff = plantModel:GetAttribute("PetBoost") == true
	if emitters.pet.Enabled ~= hasPetBuff then
		emitters.pet.Enabled = hasPetBuff
		if hasPetBuff then
			print(string.format("[BuffParticles] Pet particles enabled for %s", plantModel.Name))
		else
			print(string.format("[BuffParticles] Pet particles disabled for %s", plantModel.Name))
		end
	end
end

-- Scan for plants and update particles
local function scanAndUpdatePlants()
	local gardensFolder = Workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then 
		warn("[BuffParticles] Gardens folder not found in Workspace")
		return 
	end
	
	local plantsFound = 0
	
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
			if plotsFolder and plotsFolder:IsA("Folder") then
				for _, anchor in ipairs(plotsFolder:GetChildren()) do
					if anchor:IsA("BasePart") then
						for _, child in ipairs(anchor:GetChildren()) do
							if child:IsA("Model") and child:GetAttribute("PlantType") then
								plantsFound = plantsFound + 1
								
								-- Setup particles if not already tracked
								setupPlantParticles(child)
								
								-- Update particle states
								updatePlantParticles(child)
							end
						end
					end
				end
			end
		end
	end
	
	-- Clean up destroyed plants
	for plant, _ in pairs(trackedPlants) do
		if not plant.Parent then
			trackedPlants[plant] = nil
		end
	end
end

-- Initialize
function BuffParticles.Initialize()
	print("[BuffParticles] Initializing...")
	
	-- Listen for weather changes
	local weatherEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED, 10)
	if weatherEvent then
		weatherEvent.OnClientEvent:Connect(function(weatherType)
			currentWeather = weatherType
			print(string.format("[BuffParticles] Weather changed to: %s", weatherType))
			
			-- Immediately update all plants
			for plant, _ in pairs(trackedPlants) do
				updatePlantParticles(plant)
			end
		end)
		print("[BuffParticles] ✓ Weather event listener connected")
	else
		warn("[BuffParticles] WeatherChanged event not found!")
	end
	
	-- Update every 0.5 seconds (not every frame for performance)
	local updateInterval = 0.5
	local timeSinceLastUpdate = 0

	RunService.Heartbeat:Connect(function(deltaTime)
		timeSinceLastUpdate = timeSinceLastUpdate + deltaTime
		
		if timeSinceLastUpdate >= updateInterval then
			scanAndUpdatePlants()
			timeSinceLastUpdate = 0
		end
	end)
	
	print("[BuffParticles] ✓ Initialized - Buff particles enabled")
end

return BuffParticles
