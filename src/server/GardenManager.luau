-- GardenManager.luau
-- Manages pre-built garden folders, plant slots, and persistence.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[GardenManager] Shared folder missing; garden system disabled")
	return {}
end

local function safeRequire(name)
	local ok, mod = pcall(function()
		return require(sharedFolder:WaitForChild(name, 5))
	end)
	if not ok then
		warn(string.format("[GardenManager] Failed to load %s: %s", name, tostring(mod)))
		return nil
	end
	return mod
end

local Constants = safeRequire("Constants")
local Config = safeRequire("Config")
local PlantModule = safeRequire("PlantModule")
local BuffsModule = safeRequire("BuffsModule")
local EggModule = safeRequire("EggModule")
if not (Constants and Config and PlantModule and BuffsModule) then
	return {}
end

local EconomyService = require(ServerScriptService.Server.EconomyService)
local DataService = require(ServerScriptService.Server.Persistence.DataService)

local GardenManager = {}
GardenManager.PlayerGardens = {}
GardenManager.GardenAssignments = {}
GardenManager.ActivePlants = {}

local stageOrder = {
	Constants.GROWTH_STAGES.SEED,
	Constants.GROWTH_STAGES.SPROUT,
	Constants.GROWTH_STAGES.BLOOM,
}

local function ensureRemoteEvent(eventName: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(eventName)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = eventName
	remote.Parent = ReplicatedStorage
	return remote
end

local harvestFruitEvent = ensureRemoteEvent(Constants.EVENTS.HARVEST_FRUIT)
local plantSeedAtPositionEvent = ensureRemoteEvent(Constants.EVENTS.PLANT_SEED_AT_POSITION) -- Free-form planting

local function getGardensFolder(): Folder?
	local folder = Config.functions.GetWorldFolder(Config.World.GardensFolder)
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function ensurePlayerCache(userId: number): {[number]: Model}
	local cache = GardenManager.ActivePlants[userId]
	if not cache then
		cache = {}
		GardenManager.ActivePlants[userId] = cache
	end
	return cache
end

function GardenManager.GetPlayerGarden(player: Player): Folder?
	return GardenManager.PlayerGardens[player.UserId]
end

-- Setup ProximityPrompt on a single fruit for collection
local function setupFruitPrompt(fruit: Instance, plantModel: Model, userId: number)
	-- Remove existing prompt if present
	local existingPrompt = fruit:FindFirstChildOfClass("ProximityPrompt")
	if existingPrompt then
		existingPrompt:Destroy()
	end
	
	local fruitConfig = Constants.FRUIT_CONFIG
	local fruitPart = fruit:IsA("BasePart") and fruit or fruit:FindFirstChildWhichIsA("BasePart")
	
	if not fruitPart then
		warn("[GardenManager] Fruit has no BasePart for ProximityPrompt")
		return
	end
	
	-- Create ProximityPrompt for fruit collection
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = fruitConfig.PromptActionText or "Collect"
	prompt.ObjectText = fruit:GetAttribute("FruitType") or fruitConfig.PromptObjectText or "Fruit"
	prompt.HoldDuration = fruitConfig.PromptHoldDuration or 0.3
	prompt.MaxActivationDistance = fruitConfig.PromptMaxDistance or 12
	prompt.RequiresLineOfSight = false
	-- Start with prompt disabled until fruit is revealed
	prompt.Enabled = fruit:GetAttribute("Revealed") == true
	prompt.Parent = fruitPart
	
	-- Listen for fruit reveal to enable the prompt
	fruit:GetAttributeChangedSignal("Revealed"):Connect(function()
		if fruit:GetAttribute("Revealed") then
			prompt.Enabled = true
		end
	end)
	
	-- Handle fruit collection
	prompt.Triggered:Connect(function(triggeringPlayer)
		-- Only owner can collect
		if triggeringPlayer.UserId ~= userId then
			return
		end
		
		-- Verify fruit still exists and is revealed
		if not fruit.Parent then
			return
		end
		
		-- Don't allow collecting unrevealed fruits
		if not fruit:GetAttribute("Revealed") then
			return
		end
		
		local fruitType = fruit:GetAttribute("FruitType")
		local fruitWeight = fruit:GetAttribute("FruitWeight") or 1.0
		
		-- Check if this plant should be removed after harvest (0-1 fruit plants)
		local shouldRemovePlant = PlantModule.ShouldRemovePlantOnHarvest(plantModel)
		
		-- Add fruit to player inventory
		local success, fruitInstance = DataService.AddFruitInstance(userId, fruitType, fruitWeight)
		if success then
			-- Sync inventory to client (no pet changes)
			EconomyService.SyncPlayerData(triggeringPlayer, false)
			
			-- Fire event to client for visual feedback
			harvestFruitEvent:FireClient(triggeringPlayer, fruitType, 1)
			
			if shouldRemovePlant then
				-- Plant has 0-1 fruits, harvesting removes the whole plant
				local plantId = plantModel:GetAttribute("PlantId")
				if plantId then
					DataService.RemoveFreePlant(userId, plantId)
				end
				
				-- Remove from active plants cache
				local cache = GardenManager.ActivePlants[userId]
				if cache and plantId then
					cache[plantId] = nil
				end
				
				plantModel:Destroy()
			else
				-- Plant has multiple fruits, just remove the fruit
				PlantModule.RemoveFruit(fruit)
			end
		else
			warn(string.format("[GardenManager] Failed to add fruit for player %d", userId))
		end
	end)
end

-- Public function to setup harvest detector (can be called from AdminCommands)
-- Now spawns fruits with ProximityPrompts instead of ClickDetector
function GardenManager.SetupPlantHarvestDetector(plantModel: Model, userId: number)
	-- Only setup harvest detector for bloom stage plants
	local stage = plantModel:GetAttribute("Stage")
	if stage ~= Constants.GROWTH_STAGES.BLOOM then
		return
	end
	
	local plantPart = plantModel:FindFirstChild("Plant")
	if not plantPart then
		return
	end

	local function findPrimary(partOrModel: Instance): BasePart?
		if partOrModel:IsA("BasePart") then
			return partOrModel
		end
		if partOrModel:IsA("Model") then
			return partOrModel.PrimaryPart or partOrModel:FindFirstChildWhichIsA("BasePart", true)
		end
		return nil
	end

	local plantPrimary = findPrimary(plantPart)
	if not plantPrimary then
		return
	end
	
	-- Remove old ClickDetector if present (legacy cleanup)
	local existingCD = plantPrimary:FindFirstChildOfClass("ClickDetector")
	if existingCD then
		existingCD:Destroy()
	end

	-- Spawn fruits on the plant (they start invisible)
	local fruits = PlantModule.SpawnFruits(plantModel)
	
	-- Setup ProximityPrompt on each fruit (prompts disabled until revealed)
	for _, fruit in ipairs(fruits) do
		setupFruitPrompt(fruit, plantModel, userId)
	end
	
	-- Start fruit reveal timer - fruits become visible one by one over time
	PlantModule.StartFruitRevealTimer(plantModel, function(revealedFruit, plant, revealIndex)
		-- Callback when a fruit is revealed (already has prompt setup)
		-- VFX could be added here if desired
	end)
	
	-- Feature 4: Start fruit regrowth system (plants don't die, fruits regrow)
	-- Only for plants with multiple fruits (single-fruit plants get removed on harvest)
	if not PlantModule.ShouldRemovePlantOnHarvest(plantModel) then
		PlantModule.StartFruitRegrowth(plantModel, function(newFruit, plant)
			-- Setup prompt on newly regrown fruit
			local ownerUserId = plant:GetAttribute("OwnerUserId") or plant:GetAttribute("Owner")
			if ownerUserId then
				setupFruitPrompt(newFruit, plant, ownerUserId)
				-- Newly regrown fruits should be revealed immediately
				PlantModule.RevealFruit(newFruit)
			end
		end)
	end
end

local function updateGardenSign(gardenFolder: Folder, playerName: string?)
	local signModel = gardenFolder:FindFirstChild(Config.World.PlayerSignName)
	if not signModel or not signModel:IsA("Model") then
		return
	end

	local signPart = signModel:FindFirstChild(Config.World.PlayerSignPartName)
	if not signPart or not signPart:IsA("BasePart") then
		return
	end

	local surfaceGui = signPart:FindFirstChildWhichIsA("SurfaceGui")
	if not surfaceGui then
		return
	end

	local label = surfaceGui:FindFirstChildWhichIsA("TextLabel")
	if not label then
		return
	end

	if playerName then
		label.Text = string.format("%s's Garden", playerName)
	else
		label.Text = Config.Garden.DefaultSignText or "Available"
	end

	if Config.Garden.SignTextColor then
		label.TextColor3 = Config.Garden.SignTextColor
	end

	if Config.Garden.SignBackgroundColor then
		label.BackgroundColor3 = Config.Garden.SignBackgroundColor
	end
end

local function setupGrowAllPrompt(gardenFolder: Folder)
	local signName = Config.World.GrowAllSignName or "GrowAll"
	local growAllModel = gardenFolder:FindFirstChild(signName)
	if not growAllModel then
		return
	end

	-- Theme colors (matching GardenSignHandler)
	local THEME = {
		ForestDark = Color3.fromRGB(18, 10, 28),
		ForestDeep = Color3.fromRGB(28, 16, 40),
		TealGem = Color3.fromRGB(86, 108, 186),
		GoldLeaf = Color3.fromRGB(210, 168, 120),
		TextLight = Color3.fromRGB(228, 218, 240),
		TextGold = Color3.fromRGB(210, 190, 230),
	}

	local function ensureGrowAllGui()
		local product = Constants.GROW_ALL_PRODUCT
		local displayName = product and product.DisplayName or "Grow All"
		local priceText = product and product.RobuxPrice and tostring(product.RobuxPrice) or "?"

		local signPart = growAllModel:FindFirstChild(Config.World.PlayerSignPartName)
		if not signPart or not signPart:IsA("BasePart") then
			signPart = growAllModel:FindFirstChildWhichIsA("BasePart")
		end
		if not signPart then
			return
		end

		-- Find the existing SurfaceGui (like PlayerSign)
		local surfaceGui = signPart:FindFirstChildOfClass("SurfaceGui")
		if not surfaceGui then
			-- Create one if missing
			surfaceGui = Instance.new("SurfaceGui")
			surfaceGui.Name = "SignSurfaceGui"
			surfaceGui.Face = Enum.NormalId.Front
			surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			surfaceGui.PixelsPerStud = 50
			surfaceGui.Parent = signPart
		end

		-- Clear existing content
		for _, child in ipairs(surfaceGui:GetChildren()) do
			if child.Name == "GrowAllContent" then
				child:Destroy()
			end
		end

		-- Create main content frame (same structure as GardenSignHandler)
		local mainFrame = Instance.new("Frame")
		mainFrame.Name = "GrowAllContent"
		mainFrame.Size = UDim2.new(1, 0, 1, 0)
		mainFrame.BackgroundColor3 = THEME.ForestDark
		mainFrame.BackgroundTransparency = 0.7
		mainFrame.Parent = surfaceGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = mainFrame

		local stroke = Instance.new("UIStroke")
		stroke.Color = THEME.TealGem
		stroke.Thickness = 2
		stroke.Transparency = 0.3
		stroke.Parent = mainFrame

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.PaddingTop = UDim.new(0, 8)
		padding.PaddingBottom = UDim.new(0, 8)
		padding.Parent = mainFrame

		-- Left side: Title and price (same layout as GardenSignHandler infoFrame)
		local infoFrame = Instance.new("Frame")
		infoFrame.Name = "InfoFrame"
		infoFrame.Size = UDim2.new(0.6, 0, 1, 0)
		infoFrame.Position = UDim2.new(0, 0, 0, 0)
		infoFrame.BackgroundTransparency = 1
		infoFrame.Parent = mainFrame

		local infoLayout = Instance.new("UIListLayout")
		infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
		infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		infoLayout.Padding = UDim.new(0, 4)
		infoLayout.Parent = infoFrame

		-- Title label (like player name)
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, 0, 0, 24)
		titleLabel.LayoutOrder = 1
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = displayName
		titleLabel.TextColor3 = THEME.TextLight
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 20
		titleLabel.TextScaled = true
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabel.Parent = infoFrame

		-- Subtitle (like garden level)
		local subtitleLabel = Instance.new("TextLabel")
		subtitleLabel.Name = "SubtitleLabel"
		subtitleLabel.Size = UDim2.new(1, 0, 0, 18)
		subtitleLabel.LayoutOrder = 2
		subtitleLabel.BackgroundTransparency = 1
		subtitleLabel.Text = "🌱 Instant Bloom"
		subtitleLabel.TextColor3 = THEME.TextGold
		subtitleLabel.Font = Enum.Font.Gotham
		subtitleLabel.TextSize = 16
		subtitleLabel.TextScaled = true
		subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		subtitleLabel.Parent = infoFrame

		-- Price row (like likes row)
		local priceFrame = Instance.new("Frame")
		priceFrame.Name = "PriceFrame"
		priceFrame.Size = UDim2.new(1, 0, 0, 22)
		priceFrame.LayoutOrder = 3
		priceFrame.BackgroundTransparency = 1
		priceFrame.Parent = infoFrame

		local priceLayout = Instance.new("UIListLayout")
		priceLayout.FillDirection = Enum.FillDirection.Horizontal
		priceLayout.SortOrder = Enum.SortOrder.LayoutOrder
		priceLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		priceLayout.Padding = UDim.new(0, 6)
		priceLayout.Parent = priceFrame

		-- Robux icon badge (like heart icon)
		local robuxBadge = Instance.new("TextLabel")
		robuxBadge.Name = "RobuxIcon"
		robuxBadge.Size = UDim2.new(0, 22, 0, 22)
		robuxBadge.LayoutOrder = 1
		robuxBadge.BackgroundColor3 = THEME.ForestDeep
		robuxBadge.BackgroundTransparency = 0.5
		robuxBadge.Text = "R$"
		robuxBadge.TextSize = 12
		robuxBadge.Font = Enum.Font.GothamBold
		robuxBadge.TextColor3 = THEME.GoldLeaf
		robuxBadge.Parent = priceFrame

		local robuxCorner = Instance.new("UICorner")
		robuxCorner.CornerRadius = UDim.new(0.5, 0)
		robuxCorner.Parent = robuxBadge

		-- Price amount (like like count)
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(0, 40, 0, 22)
		priceLabel.LayoutOrder = 2
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = priceText
		priceLabel.TextColor3 = THEME.GoldLeaf
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.TextSize = 16
		priceLabel.TextScaled = true
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = priceFrame

		-- Right side: Icon (like avatar frame)
		local iconFrame = Instance.new("Frame")
		iconFrame.Name = "IconFrame"
		iconFrame.Size = UDim2.new(0.35, 0, 0.9, 0)
		iconFrame.Position = UDim2.new(0.62, 0, 0.05, 0)
		iconFrame.BackgroundColor3 = THEME.ForestDeep
		iconFrame.Parent = mainFrame

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0.5, 0)
		iconCorner.Parent = iconFrame

		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color = THEME.GoldLeaf
		iconStroke.Thickness = 2
		iconStroke.Parent = iconFrame

		local iconAspect = Instance.new("UIAspectRatioConstraint")
		iconAspect.AspectRatio = 1
		iconAspect.Parent = iconFrame

		-- Plant/growth emoji icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(1, -6, 1, -6)
		iconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = "🌸"
		iconLabel.TextScaled = true
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.Parent = iconFrame
	end

	if growAllModel:GetAttribute("GrowAllPromptBound") then
		ensureGrowAllGui()
		return
	end

	local prompt = growAllModel:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		for _, descendant in ipairs(growAllModel:GetDescendants()) do
			if descendant:IsA("ProximityPrompt") then
				prompt = descendant
				break
			end
		end
	end

	if not prompt then
		warn("[GardenManager] GrowAll sign is missing a ProximityPrompt")
		return
	end

	local product = Constants.GROW_ALL_PRODUCT
	prompt.ActionText = product and product.DisplayName or "Grow All"
	prompt.ObjectText = product and product.RobuxPrice and ("R$ " .. tostring(product.RobuxPrice)) or "R$ ?"

	growAllModel:SetAttribute("GrowAllPromptBound", true)
	ensureGrowAllGui()

	prompt.Triggered:Connect(function(player)
		if not player or not player:IsA("Player") then
			return
		end

		local ownerId = gardenFolder:GetAttribute("OwnerUserId")
		if ownerId ~= player.UserId then
			return
		end

		EconomyService.PromptGrowAllPurchase(player)
	end)
end

-- Calculate the correct stage and remaining time based on PlantTime (supports offline growth)

local function calculateOfflineGrowth(plantType: string, plantTime: number, baseStageTime: number?)
	local config = Constants.PLANT_CONFIG[plantType]
	if not config then
		return Constants.GROWTH_STAGES.SEED, 0, baseStageTime or 60
	end

	local growthTime = baseStageTime or config.GrowthTime or 60
	local elapsed = os.time() - plantTime
	
	-- Stage timeline: SEED (0 to growthTime) -> SPROUT (growthTime to 2*growthTime) -> BLOOM (after 2*growthTime)
	if elapsed >= growthTime * 2 then
		-- Already at BLOOM
		return Constants.GROWTH_STAGES.BLOOM, 0, 0
	elseif elapsed >= growthTime then
		-- At SPROUT, calculate remaining time to BLOOM
		local remainingTime = (growthTime * 2) - elapsed
		return Constants.GROWTH_STAGES.SPROUT, remainingTime, growthTime
	else
		-- Still at SEED, calculate remaining time to SPROUT
		local remainingTime = growthTime - elapsed
		return Constants.GROWTH_STAGES.SEED, remainingTime, growthTime
	end
end

local function continueGrowthFromStage(plantModel: Model, savedStage: string?, savedPlantTime: number?)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	if not config then
		return
	end

	local baseStageTime = plantModel:GetAttribute("BaseStageTime")
	if type(baseStageTime) ~= "number" then
		baseStageTime = Constants.GetDefaultBaseStageGrowthSecondsForPlant(plantType)
		plantModel:SetAttribute("BaseStageTime", baseStageTime)
	end
	
	-- Use saved PlantTime for offline growth calculation, or current time if not available
	local plantTime = savedPlantTime or plantModel:GetAttribute("PlantTime") or os.time()
	plantModel:SetAttribute("PlantTime", plantTime)
	
	-- Calculate correct stage based on elapsed time (offline growth)
	local calculatedStage, remainingTime, stageGrowthTime = calculateOfflineGrowth(plantType, plantTime, baseStageTime)
	
	-- Set the calculated stage
	plantModel:SetAttribute("Stage", calculatedStage)
	plantModel:SetAttribute("Harvestable", calculatedStage == Constants.GROWTH_STAGES.BLOOM)
	plantModel:SetAttribute("StageStartTime", os.time())
	plantModel:SetAttribute("StageGrowthTime", remainingTime)
	PlantModule.UpdatePlantVisual(plantModel)
	
	-- If already at BLOOM, setup harvest detector and return
	if calculatedStage == Constants.GROWTH_STAGES.BLOOM then
		local ownerId = plantModel:GetAttribute("OwnerUserId")
		if ownerId then
			GardenManager.SetupPlantHarvestDetector(plantModel, ownerId)
		end
		return
	end
	
	-- Continue growth from calculated stage with remaining time
	local startIndex = 1
	for index, stage in ipairs(stageOrder) do
		if stage == calculatedStage then
			startIndex = index
			break
		end
	end

	task.spawn(function()
		-- Wait remaining time for current stage first
		if remainingTime > 0 then
			task.wait(remainingTime)
			
			if not plantModel.Parent then
				return
			end
		end
		
		-- Progress through remaining stages
		for index = startIndex + 1, #stageOrder do
			local nextStage = stageOrder[index]
			
			-- Apply buffs for future stages
			local multiplier = BuffsModule.GetGrowthMultiplier(plantModel)
			local waitTime = math.max(baseStageTime * multiplier, 0.1)

			plantModel:SetAttribute("Stage", nextStage)
			plantModel:SetAttribute("Harvestable", nextStage == Constants.GROWTH_STAGES.BLOOM)
			plantModel:SetAttribute("StageStartTime", os.time())
			plantModel:SetAttribute("StageGrowthTime", waitTime)
			PlantModule.UpdatePlantVisual(plantModel)
			
			-- Setup harvest detector when reaching bloom stage
			if nextStage == Constants.GROWTH_STAGES.BLOOM then
				local ownerId = plantModel:GetAttribute("OwnerUserId")
				if ownerId then
					GardenManager.SetupPlantHarvestDetector(plantModel, ownerId)
				end
				return
			end
			
			task.wait(waitTime)
			
			if not plantModel.Parent then
				return
			end
		end
	end)
end

local function savePlantSlots(userId: number, gardenFolder: Folder)
	if not Config.Economy.EnablePersistence then
		return
	end
	
	-- Save all free-form plants in the garden
	local plotsFolder = gardenFolder:FindFirstChild(Config.World.PlotsFolder)
	local parentFolder = plotsFolder or gardenFolder
	local savedCount = 0
	
	-- First, clear existing free plants data to avoid duplicates
	DataService.ClearAllFreePlants(userId)
	
	-- Find and save all plants (and planted eggs)
	for _, child in ipairs(parentFolder:GetChildren()) do
		if child:IsA("Model") and (child:GetAttribute("PlantType") or child:GetAttribute("EggType") or child:GetAttribute("Kind") == "Egg") then
			local plantId = child:GetAttribute("PlantId")
			if not plantId then
				plantId = game:GetService("HttpService"):GenerateGUID(false)
				child:SetAttribute("PlantId", plantId)
			end
			
			local position = child.PrimaryPart and child.PrimaryPart.Position 
				or child:FindFirstChild("Base") and child.Base.Position
				or Vector3.new(0, 0, 0)
			
			local eggType = child:GetAttribute("EggType")
			if type(eggType) == "string" then
				DataService.AddFreePlant(userId, {
					Id = plantId,
					Kind = "Egg",
					Type = eggType,
					PlantTime = child:GetAttribute("PlantTime") or os.time(),
					HatchAt = child:GetAttribute("HatchAt") or 0,
					Position = {X = position.X, Y = position.Y, Z = position.Z},
				})
			else
				DataService.AddFreePlant(userId, {
					Id = plantId,
					Type = child:GetAttribute("PlantType"),
					Stage = child:GetAttribute("Stage") or Constants.GROWTH_STAGES.SEED,
					PlantTime = child:GetAttribute("PlantTime") or os.time(),
					BaseStageTime = child:GetAttribute("BaseStageTime"),
					Position = {X = position.X, Y = position.Y, Z = position.Z},
					WateredUntil = child:GetAttribute("WateredUntil") or 0,
					PetBoost = child:GetAttribute("PetBoost") or false,
					Size = child:GetAttribute("Size") or 1,
					Weight = child:GetAttribute("Weight") or 1,
				})
			end
			savedCount = savedCount + 1
		end
	end
	
	-- print(string.format("[SavePlants] Saved %d free-form plants for UserId %d", savedCount, userId))
end

local function restorePlantSlots(userId: number, gardenFolder: Folder)
	local cache = ensurePlayerCache(userId)

	-- Clear all existing plants first
	local plotsFolder = gardenFolder:FindFirstChild(Config.World.PlotsFolder)
	local parentFolder = plotsFolder or gardenFolder
	
	for _, child in ipairs(parentFolder:GetChildren()) do
		if child:IsA("Model") and (child:GetAttribute("PlantType") or child:GetAttribute("EggType") or child:GetAttribute("Kind") == "Egg") then
			child:Destroy()
		end
	end

	if not Config.Garden.RestorePlantsOnJoin then
		return
	end

	-- Restore free-form plants
	local freePlants = DataService.GetAllFreePlants(userId)
	local freePlantCount = 0
	for _ in pairs(freePlants) do freePlantCount = freePlantCount + 1 end
	
	if freePlantCount > 0 then
		-- print(string.format("[RestorePlants] Restoring %d free-form plants", freePlantCount))

		local function hatchEggAndCleanup(ownerUserId: number, eggType: string, freePlantId: string, eggModel: Model?)
			local rolledPetType = nil
			local rolledRarity = nil
			rolledPetType, rolledRarity = EconomyService.RollPetFromEggType(eggType)
			if not rolledPetType then
				warn("[GardenManager] No pet rolled for eggType:", eggType)
				return
			end

			local sizeWeight = Constants.GenerateRandomSizeWeight("Pet")
			local petInstance = DataService.AddPetInstance(ownerUserId, rolledPetType, sizeWeight.Size, sizeWeight.Weight)
			if not petInstance then
				warn("[GardenManager] Failed to add pet instance for hatched egg")
				return
			end

			DataService.RemoveFreePlant(ownerUserId, freePlantId)
			local cacheForUser = GardenManager.ActivePlants[ownerUserId]
			if cacheForUser then
				cacheForUser[freePlantId] = nil
			end

			if eggModel and eggModel.Parent then
				eggModel:Destroy()
			end

			local ownerPlayer = Players:GetPlayerByUserId(ownerUserId)
			if ownerPlayer then
				EconomyService.SyncPlayerData(ownerPlayer, true)
			end
		end
		
		for plantId, state in pairs(freePlants) do
			if type(state) == "table" and type(state.Type) == "string" and state.Position then
				local position = Vector3.new(
					state.Position.X or 0,
					state.Position.Y or 0,
					state.Position.Z or 0
				)

				local isEgg = state.Kind == "Egg" or Constants.EGG_CONFIG[state.Type] ~= nil
				if isEgg and EggModule then
					local eggType = state.Type
					local hatchAt = tonumber(state.HatchAt) or 0
					local now = os.time()
					if hatchAt > 0 and hatchAt <= now then
						hatchEggAndCleanup(userId, eggType, plantId, nil)
					else
						local eggModel = EggModule.CreateEggModel(eggType, position)
						if eggModel then
							eggModel:SetAttribute("PlantId", plantId)
							eggModel:SetAttribute("Kind", "Egg")
							eggModel:SetAttribute("EggType", eggType)
							eggModel:SetAttribute("OwnerUserId", userId)
							eggModel:SetAttribute("Owner", userId)
							eggModel:SetAttribute("PlantTime", state.PlantTime or now)
							eggModel:SetAttribute("HatchAt", hatchAt)
							eggModel:SetAttribute("FreePlanted", true)
							eggModel.Parent = parentFolder
							cache[plantId] = eggModel

							local remaining = 0
							if hatchAt > 0 then
								remaining = math.max(0, hatchAt - now)
							else
								local eggConfig = Constants.EGG_CONFIG[eggType]
								remaining = eggConfig and eggConfig.HatchTimeSeconds or 60
							end

							task.delay(remaining, function()
								hatchEggAndCleanup(userId, eggType, plantId, eggModel)
							end)
						end
					end
				else
					local savedSize = state.Size or 1
					local plantModel = PlantModule.CreatePlantModel(state.Type, position, savedSize)
					
					if plantModel then
						plantModel:SetAttribute("PlantId", plantId)
						plantModel:SetAttribute("OwnerUserId", userId)
						plantModel:SetAttribute("Owner", userId)
						plantModel:SetAttribute("WateredUntil", state.WateredUntil or 0)
						plantModel:SetAttribute("PetBoost", state.PetBoost or false)
						plantModel:SetAttribute("Size", state.Size or 1)
						plantModel:SetAttribute("Weight", state.Weight or 1)
						plantModel:SetAttribute("PlantTime", state.PlantTime or os.time())
						if type(state.BaseStageTime) == "number" then
							plantModel:SetAttribute("BaseStageTime", state.BaseStageTime)
						else
							plantModel:SetAttribute("BaseStageTime", Constants.GetDefaultBaseStageGrowthSecondsForPlant(state.Type))
						end
						plantModel:SetAttribute("FreePlanted", true)
						plantModel.Parent = parentFolder
						
						continueGrowthFromStage(plantModel, state.Stage, state.PlantTime)
						cache[plantId] = plantModel
						
						-- print(string.format("[RestorePlants] ✓ Restored free plant %s at position", state.Type))
					end
				end
			end
		end
	end
end

local function findGardenForPlayer(userId: number): Folder?
	local gardensFolder = getGardensFolder()
	if not gardensFolder then
		return nil
	end

	for gardenName, assignedUserId in pairs(GardenManager.GardenAssignments) do
		if assignedUserId == userId then
			local garden = gardensFolder:FindFirstChild(gardenName)
			if garden and garden:IsA("Folder") then
				return garden
			end
		end
	end

	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local ownerId = garden:GetAttribute("OwnerUserId")
			if ownerId == userId then
				return garden
			end
		end
	end

	if Config.Garden.GardenNames then
		for _, gardenName in ipairs(Config.Garden.GardenNames) do
			local garden = gardensFolder:FindFirstChild(gardenName)
			if garden and garden:IsA("Folder") then
				local assignedUserId = GardenManager.GardenAssignments[garden.Name]
				local ownerId = garden:GetAttribute("OwnerUserId")
				if not assignedUserId and (not ownerId or ownerId == 0) then
					return garden
				end
			end
		end
	end

	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local assignedUserId = GardenManager.GardenAssignments[garden.Name]
			local ownerId = garden:GetAttribute("OwnerUserId")
			if not assignedUserId and (not ownerId or ownerId == 0) then
				return garden
			end
		end
	end

	return nil
end

local function growPlantToBloom(plantModel: Model, ownerId: number)
	plantModel:SetAttribute("Stage", Constants.GROWTH_STAGES.BLOOM)
	plantModel:SetAttribute("Harvestable", true)
	plantModel:SetAttribute("StageStartTime", os.time())
	plantModel:SetAttribute("StageGrowthTime", 0)
	PlantModule.UpdatePlantVisual(plantModel)
	GardenManager.SetupPlantHarvestDetector(plantModel, ownerId)
end

local function growAllPlantsInGarden(gardenFolder: Folder, ownerId: number): number
	local grown = 0
	local container = gardenFolder:FindFirstChild(Config.World.PlotsFolder) or gardenFolder

	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("PlantType") then
			growPlantToBloom(descendant, ownerId)
			grown += 1
		end
	end

	return grown
end

function GardenManager.GrowAllPlantsForUser(userId: number): number
	local garden = GardenManager.PlayerGardens[userId] or findGardenForPlayer(userId)
	if not garden then
		return 0
	end

	return growAllPlantsInGarden(garden, userId)
end

-- Note: Old slot-based setupClickDetectors removed - using free-form planting now

local function bootstrapGardens()
	local gardensFolder = getGardensFolder()
	if not gardensFolder then
		warn("GardenManager: Missing gardens folder", Config.World.GardensFolder)
		return
	end

	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			garden:SetAttribute("OwnerUserId", 0)
			GardenManager.GardenAssignments[garden.Name] = nil
			updateGardenSign(garden, nil)
			setupGrowAllPrompt(garden)
			
			-- Clear any existing plants in the plots folder
			local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
			if plotsFolder then
				for _, child in ipairs(plotsFolder:GetChildren()) do
					if child:IsA("Model") and child:GetAttribute("PlantType") then
						child:Destroy()
					end
				end
			end
		end
	end
end

function GardenManager.AssignGarden(player: Player): (boolean, string?)
	if GardenManager.PlayerGardens[player.UserId] then
-- print(string.format("[AssignGarden] %s already has a garden assigned", player.Name))
		return true, nil
	end

	local garden = findGardenForPlayer(player.UserId)
	if not garden then
		warn(string.format("[AssignGarden] No available gardens for %s", player.Name))
		return false, "No available gardens"
	end

-- print(string.format("[AssignGarden] Assigning %s to %s", garden.Name, player.Name))

	GardenManager.PlayerGardens[player.UserId] = garden
	GardenManager.GardenAssignments[garden.Name] = player.UserId
	garden:SetAttribute("OwnerUserId", player.UserId)
	updateGardenSign(garden, player.DisplayName)

	-- Teleport player to their garden spawn point on first join
	local tpPart = garden:FindFirstChild(Config.World.TeleportPartName, true) -- Search recursively
	if tpPart and tpPart:IsA("BasePart") then
		-- Wait for character to load
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
		
		if humanoidRootPart then
			humanoidRootPart.CFrame = tpPart.CFrame + Vector3.new(0, 3, 0) -- Teleport slightly above the part
-- print(string.format("[AssignGarden] Teleported %s to their garden", player.Name))
		end
	else
		warn(string.format("[AssignGarden] No %s found in %s", Config.World.TeleportPartName, garden.Name))
	end

	-- Wait a moment for DataService to be ready
	task.wait(0.5)
	
	-- Check if DataService has loaded the profile
	if not DataService.IsDataLoaded(player.UserId) then
		warn(string.format("[AssignGarden] DataService not ready for %s, delaying plant restoration", player.Name))
		task.spawn(function()
			local attempts = 0
			while not DataService.IsDataLoaded(player.UserId) and attempts < 20 do
				task.wait(0.5)
				attempts = attempts + 1
			end
			if DataService.IsDataLoaded(player.UserId) then
-- print(string.format("[AssignGarden] DataService ready after %d attempts, restoring plants", attempts))
				restorePlantSlots(player.UserId, garden)
			else
				warn(string.format("[AssignGarden] DataService never loaded for %s, skipping plant restoration", player.Name))
			end
		end)
	else
		restorePlantSlots(player.UserId, garden)
	end

-- print(string.format("[AssignGarden] ✓ Successfully assigned %s to %s", garden.Name, player.Name))
	return true, nil
end

function GardenManager.ReleaseGarden(player: Player)
	local garden = GardenManager.PlayerGardens[player.UserId]
	if not garden then
		return
	end

	-- Save free-form plants before releasing
	if Config.Garden.SavePlantsOnLeave then
		savePlantSlots(player.UserId, garden)
	else
		DataService.ClearAllFreePlants(player.UserId)
	end

	-- Clear all plants from the plots folder
	local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
	if plotsFolder then
		for _, child in ipairs(plotsFolder:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("PlantType") then
				child:Destroy()
			end
		end
	end

	GardenManager.ActivePlants[player.UserId] = nil
	GardenManager.PlayerGardens[player.UserId] = nil

	if Config.Garden.FreeOnLeave then
		GardenManager.GardenAssignments[garden.Name] = nil
		garden:SetAttribute("OwnerUserId", 0)
		updateGardenSign(garden, nil)
	else
		GardenManager.GardenAssignments[garden.Name] = player.UserId
		garden:SetAttribute("OwnerUserId", player.UserId)
		updateGardenSign(garden, player.DisplayName)
	end
end

-- Get the plot floor/ground for a garden
function GardenManager.GetPlotFloor(gardenFolder: Folder): BasePart?
	-- Try looking in Plots folder for "Plot" part first (used for validation bounds)
	local plotsFolder = gardenFolder:FindFirstChild(Config.World.PlotsFolder)
	if plotsFolder then
		local plotPart = plotsFolder:FindFirstChild("Plot")
		if plotPart and plotPart:IsA("BasePart") then
			return plotPart
		end
		
		local floor = plotsFolder:FindFirstChild(Config.World.FloorName) or plotsFolder:FindFirstChild("Floor")
		if floor and floor:IsA("BasePart") then
			return floor
		end
	end
	
	-- Try to find Floor part directly in garden
	local floor = gardenFolder:FindFirstChild(Config.World.FloorName)
	if floor and floor:IsA("BasePart") then
		return floor
	end
	
	return nil
end

-- Check if position is within garden plot bounds (uses "Plot1-Plot8" parts in Plots folder)
function GardenManager.IsPositionInPlot(gardenFolder: Folder, position: Vector3): boolean
	local plotsFolder = gardenFolder:FindFirstChild(Config.World.PlotsFolder)
	
	if not plotsFolder then
		-- No plots folder, use distance-based fallback
		return false
	end
	
	-- Check against all plot parts (Plot1 through Plot8)
	for i = 1, 8 do
		local plotPart = plotsFolder:FindFirstChild("Plot" .. i)
		if plotPart and plotPart:IsA("BasePart") then
			-- Convert position to local space of the plot part to properly handle rotation
			local localPos = plotPart.CFrame:PointToObjectSpace(position)
			local halfSize = plotPart.Size / 2
			
			-- Add a small margin to avoid edge-case rejections (1 stud buffer)
			local margin = 1.0
			
			local inBounds = localPos.X >= -halfSize.X - margin
				and localPos.X <= halfSize.X + margin
				and localPos.Z >= -halfSize.Z - margin
				and localPos.Z <= halfSize.Z + margin
			
			if inBounds then
				return true
			end
		end
	end
	
	-- Fallback: check if within reasonable distance of any part in plots folder
	for _, child in ipairs(plotsFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local maxDistance = 30 -- studs
			if (position - child.Position).Magnitude < maxDistance then
				return true
			end
		end
	end
	
	return false
end

-- Get all plants in a garden (for free planting mode)
function GardenManager.GetAllPlantsInGarden(userId: number): {Model}
	local plants = {}
	local cache = GardenManager.ActivePlants[userId]
	if cache then
		for _, plant in pairs(cache) do
			if plant and plant.Parent then
				table.insert(plants, plant)
			end
		end
	end
	return plants
end

-- Check minimum spacing between plants
function GardenManager.CheckPlantSpacing(gardenFolder: Folder, userId: number, position: Vector3): boolean
	local minSpacing = Constants.FREE_PLANTING and Constants.FREE_PLANTING.MinPlantSpacing or 3.0
	
	local plants = GardenManager.GetAllPlantsInGarden(userId)
	for _, plant in ipairs(plants) do
		local basePart = plant:FindFirstChild("Base") or plant.PrimaryPart
		if basePart then
			local distance = (basePart.Position - position).Magnitude
			if distance < minSpacing then
				return false
			end
		end
	end
	
	return true
end

-- Count plants in garden (for max limit)
function GardenManager.CountPlantsInGarden(userId: number): number
	local count = 0
	local cache = GardenManager.ActivePlants[userId]
	if cache then
		for _, plant in pairs(cache) do
			if plant and plant.Parent then
				count = count + 1
			end
		end
	end
	return count
end

-- Free-form planting at any position on the plot
function GardenManager.PlantSeedAtPosition(player: Player, position: Vector3, plantType: string): (boolean, string?)
	if type(plantType) ~= "string" then
		return false, "Invalid plant type"
	end
	
	local garden = GardenManager.PlayerGardens[player.UserId]
	if not garden then
		return false, "No garden assigned"
	end
	
	-- Check if position is within the plot bounds
	if not GardenManager.IsPositionInPlot(garden, position) then
		return false, "Position outside plot bounds"
	end
	
	-- Check max plants limit
	local freePlantingConfig = Constants.FREE_PLANTING or {}
	local maxPlants = freePlantingConfig.MaxPlantsPerGarden or 20
	local currentCount = GardenManager.CountPlantsInGarden(player.UserId)
	if currentCount >= maxPlants then
		return false, "Maximum plants reached"
	end
	
	-- Check plant spacing
	if not GardenManager.CheckPlantSpacing(garden, player.UserId, position) then
		return false, "Too close to another plant"
	end
	
	local isSeed = Constants.PLANT_CONFIG[plantType] ~= nil
	local isEgg = Constants.EGG_CONFIG[plantType] ~= nil
	if not isSeed and not isEgg then
		return false, "Invalid item"
	end

	if isSeed then
		if not EconomyService.RemoveSeed(player, plantType) then
			return false, "Seed unavailable"
		end
	else
		if not EconomyService.RemoveEgg(player, plantType, 1) then
			return false, "Egg unavailable"
		end
	end
	
	-- Generate unique ID and random size/weight
	local HttpService = game:GetService("HttpService")
	local plantId = HttpService:GenerateGUID(false)
	local sizeWeight = Constants.GenerateRandomSizeWeight("Plant")
	
	-- Adjust Y position to be on/above plot surface
	local plotFloor = GardenManager.GetPlotFloor(garden)
	local plantY = position.Y
	if plotFloor then
		plantY = plotFloor.Position.Y + plotFloor.Size.Y / 2 + (freePlantingConfig.PlantHeightOffset or 0.1)
	end
	local adjustedPosition = Vector3.new(position.X, plantY, position.Z)
	
	local function parentToGarden(model: Model)
		local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
		if plotsFolder then
			model.Parent = plotsFolder
		else
			model.Parent = garden
		end
	end

	local cache = ensurePlayerCache(player.UserId)

	if isSeed then
		local plantModel = PlantModule.CreatePlantModel(plantType, adjustedPosition, sizeWeight.Size)
		if not plantModel then
			EconomyService.AddSeed(player, plantType, 1)
			return false, "Failed to create plant model"
		end
		
		-- Set attributes
		plantModel:SetAttribute("PlantId", plantId)
		plantModel:SetAttribute("OwnerUserId", player.UserId)
		plantModel:SetAttribute("Owner", player.UserId)
		plantModel:SetAttribute("WateredUntil", 0)
		plantModel:SetAttribute("PetBoost", false)
		plantModel:SetAttribute("Size", sizeWeight.Size)
		plantModel:SetAttribute("Weight", sizeWeight.Weight)
		plantModel:SetAttribute("BaseStageTime", Constants.RollBaseStageGrowthSecondsForPlant(plantType))
		plantModel:SetAttribute("FreePlanted", true)
		plantModel:SetAttribute("PlantPosition", adjustedPosition) -- Store position for persistence
		
		parentToGarden(plantModel)
		cache[plantId] = plantModel
		
		-- Save to DataStore if persistence enabled
		if Config.Economy.EnablePersistence then
			DataService.AddFreePlant(player.UserId, {
				Id = plantId,
				Type = plantType,
				Stage = plantModel:GetAttribute("Stage"),
				PlantTime = plantModel:GetAttribute("PlantTime") or os.time(),
				BaseStageTime = plantModel:GetAttribute("BaseStageTime"),
				Position = {X = adjustedPosition.X, Y = adjustedPosition.Y, Z = adjustedPosition.Z},
				WateredUntil = 0,
				PetBoost = false,
				Size = sizeWeight.Size,
				Weight = sizeWeight.Weight,
			})
			task.spawn(function()
				DataService.ForceSave(player.UserId)
			end)
		end
		
		-- Start growth
		task.spawn(PlantModule.GrowPlant, plantModel)
	else
		if not EggModule then
			DataService.AddEgg(player.UserId, plantType, 1)
			EconomyService.SyncPlayerData(player, false)
			return false, "Egg module missing"
		end

		local eggConfig = Constants.EGG_CONFIG[plantType]
		local hatchSeconds = eggConfig and eggConfig.HatchTimeSeconds or 60
		local plantedAt = os.time()
		local hatchAt = plantedAt + hatchSeconds
		local userId = player.UserId

		local eggModel = EggModule.CreateEggModel(plantType, adjustedPosition)
		if not eggModel then
			DataService.AddEgg(player.UserId, plantType, 1)
			EconomyService.SyncPlayerData(player, false)
			return false, "Failed to create egg model"
		end

		eggModel:SetAttribute("PlantId", plantId)
		eggModel:SetAttribute("Kind", "Egg")
		eggModel:SetAttribute("EggType", plantType)
		eggModel:SetAttribute("OwnerUserId", player.UserId)
		eggModel:SetAttribute("Owner", player.UserId)
		eggModel:SetAttribute("PlantTime", plantedAt)
		eggModel:SetAttribute("HatchAt", hatchAt)
		eggModel:SetAttribute("FreePlanted", true)

		parentToGarden(eggModel)
		cache[plantId] = eggModel

		if Config.Economy.EnablePersistence then
			DataService.AddFreePlant(userId, {
				Id = plantId,
				Kind = "Egg",
				Type = plantType,
				PlantTime = plantedAt,
				HatchAt = hatchAt,
				Position = {X = adjustedPosition.X, Y = adjustedPosition.Y, Z = adjustedPosition.Z},
			})
			task.spawn(function()
				DataService.ForceSave(userId)
			end)
		end

		task.delay(hatchSeconds, function()
			if not eggModel.Parent then
				return
			end

			local eggType = eggModel:GetAttribute("EggType")
			if type(eggType) ~= "string" then
				return
			end

			local rolledPetType = nil
			local rolledRarity = nil
			rolledPetType, rolledRarity = EconomyService.RollPetFromEggType(eggType)
			if not rolledPetType then
				warn("[GardenManager] No pet rolled for planted egg:", eggType)
				return
			end

			local petSizeWeight = Constants.GenerateRandomSizeWeight("Pet")
			local petInstance = DataService.AddPetInstance(userId, rolledPetType, petSizeWeight.Size, petSizeWeight.Weight)
			if not petInstance then
				warn("[GardenManager] Failed to add pet instance for planted egg hatch")
				return
			end

			DataService.RemoveFreePlant(userId, plantId)
			cache[plantId] = nil
			eggModel:Destroy()
			local ownerPlayer = Players:GetPlayerByUserId(userId)
			if ownerPlayer then
				EconomyService.SyncPlayerData(ownerPlayer, true)
			end
		end)
	end
	
	return true, nil
end

function GardenManager.Initialize()
	bootstrapGardens()

	EconomyService.SetGrowAllRewardHandler(function(userId)
		return GardenManager.GrowAllPlantsForUser(userId)
	end)
	
	-- Free-form planting event handler
	plantSeedAtPositionEvent.OnServerEvent:Connect(function(player, position, plantType)
		if typeof(position) ~= "Vector3" then
			warn(string.format("GardenManager: Invalid position type from %s", player.Name))
			return
		end
		local success, message = GardenManager.PlantSeedAtPosition(player, position, plantType)
		if not success then
			warn(string.format("GardenManager: PlantSeedAtPosition rejected for %s (%s)", player.Name, message or "unknown error"))
		end
	end)

	if Config.Garden.AssignOnJoin then
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				GardenManager.AssignGarden(player)
			end)
		end

		Players.PlayerAdded:Connect(function(player)
			task.defer(function()
				task.wait(0.3)
				GardenManager.AssignGarden(player)
			end)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		GardenManager.ReleaseGarden(player)
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			GardenManager.ReleaseGarden(player)
		end
	end)

-- print("GardenManager initialized")
end

return GardenManager
