-- WeatherEffects.client.luau
-- Shows visual effects when weather changes and affects plants

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Config = require(ReplicatedStorage.Shared.Config)
local VFXModule = require(ReplicatedStorage.Shared.VFXModule)

local player = Players.LocalPlayer

-- Create weather particles for rainy/stormy weather
local function createRainEffect()
	local rainPart = Instance.new("Part")
	rainPart.Name = "RainEffect"
	rainPart.Size = Vector3.new(100, 1, 100)
	rainPart.Position = Vector3.new(0, 50, 0)
	rainPart.Transparency = 1
	rainPart.Anchored = true
	rainPart.CanCollide = false
	rainPart.Parent = Workspace
	
	local rainEmitter = Instance.new("ParticleEmitter")
	rainEmitter.Name = "Rain"
	rainEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	rainEmitter.Color = ColorSequence.new(Color3.fromRGB(150, 180, 220))
	rainEmitter.Size = NumberSequence.new(0.2, 0.2)
	rainEmitter.Transparency = NumberSequence.new(0.3, 0.5)
	rainEmitter.Lifetime = NumberRange.new(2, 3)
	rainEmitter.Rate = 100
	rainEmitter.Speed = NumberRange.new(30, 40)
	rainEmitter.SpreadAngle = Vector2.new(5, 5)
	rainEmitter.Acceleration = Vector3.new(0, -50, 0)
	rainEmitter.Parent = rainPart
	
	return rainPart
end

local currentRainEffect = nil

-- Show plant boost indicators when weather benefits them
local function showPlantBoostEffects(weatherType)
	local config = Constants.WEATHER_CONFIG[weatherType]
	if not config or config.GrowthMultiplier <= 1.0 then return end
	
	-- Find player's garden plot
	local gardenWorld = Workspace:FindFirstChild(Config.World.GardenWorldName)
	if not gardenWorld then return end
	
	local plotsFolder = gardenWorld:FindFirstChild(Config.World.GardenPlotsFolder)
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

-- Listen for weather changes
local weatherEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED)
weatherEvent.OnClientEvent:Connect(function(weatherType)
	print("Weather changed to:", weatherType)
	
	-- Remove old rain effect
	if currentRainEffect then
		currentRainEffect:Destroy()
		currentRainEffect = nil
	end
	
	-- Add rain effect for rainy/stormy weather
	if weatherType == Constants.WEATHER_TYPES.RAINY or weatherType == Constants.WEATHER_TYPES.STORMY then
		currentRainEffect = createRainEffect()
	end
	
	-- Show boost effects on plants
	task.wait(0.5) -- Small delay for dramatic effect
	showPlantBoostEffects(weatherType)
end)

print("WeatherEffects client initialized")
