-- PlantModule.luau
-- Handles plant growth logic with weather-based multipliers and buffs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local BuffsModule = require(ReplicatedStorage.Shared.BuffsModule)
local VFXModule = require(ReplicatedStorage.Shared.VFXModule)

local PlantModule = {}

-- Helper function to find plant folder with case-insensitive matching

local function findPlantFolder(plantsFolder, plantType)
	-- Try exact match first
	local plantFolder = plantsFolder:FindFirstChild(plantType)
	
	-- If not found, try case-insensitive / partial match
	if not plantFolder then
		local plantTypeLower = string.lower(plantType)
		for _, child in ipairs(plantsFolder:GetChildren()) do
			local childNameLower = string.lower(child.Name)
			-- Check if folder name contains the plant type or vice versa
			if string.find(childNameLower, plantTypeLower, 1, true) or string.find(plantTypeLower, childNameLower, 1, true) then
				plantFolder = child
				break
			end
		end
	end
	
	return plantFolder
end

local function clonePlantPart(instance: Instance): Instance?
	if instance:IsA("BasePart") then
		return instance:Clone()
	end

	if instance:IsA("Model") then
		return instance:Clone()
	end

	return nil
end

local function addDirtPile(plantFolder: Folder, plantModel: Model, anchorPosition: Vector3, sizeMultiplier: number)
	local dirtTemplate = plantFolder:FindFirstChild("Dirt")
	if not (dirtTemplate and dirtTemplate:IsA("BasePart")) then
		return
	end

	local dirt = dirtTemplate:Clone()
	dirt.Name = "Dirt"
	dirt.CanCollide = false
	dirt.Anchored = true

	if sizeMultiplier and dirt:IsA("BasePart") then
		dirt.Size = dirt.Size * sizeMultiplier
	end

	local halfHeight = dirt.Size.Y * 0.5
	dirt.CFrame = CFrame.new(anchorPosition + Vector3.new(0, halfHeight, 0))
	dirt.Parent = plantModel
end

local function getPrimaryCFrame(instance: Instance): CFrame?
	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	if instance:IsA("Model") then
		local primary = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
		if primary then
			return primary.CFrame
		end
	end

	return nil
end

local function getBoundingHeight(instance: Instance): number?
	if instance:IsA("BasePart") then
		return instance.Size.Y
	end
	if instance:IsA("Model") then
		local _, size = instance:GetBoundingBox()
		return size.Y
	end
	return nil
end

local function collectFruitTemplates(plantFolder: Instance, plantPart: Instance?)
	local fruitTemplates = {}
	local templateRootCFrame: CFrame? = nil

	local function hasFruitPrefix(name: string): boolean
		return string.sub(name, 1, 5) == "Fruit"
	end

	local function parseFruitIndex(name: string): number?
		if not hasFruitPrefix(name) then
			return nil
		end
		local suffix = string.sub(name, 6)
		local num = tonumber(suffix)
		return num
	end

	local function isDescendantOfFruitModel(instance: Instance, root: Instance): boolean
		local current = instance.Parent
		while current and current ~= root do
			if current:IsA("Model") and hasFruitPrefix(current.Name) then
				return true
			end
			current = current.Parent
		end
		return false
	end

	local function collectFromRoot(rootInstance: Instance)
		local rootCFrame = getPrimaryCFrame(rootInstance)
		if not rootCFrame then
			return
		end
		templateRootCFrame = rootCFrame

		for _, desc in ipairs(rootInstance:GetDescendants()) do
			if desc:IsA("Model") and hasFruitPrefix(desc.Name) then
				table.insert(fruitTemplates, desc)
			elseif desc:IsA("BasePart") and hasFruitPrefix(desc.Name) then
				-- If a Fruit* model exists, prefer it over parts inside that model.
				if not isDescendantOfFruitModel(desc, rootInstance) then
					table.insert(fruitTemplates, desc)
				end
			end
		end
	end

	-- First, try fruits authored under the current plant model (runtime Plant instance)
	if plantPart then
		collectFromRoot(plantPart)
	end

	-- Fallback: fruits under plant folder (content repo)
	if #fruitTemplates == 0 then
		local matureModel = plantFolder:FindFirstChild("Mature")
		if matureModel and matureModel:IsA("Model") then
			collectFromRoot(matureModel)
		end
	end

	table.sort(fruitTemplates, function(a: Instance, b: Instance)
		local aIndex = parseFruitIndex(a.Name)
		local bIndex = parseFruitIndex(b.Name)
		if aIndex and bIndex then
			return aIndex < bIndex
		end
		if aIndex then
			return true
		end
		if bIndex then
			return false
		end
		return a.Name < b.Name
	end)

	return fruitTemplates, templateRootCFrame
end

-- Create a plant model
-- @param plantType: string - The type of plant to create
-- @param position: Vector3 - The position to spawn the plant
-- @param sizeMultiplier: number? - Optional size multiplier (default 1.0, range 0.85-1.15)
function PlantModule.CreatePlantModel(plantType, position, sizeMultiplier)
	local config = Constants.PLANT_CONFIG[plantType]
	
	-- Default size multiplier to 1.0 if not provided
	sizeMultiplier = sizeMultiplier or 1.0
	
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
	
	local plantFolder = findPlantFolder(plantsFolder, plantType)
	if not plantFolder then
		warn("[PlantModule] Plant folder not found for:", plantType)
		return nil
	end
	
	-- Model naming: Seed, Sprout, Mature, Fruit1-4
	local seedMesh = plantFolder:FindFirstChild("Seed")
	local matureMesh = plantFolder:FindFirstChild("Mature")
	
	if not seedMesh then
		warn("[PlantModule] Missing Seed mesh for:", plantType)
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
	
	-- Add optional dirt pile at the anchor position
	addDirtPile(plantFolder, plantModel, position, sizeMultiplier)

	-- Clone seed mesh as the plant part (will swap models based on stage)
	local plantPart = clonePlantPart(seedMesh)
	if not plantPart then
		warn("[PlantModule] Seed mesh has no BasePart for:", plantType)
		return nil
	end
	plantPart.Name = "Plant"

	-- Position plant on top of the Base part (use mesh height so it sits on ground)
	local stageOffset = Constants.STAGE_OFFSETS[Constants.GROWTH_STAGES.SEED] or Vector3.new()
	if plantPart:IsA("BasePart") then
		local height = getBoundingHeight(plantPart) or plantPart.Size.Y
		local anchorCFrame = CFrame.new(position + stageOffset + Vector3.new(0, height * 0.5, 0))
		plantPart.CFrame = anchorCFrame
		plantPart.Anchored = true
		plantPart.Parent = plantModel
		plantPart:SetAttribute("PlantType", plantType)
	elseif plantPart:IsA("Model") then
		local primary = plantPart.PrimaryPart or plantPart:FindFirstChildWhichIsA("BasePart", true)
		if primary then
			for _, desc in ipairs(plantPart:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Anchored = true
				end
			end
			local _, size = plantPart:GetBoundingBox()
			local anchorCFrame = CFrame.new(position + stageOffset + Vector3.new(0, size.Y * 0.5, 0))
			plantPart:PivotTo(anchorCFrame)
			plantPart.Parent = plantModel
			plantPart:SetAttribute("PlantType", plantType)
		else
			warn("[PlantModule] Seed model missing PrimaryPart/BasePart:", plantType)
			return nil
		end
	end
	
	-- Store references to mesh names
	plantModel:SetAttribute("SeedMeshName", "Seed")
	plantModel:SetAttribute("SproutMeshName", "Sprout")
	plantModel:SetAttribute("MatureMeshName", "Mature")
	
	-- Store size multiplier for later use in visuals
	plantModel:SetAttribute("SizeMultiplier", sizeMultiplier)
	
	-- Add light if needed
	if config.EmitsLight then
		local light = Instance.new("PointLight")
		light.Brightness = 0
		light.Range = 10 * sizeMultiplier -- Scale light range with size
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
	local sizeMultiplier = plantModel:GetAttribute("SizeMultiplier") or 1.0
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then return end
	
	-- Get plant models from ReplicatedStorage
	local plantsFolder = ReplicatedStorage:FindFirstChild("Plants")
	if not plantsFolder then return end
	
	local plantFolder = findPlantFolder(plantsFolder, plantType)
	if not plantFolder then return end
	
	-- Model naming: Seed, Sprout, Mature
	local seedMesh = plantFolder:FindFirstChild("Seed")
	local sproutMesh = plantFolder:FindFirstChild("Sprout")
	local matureMesh = plantFolder:FindFirstChild("Mature")
	
	local currentPlantPart = plantModel:FindFirstChild("Plant")
	if not currentPlantPart then return end
	
	-- Store current properties
	local currentPosition = currentPlantPart.Position
	local light = currentPlantPart:FindFirstChild("PointLight")
	
	-- Determine which mesh to use and scale based on stage
	local newMesh
	local scale = 1 * sizeMultiplier
	local transparency = 0
	local lightBrightness = 0

	if stage == Constants.GROWTH_STAGES.SEED then
		newMesh = seedMesh
		transparency = 0.3
		lightBrightness = 0
	elseif stage == Constants.GROWTH_STAGES.SPROUT then
		newMesh = sproutMesh or seedMesh
		transparency = 0
		lightBrightness = 0.5
	elseif stage == Constants.GROWTH_STAGES.BLOOM then
		newMesh = matureMesh or sproutMesh or seedMesh
		transparency = 0
		lightBrightness = 2
	end
	
	-- Replace the plant part with the appropriate mesh
	if newMesh then
		local replacement = clonePlantPart(newMesh)
		if not replacement then
			warn("[PlantModule] Mesh has no cloneable instance for:", plantType)
			return
		end
		replacement.Name = "Plant"
		replacement:SetAttribute("PlantType", plantType)
		
		local basePart = plantModel:FindFirstChild("Base")
		local anchorCFrame = basePart and basePart.CFrame or CFrame.new(currentPosition)
		local stageOffset = Constants.STAGE_OFFSETS[stage] or Vector3.new()
		local extraYOffset = 0
		if stage == Constants.GROWTH_STAGES.SPROUT or stage == Constants.GROWTH_STAGES.BLOOM then
			extraYOffset = -3
		end

		-- Transfer or create light later onto the primary/first part
		local function applyLighting(targetPart: BasePart)
			if not config.EmitsLight then
				return
			end
			if light then
				light.Parent = targetPart
			else
				light = Instance.new("PointLight")
				light.Range = 10 * sizeMultiplier
				light.Color = config.Color
				light.Parent = targetPart
			end
			light.Brightness = lightBrightness
		end

		if replacement:IsA("BasePart") then
			replacement.Transparency = transparency
			replacement.Anchored = true
			replacement.Size = replacement.Size * scale
			replacement.CFrame = anchorCFrame * CFrame.new(stageOffset + Vector3.new(0, extraYOffset, 0) + Vector3.new(0, replacement.Size.Y * 0.5, 0))
			applyLighting(replacement)
		elseif replacement:IsA("Model") then
			local primary = replacement.PrimaryPart or replacement:FindFirstChildWhichIsA("BasePart", true)
			if not primary then
				warn("[PlantModule] Model missing PrimaryPart/BasePart for:", plantType)
				return
			end
			replacement:ScaleTo(scale)
			for _, desc in ipairs(replacement:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Anchored = true
					desc.Transparency = transparency
				end
			end
			local _, size = replacement:GetBoundingBox()
			replacement:PivotTo(anchorCFrame * CFrame.new(stageOffset + Vector3.new(0, extraYOffset, 0) + Vector3.new(0, size.Y * 0.5, 0)))
			applyLighting(primary)
		else
			warn("[PlantModule] Unsupported replacement type for:", plantType)
			return
		end

		currentPlantPart:Destroy()
		replacement.Parent = plantModel
	end
end

-- Grow plant over time with dynamic buff system
function PlantModule.GrowPlant(plantModel)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then return end

	local baseStageTime = plantModel:GetAttribute("BaseStageTime")
	if type(baseStageTime) ~= "number" then
		baseStageTime = Constants.GetDefaultBaseStageGrowthSecondsForPlant(plantType)
		plantModel:SetAttribute("BaseStageTime", baseStageTime)
	end
	
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
			local growthTime = math.max(baseStageTime * buffMultiplier, 0.1)
			
			-- Update stage and track timing for countdown display
			plantModel:SetAttribute("Stage", stage)
			plantModel:SetAttribute("StageStartTime", os.time())
			plantModel:SetAttribute("StageGrowthTime", growthTime)
			PlantModule.UpdatePlantVisual(plantModel)
			
			-- Emit growth VFX
			VFXModule.TryEmitGrowth(plantModel)
			
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

-- Get harvest value (returns FruitSellPrice - what player gets for 1 fruit)
-- Weight affects sell price: heavier plants are worth more
function PlantModule.GetHarvestValue(plantModel)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	
	if not config then return 0 end
	
	-- Apply weight multiplier to sell price
	local weight = plantModel:GetAttribute("Weight") or 1
	local basePrice = config.FruitSellPrice
	local adjustedPrice = math.floor(basePrice * weight + 0.5)
	
	return adjustedPrice
end

-- Spawn individual fruit models around a bloom-stage plant
-- Returns a table of spawned fruit models
function PlantModule.SpawnFruits(plantModel)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	local fruitConfig = Constants.FRUIT_CONFIG
	
	if not config then
		warn("[PlantModule] Invalid plant type for fruit spawning:", plantType)
		return {}
	end
	
	-- Get plant models folder
	local plantsFolder = ReplicatedStorage:FindFirstChild("Plants")
	if not plantsFolder then
		warn("[PlantModule] Plants folder not found")
		return {}
	end
	
	local plantFolder = findPlantFolder(plantsFolder, plantType)
	if not plantFolder then
		warn("[PlantModule] Plant folder not found for:", plantType)
		return {}
	end
	
	local plantPart = plantModel:FindFirstChild("Plant")
	local fruitTemplates, templateRoot = collectFruitTemplates(plantFolder, plantPart)
	for _, template in ipairs(fruitTemplates) do
		if plantPart and template:IsDescendantOf(plantPart) then
			if template:IsA("BasePart") then
				template.Transparency = 1
				template.CanCollide = false
			elseif template:IsA("Model") then
				for _, part in ipairs(template:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
						part.CanCollide = false
					end
				end
			end
		end
	end
	local usePlaceholder = #fruitTemplates == 0

	local plantRootCFrame = plantPart and getPrimaryCFrame(plantPart)
	if not plantRootCFrame then
		warn("[PlantModule] No Plant root found for fruit spawning")
		return {}
	end

	local minFruits = fruitConfig.MinFruitsPerPlant or 1
	local maxFruits = fruitConfig.MaxFruitsPerPlant or 4

	if not usePlaceholder then
		maxFruits = math.min(maxFruits, #fruitTemplates)
		minFruits = math.min(minFruits, maxFruits)
	end

	local numFruits
	if usePlaceholder then
		numFruits = math.random(minFruits, math.max(minFruits, maxFruits))
	else
		numFruits = math.min(#fruitTemplates, maxFruits)
	end
	local sizeMultiplier = plantModel:GetAttribute("SizeMultiplier") or 1.0
	-- Use 1.0 for authored fruits (already correct size), only scale placeholders
	local fruitScale = usePlaceholder and ((fruitConfig.FruitScale or 0.4) * sizeMultiplier) or 1.0

	local fruitsFolder = plantModel:FindFirstChild("Fruits")
	if not fruitsFolder then
		fruitsFolder = Instance.new("Folder")
		fruitsFolder.Name = "Fruits"
		fruitsFolder.Parent = plantModel
	end

	local spawnedFruits = {}
	local offsets = fruitConfig.SpawnOffsets or {}
	local heightOffset = fruitConfig.HeightOffset or -0.3

	for i = 1, numFruits do
		local fruit
		if usePlaceholder then
			fruit = Instance.new("Part")
			fruit.Name = plantType .. "Fruit" .. i
			fruit.Shape = Enum.PartType.Ball
			fruit.Size = Vector3.new(0.8, 0.8, 0.8) * fruitScale
			fruit.Color = config.Color or Color3.fromRGB(255, 100, 100)
			fruit.Material = Enum.Material.SmoothPlastic
			fruit.Anchored = true
			fruit.CanCollide = false
			if config.EmitsLight then
				local light = Instance.new("PointLight")
				light.Brightness = 0.5
				light.Range = 4
				light.Color = config.Color
				light.Parent = fruit
			end
			-- Legacy positional scatter
			local offsetIndex = ((i - 1) % math.max(#offsets, 1)) + 1
			local offset = offsets[offsetIndex] or Vector3.new(0, 0, 0)
			local randomOffset = Vector3.new(
				(math.random() - 0.5) * 0.3,
				(math.random() - 0.5) * 0.2,
				(math.random() - 0.5) * 0.3
			)
			offset = offset * sizeMultiplier + randomOffset + Vector3.new(0, heightOffset * sizeMultiplier, 0)
			fruit.CFrame = plantRootCFrame * CFrame.new(offset)
		else
			local template = fruitTemplates[i]
			if not template then
				break
			end
			fruit = template:Clone()
			fruit.Name = plantType .. "Fruit" .. i
			if fruit:IsA("BasePart") then
				fruit.Anchored = true
				fruit.CanCollide = false
				-- Keep original size for authored fruits
			elseif fruit:IsA("Model") then
				for _, part in ipairs(fruit:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true
						part.CanCollide = false
					end
				end
			end
			local relCFrame
			if templateRoot then
				local templateCFrame = getPrimaryCFrame(template)
				if templateCFrame then
					relCFrame = templateRoot:ToObjectSpace(templateCFrame)
				else
					relCFrame = CFrame.new()
				end
			else
				relCFrame = CFrame.new()
			end
			if fruit:IsA("BasePart") then
				fruit.CFrame = plantRootCFrame * relCFrame
			elseif fruit:IsA("Model") then
				fruit:PivotTo(plantRootCFrame * relCFrame)
			end
		end

		fruit:SetAttribute("FruitType", plantType .. "Fruit")
		fruit:SetAttribute("PlantType", plantType)
		fruit:SetAttribute("FruitIndex", i)
		fruit:SetAttribute("Revealed", false)
		fruit:SetAttribute("UseScaleReveal", usePlaceholder)

		if fruit:IsA("BasePart") then
			fruit.Transparency = 1
			if usePlaceholder then
				fruit.Size = fruit.Size * 0.01
			end
		elseif fruit:IsA("Model") then
			for _, part in ipairs(fruit:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
		end

		local plantWeight = plantModel:GetAttribute("Weight") or 1
		local fruitWeight = (plantWeight / numFruits) * (0.9 + math.random() * 0.2)
		fruitWeight = math.floor(fruitWeight * 100 + 0.5) / 100
		fruit:SetAttribute("FruitWeight", fruitWeight)

		fruit.Parent = fruitsFolder
		table.insert(spawnedFruits, fruit)
	end

	plantModel:SetAttribute("FruitCount", #spawnedFruits)
	plantModel:SetAttribute("FruitsRemaining", #spawnedFruits)
	plantModel:SetAttribute("FruitsRevealed", 0)
	plantModel:SetAttribute("NextFruitRevealTime", os.time())

	return spawnedFruits
end

-- Reveal a single fruit with animation (scale up and fade in)
function PlantModule.RevealFruit(fruit)
	if not fruit or not fruit.Parent then return end
	if fruit:GetAttribute("Revealed") then return end -- Already revealed
	
	fruit:SetAttribute("Revealed", true)
	
	local fruitConfig = Constants.FRUIT_CONFIG
	local revealDuration = fruitConfig.FruitRevealDuration or 1.5
	local useScale = fruit:GetAttribute("UseScaleReveal")
	if useScale == nil then
		useScale = fruitConfig.FruitRevealScale ~= false
	end
	
	local plantModel = fruit.Parent and fruit.Parent.Parent
	local sizeMultiplier = plantModel and plantModel:GetAttribute("SizeMultiplier") or 1.0
	local targetScale = (fruitConfig.FruitScale or 0.4) * sizeMultiplier
	
	task.spawn(function()
		local steps = 20
		local stepTime = revealDuration / steps
		
		for step = 1, steps do
			if not fruit or not fruit.Parent then return end
			
			local progress = step / steps
			
			if fruit:IsA("BasePart") then
				-- Scale up
				if useScale then
					local baseSize = Vector3.new(0.8, 0.8, 0.8) * targetScale
					fruit.Size = baseSize * progress
				end
				-- Fade in
				fruit.Transparency = 1 - progress
			elseif fruit:IsA("Model") then
				for _, part in ipairs(fruit:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1 - progress
					end
				end
			end
			
			task.wait(stepTime)
		end
		
		-- Ensure final state
		if fruit and fruit.Parent then
			if fruit:IsA("BasePart") then
				fruit.Transparency = 0
				if useScale then
					fruit.Size = Vector3.new(0.8, 0.8, 0.8) * targetScale
				end
			elseif fruit:IsA("Model") then
				for _, part in ipairs(fruit:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0
					end
				end
			end
		end
	end)
end

-- Start the fruit reveal timer system for a plant
-- onFruitRevealed callback is called when each fruit is revealed
function PlantModule.StartFruitRevealTimer(plantModel, onFruitRevealed)
	local fruitConfig = Constants.FRUIT_CONFIG
	local revealTime = fruitConfig.FruitRevealTimeSeconds or 20
	local totalFruits = plantModel:GetAttribute("FruitCount") or 0
	
	-- If 0-1 fruits, the plant IS the fruit - mark for full harvest
	if totalFruits <= 1 then
		plantModel:SetAttribute("HarvestRemovesPlant", true)
		-- Reveal the single fruit immediately if it exists
		local fruits = PlantModule.GetFruits(plantModel)
		if #fruits > 0 then
			PlantModule.RevealFruit(fruits[1])
			plantModel:SetAttribute("FruitsRevealed", 1)
			if onFruitRevealed then
				onFruitRevealed(fruits[1], plantModel, 1)
			end
		end
		return
	end
	
	plantModel:SetAttribute("HarvestRemovesPlant", false)
	
	task.spawn(function()
		local revealedCount = 0
		
		while plantModel and plantModel.Parent and revealedCount < totalFruits do
			-- Get unrevealed fruits
			local fruits = PlantModule.GetFruits(plantModel)
			local unrevealedFruit = nil
			
			for _, fruit in ipairs(fruits) do
				if not fruit:GetAttribute("Revealed") then
					unrevealedFruit = fruit
					break
				end
			end
			
			if unrevealedFruit then
				PlantModule.RevealFruit(unrevealedFruit)
				revealedCount = revealedCount + 1
				plantModel:SetAttribute("FruitsRevealed", revealedCount)
				
				-- Update next reveal time for countdown display
				if revealedCount < totalFruits then
					plantModel:SetAttribute("NextFruitRevealTime", os.time() + revealTime)
				else
					plantModel:SetAttribute("NextFruitRevealTime", 0) -- All fruits revealed
				end
				
				if onFruitRevealed then
					onFruitRevealed(unrevealedFruit, plantModel, revealedCount)
				end
			end
			
			-- Wait for next reveal
			if revealedCount < totalFruits then
				task.wait(revealTime)
			else
				break
			end
		end
	end)
end

-- Get the remaining time until the next fruit is revealed
function PlantModule.GetNextFruitRevealTime(plantModel)
	local nextTime = plantModel:GetAttribute("NextFruitRevealTime") or 0
	if nextTime == 0 then
		return 0 -- All fruits revealed
	end
	return math.max(0, nextTime - os.time())
end

-- Check if plant harvesting should remove the entire plant
function PlantModule.ShouldRemovePlantOnHarvest(plantModel)
	return plantModel:GetAttribute("HarvestRemovesPlant") == true
end

-- Get all fruits on a plant
function PlantModule.GetFruits(plantModel)
	local fruitsFolder = plantModel:FindFirstChild("Fruits")
	if not fruitsFolder then return {} end
	
	local fruits = {}
	for _, child in ipairs(fruitsFolder:GetChildren()) do
		if child:GetAttribute("FruitType") then
			table.insert(fruits, child)
		end
	end
	return fruits
end

-- Remove a specific fruit from a plant
function PlantModule.RemoveFruit(fruitInstance)
	local plantModel = fruitInstance.Parent and fruitInstance.Parent.Parent
	if plantModel and plantModel:GetAttribute("PlantType") then
		local remaining = (plantModel:GetAttribute("FruitsRemaining") or 1) - 1
		plantModel:SetAttribute("FruitsRemaining", remaining)
	end
	fruitInstance:Destroy()
end

-- ============================================================================
-- FRUIT REGROWTH SYSTEM
-- Feature 4: Plants don't die - they regrow fruit over time
-- ============================================================================

-- Configuration for fruit regrowth
local REGROWTH_CONFIG = {
	Enabled = true,
	RegrowthTime = 30, -- Seconds to regrow 1 fruit
	MaxFruits = 5, -- Maximum fruits per plant
	GrowOneAtATime = true, -- If true, only grows 1 fruit at a time
}

-- Spawn a single fruit on a plant (for regrowth)
function PlantModule.SpawnSingleFruit(plantModel, fruitIndex)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	local fruitConfig = Constants.FRUIT_CONFIG
	
	if not config then return nil end
	
	local plantsFolder = ReplicatedStorage:FindFirstChild("Plants")
	if not plantsFolder then return nil end
	
	local plantFolder = findPlantFolder(plantsFolder, plantType)
	if not plantFolder then return nil end

	local plantPart = plantModel:FindFirstChild("Plant")
	local plantRootCFrame = plantPart and getPrimaryCFrame(plantPart)
	if not plantRootCFrame then return nil end

	local fruitTemplates, templateRoot = collectFruitTemplates(plantFolder, plantPart)
	for _, template in ipairs(fruitTemplates) do
		if plantPart and template:IsDescendantOf(plantPart) then
			if template:IsA("BasePart") then
				template.Transparency = 1
				template.CanCollide = false
			elseif template:IsA("Model") then
				for _, part in ipairs(template:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
						part.CanCollide = false
					end
				end
			end
		end
	end
	local usePlaceholder = #fruitTemplates == 0
	
	-- Get or create fruits folder
	local fruitsFolder = plantModel:FindFirstChild("Fruits")
	if not fruitsFolder then
		fruitsFolder = Instance.new("Folder")
		fruitsFolder.Name = "Fruits"
		fruitsFolder.Parent = plantModel
	end
	
	local sizeMultiplier = plantModel:GetAttribute("SizeMultiplier") or 1.0
	-- Use 1.0 for authored fruits (already correct size), only scale placeholders
	local fruitScale = usePlaceholder and ((fruitConfig.FruitScale or 0.4) * sizeMultiplier) or 1.0
	
	local fruit
	local templateIndex
	if usePlaceholder then
		fruit = Instance.new("Part")
		fruit.Name = plantType .. "Fruit" .. fruitIndex
		fruit.Shape = Enum.PartType.Ball
		fruit.Size = Vector3.new(0.8, 0.8, 0.8) * fruitScale
		fruit.Color = config.Color or Color3.fromRGB(255, 100, 100)
		fruit.Material = Enum.Material.SmoothPlastic
		fruit.Anchored = true
		fruit.CanCollide = false
		
		if config.EmitsLight then
			local light = Instance.new("PointLight")
			light.Brightness = 0.5
			light.Range = 4
			light.Color = config.Color
			light.Parent = fruit
		end
	else
		templateIndex = ((fruitIndex - 1) % #fruitTemplates) + 1
		local fruitTemplate = fruitTemplates[templateIndex]
		fruit = fruitTemplate:Clone()
		fruit.Name = plantType .. "Fruit" .. fruitIndex
		
		if fruit:IsA("BasePart") then
			-- Keep original size for authored fruits
			fruit.Anchored = true
			fruit.CanCollide = false
		elseif fruit:IsA("Model") then
			for _, part in ipairs(fruit:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
				end
			end
		end
	end

	local offsets = fruitConfig.SpawnOffsets or {}
	local heightOffset = fruitConfig.HeightOffset or -0.3
	local relCFrame
	if usePlaceholder then
		local offsetIndex = ((fruitIndex - 1) % math.max(#offsets, 1)) + 1
		local offset = offsets[offsetIndex] or Vector3.new(0, 0, 0)
		local randomOffset = Vector3.new(
			(math.random() - 0.5) * 0.3,
			(math.random() - 0.5) * 0.2,
			(math.random() - 0.5) * 0.3
		)
		offset = offset * sizeMultiplier + randomOffset + Vector3.new(0, heightOffset * sizeMultiplier, 0)
		relCFrame = CFrame.new(offset)
	else
		if templateRoot then
			local templateCFrame = getPrimaryCFrame(fruitTemplates[templateIndex])
			if templateCFrame then
				relCFrame = templateRoot:ToObjectSpace(templateCFrame)
			else
				relCFrame = CFrame.new()
			end
		else
			relCFrame = CFrame.new()
		end
	end

	if fruit:IsA("BasePart") then
		fruit.CFrame = plantRootCFrame * relCFrame
	elseif fruit:IsA("Model") then
		fruit:PivotTo(plantRootCFrame * relCFrame)
	end
	
	-- Set fruit attributes
	fruit:SetAttribute("FruitType", plantType .. "Fruit")
	fruit:SetAttribute("PlantType", plantType)
	fruit:SetAttribute("FruitIndex", fruitIndex)
	fruit:SetAttribute("Revealed", false)
	fruit:SetAttribute("UseScaleReveal", usePlaceholder)

	if fruit:IsA("BasePart") then
		fruit.Transparency = 1
		if usePlaceholder then
			fruit.Size = fruit.Size * 0.01
		end
	elseif fruit:IsA("Model") then
		for _, part in ipairs(fruit:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
	end
	
	local plantWeight = plantModel:GetAttribute("Weight") or 1
	local fruitWeight = plantWeight * (0.9 + math.random() * 0.2)
	fruitWeight = math.floor(fruitWeight * 100 + 0.5) / 100
	fruit:SetAttribute("FruitWeight", fruitWeight)
	
	fruit.Parent = fruitsFolder
	
	-- Update fruit count
	local currentCount = plantModel:GetAttribute("FruitsRemaining") or 0
	plantModel:SetAttribute("FruitsRemaining", currentCount + 1)
	
	return fruit
end

-- Start fruit regrowth loop for a plant (called from server after bloom)
function PlantModule.StartFruitRegrowth(plantModel, onFruitSpawned)
	if not REGROWTH_CONFIG.Enabled then return end
	
	local plantType = plantModel:GetAttribute("PlantType")
	if not plantType then return end
	
	task.spawn(function()
		local fruitIndex = plantModel:GetAttribute("FruitCount") or 1
		
		while plantModel and plantModel.Parent do
			local currentFruits = plantModel:GetAttribute("FruitsRemaining") or 0
			
			-- Check if we can grow more fruit
			if currentFruits < REGROWTH_CONFIG.MaxFruits then
				-- Wait for regrowth time
				-- Apply growth buffs if BuffsModule is available
				local regrowthTime = REGROWTH_CONFIG.RegrowthTime
				local multiplier = 1
				
				pcall(function()
					multiplier = BuffsModule.GetGrowthMultiplier(plantModel)
				end)
				
				local adjustedTime = regrowthTime * multiplier
				task.wait(adjustedTime)
				
				-- Check if plant still exists
				if not plantModel or not plantModel.Parent then break end
				
				-- Spawn a new fruit
				fruitIndex = fruitIndex + 1
				local newFruit = PlantModule.SpawnSingleFruit(plantModel, fruitIndex)
				
				if newFruit and onFruitSpawned then
					onFruitSpawned(newFruit, plantModel)
				end
			else
				-- At max capacity, wait and check again
				task.wait(5)
			end
		end
	end)
end

-- Check if plant should regrow fruits (for restoring plants)
function PlantModule.ShouldRegrowFruits(plantModel)
	local stage = plantModel:GetAttribute("Stage")
	if stage ~= Constants.GROWTH_STAGES.BLOOM then
		return false
	end
	
	local currentFruits = plantModel:GetAttribute("FruitsRemaining") or 0
	return currentFruits < REGROWTH_CONFIG.MaxFruits
end

-- Get max fruits for a plant
function PlantModule.GetMaxFruits()
	return REGROWTH_CONFIG.MaxFruits
end

-- Get regrowth time
function PlantModule.GetRegrowthTime()
	return REGROWTH_CONFIG.RegrowthTime
end

return PlantModule
