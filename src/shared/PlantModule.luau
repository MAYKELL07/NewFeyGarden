-- PlantModule.luau
-- Handles plant growth logic with weather-based multipliers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local PlantModule = {}

-- Create a plant model
function PlantModule.CreatePlantModel(plantType, position)
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then
		warn("Invalid plant type:", plantType)
		return nil
	end
	
	-- Create plant model
	local plantModel = Instance.new("Model")
	plantModel.Name = plantType
	
	-- Create base part
	local basePart = Instance.new("Part")
	basePart.Name = "Base"
	basePart.Size = Vector3.new(1, 0.5, 1)
	basePart.Position = position
	basePart.Anchored = true
	basePart.Color = Color3.fromRGB(139, 69, 19) -- Brown soil
	basePart.Parent = plantModel
	
	-- Create plant part
	local plantPart = Instance.new("Part")
	plantPart.Name = "Plant"
	plantPart.Size = Vector3.new(0.5, 0.5, 0.5)
	plantPart.Position = position + Vector3.new(0, 1, 0)
	plantPart.Anchored = true
	plantPart.Color = config.Color
	plantPart.Shape = Enum.PartType.Ball
	plantPart.Parent = plantModel
	
	-- Add light if needed
	if config.EmitsLight then
		local light = Instance.new("PointLight")
		light.Brightness = 0
		light.Range = 10
		light.Color = config.Color
		light.Parent = plantPart
	end
	
	-- Set attributes
	plantModel:SetAttribute("PlantType", plantType)
	plantModel:SetAttribute("Stage", Constants.GROWTH_STAGES.SEED)
	plantModel:SetAttribute("GrowthProgress", 0)
	plantModel:SetAttribute("PlantTime", os.time())
	
	plantModel.PrimaryPart = basePart
	
	return plantModel
end

-- Update plant visual based on stage
function PlantModule.UpdatePlantVisual(plantModel)
	local stage = plantModel:GetAttribute("Stage")
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then return end
	
	local plantPart = plantModel:FindFirstChild("Plant")
	if not plantPart then return end
	
	-- Update size and position based on stage
	if stage == Constants.GROWTH_STAGES.SEED then
		plantPart.Size = Vector3.new(0.5, 0.5, 0.5)
		plantPart.Position = plantModel.Base.Position + Vector3.new(0, 0.5, 0)
		plantPart.Transparency = 0.3
		
		-- Turn off light
		local light = plantPart:FindFirstChild("PointLight")
		if light then light.Brightness = 0 end
		
	elseif stage == Constants.GROWTH_STAGES.SPROUT then
		plantPart.Size = Vector3.new(1, 2, 1)
		plantPart.Position = plantModel.Base.Position + Vector3.new(0, 1.25, 0)
		plantPart.Transparency = 0
		
		-- Dim light
		local light = plantPart:FindFirstChild("PointLight")
		if light then light.Brightness = 0.5 end
		
	elseif stage == Constants.GROWTH_STAGES.BLOOM then
		plantPart.Size = Vector3.new(2, 3, 2)
		plantPart.Position = plantModel.Base.Position + Vector3.new(0, 2, 0)
		plantPart.Transparency = 0
		
		-- Full light
		local light = plantPart:FindFirstChild("PointLight")
		if light then light.Brightness = 2 end
	end
end

-- Grow plant over time
function PlantModule.GrowPlant(plantModel, weatherMultiplier, petBoost)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then return end
	
	local stages = {
		Constants.GROWTH_STAGES.SEED,
		Constants.GROWTH_STAGES.SPROUT,
		Constants.GROWTH_STAGES.BLOOM
	}
	
	weatherMultiplier = weatherMultiplier or 1.0
	petBoost = petBoost or 1.0
	
	task.spawn(function()
		for i, stage in ipairs(stages) do
			-- Calculate growth time with multipliers
			local growthTime = config.GrowthTime * weatherMultiplier * petBoost
			
			-- Update stage
			plantModel:SetAttribute("Stage", stage)
			PlantModule.UpdatePlantVisual(plantModel)
			
			print(plantModel.Name .. " grew to " .. stage)
			
			-- Wait for next stage (except on last stage)
			if i < #stages then
				task.wait(growthTime)
			end
		end
		
		-- Mark as harvestable
		plantModel:SetAttribute("Harvestable", true)
	end)
end

-- Check if plant can be harvested
function PlantModule.CanHarvest(plantModel)
	return plantModel:GetAttribute("Stage") == Constants.GROWTH_STAGES.BLOOM
end

-- Get harvest value
function PlantModule.GetHarvestValue(plantModel)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then return 0 end
	
	return config.SellPrice
end

return PlantModule
