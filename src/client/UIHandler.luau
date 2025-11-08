-- UIHandler.luau
-- Simplified UI handler that uses pre-built UI from StarterGui
-- Run UISetup ModuleScript once in Studio first!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- NPCUIHandler for camera control
local NPCUIHandler = require(script.Parent:WaitForChild("NPCUIHandler"))

-- Audio Manager (optional - won't break if not loaded)
local AudioManager
pcall(function()
	AudioManager = require(script.Parent:WaitForChild("AudioManager"))
end)

local UIHandler = {}
local selectedPlantType = nil
local playerInventory = {Seeds = {}, Pets = {}, Fruits = {}}
local playerCoins = 0
local currentWeather = Constants.WEATHER_TYPES.SUNNY
local screenGui = nil

-- ENCHANTED FOREST THEME - Matching UISetup.luau
local THEME = {
	-- Backgrounds: Deep forest night
	ForestDark = Color3.fromRGB(25, 50, 35),
	ForestDeep = Color3.fromRGB(35, 60, 45),
	WoodBark = Color3.fromRGB(50, 60, 45),
	MossGreen = Color3.fromRGB(45, 70, 55),
	
	-- Panels: Organic wood and stone
	WoodPanel = Color3.fromRGB(60, 70, 55),
	StonePanel = Color3.fromRGB(60, 75, 65),
	LeafPanel = Color3.fromRGB(50, 75, 60),
	
	-- Accents: Magical glows and natural gems
	TealGem = Color3.fromRGB(88, 160, 140),
	TealGlow = Color3.fromRGB(110, 190, 170),
	GoldLeaf = Color3.fromRGB(235, 185, 95),
	AmberGlow = Color3.fromRGB(255, 200, 120),
	
	-- Text: Off-white and pale colors
	TextLight = Color3.fromRGB(245, 238, 220),
	TextGold = Color3.fromRGB(240, 200, 130),
	TextMoss = Color3.fromRGB(180, 220, 190),
	
	-- Borders: Natural vine and leaf strokes
	VineStroke = Color3.fromRGB(88, 160, 108),
	GlowStroke = Color3.fromRGB(140, 255, 200),
}

-- Forward declarations
local updateSellShop
local updatePetsWindow

-- Helper to play UI sounds
local function playSound(soundName)
	if AudioManager then
		AudioManager.PlaySFX(soundName)
	end
end

-- Helper to hide/show HUD elements
local function hideHUD()
	if not screenGui then return end
	local currencyFrame = screenGui:FindFirstChild("CurrencyFrame")
	local weatherFrame = screenGui:FindFirstChild("WeatherFrame")
	local inventoryFrame = screenGui:FindFirstChild("InventoryFrame")
	local fruitsFrame = screenGui:FindFirstChild("FruitsFrame")
	local petsButton = screenGui:FindFirstChild("PetsButton")
	
	if currencyFrame then currencyFrame.Visible = false end
	if weatherFrame then weatherFrame.Visible = false end
	if inventoryFrame then inventoryFrame.Visible = false end
	if fruitsFrame then fruitsFrame.Visible = false end
	if petsButton then petsButton.Visible = false end
end

local function showHUD()
	if not screenGui then return end
	local currencyFrame = screenGui:FindFirstChild("CurrencyFrame")
	local weatherFrame = screenGui:FindFirstChild("WeatherFrame")
	local inventoryFrame = screenGui:FindFirstChild("InventoryFrame")
	local fruitsFrame = screenGui:FindFirstChild("FruitsFrame")
	local petsButton = screenGui:FindFirstChild("PetsButton")
	
	if currencyFrame then currencyFrame.Visible = true end
	if weatherFrame then weatherFrame.Visible = true end
	if inventoryFrame then inventoryFrame.Visible = true end
	if fruitsFrame then fruitsFrame.Visible = true end
	if petsButton then petsButton.Visible = true end
end

-- =============================================================================
-- ANIMATION HELPERS
-- =============================================================================
local function fadeIn(gui, duration)
	gui.Visible = true
	local tween = TweenService:Create(gui, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = gui.BackgroundTransparency,
		Position = gui.Position
	})
	tween:Play()
end

local function fadeOut(gui, duration)
	local originalTransparency = gui.BackgroundTransparency
	local tween = TweenService:Create(gui, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		gui.Visible = false
		gui.BackgroundTransparency = originalTransparency
	end)
end

local function scaleButton(button)
	local hover = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = button.Size * 1.05
	})
	local reset = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = button.Size / 1.05
	})
	
	button.MouseEnter:Connect(function() hover:Play() end)
	button.MouseLeave:Connect(function() reset:Play() end)
end

-- =============================================================================
-- NOTIFICATION SYSTEM
-- =============================================================================
local function showNotification(message, color, icon)
	if not screenGui then return end
	local container = screenGui:FindFirstChild("NotificationContainer")
	if not container then return end

	local accentColor = color or THEME.Notification

	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(1, 0, 0, 44)
	notif.BackgroundColor3 = accentColor
	notif.BackgroundTransparency = 0.15
	notif.BorderSizePixel = 0
	notif.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notif

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 1.5
	stroke.Color = THEME.PanelStroke
	stroke.Transparency = 0.35
	stroke.Parent = notif

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, accentColor),
		ColorSequenceKeypoint.new(1, THEME.NotificationAlt)
	})
	gradient.Rotation = 30
	gradient.Parent = notif

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0.14, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon or "*"
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextScaled = true
	iconLabel.TextColor3 = THEME.TextLight
	iconLabel.Parent = notif

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(0.78, 0, 1, 0)
	textLabel.Position = UDim2.new(0.18, 0, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 16
	textLabel.TextColor3 = THEME.TextLight
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = notif

	notif.Position = UDim2.new(0, 0, 0, -55)
	notif.BackgroundTransparency = 1
	local tweenIn = TweenService:Create(notif, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0.15
	})
	tweenIn:Play()

	task.delay(1.6, function()
		local tweenOut = TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0, 0, 0, -55),
			BackgroundTransparency = 1
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
end


-- =============================================================================
-- CURRENCY UPDATE
-- =============================================================================
local function updateCurrencyDisplay(coins, isTotal)
	if not screenGui then return end
	local coinLabel = screenGui.CurrencyFrame:FindFirstChild("CoinLabel")
	if not coinLabel then return end
	
	if isTotal then
		playerCoins = coins
	else
		playerCoins = playerCoins + coins
		-- Show notification for coin gain/loss
		if coins > 0 then
			showNotification("+" .. coins .. " coins earned!", THEME.TextGold, "💰")
		end
	end
	
	-- Animate counter
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	coinLabel.Text = tostring(playerCoins)
	
	-- Pulse effect
	local pulse = TweenService:Create(coinLabel, TweenInfo.new(0.2), {TextSize = 24})
	local reset = TweenService:Create(coinLabel, TweenInfo.new(0.2), {TextSize = 18})
	pulse:Play()
	pulse.Completed:Connect(function() reset:Play() end)
end

-- =============================================================================
-- INVENTORY UPDATE
-- =============================================================================
local function createInventoryItem(plantType, count, container)
	if not screenGui then return end
	local config = Constants.PLANT_CONFIG[plantType]
	if not config then return end
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = plantType
	itemFrame.Size = UDim2.new(0, 80, 1, -10)
	itemFrame.BackgroundColor3 = THEME.LeafPanel
	itemFrame.BorderSizePixel = 0
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = itemFrame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(THEME.LeafPanel, THEME.MossGreen)
	gradient.Rotation = 90
	gradient.Parent = itemFrame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 1
	stroke.Color = THEME.VineStroke
	stroke.Transparency = 0.4
	stroke.Parent = itemFrame
	
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0.7, 0)
	button.BackgroundTransparency = 1
	button.Text = "🌱"
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = config.EmitsLight and THEME.TextGold or THEME.TextLight
	button.Parent = itemFrame
	
	button.MouseButton1Click:Connect(function()
		if selectedPlantType == plantType then
			selectedPlantType = nil
			itemFrame.BackgroundColor3 = THEME.LeafPanel
			showNotification("Seed stored for later.", THEME.WoodPanel, "👋")
		else
			selectedPlantType = plantType
			-- Reset all
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Frame") then
					child.BackgroundColor3 = THEME.LeafPanel
				end
			end
			itemFrame.BackgroundColor3 = THEME.TealGem
			showNotification(plantType .. " prepared for planting!", THEME.TealGem, "🌱")
		end
	end)
	
	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, 0, 0.3, 0)
	countLabel.Position = UDim2.new(0, 0, 0.7, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = tostring(count)
	countLabel.TextColor3 = THEME.TextLight
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextScaled = true
	countLabel.Parent = itemFrame
	
	return itemFrame
end

local function createFruitItem(fruitName, count, container)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = fruitName
	itemFrame.Size = UDim2.new(0, 80, 1, -10)
	itemFrame.BackgroundColor3 = THEME.WoodPanel
	itemFrame.BorderSizePixel = 0
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = itemFrame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(THEME.WoodPanel, THEME.WoodBark)
	gradient.Rotation = 90
	gradient.Parent = itemFrame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 1
	stroke.Color = THEME.GoldLeaf
	stroke.Transparency = 0.4
	stroke.Parent = itemFrame
	
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.7, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "🍎"
	icon.TextScaled = true
	icon.TextColor3 = THEME.TextLight
	icon.Parent = itemFrame
	
	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, 0, 0.3, 0)
	countLabel.Position = UDim2.new(0, 0, 0.7, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = tostring(count)
	countLabel.TextColor3 = THEME.TextLight
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextScaled = true
	countLabel.Parent = itemFrame
	
	return itemFrame
end

local function updateInventoryDisplay(inventory)
	if not screenGui then return end
	playerInventory = inventory
	
	-- Auto-unselect if seed count is 0
	if selectedPlantType then
		local seedCount = inventory.Seeds and inventory.Seeds[selectedPlantType] or 0
		if seedCount <= 0 then
			selectedPlantType = nil
		end
	end
	
	-- Update seeds
	local seedContainer = screenGui.InventoryFrame:WaitForChild("SeedContainer")
	for _, child in ipairs(seedContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	if inventory.Seeds then
		for plantType, count in pairs(inventory.Seeds) do
			if count > 0 then
				createInventoryItem(plantType, count, seedContainer)
			end
		end
	end
	
	-- Update fruits
	local fruitsContainer = screenGui.FruitsFrame:WaitForChild("FruitsContainer")
	for _, child in ipairs(fruitsContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	if inventory.Fruits then
		for fruitName, count in pairs(inventory.Fruits) do
			if count > 0 then
				createFruitItem(fruitName, count, fruitsContainer)
			end
		end
	end
	
	-- Update sell shop if it's open
	local sellWindow = screenGui:FindFirstChild("SellWindow")
	if sellWindow and sellWindow.Visible then
		updateSellShop()
	end
	
	-- Update pets window if it's open
	local petsWindow = screenGui:FindFirstChild("PetsWindow")
	if petsWindow and petsWindow.Visible then
		updatePetsWindow()
	end
end

-- =============================================================================
-- WEATHER UPDATE
-- =============================================================================
local function updateWeatherDisplay(weather)
	if not screenGui then return end
	currentWeather = weather
	local weatherLabel = screenGui.WeatherFrame:WaitForChild("WeatherLabel")
	
	local weatherIcons = {
		[Constants.WEATHER_TYPES.SUNNY] = "☀️",
		[Constants.WEATHER_TYPES.RAINY] = "🌧️",
		[Constants.WEATHER_TYPES.STORMY] = "⛈️"
	}
	
	local icon = weatherIcons[weather] or "☀️"
	weatherLabel.Text = icon .. " " .. weather
	
	-- Color change animation
	local colors = {
		[Constants.WEATHER_TYPES.SUNNY] = Color3.fromRGB(255, 255, 100),
		[Constants.WEATHER_TYPES.RAINY] = Color3.fromRGB(100, 150, 255),
		[Constants.WEATHER_TYPES.STORMY] = Color3.fromRGB(150, 100, 200)
	}
	
	local tween = TweenService:Create(weatherLabel, TweenInfo.new(0.5), {
		TextColor3 = colors[weather] or Color3.fromRGB(255, 255, 255)
	})
	tween:Play()
end

-- =============================================================================
-- SHOP SYSTEM
-- =============================================================================
local function createShopItem(itemName, itemType, config, container)
	if not config then 
		warn("[UIHandler] No config for", itemType, itemName)
		return 
	end
	
	-- Get the correct price field based on item type
	local price = itemType == "seed" and config.SeedPrice or config.Price
	if not price then
		warn("[UIHandler] No price for", itemType, itemName)
		return
	end
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = itemName
	itemFrame.Size = UDim2.new(1, 0, 0, 80)
	itemFrame.BackgroundColor3 = THEME.WoodPanel
	itemFrame.BorderSizePixel = 0
	itemFrame.ZIndex = 11
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = itemFrame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(THEME.WoodPanel, THEME.WoodBark)
	gradient.Rotation = 90
	gradient.Parent = itemFrame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Color = THEME.VineStroke
	stroke.Transparency = 0.3
	stroke.Parent = itemFrame
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 1, -10)
	icon.Position = UDim2.new(0, 5, 0, 5)
	icon.BackgroundTransparency = 1
	icon.Text = itemType == "seed" and "🌱" or "🐾"
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = itemType == "seed" and (config.EmitsLight and THEME.TextGold or THEME.TextMoss) or THEME.TealGlow
	icon.ZIndex = 12
	icon.Parent = itemFrame
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.45, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0.15, 0, 0.1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemName
	nameLabel.TextColor3 = THEME.TextLight
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 12
	nameLabel.Parent = itemFrame
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.45, 0, 0.3, 0)
	descLabel.Position = UDim2.new(0.15, 0, 0.55, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemType == "seed" and ("Grows in " .. (config.GrowthTime or "?") .. "s") or ("Boost: +" .. math.floor((1 - (config.WaterBoost or 1)) * 100) .. "%")
	descLabel.TextColor3 = THEME.TextMoss
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextScaled = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 12
	descLabel.Parent = itemFrame
	
	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 0.3, 0)
	priceLabel.Position = UDim2.new(0.62, 0, 0.25, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 " .. price
	priceLabel.TextColor3 = THEME.TextGold
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextScaled = true
	priceLabel.ZIndex = 12
	priceLabel.Parent = itemFrame
	
	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.15, 0, 0.5, 0)
	buyButton.Position = UDim2.new(0.83, 0, 0.25, 0)
	buyButton.BackgroundColor3 = THEME.TealGem
	buyButton.Text = "BUY"
	buyButton.TextColor3 = THEME.TextLight
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextScaled = true
	buyButton.ZIndex = 12
	buyButton.Parent = itemFrame
	
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 10)
	buyCorner.Parent = buyButton
	
	buyButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		if itemType == "seed" then
			local buyEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_SEED)
			if buyEvent then
				buyEvent:FireServer(itemName, 1) -- Buy 1 seed
				playSound("Purchase")
			end
		elseif itemType == "pet" then
			local buyEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_PET)
			if buyEvent then
				buyEvent:FireServer(itemName)
				playSound("Purchase")
			end
		end
	end)
	
	-- Hover effect
	buyButton.MouseEnter:Connect(function()
		buyButton.BackgroundColor3 = THEME.TealGlow
	end)
	buyButton.MouseLeave:Connect(function()
		buyButton.BackgroundColor3 = THEME.TealGem
	end)
end

local function populateShop()
	if not screenGui then return end
	local shopWindow = screenGui:FindFirstChild("ShopWindow")
	if not shopWindow then return end
	
	local leftPanel = shopWindow:FindFirstChild("LeftPanel")
	local shopScroll = leftPanel and leftPanel:FindFirstChild("ScrollingFrame") or shopWindow:FindFirstChild("ScrollingFrame")
	if not shopScroll then 
		warn("[UIHandler] Could not find shop ScrollingFrame")
		return 
	end
	
	-- Clear existing
	for _, child in ipairs(shopScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Add seeds
	for plantType, config in pairs(Constants.PLANT_CONFIG) do
		createShopItem(plantType, "seed", config, shopScroll)
	end
	
	-- Add pets
	for petType, config in pairs(Constants.PET_CONFIG) do
		createShopItem(petType, "pet", config, shopScroll)
	end
end

-- =============================================================================
-- PETS SYSTEM
-- =============================================================================
local function createPetItem(petType, container)
	local config = Constants.PET_CONFIG[petType]
	if not config then return end
	
	local isEquipped = (playerInventory.EquippedPet == petType)
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = petType
	itemFrame.Size = UDim2.new(1, 0, 0, 70)
	itemFrame.BackgroundColor3 = isEquipped and THEME.TealGem or THEME.WoodPanel
	itemFrame.BorderSizePixel = 0
	itemFrame.ZIndex = 11
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = itemFrame
	
	local gradient = Instance.new("UIGradient")
	if isEquipped then
		gradient.Color = ColorSequence.new(THEME.TealGem, THEME.ForestDeep)
	else
		gradient.Color = ColorSequence.new(THEME.WoodPanel, THEME.WoodBark)
	end
	gradient.Rotation = 90
	gradient.Parent = itemFrame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Color = isEquipped and THEME.GlowStroke or THEME.VineStroke
	stroke.Transparency = 0.3
	stroke.Parent = itemFrame
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 1, -10)
	icon.Position = UDim2.new(0, 5, 0, 5)
	icon.BackgroundTransparency = 1
	icon.Text = "🐾"
	icon.TextScaled = true
	icon.TextColor3 = THEME.TextLight
	icon.Font = Enum.Font.GothamBold
	icon.ZIndex = 12
	icon.Parent = itemFrame
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0.15, 0, 0.1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = petType
	nameLabel.TextColor3 = THEME.TextLight
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 12
	nameLabel.Parent = itemFrame
	
	-- Boost info
	local boostLabel = Instance.new("TextLabel")
	boostLabel.Size = UDim2.new(0.4, 0, 0.35, 0)
	boostLabel.Position = UDim2.new(0.15, 0, 0.6, 0)
	boostLabel.BackgroundTransparency = 1
	boostLabel.Text = "Boost: " .. (config.WaterBoost * 100) .. "%"
	boostLabel.TextColor3 = THEME.TextMoss
	boostLabel.Font = Enum.Font.Gotham
	boostLabel.TextSize = 12
	boostLabel.TextXAlignment = Enum.TextXAlignment.Left
	boostLabel.ZIndex = 12
	boostLabel.Parent = itemFrame
	
	-- Equipped indicator or Equip button
	if isEquipped then
		local equippedLabel = Instance.new("TextLabel")
		equippedLabel.Size = UDim2.new(0.25, 0, 0.5, 0)
		equippedLabel.Position = UDim2.new(0.72, 0, 0.25, 0)
		equippedLabel.BackgroundColor3 = THEME.TealGlow
		equippedLabel.Text = "✓ EQUIPPED"
		equippedLabel.TextColor3 = THEME.TextLight
		equippedLabel.Font = Enum.Font.GothamBold
		equippedLabel.TextSize = 11
		equippedLabel.ZIndex = 12
		equippedLabel.Parent = itemFrame
		
		local equippedCorner = Instance.new("UICorner")
		equippedCorner.CornerRadius = UDim.new(0, 8)
		equippedCorner.Parent = equippedLabel
		
		-- Unequip button
		local unequipButton = Instance.new("TextButton")
		unequipButton.Size = UDim2.new(0.2, 0, 0.4, 0)
		unequipButton.Position = UDim2.new(0.55, 0, 0.3, 0)
		unequipButton.BackgroundColor3 = THEME.WoodBark
		unequipButton.Text = "Unequip"
		unequipButton.TextColor3 = THEME.TextLight
		unequipButton.Font = Enum.Font.GothamBold
		unequipButton.TextSize = 11
		unequipButton.ZIndex = 12
		unequipButton.Parent = itemFrame
		
		local unequipCorner = Instance.new("UICorner")
		unequipCorner.CornerRadius = UDim.new(0, 8)
		unequipCorner.Parent = unequipButton
		
		unequipButton.MouseButton1Click:Connect(function()
			playSound("ButtonClick")
			local equipEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.EQUIP_PET)
			if equipEvent then
				equipEvent:FireServer("") -- Empty string to unequip
				playSound("PetUnequip")
				showNotification("Pet unequipped", THEME.WoodPanel, "🐾")
			end
		end)
		
		unequipButton.MouseEnter:Connect(function()
			unequipButton.BackgroundColor3 = THEME.ForestDark
		end)
		unequipButton.MouseLeave:Connect(function()
			unequipButton.BackgroundColor3 = THEME.WoodBark
		end)
	else
		-- Equip button
		local equipButton = Instance.new("TextButton")
		equipButton.Size = UDim2.new(0.25, 0, 0.6, 0)
		equipButton.Position = UDim2.new(0.72, 0, 0.2, 0)
		equipButton.BackgroundColor3 = THEME.TealGem
		equipButton.Text = "Equip"
		equipButton.TextColor3 = THEME.TextLight
		equipButton.Font = Enum.Font.GothamBold
		equipButton.TextScaled = true
		equipButton.ZIndex = 12
		equipButton.Parent = itemFrame
		
		local equipCorner = Instance.new("UICorner")
		equipCorner.CornerRadius = UDim.new(0, 8)
		equipCorner.Parent = equipButton
		
		equipButton.MouseButton1Click:Connect(function()
			playSound("ButtonClick")
			local equipEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.EQUIP_PET)
			if equipEvent then
				equipEvent:FireServer(petType)
				playSound("PetEquip")
				showNotification("Equipped " .. petType, THEME.TealGem, "🐾")
			end
		end)
		
		equipButton.MouseEnter:Connect(function()
			equipButton.BackgroundColor3 = THEME.TealGlow
		end)
		equipButton.MouseLeave:Connect(function()
			equipButton.BackgroundColor3 = THEME.TealGem
		end)
	end
end

updatePetsWindow = function()
	if not screenGui then return end
	local petsWindow = screenGui:FindFirstChild("PetsWindow")
	if not petsWindow then return end
	
	local leftPanel = petsWindow:FindFirstChild("LeftPanel")
	local petsScroll = leftPanel and leftPanel:FindFirstChild("ScrollingFrame") or petsWindow:FindFirstChild("ScrollingFrame")
	if not petsScroll then 
		warn("[UIHandler] Could not find pets ScrollingFrame")
		return 
	end
	
	-- Clear existing
	for _, child in ipairs(petsScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Add owned pets
	if playerInventory.Pets then
		local hasPets = false
		for petType, owned in pairs(playerInventory.Pets) do
			if owned == true then
				createPetItem(petType, petsScroll)
				hasPets = true
			end
		end
		
		if not hasPets then
			-- Show "no pets" message
			local noPetsLabel = Instance.new("TextLabel")
			noPetsLabel.Size = UDim2.new(1, -20, 0, 60)
			noPetsLabel.Position = UDim2.new(0, 10, 0, 20)
			noPetsLabel.BackgroundTransparency = 1
			noPetsLabel.Text = "No pets owned yet!\nVisit the shop to buy pets."
			noPetsLabel.TextColor3 = THEME.TextSecondary
			noPetsLabel.Font = Enum.Font.Gotham
			noPetsLabel.TextSize = 16
			noPetsLabel.ZIndex = 12
			noPetsLabel.Parent = petsScroll
		end
	else
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(1, -20, 0, 70)
		infoLabel.Position = UDim2.new(0, 10, 0, 20)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "Pet inventory sync is coming soon.\nChat with the Pet Keeper to manage companions."
		infoLabel.TextColor3 = THEME.TextSecondary
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextSize = 16
		infoLabel.ZIndex = 12
		infoLabel.Parent = petsScroll
	end
end

-- =============================================================================
-- SELL SYSTEM
-- =============================================================================
local function createSellItem(fruitName, count, container)
	-- Strip "Fruit" suffix to get plant type (e.g., "glowbudFruit" -> "glowbud")
	local plantType = fruitName:gsub("Fruit$", "")
	local config = Constants.PLANT_CONFIG[plantType]
	if not config then 
		warn("[UIHandler] No config found for plant type:", plantType, "from fruit:", fruitName)
		return 
	end
	if not config.FruitSellPrice then 
		warn("[UIHandler] No FruitSellPrice for:", plantType)
		return 
	end
	
	local sellPrice = config.FruitSellPrice
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = fruitName
	itemFrame.Size = UDim2.new(1, 0, 0, 80)
	itemFrame.BackgroundColor3 = THEME.WoodPanel
	itemFrame.BorderSizePixel = 0
	itemFrame.ZIndex = 11
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = itemFrame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(THEME.WoodPanel, THEME.WoodBark)
	gradient.Rotation = 90
	gradient.Parent = itemFrame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Color = THEME.GoldLeaf
	stroke.Transparency = 0.3
	stroke.Parent = itemFrame
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 1, -10)
	icon.Position = UDim2.new(0, 5, 0, 5)
	icon.BackgroundTransparency = 1
	icon.Text = "🍎"
	icon.TextScaled = true
	icon.TextColor3 = THEME.TextLight
	icon.Font = Enum.Font.GothamBold
	icon.ZIndex = 12
	icon.Parent = itemFrame
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.35, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0.15, 0, 0.1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = fruitName
	nameLabel.TextColor3 = THEME.TextLight
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 12
	nameLabel.Parent = itemFrame
	
	-- Count
	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(0.35, 0, 0.3, 0)
	countLabel.Position = UDim2.new(0.15, 0, 0.55, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = "You have: " .. count
	countLabel.TextColor3 = THEME.TextMoss
	countLabel.Font = Enum.Font.Gotham
	countLabel.TextScaled = true
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	countLabel.ZIndex = 12
	countLabel.Parent = itemFrame
	
	-- Price per item
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 0.3, 0)
	priceLabel.Position = UDim2.new(0.52, 0, 0.25, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 " .. sellPrice .. " each"
	priceLabel.TextColor3 = THEME.TextGold
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextScaled = true
	priceLabel.ZIndex = 12
	priceLabel.Parent = itemFrame
	
	-- Sell 1 button
	local sell1Button = Instance.new("TextButton")
	sell1Button.Size = UDim2.new(0.12, 0, 0.5, 0)
	sell1Button.Position = UDim2.new(0.75, 0, 0.25, 0)
	sell1Button.BackgroundColor3 = THEME.TealGem
	sell1Button.Text = "SELL 1"
	sell1Button.TextColor3 = THEME.TextLight
	sell1Button.Font = Enum.Font.GothamBold
	sell1Button.TextScaled = true
	sell1Button.ZIndex = 12
	sell1Button.Parent = itemFrame
	
	local sell1Corner = Instance.new("UICorner")
	sell1Corner.CornerRadius = UDim.new(0, 10)
	sell1Corner.Parent = sell1Button
	
	sell1Button.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		local sellEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.SELL_FRUIT)
		if sellEvent then
			sellEvent:FireServer(fruitName, 1)
			playSound("Sell")
			-- Show selling notification
			local plantType = fruitName:gsub("Fruit$", "")
			showNotification("Sold 1x " .. plantType .. " for " .. sellPrice .. " coins", THEME.GoldLeaf, "💰")
		end
	end)
	
	-- Sell All button
	local sellAllButton = Instance.new("TextButton")
	sellAllButton.Size = UDim2.new(0.12, 0, 0.5, 0)
	sellAllButton.Position = UDim2.new(0.875, 0, 0.25, 0)
	sellAllButton.BackgroundColor3 = THEME.GoldLeaf
	sellAllButton.Text = "SELL ALL"
	sellAllButton.TextColor3 = THEME.ForestDark
	sellAllButton.Font = Enum.Font.GothamBold
	sellAllButton.TextScaled = true
	sellAllButton.ZIndex = 12
	sellAllButton.Parent = itemFrame
	
	local sellAllCorner = Instance.new("UICorner")
	sellAllCorner.CornerRadius = UDim.new(0, 10)
	sellAllCorner.Parent = sellAllButton
	
	sellAllButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		local sellEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.SELL_FRUIT)
		if sellEvent then
			sellEvent:FireServer(fruitName, count)
			playSound("Sell")
			-- Show selling notification
			local plantType = fruitName:gsub("Fruit$", "")
			local totalCoins = sellPrice * count
			showNotification("Sold " .. count .. "x " .. plantType .. " for " .. totalCoins .. " coins", THEME.WarningGold, "💰")
		end
	end)
	
	-- Hover effects
	sell1Button.MouseEnter:Connect(function()
		sell1Button.BackgroundColor3 = THEME.SellButtonHover
	end)
	sell1Button.MouseLeave:Connect(function()
		sell1Button.BackgroundColor3 = THEME.SellButton
	end)
	
	sellAllButton.MouseEnter:Connect(function()
		sellAllButton.BackgroundColor3 = THEME.GoldAccent
	end)
	sellAllButton.MouseLeave:Connect(function()
		sellAllButton.BackgroundColor3 = THEME.WarningGold
	end)
end

updateSellShop = function()
	if not screenGui then return end
	local sellWindow = screenGui:FindFirstChild("SellWindow")
	if not sellWindow then return end
	
	local leftPanel = sellWindow:FindFirstChild("LeftPanel")
	local sellScroll = leftPanel and leftPanel:FindFirstChild("ScrollingFrame") or sellWindow:FindFirstChild("ScrollingFrame")
	if not sellScroll then 
		warn("[UIHandler] Could not find sell ScrollingFrame")
		return 
	end
	
	-- Clear existing
	for _, child in ipairs(sellScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Add fruits from inventory
	if playerInventory.Fruits then
		for fruitName, count in pairs(playerInventory.Fruits) do
			if count > 0 then
				createSellItem(fruitName, count, sellScroll)
			end
		end
	end
end

-- =============================================================================
-- INITIALIZE
-- =============================================================================
function UIHandler.Initialize()
	print("[UIHandler] Initializing with pre-built UI...")
	
	-- Wait for UI to exist
	screenGui = playerGui:WaitForChild("FeyGardenUI", 10)
	if not screenGui then
		warn("[UIHandler] ❌ FeyGardenUI not found! Did you run the UISetup script?")
		warn("[UIHandler] Run this in Studio Command Bar: require(game.ReplicatedStorage.Setup.UISetup).CreateUI()")
		return
	end
	
	print("[UIHandler] Found FeyGardenUI!")
	
	-- Setup shop window
	local shopWindow = screenGui:WaitForChild("ShopWindow", 5)
	if shopWindow then
		local shopCloseButton = shopWindow:FindFirstChild("CloseButton")
		if shopCloseButton then
			shopCloseButton.MouseButton1Click:Connect(function()
				shopWindow.Visible = false
				NPCUIHandler.RestoreCamera()
				showHUD()
				playSound("WindowClose")
			end)
		end
	end
	
	-- Setup sell window
	local sellWindow = screenGui:WaitForChild("SellWindow", 5)
	if sellWindow then
		local sellCloseButton = sellWindow:FindFirstChild("CloseButton")
		if sellCloseButton then
			sellCloseButton.MouseButton1Click:Connect(function()
				sellWindow.Visible = false
				NPCUIHandler.RestoreCamera()
				showHUD()
				playSound("WindowClose")
			end)
		end
	end
	
	-- Setup pets window
	local petsWindow = screenGui:WaitForChild("PetsWindow", 5)
	if petsWindow then
		local titleBar = petsWindow:FindFirstChild("TitleBar")
		local petsCloseButton = titleBar and titleBar:FindFirstChild("CloseButton") or petsWindow:FindFirstChild("CloseButton")
		if petsCloseButton then
			petsCloseButton.MouseButton1Click:Connect(function()
				petsWindow.Visible = false
				NPCUIHandler.RestoreCamera()
				showHUD()
				playSound("WindowClose")
			end)
		end
	end
	
	-- Setup pets button
	local petsButton = screenGui:WaitForChild("PetsButton", 5)
	if petsButton then
		petsButton.MouseButton1Click:Connect(function()
			if petsWindow then
				petsWindow.Visible = not petsWindow.Visible
				if petsWindow.Visible then
					updatePetsWindow()
				end
			end
		end)
	end
	
	-- Setup proximity prompts
	local shopPart = workspace:WaitForChild(Config.World.ShopPartName, 10)
	if shopPart then
		local prompt = shopPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				if shopWindow then
					NPCUIHandler.MoveCameraToNPC("ShopCamera")
					populateShop()
					shopWindow.Visible = true
					hideHUD()
					playSound("WindowOpen")
				end
			end)
			print("[UIHandler] Shop ProximityPrompt connected")
		else
			warn("[UIHandler] No ProximityPrompt found on ShopPart")
		end
	else
		warn("[UIHandler] ShopPart not found:", Config.World.ShopPartName)
	end
	
	local sellPart = workspace:WaitForChild(Config.World.SellPartName, 10)
	if sellPart then
		local prompt = sellPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				if sellWindow then
					NPCUIHandler.MoveCameraToNPC("SellCamera")
					updateSellShop()
					sellWindow.Visible = true
					hideHUD()
					playSound("WindowOpen")
				end
			end)
			print("[UIHandler] Sell ProximityPrompt connected")
		else
			warn("[UIHandler] No ProximityPrompt found on SellPart")
		end
	else
		warn("[UIHandler] SellPart not found:", Config.World.SellPartName)
	end
	
	-- =============================================================================
	-- PROXIMITY PROMPTS FOR PET SHOP
	-- =============================================================================
	local petShopPart = workspace:WaitForChild("PetShopPart", 10)
	if petShopPart then
		local prompt = petShopPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				if petsWindow then
					NPCUIHandler.MoveCameraToNPC("PetCamera")
					updatePetsWindow()
					petsWindow.Visible = true
					hideHUD()
					playSound("WindowOpen")
				end
			end)
		else
			warn("[UIHandler] No ProximityPrompt found on PetShopPart")
		end
	else
		warn("[UIHandler] PetShopPart not found in workspace")
	end
	
	-- Listen for events
	local updateCurrencyEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_CURRENCY, 10)
	if updateCurrencyEvent then
		updateCurrencyEvent.OnClientEvent:Connect(updateCurrencyDisplay)
		print("[UIHandler] Connected to UPDATE_CURRENCY")
	end
	
	local updateInventoryEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_INVENTORY, 10)
	if updateInventoryEvent then
		updateInventoryEvent.OnClientEvent:Connect(updateInventoryDisplay)
		print("[UIHandler] Connected to UPDATE_INVENTORY")
	end
	
	local weatherChangedEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED, 10)
	if weatherChangedEvent then
		weatherChangedEvent.OnClientEvent:Connect(updateWeatherDisplay)
		print("[UIHandler] Connected to WEATHER_CHANGED")
	end
	
	local harvestFruitEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.HARVEST_FRUIT, 10)
	if harvestFruitEvent then
		harvestFruitEvent.OnClientEvent:Connect(function(fruitName, amount)
			showNotification("+" .. amount .. "x " .. fruitName, THEME.MainAccent, "🍎")
		end)
		print("[UIHandler] Connected to HARVEST_FRUIT")
	end
	
	-- Request initial player data from server
	local requestDataEvent = ReplicatedStorage:WaitForChild("RequestPlayerData", 10)
	if requestDataEvent then
		requestDataEvent:FireServer()
		print("[UIHandler] Requested initial player data")
	end
	
	print("[UIHandler] ✅ Initialized successfully!")
end

-- Export selected plant type getter
function UIHandler.GetSelectedPlantType()
	return selectedPlantType
end

return UIHandler
