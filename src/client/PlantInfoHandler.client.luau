-- PlantInfoHandler.client.luau
-- Handles displaying plant info on hover (name, growth countdown) and fruit highlighting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BuffsModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BuffsModule"))

-- Import ClientState for synced weather
local ClientState = require(script.Parent:WaitForChild("UI"):WaitForChild("ClientState"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- UI Elements
local infoGui = nil
local infoFrame = nil
local plantNameLabel = nil
local stageLabel = nil
local countdownLabel = nil
local fruitCountdownLabel = nil  -- New label for fruit reveal countdown
local boostLabel = nil -- Buff info

-- State
local currentHoveredPlant = nil
local highlightedFruits = {} -- Track highlighted fruits

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function createInfoUI()
	-- Create ScreenGui for plant info
	infoGui = Instance.new("ScreenGui")
	infoGui.Name = "PlantInfoGui"
	infoGui.ResetOnSpawn = false
	infoGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	infoGui.Parent = playerGui
	
	-- Create info frame
	infoFrame = Instance.new("Frame")
	infoFrame.Name = "InfoFrame"
	infoFrame.Size = UDim2.fromOffset(300, 0)
	infoFrame.AutomaticSize = Enum.AutomaticSize.Y
	infoFrame.Position = UDim2.new(0, 0, 0, 0)
	infoFrame.AnchorPoint = Vector2.new(0, 0)
	infoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	infoFrame.BackgroundTransparency = 0.2
	infoFrame.BorderSizePixel = 0
	infoFrame.Visible = false
	infoFrame.Parent = infoGui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(260, 0)
	sizeConstraint.MaxSize = Vector2.new(420, 1000)
	sizeConstraint.Parent = infoFrame
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = infoFrame
	
	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 150, 100)
	stroke.Thickness = 2
	stroke.Parent = infoFrame
	
	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = infoFrame
	
	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = infoFrame
	
	-- Plant name label
	plantNameLabel = Instance.new("TextLabel")
	plantNameLabel.Name = "PlantName"
	plantNameLabel.Size = UDim2.new(1, 0, 0, 0)
	plantNameLabel.AutomaticSize = Enum.AutomaticSize.Y
	plantNameLabel.TextWrapped = true
	plantNameLabel.BackgroundTransparency = 1
	plantNameLabel.Font = Enum.Font.GothamBold
	plantNameLabel.TextSize = 18
	plantNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	plantNameLabel.TextXAlignment = Enum.TextXAlignment.Center
	plantNameLabel.LayoutOrder = 1
	plantNameLabel.Parent = infoFrame
	
	-- Stage label
	stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "Stage"
	stageLabel.Size = UDim2.new(1, 0, 0, 0)
	stageLabel.AutomaticSize = Enum.AutomaticSize.Y
	stageLabel.TextWrapped = true
	stageLabel.BackgroundTransparency = 1
	stageLabel.Font = Enum.Font.Gotham
	stageLabel.TextSize = 15
	stageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	stageLabel.TextXAlignment = Enum.TextXAlignment.Center
	stageLabel.LayoutOrder = 2
	stageLabel.Parent = infoFrame
	
	-- Countdown label (for growth stages)
	countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "Countdown"
	countdownLabel.Size = UDim2.new(1, 0, 0, 0)
	countdownLabel.AutomaticSize = Enum.AutomaticSize.Y
	countdownLabel.TextWrapped = true
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Font = Enum.Font.Gotham
	countdownLabel.TextSize = 15
	countdownLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
	countdownLabel.LayoutOrder = 3
	countdownLabel.Parent = infoFrame
	
	-- Fruit countdown label (for bloom stage fruit reveals)
	fruitCountdownLabel = Instance.new("TextLabel")
	fruitCountdownLabel.Name = "FruitCountdown"
	fruitCountdownLabel.Size = UDim2.new(1, 0, 0, 0)
	fruitCountdownLabel.AutomaticSize = Enum.AutomaticSize.Y
	fruitCountdownLabel.TextWrapped = true
	fruitCountdownLabel.BackgroundTransparency = 1
	fruitCountdownLabel.Font = Enum.Font.Gotham
	fruitCountdownLabel.TextSize = 15
	fruitCountdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	fruitCountdownLabel.TextXAlignment = Enum.TextXAlignment.Center
	fruitCountdownLabel.LayoutOrder = 4
	fruitCountdownLabel.Visible = false  -- Only shown during bloom
	fruitCountdownLabel.Parent = infoFrame

	-- Boost label
	boostLabel = Instance.new("TextLabel")
	boostLabel.Name = "BoostLabel"
	boostLabel.Size = UDim2.new(1, 0, 0, 0)
	boostLabel.AutomaticSize = Enum.AutomaticSize.Y
	boostLabel.TextWrapped = true
	boostLabel.BackgroundTransparency = 1
	boostLabel.Font = Enum.Font.Gotham
	boostLabel.TextSize = 14
	boostLabel.TextColor3 = Color3.fromRGB(120, 210, 255)
	boostLabel.TextXAlignment = Enum.TextXAlignment.Center
	boostLabel.LayoutOrder = 5
	boostLabel.Visible = false
	boostLabel.Parent = infoFrame
end

-- ============================================================================
-- PLANT INFO DISPLAY
-- ============================================================================

local function formatTime(seconds)
	if seconds <= 0 then
		return "Ready!"
	elseif seconds < 60 then
		return string.format("%ds", math.ceil(seconds))
	else
		local mins = math.floor(seconds / 60)
		local secs = math.ceil(seconds % 60)
		return string.format("%dm %ds", mins, secs)
	end
end

local function getPlantDisplayName(plantType)
	-- Convert camelCase/lowercase to Title Case with spaces
	if not plantType then return "Unknown Plant" end
	
	-- Add space before capital letters and capitalize first letter
	local name = plantType:gsub("(%l)(%u)", "%1 %2")
	name = name:gsub("^%l", string.upper)
	return name
end

local function getStageColor(stage)
	if stage == Constants.GROWTH_STAGES.SEED then
		return Color3.fromRGB(180, 140, 100) -- Brown
	elseif stage == Constants.GROWTH_STAGES.SPROUT then
		return Color3.fromRGB(150, 200, 100) -- Light green
	elseif stage == Constants.GROWTH_STAGES.BLOOM then
		return Color3.fromRGB(100, 255, 150) -- Bright green
	end
	return Color3.fromRGB(200, 200, 200)
end

local function calculateTimeToNextStage(plantModel)
	local stage = plantModel:GetAttribute("Stage")
	local plantType = plantModel:GetAttribute("PlantType")
	
	if stage == Constants.GROWTH_STAGES.BLOOM then
		return 0, "Harvestable"
	end
	
	-- Use stage-specific timing if available
	local stageStartTime = plantModel:GetAttribute("StageStartTime")
	local stageGrowthTime = plantModel:GetAttribute("StageGrowthTime")
	
	if stageStartTime and stageGrowthTime then
		local elapsed = os.time() - stageStartTime
		local remaining = stageGrowthTime - elapsed
		
		local nextStageText = ""
		if stage == Constants.GROWTH_STAGES.SEED then
			nextStageText = "to Sprout"
		elseif stage == Constants.GROWTH_STAGES.SPROUT then
			nextStageText = "to Bloom"
		end
		
		return math.max(0, remaining), nextStageText
	end
	
	-- Fallback to plant time calculation
	local plantTime = plantModel:GetAttribute("PlantTime") or os.time()
	local growthTime = plantModel:GetAttribute("BaseStageTime")
	if type(growthTime) ~= "number" then
		growthTime = Constants.GetDefaultBaseStageGrowthSecondsForPlant(plantType)
	end
	local elapsed = os.time() - plantTime
	
	if stage == Constants.GROWTH_STAGES.SEED then
		local timeToSprout = growthTime - elapsed
		return math.max(0, timeToSprout), "to Sprout"
	elseif stage == Constants.GROWTH_STAGES.SPROUT then
		local timeToBloom = growthTime - (elapsed - growthTime)
		return math.max(0, timeToBloom), "to Bloom"
	end
	
	return 0, ""
end

local function updateInfoPosition(mousePosition: Vector2)
	if not infoFrame then return end

	local viewportSize = camera.ViewportSize
	local tooltipSize = infoFrame.AbsoluteSize

	local posX = mousePosition.X + 15
	local posY = mousePosition.Y + 15

	if posX + tooltipSize.X > viewportSize.X then
		posX = mousePosition.X - tooltipSize.X - 15
	end

	if posY + tooltipSize.Y > viewportSize.Y then
		posY = mousePosition.Y - tooltipSize.Y - 15
	end

	infoFrame.Position = UDim2.new(0, posX, 0, posY)
	infoFrame.Visible = true
end

-- Compute accurate buff status using ClientState's synced weather
local function getAccurateBuffStatus(plantModel)
	-- Get weather from ClientState (synced from server)
	local currentWeather = ClientState.CurrentWeather or "Sunny"
	local weatherMult = Config.Buffs.Weather[currentWeather] or 1.0
	
	-- Check watered status
	local now = os.time()
	local wateredUntil = plantModel:GetAttribute("WateredUntil")
	local isWatered = wateredUntil and wateredUntil > now
	local wateredMult = isWatered and (Config.Buffs.Watered or 1.5) or 1.0
	
	-- Check pet boost (set by PetController when pet is nearby)
	local hasPetBoost = plantModel:GetAttribute("PetBoost") or false
	local petMult = hasPetBoost and (Config.Buffs.PetBoost or 1.5) or 1.0
	
	-- Calculate total multiplier
	local totalMult = weatherMult * wateredMult * petMult
	
	return {
		Weather = currentWeather,
		WeatherMult = weatherMult,
		Watered = isWatered,
		WateredMult = wateredMult,
		PetBoost = hasPetBoost,
		PetMult = petMult,
		TotalMultiplier = totalMult
	}
end

-- Count current fruit availability so tooltip matches what can actually be picked
local function getFruitAvailability(plantModel)
	local fruitsFolder = plantModel:FindFirstChild("Fruits")
	local available = 0
	local attached = 0

	if fruitsFolder then
		for _, child in ipairs(fruitsFolder:GetChildren()) do
			if child:GetAttribute("FruitType") then
				attached += 1
				if child:GetAttribute("Revealed") then
					available += 1
				end
			end
		end
	end

	local attrRemaining = plantModel:GetAttribute("FruitsRemaining")
	if typeof(attrRemaining) == "number" then
		attached = math.max(attached, attrRemaining)
	end

	local total = plantModel:GetAttribute("FruitCount")
	if typeof(total) ~= "number" or total < attached then
		total = attached
	end

	return available, attached, total
end

local function showPlantInfo(plantModel, mousePosition: Vector2)
	if not infoFrame then return end
	
	currentHoveredPlant = plantModel
	
	local plantType = plantModel:GetAttribute("PlantType")
	local stage = plantModel:GetAttribute("Stage")
	local buffStatus = getAccurateBuffStatus(plantModel)
	
	-- Update plant name
	plantNameLabel.Text = getPlantDisplayName(plantType)
	
	-- Update stage with fallback
	local stageDisplay = stage
	if not stageDisplay or stageDisplay == "" then
		-- Try to detect stage from visual (fallback)
		local harvestable = plantModel:GetAttribute("Harvestable")
		if harvestable then
			stageDisplay = Constants.GROWTH_STAGES.BLOOM
		else
			stageDisplay = Constants.GROWTH_STAGES.SEED
		end
	end
	stageLabel.Text = "Stage: " .. stageDisplay
	stageLabel.TextColor3 = getStageColor(stageDisplay)
	
	-- Update countdown using stageDisplay (which has fallback logic)
	local timeRemaining, nextStageText = calculateTimeToNextStage(plantModel)
	if stageDisplay == Constants.GROWTH_STAGES.BLOOM then
		local availableFruits, attachedFruits, totalFruits = getFruitAvailability(plantModel)
		local harvestRemovesPlant = plantModel:GetAttribute("HarvestRemovesPlant")
		local nextRevealTime = plantModel:GetAttribute("NextFruitRevealTime") or 0

		countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		if totalFruits <= 0 then
			countdownLabel.Text = "🍎 Fruits: 0/0"
			fruitCountdownLabel.Visible = false
		else
			countdownLabel.Text = string.format("🍎 Ready: %d/%d", availableFruits, attachedFruits)

			if availableFruits < attachedFruits then
				local timeToNextFruit = 0
				if nextRevealTime > 0 then
					timeToNextFruit = math.max(0, nextRevealTime - os.time())
				end
				fruitCountdownLabel.Text = "⏱ Next fruit: " .. formatTime(timeToNextFruit)
				fruitCountdownLabel.Visible = true
			elseif attachedFruits == 0 then
				fruitCountdownLabel.Text = "✨ Waiting for regrowth"
				fruitCountdownLabel.Visible = true
			else
				if harvestRemovesPlant then
					fruitCountdownLabel.Text = "✨ All fruit collected • Harvest removes plant"
				else
					fruitCountdownLabel.Text = "✨ All fruit collected"
				end
				fruitCountdownLabel.Visible = true
			end
		end
	else
		countdownLabel.Text = "⏱ " .. formatTime(timeRemaining) .. " " .. nextStageText
		countdownLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
		fruitCountdownLabel.Visible = false
	end

	-- Boost info with compact "badge row" style
	local mult = buffStatus.TotalMultiplier or 1
	local boostBadges = {}
	
	-- Weather badge (always)
	local weatherText = "☀️ " .. (buffStatus.Weather or "Sunny")
	if buffStatus.WeatherMult and buffStatus.WeatherMult ~= 1.0 then
		weatherText = weatherText .. string.format(" x%.1f", buffStatus.WeatherMult)
	end
	table.insert(boostBadges, weatherText)
	
	-- Watered badge
	if buffStatus.Watered then
		table.insert(boostBadges, "💧 Watered")
	end
	
	-- Pet badge
	if buffStatus.PetBoost then
		table.insert(boostBadges, "🐾 Pet")
	end

	boostLabel.Text = string.format("⚡ x%.2f\n%s", mult, table.concat(boostBadges, "  "))
	boostLabel.Visible = true
	
	updateInfoPosition(mousePosition)
end

local function hidePlantInfo()
	if infoFrame then
		infoFrame.Visible = false
	end
	currentHoveredPlant = nil
end

-- ============================================================================
-- FRUIT HIGHLIGHTING
-- ============================================================================

local function createHighlight(part, color)
	-- Remove existing highlight
	local existing = part:FindFirstChild("FruitHighlight")
	if existing then
		existing:Destroy()
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "FruitHighlight"
	highlight.FillColor = color or Color3.fromRGB(255, 255, 100)
	highlight.FillTransparency = 1 -- Fully transparent fill (outline only)
	highlight.OutlineColor = color or Color3.fromRGB(255, 255, 100) -- Glowing outline matches fruit color
	highlight.OutlineTransparency = 0 -- Fully visible outline
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded -- Show even through walls for visibility
	highlight.Parent = part
	
	return highlight
end

local function removeHighlight(part)
	local highlight = part:FindFirstChild("FruitHighlight")
	if highlight then
		highlight:Destroy()
	end
end

-- Handle proximity prompt shown (fruit highlight on)
local function onPromptShown(prompt, inputType)
	local fruit = prompt.Parent
	if not fruit then return end
	
	-- Check if this is a fruit
	if fruit:GetAttribute("FruitType") then
		local plantType = fruit:GetAttribute("PlantType")
		local config = Constants.PLANT_CONFIG[plantType]
		local color = config and config.Color or Color3.fromRGB(255, 200, 100)
		
		createHighlight(fruit, color)
		highlightedFruits[fruit] = true
	end
end

-- Handle proximity prompt hidden (fruit highlight off)
local function onPromptHidden(prompt, inputType)
	local fruit = prompt.Parent
	if not fruit then return end
	
	if highlightedFruits[fruit] then
		removeHighlight(fruit)
		highlightedFruits[fruit] = nil
	end
end

-- ============================================================================
-- RAYCAST HOVER DETECTION
-- ============================================================================

local function raycastFromMouse(mouseLocation: Vector2)
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local character = player.Character
	if character then
		raycastParams.FilterDescendantsInstances = {character}
	end
	
	return workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)
end

local function findPlantFromPart(part)
	if not part then return nil end
	
	-- Always try to find the root plantModel (which has Stage attribute)
	-- First, check ancestors for a Model with PlantType AND Stage
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:GetAttribute("PlantType") and model:GetAttribute("Stage") then
			return model
		end
		-- If model has PlantType but no Stage, check its parent
		if model:GetAttribute("PlantType") and not model:GetAttribute("Stage") then
			local parentModel = model.Parent
			if parentModel and parentModel:IsA("Model") and parentModel:GetAttribute("PlantType") then
				return parentModel
			end
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	
	-- Fallback: Check if part itself is the plantModel
	if part:IsA("Model") and part:GetAttribute("PlantType") and part:GetAttribute("Stage") then
		return part
	end
	
	-- Check parent model for PlantType (simpler fallback)
	model = part:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("PlantType") then
		-- Check if this model's parent also has PlantType (meaning this is the Plant child)
		local parentModel = model.Parent
		if parentModel and parentModel:IsA("Model") and parentModel:GetAttribute("PlantType") then
			return parentModel
		end
		return model
	end
	
	-- Check if we hit a fruit - show parent plant info
	if part:GetAttribute("FruitType") then
		local fruitsFolder = part.Parent
		if fruitsFolder and fruitsFolder.Name == "Fruits" then
			local plantModel = fruitsFolder.Parent
			if plantModel and plantModel:GetAttribute("PlantType") then
				return plantModel
			end
		end
	end
	
	return nil
end

-- ============================================================================
-- MAIN UPDATE LOOP
-- ============================================================================

local function onUpdate()
	local mousePosition = UserInputService:GetMouseLocation()

	-- Raycast to find what we're hovering over
	local result = raycastFromMouse(mousePosition)
	
	if result then
		local plant = findPlantFromPart(result.Instance)
		
		if plant then
			if plant ~= currentHoveredPlant then
				showPlantInfo(plant, mousePosition)
			else
				-- Fully refresh tooltip while hovered (realtime countdowns + buffs)
				showPlantInfo(plant, mousePosition)
			end
		else
			hidePlantInfo()
		end
	else
		hidePlantInfo()
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function initialize()
	-- Wait for character
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	
	-- Create UI
	createInfoUI()
	
	-- Connect proximity prompt events for fruit highlighting
	ProximityPromptService.PromptShown:Connect(onPromptShown)
	ProximityPromptService.PromptHidden:Connect(onPromptHidden)
	
	-- Start update loop
	RunService.RenderStepped:Connect(onUpdate)
end

-- Start initialization
task.spawn(initialize)
