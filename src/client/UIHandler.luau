-- UIHandler.luau
-- Simplified UI handler that uses pre-built UI from StarterGui
-- Run UISetup ModuleScript once in Studio first!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlantModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlantModule"))

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
local playerInventory = {Seeds = {}, Pets = {}, Fruits = {}}
local playerCoins = 0
local currentWeather = Constants.WEATHER_TYPES.SUNNY
local screenGui = nil

-- FANTASY FRAME THEME - Purple/Blue palette (matches UISetup)
local THEME = {
	-- Backgrounds: Deep plum nights
	ForestDark = Color3.fromRGB(18, 10, 28),
	ForestDeep = Color3.fromRGB(28, 16, 40),
	WoodBark = Color3.fromRGB(72, 44, 33),
	MossGreen = Color3.fromRGB(54, 24, 66),
	
	-- Panels: Leaf + wood violet tones
	WoodPanel = Color3.fromRGB(54, 24, 66),
	StonePanel = Color3.fromRGB(70, 33, 76),
	LeafPanel = Color3.fromRGB(96, 48, 103),
	
	-- Accents: Mushroom blues + soft golds
	TealGem = Color3.fromRGB(86, 108, 186),
	TealGlow = Color3.fromRGB(130, 150, 220),
	GoldLeaf = Color3.fromRGB(210, 168, 120),
	AmberGlow = Color3.fromRGB(180, 120, 150),
	
	-- Text: Lilac/off-white
	TextLight = Color3.fromRGB(228, 218, 240),
	TextGold = Color3.fromRGB(210, 190, 230),
	TextMoss = Color3.fromRGB(182, 154, 210),
	
	-- Borders: Vine strokes tinted
	VineStroke = Color3.fromRGB(120, 80, 140),
	GlowStroke = Color3.fromRGB(160, 140, 210),
	
	-- UI Elements
	Notification = Color3.fromRGB(86, 108, 186),
	NotificationAlt = Color3.fromRGB(130, 150, 220),
	PanelStroke = Color3.fromRGB(110, 70, 140),
}

local function getPetDisplayName(petType)
	local config = Constants.PET_CONFIG[petType]
	return (config and config.DisplayName) or petType
end

-- Forward declarations
local updateSellShop
local updatePetsWindow
local updateFullInventory
local showNotification
local updateShopInventoryGrid
local updateSellInventoryGrid

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
	local hotbarFrame = screenGui:FindFirstChild("HotbarFrame")
	local petsButton = screenGui:FindFirstChild("PetsButton")
	local navigationFrame = screenGui:FindFirstChild("NavigationFrame")
	
	if currencyFrame then currencyFrame.Visible = false end
	if weatherFrame then weatherFrame.Visible = false end
	if hotbarFrame then hotbarFrame.Visible = false end
	if petsButton then petsButton.Visible = false end
	if navigationFrame then navigationFrame.Visible = false end
end

local function showHUD()
	if not screenGui then return end
	local currencyFrame = screenGui:FindFirstChild("CurrencyFrame")
	local weatherFrame = screenGui:FindFirstChild("WeatherFrame")
	local hotbarFrame = screenGui:FindFirstChild("HotbarFrame")
	local petsButton = screenGui:FindFirstChild("PetsButton")
	local navigationFrame = screenGui:FindFirstChild("NavigationFrame")
	
	if currencyFrame then currencyFrame.Visible = true end
	if weatherFrame then weatherFrame.Visible = true end
	if hotbarFrame then hotbarFrame.Visible = true end
	if petsButton then petsButton.Visible = true end
	if navigationFrame then navigationFrame.Visible = true end
end

-- =============================================================================
-- HOTBAR AND INVENTORY MANAGEMENT
-- =============================================================================
local selectedSlot = 1
local hotbarData = {} -- {[slot] = {type = "Seed"/"Fruit", name = "string", count = number}}
local currentInventoryFilter = "All"

-- Helper to get item icon
local function getItemIcon(itemName, itemType)
	-- Check if it's a known plant type
	local plantConfig = Constants.PLANT_CONFIG[itemName]
	if plantConfig then
		return "🌱" -- Seed icon
	end
	
	-- Default icons based on type
	if itemType == "Fruit" then
		return "🍎"
	elseif itemType == "Seed" then
		return "🌱"
	end
	
	return "📦" -- Default
end

local function selectHotbarSlot(slotNumber)
	if not screenGui then return end
	local hotbarFrame = screenGui:FindFirstChild("HotbarFrame")
	if not hotbarFrame then return end
	
	-- Deselect old slot
	local oldSlot = hotbarFrame:FindFirstChild("Slot" .. selectedSlot)
	if oldSlot then
		local oldStroke = oldSlot:FindFirstChild("UIStroke")
		if oldStroke then
			oldStroke.Color = THEME.TealGem
			oldStroke.Thickness = 2
		end
	end
	
	-- Select new slot
	selectedSlot = slotNumber
	local newSlot = hotbarFrame:FindFirstChild("Slot" .. slotNumber)
	if newSlot then
		local newStroke = newSlot:FindFirstChild("UIStroke")
		if newStroke then
			newStroke.Color = THEME.GoldLeaf
			newStroke.Thickness = 3
		end
	end
	
	playSound("Click")
end

local function updateHotbar()
	if not screenGui then return end
	local hotbarFrame = screenGui:FindFirstChild("HotbarFrame")
	if not hotbarFrame then return end
	
	for i = 1, 6 do
		local slot = hotbarFrame:FindFirstChild("Slot" .. i)
		if slot then
			local itemIcon = slot:FindFirstChild("ItemIcon")
			local itemCount = slot:FindFirstChild("ItemCount")
			
			if hotbarData[i] then
				local data = hotbarData[i]
				
				-- Check actual inventory count
				local actualCount = 0
				if data.type == "Seed" and playerInventory.Seeds then
					actualCount = playerInventory.Seeds[data.name] or 0
				elseif data.type == "Fruit" and playerInventory.Fruits then
					actualCount = playerInventory.Fruits[data.name] or 0
				end
				
				-- Clear slot if item count is 0
				if actualCount == 0 then
					hotbarData[i] = nil
					if itemIcon then itemIcon.Text = "" end
					if itemCount then itemCount.Text = "" end
				else
					-- Update the count in hotbarData
					hotbarData[i].count = actualCount
					
					if itemIcon then
						itemIcon.Text = getItemIcon(data.name, data.type)
					end
					if itemCount and actualCount > 0 then
						itemCount.Text = tostring(actualCount)
					else
						if itemCount then itemCount.Text = "" end
					end
				end
			else
				if itemIcon then itemIcon.Text = "" end
				if itemCount then itemCount.Text = "" end
			end
		end
	end
end

local function createInventoryItem(itemName, itemCount, itemType)
	local item = Instance.new("Frame")
	item.Name = itemName
	item.Size = UDim2.new(0, 90, 0, 90)
	item.BackgroundColor3 = THEME.ForestDeep
	item.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = item
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = itemType == "Seed" and THEME.TealGem or THEME.GoldLeaf
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = item
	
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 45, 0, 45)
	icon.Position = UDim2.new(0.5, 0, 0, 15)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Text = getItemIcon(itemName, itemType)
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Parent = item
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -10, 0, 15)
	nameLabel.Position = UDim2.new(0, 5, 1, -28)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemName
	nameLabel.TextColor3 = THEME.TextLight
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 10
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = item
	
	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.Size = UDim2.new(0, 30, 0, 20)
	countLabel.Position = UDim2.new(1, -32, 1, -22)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = tostring(itemCount)
	countLabel.TextColor3 = THEME.TextLight
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextSize = 14
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.Parent = item
	
	local countStroke = Instance.new("UIStroke")
	countStroke.Color = THEME.ForestDark
	countStroke.Thickness = 2
	countStroke.Parent = countLabel
	
	-- Click to add to selected hotbar slot
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = item
	
	button.MouseButton1Click:Connect(function()
		-- Add to currently selected hotbar slot
		hotbarData[selectedSlot] = {type = itemType, name = itemName, count = itemCount}
		updateHotbar()
		playSound("Click")
		showNotification("Added " .. itemName .. " to Slot " .. selectedSlot, THEME.TealGem, getItemIcon(itemName, itemType))
	end)
	
	return item
end

local function updateFullInventory()
	if not screenGui or not playerInventory then return end
	local inventoryWindow = screenGui:FindFirstChild("InventoryWindow")
	if not inventoryWindow or not inventoryWindow.Visible then return end
	
	local gridContainer = inventoryWindow:FindFirstChild("GridContainer")
	if not gridContainer then return end
	
	-- Clear existing items
	for _, child in ipairs(gridContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Add seeds
	if currentInventoryFilter == "All" or currentInventoryFilter == "Seeds" then
		if playerInventory.Seeds then
			for seedName, count in pairs(playerInventory.Seeds) do
				if count > 0 then
					local item = createInventoryItem(seedName, count, "Seed")
					item.Parent = gridContainer
				end
			end
		end
	end
	
	-- Add fruits
	if currentInventoryFilter == "All" or currentInventoryFilter == "Fruits" then
		if playerInventory.Fruits then
			for fruitName, count in pairs(playerInventory.Fruits) do
				if count > 0 then
					local item = createInventoryItem(fruitName, count, "Fruit")
					item.Parent = gridContainer
				end
			end
		end
	end
end

local function filterInventory(filterType)
	currentInventoryFilter = filterType
	updateFullInventory()
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
showNotification = function(message, color, icon)
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
-- INVENTORY DISPLAY (updated by server)
-- =============================================================================
local function updateInventoryDisplay(inventory)
	if not screenGui then return end
	playerInventory = inventory
	
	-- Update hotbar with new counts
	for slot, data in pairs(hotbarData) do
		if data.type == "Seed" and inventory.Seeds then
			data.count = inventory.Seeds[data.name] or 0
		elseif data.type == "Fruit" and inventory.Fruits then
			data.count = inventory.Fruits[data.name] or 0
		end
	end
	updateHotbar()
	
	-- Update inventory window if it's open
	local inventoryWindow = screenGui:FindFirstChild("InventoryWindow")
	if inventoryWindow and inventoryWindow.Visible then
		updateFullInventory()
	end
	
	-- Update shop inventory grid if shop is open
	local shopWindow = screenGui:FindFirstChild("ShopWindow")
	if shopWindow and shopWindow.Visible then
		updateShopInventoryGrid()
	end
	
	-- Update sell shop if it's open
	local sellWindow = screenGui:FindFirstChild("SellWindow")
	if sellWindow and sellWindow.Visible then
		updateSellShop()
		updateSellInventoryGrid()
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
	
	-- Owned count
	local ownedCount = 0
	if itemType == "seed" then
		ownedCount = playerInventory.Seeds and playerInventory.Seeds[itemName] or 0
	elseif itemType == "pet" then
		ownedCount = (playerInventory.Pets and playerInventory.Pets[itemName]) and 1 or 0
	end
	
	local ownedLabel = Instance.new("TextLabel")
	ownedLabel.Size = UDim2.new(0.22, 0, 0.25, 0)
	ownedLabel.Position = UDim2.new(0.6, 0, 0.1, 0)
	ownedLabel.BackgroundTransparency = 1
	ownedLabel.Text = "Owned: " .. ownedCount
	ownedLabel.TextColor3 = THEME.TextMoss
	ownedLabel.Font = Enum.Font.Gotham
	ownedLabel.TextSize = 12
	ownedLabel.TextXAlignment = Enum.TextXAlignment.Right
	ownedLabel.ZIndex = 12
	ownedLabel.Parent = itemFrame
	
	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 0.3, 0)
	priceLabel.Position = UDim2.new(0.62, 0, 0.4, 0)
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
	
	-- Add only seeds (pets have their own window)
	for plantType, config in pairs(Constants.PLANT_CONFIG) do
		createShopItem(plantType, "seed", config, shopScroll)
	end
end

-- =============================================================================
-- PETS SYSTEM
-- =============================================================================
local function createPetItem(petType, container)
	local config = Constants.PET_CONFIG[petType]
	if not config then return end
	local displayName = getPetDisplayName(petType)
	
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
	nameLabel.Text = displayName
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
				showNotification("Equipped " .. displayName, THEME.TealGem, "🐾")
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

-- Update shop right panel with grid inventory
updateShopInventoryGrid = function()
	if not screenGui then return end
	local shopWindow = screenGui:FindFirstChild("ShopWindow")
	if not shopWindow then return end
	
	local rightPanel = shopWindow:FindFirstChild("RightPanel")
	local inventoryScroll = rightPanel and rightPanel:FindFirstChild("InventoryScroll")
	if not inventoryScroll then return end
	
	-- Clear existing items
	for _, child in ipairs(inventoryScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Add seeds from inventory as grid items
	if playerInventory.Seeds then
		for seedName, count in pairs(playerInventory.Seeds) do
			if count > 0 then
				local item = createInventoryItem(seedName, count, "Seed")
				if item then
					item.Parent = inventoryScroll
				end
			end
		end
	end
end

-- Update sell right panel with grid inventory
updateSellInventoryGrid = function()
	if not screenGui then return end
	local sellWindow = screenGui:FindFirstChild("SellWindow")
	if not sellWindow then return end
	
	local rightPanel = sellWindow:FindFirstChild("RightPanel")
	local inventoryScroll = rightPanel and rightPanel:FindFirstChild("InventoryScroll")
	if not inventoryScroll then return end
	
	-- Clear existing items
	for _, child in ipairs(inventoryScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Add fruits from inventory as grid items
	if playerInventory.Fruits then
		for fruitName, count in pairs(playerInventory.Fruits) do
			if count > 0 then
				local item = createInventoryItem(fruitName, count, "Fruit")
				if item then
					item.Parent = inventoryScroll
				end
			end
		end
	end
end

-- =============================================================================
-- INITIALIZE
-- =============================================================================
function UIHandler.Initialize()
	-- Hide Roblox default backpack
	local StarterGui = game:GetService("StarterGui")
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	
	-- Wait for UI to exist
	screenGui = playerGui:WaitForChild("FeyGardenUI", 10)
	if not screenGui then
		warn("[UIHandler] ❌ FeyGardenUI not found! Did you run the UISetup script?")
		warn("[UIHandler] Run this in Studio Command Bar: require(game.ReplicatedStorage.Setup.UISetup).CreateUI()")
		return
	end
	
	-- =============================================================================
	-- WINDOW REFERENCES
	-- =============================================================================
	local shopWindow = screenGui:WaitForChild("ShopWindow", 5)
	local sellWindow = screenGui:WaitForChild("SellWindow", 5)
	local petsWindow = screenGui:WaitForChild("PetsWindow", 5)
	local inventoryWindow = screenGui:WaitForChild("InventoryWindow", 5)
	
	-- =============================================================================
	-- NAVIGATION BUTTONS (Top Center)
	-- =============================================================================
	local navigationFrame = screenGui:WaitForChild("NavigationFrame", 5)
	if navigationFrame then
		-- SEEDS Button - Opens shop window
		local seedsButton = navigationFrame:FindFirstChild("SeedsButton")
		if seedsButton then
			seedsButton.MouseButton1Click:Connect(function()
				if shopWindow then
					NPCUIHandler.MoveCameraToNPC("ShopCamera")
					populateShop()
					updateShopInventoryGrid()
					shopWindow.Visible = true
					hideHUD()
					playSound("WindowOpen")
				end
			end)
		end
		
		-- GARDEN Button - Teleports to player's garden
		local gardenButton = navigationFrame:FindFirstChild("GardenButton")
		if gardenButton then
			gardenButton.MouseButton1Click:Connect(function()
				local player = game.Players.LocalPlayer
				local character = player.Character
				if not character then return end
				
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if not humanoidRootPart then return end
				
				-- Find player's assigned garden
				local gardensFolder = workspace:FindFirstChild(Config.World.GardensFolder)
				if not gardensFolder then 
					warn("[UIHandler] Gardens folder not found")
					return
				end
				
				-- Search for garden with player's name on the sign
				for _, garden in ipairs(gardensFolder:GetChildren()) do
					if garden:IsA("Folder") then
						local playerSign = garden:FindFirstChild(Config.World.PlayerSignName)
						if playerSign then
							local signPart = playerSign:FindFirstChild(Config.World.PlayerSignPartName)
							if signPart then
								local surfaceGui = signPart:FindFirstChild("SurfaceGui")
								if surfaceGui then
									local textLabel = surfaceGui:FindFirstChild("TextLabel")
									if textLabel and textLabel.Text == player.Name then
										-- Found player's garden, teleport to TpPart or Floor
										local tpPart = garden:FindFirstChild(Config.World.TeleportPartName) or garden:FindFirstChild(Config.World.FloorName)
										if tpPart then
											humanoidRootPart.CFrame = tpPart.CFrame + Vector3.new(0, 5, 0)
											playSound("Click")
											return
										end
									end
								end
							end
						end
					end
				end
				
				warn("[UIHandler] Could not find player's garden")
			end)
		end
		
		-- SELL Button - Opens sell window
		local sellButton = navigationFrame:FindFirstChild("SellButton")
		if sellButton then
			sellButton.MouseButton1Click:Connect(function()
				if sellWindow then
					NPCUIHandler.MoveCameraToNPC("SellCamera")
					updateSellShop()
					updateSellInventoryGrid()
					sellWindow.Visible = true
					hideHUD()
					playSound("WindowOpen")
				end
			end)
		end
	end
	
	-- =============================================================================
	-- SHOP WINDOW SETUP
	-- =============================================================================
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
	
	-- =============================================================================
	-- SELL WINDOW SETUP
	-- =============================================================================
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
	
	-- =============================================================================
	-- PETS WINDOW SETUP
	-- =============================================================================
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
					updateShopInventoryGrid()
					shopWindow.Visible = true
					hideHUD()
					playSound("WindowOpen")
				end
			end)
-- -- print("[UIHandler] Shop ProximityPrompt connected")
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
					updateSellInventoryGrid()
					sellWindow.Visible = true
					hideHUD()
					playSound("WindowOpen")
				end
			end)
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
-- -- print("[UIHandler] Shop ProximityPrompt connected")
		else
			warn("[UIHandler] No ProximityPrompt found on PetShopPart")
		end
	else
		warn("[UIHandler] PetShopPart not found in workspace")
	end
	
	-- =============================================================================
	-- INVENTORY WINDOW (Press B)
	-- =============================================================================
	if inventoryWindow then
		local invCloseButton = inventoryWindow:FindFirstChild("TitleBar") and inventoryWindow.TitleBar:FindFirstChild("CloseButton")
		if invCloseButton then
			invCloseButton.MouseButton1Click:Connect(function()
				inventoryWindow.Visible = false
				playSound("WindowClose")
			end)
		end
		
		-- Set up tab buttons
		local tabContainer = inventoryWindow:FindFirstChild("TabContainer")
		if tabContainer then
			local seedsTab = tabContainer:FindFirstChild("SeedsTab")
			local fruitsTab = tabContainer:FindFirstChild("FruitsTab")
			local allTab = tabContainer:FindFirstChild("AllTab")
			
			if seedsTab then
				seedsTab.MouseButton1Click:Connect(function()
					filterInventory("Seeds")
				end)
			end
			if fruitsTab then
				fruitsTab.MouseButton1Click:Connect(function()
					filterInventory("Fruits")
				end)
			end
			if allTab then
				allTab.MouseButton1Click:Connect(function()
					filterInventory("All")
				end)
			end
		end
		
-- -- print("[UIHandler] Inventory window set up")
	end
	
	-- =============================================================================
	-- HOTBAR SETUP - Click slots to select
	-- =============================================================================
	local hotbarFrame = screenGui:WaitForChild("HotbarFrame", 5)
	if hotbarFrame then
		for i = 1, 6 do
			local slot = hotbarFrame:FindFirstChild("Slot" .. i)
			if slot then
				local slotButton = slot:FindFirstChild("SlotButton")
				if slotButton then
					slotButton.MouseButton1Click:Connect(function()
						selectHotbarSlot(i)
					end)
				end
			end
		end
		-- Select slot 1 by default
		selectHotbarSlot(1)
	end
	
	-- =============================================================================
	-- KEYBOARD CONTROLS
	-- =============================================================================
	local UserInputService = game:GetService("UserInputService")
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Press B to toggle inventory
		if input.KeyCode == Enum.KeyCode.B and inventoryWindow then
			inventoryWindow.Visible = not inventoryWindow.Visible
			if inventoryWindow.Visible then
				updateFullInventory()
				playSound("WindowOpen")
			else
				playSound("WindowClose")
			end
		end
		
		-- Press 1-6 to select hotbar slots
		local numberKeys = {
			[Enum.KeyCode.One] = 1,
			[Enum.KeyCode.Two] = 2,
			[Enum.KeyCode.Three] = 3,
			[Enum.KeyCode.Four] = 4,
			[Enum.KeyCode.Five] = 5,
			[Enum.KeyCode.Six] = 6,
		}
		
		if numberKeys[input.KeyCode] then
			selectHotbarSlot(numberKeys[input.KeyCode])
		end
	end)
	
	-- Listen for events
	local updateCurrencyEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_CURRENCY, 10)
	if updateCurrencyEvent then
		updateCurrencyEvent.OnClientEvent:Connect(updateCurrencyDisplay)
	end
	
	local updateInventoryEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_INVENTORY, 10)
	if updateInventoryEvent then
		updateInventoryEvent.OnClientEvent:Connect(updateInventoryDisplay)
	end
	
	local weatherChangedEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED, 10)
	if weatherChangedEvent then
		weatherChangedEvent.OnClientEvent:Connect(updateWeatherDisplay)
	end
	
	local harvestFruitEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.HARVEST_FRUIT, 10)
	if harvestFruitEvent then
		harvestFruitEvent.OnClientEvent:Connect(function(fruitName, amount)
			showNotification("+" .. amount .. "x " .. fruitName, THEME.MainAccent, "🍎")
		end)
	end
	
	-- Request initial player data from server
	local requestDataEvent = ReplicatedStorage:WaitForChild("RequestPlayerData", 10)
	if requestDataEvent then
		requestDataEvent:FireServer()
	end
end

-- Export selected plant type getter (from hotbar)
function UIHandler.GetSelectedPlantType()
	-- Get the item in the currently selected hotbar slot
	local slotData = hotbarData[selectedSlot]
	if slotData and slotData.type == "Seed" and slotData.count > 0 then
		return slotData.name
	end
	return nil
end

return UIHandler
