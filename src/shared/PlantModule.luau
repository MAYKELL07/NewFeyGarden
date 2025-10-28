-- PlantModule.luau
-- Handles plant growth logic with weather-based multipliers and buffs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local BuffsModule = require(ReplicatedStorage.Shared.BuffsModule)
local VFXModule = require(ReplicatedStorage.Shared.VFXModule)

local PlantModule = {}

-- Create a plant model
function PlantModule.CreatePlantModel(plantType, position)
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then
		warn("Invalid plant type:", plantType)
		return nil
	end
	
	-- Get plant models from ReplicatedStorage
	local plantsFolder = ReplicatedStorage:FindFirstChild("Plants")
	if not plantsFolder then
		warn("[PlantModule] Plants folder not found in ReplicatedStorage")
		return nil
	end
	
	local plantFolder = plantsFolder:FindFirstChild(plantType)
	if not plantFolder then
		warn("[PlantModule] Plant folder not found for:", plantType)
		return nil
	end
	
	local seedMesh = plantFolder:FindFirstChild("seed")
	local plantMesh = plantFolder:FindFirstChild("plant")
	
	if not seedMesh or not plantMesh then
		warn("[PlantModule] Missing seed or plant mesh for:", plantType)
		return nil
	end
	
	-- Create plant model container
	local plantModel = Instance.new("Model")
	plantModel.Name = plantType
	
	-- Create base part (invisible anchor)
	local basePart = Instance.new("Part")
	basePart.Name = "Base"
	basePart.Size = Vector3.new(2, 0.1, 2)
	basePart.Position = position
	basePart.Anchored = true
	basePart.Transparency = 1
	basePart.CanCollide = false
	basePart.Parent = plantModel
	
	-- Clone seed mesh as the plant part (will swap models based on stage)
	local plantPart = seedMesh:Clone()
	plantPart.Name = "Plant"
	plantPart.Position = position + Vector3.new(0, 1, 0)
	plantPart.Anchored = true
	plantPart.Parent = plantModel
	
	-- Store references to both meshes
	plantModel:SetAttribute("SeedMeshName", "seed")
	plantModel:SetAttribute("PlantMeshName", "plant")
	
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
	
	-- Get plant models from ReplicatedStorage
	local plantsFolder = ReplicatedStorage:FindFirstChild("Plants")
	if not plantsFolder then return end
	
	local plantFolder = plantsFolder:FindFirstChild(plantType)
	if not plantFolder then return end
	
	local seedMesh = plantFolder:FindFirstChild("seed")
	local plantMesh = plantFolder:FindFirstChild("plant")
	
	if not seedMesh or not plantMesh then return end
	
	local currentPlantPart = plantModel:FindFirstChild("Plant")
	if not currentPlantPart then return end
	
	-- Store current properties
	local currentPosition = currentPlantPart.Position
	local light = currentPlantPart:FindFirstChild("PointLight")
	
	-- Determine which mesh to use and scale based on stage
	local newMesh
	local scale = 1
	local transparency = 0
	local lightBrightness = 0
	
	if stage == Constants.GROWTH_STAGES.SEED then
		newMesh = seedMesh
		scale = 1.5  -- 3x larger than original 0.5
		transparency = 0.3
		lightBrightness = 0
		
	elseif stage == Constants.GROWTH_STAGES.SPROUT then
		newMesh = plantMesh
		scale = 2.1  -- 3x larger than original 0.7
		transparency = 0
		lightBrightness = 0.5
		
	elseif stage == Constants.GROWTH_STAGES.BLOOM then
		newMesh = plantMesh
		scale = 3.0  -- 3x larger than original 1.0
		transparency = 0
		lightBrightness = 2
	end
	
	-- Replace the plant part with the appropriate mesh
	if newMesh then
		local replacementPart = newMesh:Clone()
		replacementPart.Name = "Plant"
		replacementPart.Position = currentPosition
		replacementPart.Anchored = true
		
		-- Apply scale
		if replacementPart:IsA("MeshPart") then
			replacementPart.Size = newMesh.Size * scale
		end
		
		replacementPart.Transparency = transparency
		
		-- Transfer or create light
		if config.EmitsLight then
			if light then
				light.Parent = replacementPart
			else
				light = Instance.new("PointLight")
				light.Range = 10
				light.Color = config.Color
				light.Parent = replacementPart
			end
			light.Brightness = lightBrightness
		end
		
		-- Replace in model
		currentPlantPart:Destroy()
		replacementPart.Parent = plantModel
	end
end

-- Grow plant over time with dynamic buff system
function PlantModule.GrowPlant(plantModel)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then return end
	
	local stages = {
		Constants.GROWTH_STAGES.SEED,
		Constants.GROWTH_STAGES.SPROUT,
		Constants.GROWTH_STAGES.BLOOM
	}
	
	task.spawn(function()
		for i, stage in ipairs(stages) do
			-- Get current buff multiplier (dynamic - checks buffs each stage)
			local buffMultiplier = BuffsModule.GetGrowthMultiplier(plantModel)
			
			-- Calculate growth time with buffs
			local growthTime = config.GrowthTime * buffMultiplier
			
			-- Update stage
			plantModel:SetAttribute("Stage", stage)
			PlantModule.UpdatePlantVisual(plantModel)
			
			-- Emit growth VFX
			VFXModule.TryEmitGrowth(plantModel)
			
			-- Debug info
			local buffStatus = BuffsModule.GetBuffStatus(plantModel)
			print(string.format("%s grew to %s (%.2fs, mult: %.2f)", 
				plantModel.Name, stage, growthTime, buffMultiplier))
			
			-- Wait for next stage (except on last stage)
			if i < #stages then
				task.wait(growthTime)
			end
		end
		
		-- Mark as harvestable
		plantModel:SetAttribute("Harvestable", true)
		print(plantModel.Name .. " is now harvestable!")
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
