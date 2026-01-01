-- PlantInfoHandler.client.luau
-- Handles displaying plant info on hover (name, growth countdown) and fruit highlighting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

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
	infoFrame.Size = UDim2.new(0, 200, 0, 110)  -- Slightly larger to fit fruit info
	infoFrame.Position = UDim2.new(0, 0, 0, 0)
	infoFrame.AnchorPoint = Vector2.new(0, 0)
	infoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	infoFrame.BackgroundTransparency = 0.2
	infoFrame.BorderSizePixel = 0
	infoFrame.Visible = false
	infoFrame.Parent = infoGui
	
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
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = infoFrame
	
	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = infoFrame
	
	-- Plant name label
	plantNameLabel = Instance.new("TextLabel")
	plantNameLabel.Name = "PlantName"
	plantNameLabel.Size = UDim2.new(1, 0, 0, 22)
	plantNameLabel.BackgroundTransparency = 1
	plantNameLabel.Font = Enum.Font.GothamBold
	plantNameLabel.TextSize = 16
	plantNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	plantNameLabel.TextXAlignment = Enum.TextXAlignment.Center
	plantNameLabel.LayoutOrder = 1
	plantNameLabel.Parent = infoFrame
	
	-- Stage label
	stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "Stage"
	stageLabel.Size = UDim2.new(1, 0, 0, 18)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Font = Enum.Font.Gotham
	stageLabel.TextSize = 14
	stageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	stageLabel.TextXAlignment = Enum.TextXAlignment.Center
	stageLabel.LayoutOrder = 2
	stageLabel.Parent = infoFrame
	
	-- Countdown label (for growth stages)
	countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "Countdown"
	countdownLabel.Size = UDim2.new(1, 0, 0, 18)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Font = Enum.Font.Gotham
	countdownLabel.TextSize = 14
	countdownLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
	countdownLabel.LayoutOrder = 3
	countdownLabel.Parent = infoFrame
	
	-- Fruit countdown label (for bloom stage fruit reveals)
	fruitCountdownLabel = Instance.new("TextLabel")
	fruitCountdownLabel.Name = "FruitCountdown"
	fruitCountdownLabel.Size = UDim2.new(1, 0, 0, 18)
	fruitCountdownLabel.BackgroundTransparency = 1
	fruitCountdownLabel.Font = Enum.Font.Gotham
	fruitCountdownLabel.TextSize = 14
	fruitCountdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	fruitCountdownLabel.TextXAlignment = Enum.TextXAlignment.Center
	fruitCountdownLabel.LayoutOrder = 4
	fruitCountdownLabel.Visible = false  -- Only shown during bloom
	fruitCountdownLabel.Parent = infoFrame
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
	local config = Constants.PLANT_CONFIG[plantType]
	if not config then
		return 0, "Unknown"
	end
	
	local growthTime = config.GrowthTime or 60
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

local function showPlantInfo(plantModel, mousePosition: Vector2)
	if not infoFrame then return end
	
	currentHoveredPlant = plantModel
	
	local plantType = plantModel:GetAttribute("PlantType")
	local stage = plantModel:GetAttribute("Stage")
	
	-- Update plant name
	plantNameLabel.Text = getPlantDisplayName(plantType)
	
	-- Update stage
	stageLabel.Text = "Stage: " .. (stage or "Unknown")
	stageLabel.TextColor3 = getStageColor(stage)
	
	-- Update countdown
	local timeRemaining, nextStageText = calculateTimeToNextStage(plantModel)
	if stage == Constants.GROWTH_STAGES.BLOOM then
		-- Show fruit info instead of harvest ready
		local fruitsRevealed = plantModel:GetAttribute("FruitsRevealed") or 0
		local totalFruits = plantModel:GetAttribute("FruitCount") or 0
		local fruitsRemaining = plantModel:GetAttribute("FruitsRemaining") or 0
		local harvestRemovesPlant = plantModel:GetAttribute("HarvestRemovesPlant")
		
		if harvestRemovesPlant then
			-- Single fruit plant - harvest removes the whole plant
			countdownLabel.Text = "🍎 Ready to Harvest!"
			countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			fruitCountdownLabel.Visible = false
		else
			-- Multi-fruit plant - show fruit status
			countdownLabel.Text = string.format("🍎 Fruits: %d/%d ready", fruitsRevealed, totalFruits)
			countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			
			-- Show next fruit reveal countdown
			local nextRevealTime = plantModel:GetAttribute("NextFruitRevealTime") or 0
			if nextRevealTime > 0 and fruitsRevealed < totalFruits then
				local timeToNextFruit = math.max(0, nextRevealTime - os.time())
				fruitCountdownLabel.Text = "⏱ Next fruit: " .. formatTime(timeToNextFruit)
				fruitCountdownLabel.Visible = true
			elseif fruitsRemaining > 0 then
				fruitCountdownLabel.Text = "✨ All fruits ready!"
				fruitCountdownLabel.Visible = true
			else
				fruitCountdownLabel.Text = "🔄 Regrowing..."
				fruitCountdownLabel.Visible = true
			end
		end
	else
		countdownLabel.Text = "⏱ " .. formatTime(timeRemaining) .. " " .. nextStageText
		countdownLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
		fruitCountdownLabel.Visible = false
	end
	
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
	
	-- Check if part itself has PlantType
	if part:GetAttribute("PlantType") then
		return part
	end
	
	-- Check parent model
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("PlantType") then
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
				-- Update position and countdown
				updateInfoPosition(mousePosition)
				
				-- Update countdown timer
				local stage = plant:GetAttribute("Stage")
				if stage == Constants.GROWTH_STAGES.BLOOM then
					-- Update fruit countdown during bloom
					local fruitsRevealed = plant:GetAttribute("FruitsRevealed") or 0
					local totalFruits = plant:GetAttribute("FruitCount") or 0
					local fruitsRemaining = plant:GetAttribute("FruitsRemaining") or 0
					local harvestRemovesPlant = plant:GetAttribute("HarvestRemovesPlant")
					
					if not harvestRemovesPlant then
						countdownLabel.Text = string.format("🍎 Fruits: %d/%d ready", fruitsRevealed, totalFruits)
						
						local nextRevealTime = plant:GetAttribute("NextFruitRevealTime") or 0
						if nextRevealTime > 0 and fruitsRevealed < totalFruits then
							local timeToNextFruit = math.max(0, nextRevealTime - os.time())
							fruitCountdownLabel.Text = "⏱ Next fruit: " .. formatTime(timeToNextFruit)
							fruitCountdownLabel.Visible = true
						elseif fruitsRemaining > 0 then
							fruitCountdownLabel.Text = "✨ All fruits ready!"
							fruitCountdownLabel.Visible = true
						else
							fruitCountdownLabel.Text = "🔄 Regrowing..."
							fruitCountdownLabel.Visible = true
						end
					end
				else
					local timeRemaining, nextStageText = calculateTimeToNextStage(plant)
					countdownLabel.Text = "⏱ " .. formatTime(timeRemaining) .. " " .. nextStageText
					fruitCountdownLabel.Visible = false
				end
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
