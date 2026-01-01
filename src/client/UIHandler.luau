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
local hudGroup: Instance? = nil
local windowGroup: Instance? = nil
local overlayGroup: Instance? = nil

-- NPCUIHandler for camera control
local NPCUIHandler = require(script.Parent:WaitForChild("NPCUIHandler"))

-- ToolController for tool equipping
local ToolController
pcall(function()
	ToolController = require(script.Parent:WaitForChild("ToolController"))
end)

-- ItemHoldController for holding seeds/fruits in hand
local ItemHoldController
pcall(function()
	ItemHoldController = require(script.Parent:WaitForChild("ItemHoldController"))
end)

print("[UIHandler] ItemHoldController loaded:", ItemHoldController ~= nil)

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
local uiRoot: Instance? = nil

-- Ready state for LoadingScreen synchronization
UIHandler.IsReady = false
UIHandler.ReadyEvent = Instance.new("BindableEvent")

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
	
	-- Button States
	SellButton = Color3.fromRGB(86, 108, 186),
	SellButtonHover = Color3.fromRGB(110, 135, 210),
	GoldAccent = Color3.fromRGB(230, 190, 100),
	WarningGold = Color3.fromRGB(200, 160, 80),
}

local function getPetDisplayName(petType)
	local config = Constants.PET_CONFIG[petType]
	return (config and config.DisplayName) or petType
end

-- Get rarity color for pets
local function getRarityColor(petType)
	local rarity = Constants.PET_RARITIES and Constants.PET_RARITIES[petType]
	if rarity and Constants.RARITY_COLORS then
		return Constants.RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
	end
	return Color3.new(1, 1, 1)
end

-- Forward declarations
local updateSellShop
local updatePetsWindow
local updateFullInventory
local showNotification
local updateShopInventoryGrid
local updateEggShop
local updateSellInventoryGrid
local updatePetShopWindow
local updateGearShopWindow
local isPetEquipped
local isPetInGarden
local createPetShopPreviewItem

-- Helper to play UI sounds
local function playSound(soundName)
	if AudioManager then
		AudioManager.PlaySFX(soundName)
	end
end

local function getSidePanel()
	return hudGroup and hudGroup:FindFirstChild("SidePanel")
end

local function findSideButton(name: string)
	local panel = getSidePanel()
	if panel then
		local button = panel:FindFirstChild(name)
		if button then
			return button
		end
	end

	return hudGroup and hudGroup:FindFirstChild(name)
end

-- Helper to hide/show HUD elements (for shop windows)
local function hideHUD()
	if not screenGui then return end
	local currencyFrame = hudGroup and hudGroup:FindFirstChild("CurrencyFrame")
	local sidePanel = getSidePanel()
	local weatherFrame = (sidePanel and sidePanel:FindFirstChild("WeatherFrame")) or (hudGroup and hudGroup:FindFirstChild("WeatherFrame"))
	local petsButton = hudGroup and hudGroup:FindFirstChild("PetsButton")
	local navigationFrame = hudGroup and hudGroup:FindFirstChild("NavigationFrame")

	if currencyFrame then currencyFrame.Visible = false end
	if sidePanel then sidePanel.Visible = false end
	if weatherFrame then weatherFrame.Visible = false end
	if petsButton then petsButton.Visible = false end
	if navigationFrame then navigationFrame.Visible = false end
	-- NOTE: Hotbar stays visible
end

local function showHUD()
	if not screenGui then return end
	local currencyFrame = hudGroup and hudGroup:FindFirstChild("CurrencyFrame")
	local sidePanel = getSidePanel()
	local weatherFrame = (sidePanel and sidePanel:FindFirstChild("WeatherFrame")) or (hudGroup and hudGroup:FindFirstChild("WeatherFrame"))
	local hotbarFrame = hudGroup and hudGroup:FindFirstChild("HotbarFrame")
	local petsButton = hudGroup and hudGroup:FindFirstChild("PetsButton")
	local navigationFrame = hudGroup and hudGroup:FindFirstChild("NavigationFrame")

	if currencyFrame then currencyFrame.Visible = true end
	if sidePanel then sidePanel.Visible = true end
	if weatherFrame then weatherFrame.Visible = true end
	if hotbarFrame then hotbarFrame.Visible = true end
	if petsButton then petsButton.Visible = true end
	if navigationFrame then navigationFrame.Visible = true end
end

-- =============================================================================
-- HOTBAR AND INVENTORY MANAGEMENT
-- =============================================================================
local selectedSlot = 1
-- {[slot] = {type = "Seed"/"Fruit"/"Tool", name = "string", count = number (nil for tools)}}
local hotbarData = {
	[1] = {type = "Tool", name = "WateringCan"},
	[2] = {type = "Tool", name = "Shovel"},
}

-- Hotbar slots 1 and 2 are reserved for core tools
local lockedToolSlots = {
	[1] = {type = "Tool", name = "WateringCan"},
	[2] = {type = "Tool", name = "Shovel"},
}

local function isLockedToolSlot(slotIndex: number): boolean
	return lockedToolSlots[slotIndex] ~= nil
end

local function enforceToolSlots()
	for slotIndex, data in pairs(lockedToolSlots) do
		local slotData = hotbarData[slotIndex]
		if not slotData or slotData.type ~= "Tool" or slotData.name ~= data.name then
			hotbarData[slotIndex] = {type = "Tool", name = data.name}
		end
	end
end

local function getFallbackHotbarSlot(): number
	for i = 3, 6 do
		local slotData = hotbarData[i]
		if not slotData or slotData.type ~= "Tool" then
			return i
		end
	end

	return 3
end

-- Ensure default tool slots are set on load
enforceToolSlots()

local currentInventoryFilter = "All"

-- Helper to get item icon
local function getItemIcon(itemName, itemType)
	-- Tool icons
	if itemType == "Tool" then
		if itemName == "WateringCan" then
			return "💧"
		elseif itemName == "Shovel" then
			return "🪓"
		end
		return "🔧"
	end
	
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
	enforceToolSlots()
	if not screenGui then return end
	local hotbarFrame = hudGroup and hudGroup:FindFirstChild("HotbarFrame")
	if not hotbarFrame then return end
	local slotsContainer = hotbarFrame:FindFirstChild("Slots") or hotbarFrame
	
	-- Deselect old slot
	local oldSlot = slotsContainer:FindFirstChild("Slot" .. selectedSlot)
	if oldSlot then
		local oldStroke = oldSlot:FindFirstChild("UIStroke")
		if oldStroke then
			oldStroke.Color = THEME.TealGem
			oldStroke.Thickness = 2
		end
	end
	
	-- Handle tool/item equipping/unequipping
	local newSlotData = hotbarData[slotNumber]
	local oldSlotData = hotbarData[selectedSlot]
	
	print("[UIHandler DEBUG] selectHotbarSlot:", slotNumber)
	print("[UIHandler DEBUG] oldSlotData:", oldSlotData and oldSlotData.type or "nil", oldSlotData and oldSlotData.name or "")
	print("[UIHandler DEBUG] newSlotData:", newSlotData and newSlotData.type or "nil", newSlotData and newSlotData.name or "")
	
	-- Unequip old item/tool
	if oldSlotData then
		if oldSlotData.type == "Tool" and ToolController then
			ToolController.UnequipTool()
		elseif (oldSlotData.type == "Seed" or oldSlotData.type == "Fruit") and ItemHoldController then
			print("[UIHandler DEBUG] Unholding old item")
			ItemHoldController.UnholdItem()
		end
	end
	
	-- Equip new item/tool
	if newSlotData then
		if newSlotData.type == "Tool" and ToolController then
			ToolController.EquipTool(newSlotData.name)
		elseif (newSlotData.type == "Seed" or newSlotData.type == "Fruit") and ItemHoldController then
			print("[UIHandler DEBUG] Holding new item:", newSlotData.type, newSlotData.name)
			-- Generate or use existing weight for the item
			local weight = newSlotData.weight or 1.0
			if not newSlotData.weight then
				-- Generate random weight if not already set
				local sizeWeight = Constants.GenerateRandomSizeWeight("Plant")
				weight = sizeWeight.Weight
				newSlotData.weight = weight
			end
			local success = ItemHoldController.HoldItem(newSlotData.type, newSlotData.name, weight)
			print("[UIHandler DEBUG] HoldItem result:", success)
		else
			print("[UIHandler DEBUG] Empty slot or unknown type")
		end
	end
	
	-- Select new slot
	selectedSlot = slotNumber
	local newSlot = slotsContainer:FindFirstChild("Slot" .. slotNumber)
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
	enforceToolSlots()
	if not screenGui then return end
	local hotbarFrame = hudGroup and hudGroup:FindFirstChild("HotbarFrame")
	if not hotbarFrame then return end
	local slotsContainer = hotbarFrame:FindFirstChild("Slots") or hotbarFrame
	
	for i = 1, 6 do
		local slot = slotsContainer:FindFirstChild("Slot" .. i)
		if slot then
			local itemIcon = slot:FindFirstChild("ItemIcon")
			local itemCount = slot:FindFirstChild("ItemCount")
			
			if hotbarData[i] then
				local data = hotbarData[i]
				
				-- Tools don't have counts and are always available
				if data.type == "Tool" then
					if itemIcon then
						itemIcon.Text = getItemIcon(data.name, data.type)
					end
					if itemCount then
						itemCount.Text = "" -- No count for tools
					end
				else
					-- Check actual inventory count for Seeds/Fruits
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
				end
			else
				if itemIcon then itemIcon.Text = "" end
				if itemCount then itemCount.Text = "" end
			end
		end
	end
end

local function createInventoryItem(itemName, itemCount, itemType, container)
	-- Find and clone the template
	local template = container and container:FindFirstChild("InventoryItemTemplate")
	if not template then
		warn("[UIHandler] InventoryItemTemplate not found in container")
		return nil
	end
	
	local item = template:Clone()
	item.Name = itemName
	item.Visible = true
	
	-- Update stroke color based on item type
	local stroke = item:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = itemType == "Seed" and THEME.TealGem or THEME.GoldLeaf
	end
	
	-- Update icon
	local itemIcon = item:FindFirstChild("ItemIcon")
	if itemIcon then
		itemIcon.Text = getItemIcon(itemName, itemType)
	end
	
	-- Update name
	local nameLabel = item:FindFirstChild("ItemName")
	if nameLabel then
		nameLabel.Text = itemName
	end
	
	-- Update count
	local countBadge = item:FindFirstChild("CountBadge")
	local countLabel = countBadge and countBadge:FindFirstChild("CountLabel")
	if countLabel then
		countLabel.Text = "x" .. tostring(itemCount)
	end
	
	-- Connect click handler
	local clickButton = item:FindFirstChild("ClickButton")
	if clickButton then
		clickButton.MouseButton1Click:Connect(function()
			enforceToolSlots()
			local targetSlot = selectedSlot
			local notificationColor = THEME.TealGem
			local notificationText = "Added " .. itemName .. " to Slot " .. targetSlot
			local notificationIcon = getItemIcon(itemName, itemType)

			if isLockedToolSlot(targetSlot) then
				targetSlot = getFallbackHotbarSlot()
				notificationColor = THEME.AmberGlow
				notificationText = "Slots 1-2 are for tools. Added to Slot " .. targetSlot .. " instead"
			end

			hotbarData[targetSlot] = {type = itemType, name = itemName, count = itemCount}
			selectHotbarSlot(targetSlot)
			updateHotbar()
			playSound("Click")
			showNotification(notificationText, notificationColor, notificationIcon)
		end)
	end
	
	item.Parent = container
	return item
end

local function updateFullInventory()
	if not screenGui or not playerInventory then return end
	local inventoryWindow = windowGroup and windowGroup:FindFirstChild("InventoryWindow")
	if not inventoryWindow or not inventoryWindow.Visible then return end
	
	local gridContainer = inventoryWindow:FindFirstChild("GridContainer")
	if not gridContainer then return end
	
	-- Clear existing items (preserve template)
	for _, child in ipairs(gridContainer:GetChildren()) do
		if child:IsA("Frame") and not string.find(child.Name, "Template") then
			child:Destroy()
		end
	end
	
	-- Add seeds
	if currentInventoryFilter == "All" or currentInventoryFilter == "Seeds" then
		if playerInventory.Seeds then
			for seedName, count in pairs(playerInventory.Seeds) do
				if count > 0 then
					createInventoryItem(seedName, count, "Seed", gridContainer)
				end
			end
		end
	end
	
	-- Add fruits
	if currentInventoryFilter == "All" or currentInventoryFilter == "Fruits" then
		if playerInventory.Fruits then
			for fruitName, count in pairs(playerInventory.Fruits) do
				if count > 0 then
					createInventoryItem(fruitName, count, "Fruit", gridContainer)
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
	local container = hudGroup and hudGroup:FindFirstChild("NotificationContainer")
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
	local currencyFrame = hudGroup and hudGroup:FindFirstChild("CurrencyFrame")
	local coinLabel = currencyFrame and currencyFrame:FindFirstChild("CoinLabel")
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
	enforceToolSlots()
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
	local inventoryWindow = windowGroup and windowGroup:FindFirstChild("InventoryWindow")
	if inventoryWindow and inventoryWindow.Visible then
		updateFullInventory()
	end
	
	-- Update shop inventory grid if shop is open
	local shopWindow = windowGroup and windowGroup:FindFirstChild("ShopWindow")
	if shopWindow and shopWindow.Visible then
		updateShopInventoryGrid()
	end
	
	-- Update sell shop if it's open
	local sellWindow = windowGroup and windowGroup:FindFirstChild("SellWindow")
	if sellWindow and sellWindow.Visible then
		updateSellShop()
		updateSellInventoryGrid()
	end
	
	-- Update pets window if it's open
	local petsWindow = windowGroup and windowGroup:FindFirstChild("PetsWindow")
	if petsWindow and petsWindow.Visible then
		updatePetsWindow()
		updateEggShop()
	end
	
	-- Update pet shop window if open
	local petShopWindow = windowGroup and windowGroup:FindFirstChild("PetShopWindow")
	if petShopWindow and petShopWindow.Visible then
		if updatePetShopWindow then
			updatePetShopWindow()
		end
	end
	
	-- Update gear shop window if open
	local gearShopWindow = windowGroup and windowGroup:FindFirstChild("GearShopWindow")
	if gearShopWindow and gearShopWindow.Visible then
		updateGearShopWindow()
	end
end

-- =============================================================================
-- WEATHER UPDATE
-- =============================================================================
local function updateWeatherDisplay(weather)
	if not screenGui then return end
	currentWeather = weather
	local weatherFrame = findSideButton("WeatherFrame") or findSideButton("WeatherButton")
	if not weatherFrame then return end
	local weatherLabel = weatherFrame:FindFirstChild("WeatherLabel") or weatherFrame:FindFirstChild("Label")
	if not weatherLabel then return end
	
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
-- SHOP SYSTEM WITH ROTATION AND STOCK
-- =============================================================================

-- Shop inventory state (will be updated from server)
local currentShopInventory = {}

-- Forward declarations
local populateShop

local function createShopItem(itemName, itemType, config, container, stock)
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
	
	local soldOut = stock ~= nil and stock <= 0
	local rarity = Constants.PLANT_RARITIES and Constants.PLANT_RARITIES[itemName] or "Common"
	local rarityColor = Constants.RARITY_COLORS and Constants.RARITY_COLORS[rarity] or THEME.TextMoss
	
	-- Find and clone the template from the container
	local template = container:FindFirstChild("ShopItemTemplate")
	if not template then
		warn("[UIHandler] ShopItemTemplate not found in container, falling back to old method")
		-- Fallback: create from scratch (old method)
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = itemName
		itemFrame.Size = UDim2.new(1, 0, 0, 80)
		itemFrame.BackgroundColor3 = soldOut and THEME.StonePanel or THEME.WoodPanel
		itemFrame.BorderSizePixel = 0
		itemFrame.ZIndex = 11
		itemFrame.Parent = container
		return
	end
	
	-- Clone the template
	local itemCard = template:Clone()
	itemCard.Name = itemName
	itemCard.Visible = true
	
	-- Update sold out appearance
	if soldOut then
		itemCard.BackgroundColor3 = THEME.StonePanel
		local stroke = itemCard:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Transparency = 0.6 end
	else
		local stroke = itemCard:FindFirstChildOfClass("UIStroke")
		if stroke then 
			stroke.Color = rarityColor 
			stroke.Transparency = 0.3
		end
	end
	
	-- Update icon container
	local iconContainer = itemCard:FindFirstChild("IconContainer")
	if iconContainer then
		local itemIcon = iconContainer:FindFirstChild("ItemIcon")
		if itemIcon then
			itemIcon.Text = itemType == "seed" and "🌱" or "🐾"
			itemIcon.TextColor3 = itemType == "seed" and (config.EmitsLight and THEME.TextGold or THEME.TextMoss) or THEME.TealGlow
			itemIcon.TextTransparency = soldOut and 0.5 or 0
		end
	end
	
	-- Update info container
	local infoContainer = itemCard:FindFirstChild("InfoContainer")
	if infoContainer then
		local nameLabel = infoContainer:FindFirstChild("ItemName")
		if nameLabel then
			nameLabel.Text = itemName
			nameLabel.TextColor3 = soldOut and THEME.TextMoss or THEME.TextLight
		end
		
		local rarityLabel = infoContainer:FindFirstChild("ItemRarity")
		if rarityLabel then
			rarityLabel.Text = rarity
			rarityLabel.TextColor3 = rarityColor
		end
		
		local stockLabel = infoContainer:FindFirstChild("ItemStock")
		if stockLabel then
			if stock ~= nil then
				stockLabel.Text = soldOut and "SOLD OUT" or ("Stock: " .. stock)
				stockLabel.TextColor3 = soldOut and Color3.fromRGB(255, 100, 100) or THEME.TextMoss
			else
				stockLabel.Text = itemType == "seed" and ("Grows in " .. (config.GrowthTime or "?") .. "s") or ""
			end
		end
	end
	
	-- Update action container
	local actionContainer = itemCard:FindFirstChild("ActionContainer")
	if actionContainer then
		local priceLabel = actionContainer:FindFirstChild("PriceLabel")
		if priceLabel then
			priceLabel.Text = "💰 " .. price
		end
		
		local buyButton = actionContainer:FindFirstChild("BuyButton")
		if buyButton then
			buyButton.Text = soldOut and "—" or "🛒 BUY"
			buyButton.BackgroundColor3 = soldOut and THEME.StonePanel or THEME.TealGem
			buyButton.Active = not soldOut
			
			if not soldOut then
				buyButton.MouseButton1Click:Connect(function()
					playSound("ButtonClick")
					if itemType == "seed" then
						local buyEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_SEED)
						if buyEvent then
							buyEvent:FireServer(itemName, 1) -- Buy 1 seed
							-- Optimistically update local stock
							if currentShopInventory and currentShopInventory[itemName] and currentShopInventory[itemName].Stock then
								currentShopInventory[itemName].Stock = math.max(0, currentShopInventory[itemName].Stock - 1)
								populateShop()
								updateShopInventoryGrid()
							end
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
		end
	end
	
	itemCard.Parent = container
end

populateShop = function()
	if not screenGui then return end
	local shopWindow = windowGroup and windowGroup:FindFirstChild("ShopWindow")
	if not shopWindow then return end
	
	local leftPanel = shopWindow:FindFirstChild("LeftPanel")
	local shopScroll = leftPanel and leftPanel:FindFirstChild("ScrollingFrame") or shopWindow:FindFirstChild("ScrollingFrame")
	if not shopScroll then 
		warn("[UIHandler] Could not find shop ScrollingFrame")
		return 
	end
	
	-- Clear existing items (but preserve templates and layouts)
	for _, child in ipairs(shopScroll:GetChildren()) do
		if child:IsA("Frame") and not child.Name:find("Template") then 
			child:Destroy() 
		end
	end
	
	-- Check if we have rotating shop inventory
	if currentShopInventory and next(currentShopInventory) ~= nil then
		-- Use rotating shop inventory with stock
		for plantType, seedData in pairs(currentShopInventory) do
			local config = Constants.PLANT_CONFIG[plantType]
			if config then
				local stock = seedData and seedData.Stock or nil
				createShopItem(plantType, "seed", config, shopScroll, stock)
			end
		end
	else
		-- Fallback: show all seeds (no stock limit)
		for plantType, config in pairs(Constants.PLANT_CONFIG) do
			createShopItem(plantType, "seed", config, shopScroll, nil)
		end
	end
end

-- Note: updateShopInventoryGrid is defined later in Initialize section
-- This local alias exists for backward compatibility
local function refreshShopGrid()
	populateShop()
end

-- =============================================================================
-- EGG SHOP SYSTEM (Gacha)
-- =============================================================================
local function createEggShopItem(eggType, config, container)
	if not config then
		warn("[UIHandler] No config for egg type:", eggType)
		return
	end
	
	local price = config.Price or 100
	local rarityColor = Constants.RARITY_COLORS and Constants.RARITY_COLORS[eggType] or THEME.TextLight
	local ownedCount = playerInventory.Eggs and playerInventory.Eggs[eggType] or 0
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = eggType .. "Egg"
	itemFrame.Size = UDim2.new(1, 0, 0, 100)
	itemFrame.BackgroundColor3 = THEME.WoodPanel
	itemFrame.BorderSizePixel = 0
	itemFrame.ZIndex = 11
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = itemFrame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(THEME.WoodPanel, THEME.ForestDeep)
	gradient.Rotation = 90
	gradient.Parent = itemFrame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Color = rarityColor
	stroke.Transparency = 0.2
	stroke.Parent = itemFrame
	
	-- Egg image
	local eggImage = Instance.new("ImageLabel")
	eggImage.Size = UDim2.new(0, 70, 0, 85)
	eggImage.Position = UDim2.new(0, 8, 0, 8)
	eggImage.BackgroundTransparency = 1
	eggImage.Image = config.ImageId or ""
	eggImage.ScaleType = Enum.ScaleType.Fit
	eggImage.ZIndex = 12
	eggImage.Parent = itemFrame
	
	-- Egg name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 0, 24)
	nameLabel.Position = UDim2.new(0.2, 0, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = eggType .. " Egg"
	nameLabel.TextColor3 = rarityColor
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 12
	nameLabel.Parent = itemFrame
	
	-- Drop chances info
	local dropChances = config.DropChances or {}
	local chanceText = ""
	for rarity, chance in pairs(dropChances) do
		if chance > 0 then
			chanceText = chanceText .. rarity .. ": " .. (chance * 100) .. "% "
		end
	end
	
	local chanceLabel = Instance.new("TextLabel")
	chanceLabel.Size = UDim2.new(0.55, 0, 0, 16)
	chanceLabel.Position = UDim2.new(0.2, 0, 0, 34)
	chanceLabel.BackgroundTransparency = 1
	chanceLabel.Text = chanceText
	chanceLabel.TextColor3 = THEME.TextMoss
	chanceLabel.Font = Enum.Font.Gotham
	chanceLabel.TextSize = 10
	chanceLabel.TextXAlignment = Enum.TextXAlignment.Left
	chanceLabel.TextWrapped = true
	chanceLabel.ZIndex = 12
	chanceLabel.Parent = itemFrame
	
	-- Owned count
	local ownedLabel = Instance.new("TextLabel")
	ownedLabel.Size = UDim2.new(0.25, 0, 0, 16)
	ownedLabel.Position = UDim2.new(0.2, 0, 0, 54)
	ownedLabel.BackgroundTransparency = 1
	ownedLabel.Text = "Owned: " .. ownedCount
	ownedLabel.TextColor3 = THEME.TextMoss
	ownedLabel.Font = Enum.Font.Gotham
	ownedLabel.TextSize = 12
	ownedLabel.TextXAlignment = Enum.TextXAlignment.Left
	ownedLabel.ZIndex = 12
	ownedLabel.Parent = itemFrame
	
	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 0, 20)
	priceLabel.Position = UDim2.new(0.2, 0, 0, 72)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 " .. price
	priceLabel.TextColor3 = THEME.TextGold
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 14
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.ZIndex = 12
	priceLabel.Parent = itemFrame
	
	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.2, 0, 0, 35)
	buyButton.Position = UDim2.new(0.78, 0, 0, 10)
	buyButton.BackgroundColor3 = THEME.TealGem
	buyButton.Text = "BUY"
	buyButton.TextColor3 = THEME.TextLight
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 14
	buyButton.ZIndex = 12
	buyButton.Parent = itemFrame
	
	Instance.new("UICorner", buyButton).CornerRadius = UDim.new(0, 8)
	
	buyButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		local buyEggEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_EGG)
		if buyEggEvent then
			buyEggEvent:FireServer(eggType)
			playSound("Purchase")
		end
	end)
	
	buyButton.MouseEnter:Connect(function()
		buyButton.BackgroundColor3 = THEME.TealGlow
	end)
	buyButton.MouseLeave:Connect(function()
		buyButton.BackgroundColor3 = THEME.TealGem
	end)
	
	-- Open button (if player has eggs)
	local openButton = Instance.new("TextButton")
	openButton.Size = UDim2.new(0.2, 0, 0, 35)
	openButton.Position = UDim2.new(0.78, 0, 0, 52)
	openButton.BackgroundColor3 = ownedCount > 0 and THEME.AmberGlow or THEME.ForestDark
	openButton.Text = "OPEN"
	openButton.TextColor3 = THEME.TextLight
	openButton.Font = Enum.Font.GothamBold
	openButton.TextSize = 14
	openButton.ZIndex = 12
	openButton.Parent = itemFrame
	
	Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 8)
	
	if ownedCount > 0 then
		openButton.MouseButton1Click:Connect(function()
			playSound("ButtonClick")
			local openEggEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.OPEN_EGG)
			if openEggEvent then
				openEggEvent:FireServer(eggType)
				-- Animation handled by EggOpeningUI listening to EggOpened event
			end
		end)
		
		openButton.MouseEnter:Connect(function()
			openButton.BackgroundColor3 = THEME.GoldLeaf
		end)
		openButton.MouseLeave:Connect(function()
			openButton.BackgroundColor3 = THEME.AmberGlow
		end)
	end
end

-- Update egg shop display
updateEggShop = function()
	if not screenGui then return end
	local petsWindow = windowGroup and windowGroup:FindFirstChild("PetsWindow")
	if not petsWindow then return end
	
	-- Look for an egg shop section in the right panel or create in left panel
	local rightPanel = petsWindow:FindFirstChild("RightPanel")
	local eggScroll = rightPanel and rightPanel:FindFirstChild("EggScroll")
	
	-- If no dedicated egg scroll, use a section in the left panel or create one
	if not eggScroll then
		local leftPanel = petsWindow:FindFirstChild("LeftPanel")
		eggScroll = leftPanel and leftPanel:FindFirstChild("EggScroll")
	end
	
	-- Fallback: try to find any ScrollingFrame we can use for eggs
	if not eggScroll then
		-- Create egg section dynamically in the pets scroll
		return
	end
	
	-- Clear existing egg items
	for _, child in ipairs(eggScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Add egg types
	if Constants.EGG_CONFIG then
		for eggType, config in pairs(Constants.EGG_CONFIG) do
			createEggShopItem(eggType, config, eggScroll)
		end
	end
end

-- =============================================================================
-- PET SHOP WINDOW (Separate: Egg Shop + Pet Inventory Preview)
-- =============================================================================
updatePetShopWindow = function()
	if not screenGui then return end
	local petShopWindow = windowGroup and windowGroup:FindFirstChild("PetShopWindow")
	if not petShopWindow then 
		warn("[UIHandler] PetShopWindow not found")
		return 
	end
	
	-- LEFT PANEL - Egg Shop
	local leftPanel = petShopWindow:FindFirstChild("LeftPanel")
	if leftPanel then
		local eggShopScroll = leftPanel:FindFirstChild("EggShopScroll")
		if eggShopScroll then
			-- Clear existing
			for _, child in ipairs(eggShopScroll:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			
			-- Add egg types
			if Constants.EGG_CONFIG then
				for eggType, config in pairs(Constants.EGG_CONFIG) do
					createEggShopItem(eggType, config, eggShopScroll)
				end
			end
		end
	end
	
	-- RIGHT PANEL - Player's Pet Inventory Preview
	local rightPanel = petShopWindow:FindFirstChild("RightPanel")
	if rightPanel then
		local petPreviewScroll = rightPanel:FindFirstChild("PetPreviewScroll")
		if petPreviewScroll then
			-- Clear existing
			for _, child in ipairs(petPreviewScroll:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			
			-- Add pet counts header
			local maxEquipped = Constants.MAX_EQUIPPED_PETS or 3
			local maxGarden = Constants.MAX_GARDEN_PETS or 7
			local currentEquipped = playerInventory.EquippedPets and #playerInventory.EquippedPets or 0
			local currentGarden = playerInventory.GardenPets and #playerInventory.GardenPets or 0
			
			-- Add pets from inventory
			if playerInventory.Pets and type(playerInventory.Pets) == "table" and #playerInventory.Pets > 0 then
				for _, petInstance in ipairs(playerInventory.Pets) do
					if type(petInstance) == "table" and petInstance.Id and petInstance.PetType then
						createPetShopPreviewItem(petInstance, petPreviewScroll)
					end
				end
			else
				-- Show "no pets" message
				local noPetsFrame = Instance.new("Frame")
				noPetsFrame.Name = "NoPetsFrame"
				noPetsFrame.Size = UDim2.new(1, 0, 0, 100)
				noPetsFrame.BackgroundTransparency = 1
				noPetsFrame.Parent = petPreviewScroll
				
				local noPetsLabel = Instance.new("TextLabel")
				noPetsLabel.Size = UDim2.new(1, -20, 1, 0)
				noPetsLabel.Position = UDim2.new(0, 10, 0, 0)
				noPetsLabel.BackgroundTransparency = 1
				noPetsLabel.Text = "No pets yet!\n\nBuy eggs to hatch\nyour first companion!"
				noPetsLabel.TextColor3 = THEME.TextMoss
				noPetsLabel.Font = Enum.Font.GothamBold
				noPetsLabel.TextSize = 16
				noPetsLabel.ZIndex = 13
				noPetsLabel.TextWrapped = true
				noPetsLabel.Parent = noPetsFrame
			end
		end
	end
end

-- =============================================================================
-- GEAR SHOP WINDOW (Tools and Equipment)
-- =============================================================================

-- Create a gear shop item
local function createGearShopItem(gearType, config, container)
	if not config then return end
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = gearType
	itemFrame.Size = UDim2.new(1, -10, 0, 110)
	itemFrame.BackgroundColor3 = THEME.ForestDeep
	itemFrame.BorderSizePixel = 0
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = itemFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.TealGem
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent = itemFrame
	
	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0.2, 0, 0.7, 0)
	iconLabel.Position = UDim2.new(0.02, 0, 0.15, 0)
	iconLabel.BackgroundColor3 = THEME.ForestDark
	iconLabel.Text = config.Icon or "🔧"
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.ZIndex = 13
	iconLabel.Parent = itemFrame
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconLabel
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	nameLabel.Position = UDim2.new(0.25, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = config.DisplayName or gearType
	nameLabel.TextColor3 = THEME.TextLight
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 13
	nameLabel.Parent = itemFrame
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(0.5, 0, 0.35, 0)
	descLabel.Position = UDim2.new(0.25, 0, 0.35, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = config.Description or ""
	descLabel.TextColor3 = THEME.TextMoss
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 13
	descLabel.Parent = itemFrame
	
	-- Price / Buy Button
	local hasGear = playerInventory.Gear and playerInventory.Gear[gearType]
	
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0.22, 0, 0.35, 0)
	buyButton.Position = UDim2.new(0.76, 0, 0.55, 0)
	buyButton.ZIndex = 14
	buyButton.Parent = itemFrame
	
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton
	
	if hasGear then
		buyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		buyButton.Text = "OWNED"
		buyButton.TextColor3 = THEME.TextMoss
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextScaled = true
	else
		buyButton.BackgroundColor3 = THEME.TealGem
		buyButton.Text = "🪙 " .. tostring(config.Price or 0)
		buyButton.TextColor3 = THEME.TextLight
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextScaled = true
		
		-- Buy functionality
		buyButton.MouseButton1Click:Connect(function()
			if playerCoins >= config.Price then
				local buyGearEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_GEAR)
				if buyGearEvent then
					buyGearEvent:FireServer(gearType)
					playSound("Purchase")
					showNotification("Purchased " .. (config.DisplayName or gearType) .. "!", THEME.TealGem, config.Icon or "🔧")
				end
			else
				showNotification("Not enough coins!", THEME.AmberGlow, "🪙")
				playSound("Error")
			end
		end)
	end
end

-- Create an owned gear item for the right panel
local function createOwnedGearItem(gearType, config, container)
	if not config then return end
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = gearType
	itemFrame.Size = UDim2.new(0, 90, 0, 110)
	itemFrame.BackgroundColor3 = THEME.ForestDeep
	itemFrame.BorderSizePixel = 0
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = itemFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.GoldLeaf
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = itemFrame
	
	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0.8, 0, 0.5, 0)
	iconLabel.Position = UDim2.new(0.1, 0, 0.05, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = config.Icon or "🔧"
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.ZIndex = 13
	iconLabel.Parent = itemFrame
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(0.9, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = config.DisplayName or gearType
	nameLabel.TextColor3 = THEME.TextLight
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextWrapped = true
	nameLabel.ZIndex = 13
	nameLabel.Parent = itemFrame
end

-- Update the gear shop window
updateGearShopWindow = function()
	if not screenGui then return end
	local gearShopWindow = windowGroup and windowGroup:FindFirstChild("GearShopWindow")
	if not gearShopWindow then return end
	
	-- LEFT PANEL - Gear Shop
	local leftPanel = gearShopWindow:FindFirstChild("LeftPanel")
	if leftPanel then
		local gearShopScroll = leftPanel:FindFirstChild("GearShopScroll")
		if gearShopScroll then
			-- Clear existing (keep UIListLayout and UIPadding)
			for _, child in ipairs(gearShopScroll:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			
			-- Add gear items from Constants
			if Constants.GEAR_CONFIG then
				for gearType, config in pairs(Constants.GEAR_CONFIG) do
					createGearShopItem(gearType, config, gearShopScroll)
				end
			end
		end
	end
	
	-- RIGHT PANEL - Player's Owned Gear
	local rightPanel = gearShopWindow:FindFirstChild("RightPanel")
	if rightPanel then
		local gearInventoryScroll = rightPanel:FindFirstChild("GearInventoryScroll")
		if gearInventoryScroll then
			-- Clear existing
			for _, child in ipairs(gearInventoryScroll:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			
			-- Add owned gear
			local hasAnyGear = false
			if playerInventory.Gear and Constants.GEAR_CONFIG then
				for gearType, owned in pairs(playerInventory.Gear) do
					if owned then
						local config = Constants.GEAR_CONFIG[gearType]
						if config then
							createOwnedGearItem(gearType, config, gearInventoryScroll)
							hasAnyGear = true
						end
					end
				end
			end
			
			-- Show "no gear" message if empty
			if not hasAnyGear then
				local noGearFrame = Instance.new("Frame")
				noGearFrame.Name = "NoGearFrame"
				noGearFrame.Size = UDim2.new(1, 0, 0, 100)
				noGearFrame.BackgroundTransparency = 1
				noGearFrame.Parent = gearInventoryScroll
				
				local noGearLabel = Instance.new("TextLabel")
				noGearLabel.Size = UDim2.new(1, -20, 1, 0)
				noGearLabel.Position = UDim2.new(0, 10, 0, 0)
				noGearLabel.BackgroundTransparency = 1
				noGearLabel.Text = "No gear yet!\n\nPurchase tools from\nthe shop to start!"
				noGearLabel.TextColor3 = THEME.TextMoss
				noGearLabel.Font = Enum.Font.GothamBold
				noGearLabel.TextSize = 16
				noGearLabel.ZIndex = 13
				noGearLabel.TextWrapped = true
				noGearLabel.Parent = noGearFrame
			end
		end
	end
end

-- =============================================================================
-- PETS SYSTEM (Gacha/Instance-based)
-- =============================================================================

-- Check if a pet instance is equipped (by Id)
isPetEquipped = function(petId)
	-- First check EquippedPetIds (just IDs)
	if playerInventory.EquippedPetIds then
		for _, id in ipairs(playerInventory.EquippedPetIds) do
			if id == petId then return true end
		end
	end
	-- Fallback: check EquippedPets (full instances)
	if playerInventory.EquippedPets then
		for _, pet in ipairs(playerInventory.EquippedPets) do
			if type(pet) == "table" and pet.Id == petId then return true end
			if type(pet) == "string" and pet == petId then return true end
		end
	end
	return false
end

-- Check if a pet instance is in garden (by Id)
isPetInGarden = function(petId)
	-- First check GardenPetIds (just IDs)
	if playerInventory.GardenPetIds then
		for _, id in ipairs(playerInventory.GardenPetIds) do
			if id == petId then return true end
		end
	end
	-- Fallback: check GardenPets (full instances)
	if playerInventory.GardenPets then
		for _, pet in ipairs(playerInventory.GardenPets) do
			if type(pet) == "table" and pet.Id == petId then return true end
			if type(pet) == "string" and pet == petId then return true end
		end
	end
	return false
end

-- Create compact pet preview item for pet shop right panel (grid layout)
createPetShopPreviewItem = function(petInstance, container)
	local petType = petInstance.PetType
	local petId = petInstance.Id
	local petSize = petInstance.Size or 1
	local petWeight = petInstance.Weight or 1
	
	local config = Constants.PET_CONFIG[petType]
	if not config then return end
	
	local displayName = getPetDisplayName(petType)
	local rarityColor = getRarityColor(petType)
	local isEquipped = isPetEquipped(petId)
	local isInGarden = isPetInGarden(petId)
	
	local baseBoost = config.WaterBoost or 0
	local actualBoost = baseBoost * petWeight
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = petId
	itemFrame.Size = UDim2.new(0, 130, 0, 130)
	itemFrame.BackgroundColor3 = isEquipped and THEME.TealGem or (isInGarden and THEME.MossGreen or THEME.WoodPanel)
	itemFrame.BorderSizePixel = 0
	itemFrame.ZIndex = 13
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = itemFrame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(itemFrame.BackgroundColor3, THEME.WoodBark)
	gradient.Rotation = 90
	gradient.Parent = itemFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Color = rarityColor
	stroke.Parent = itemFrame
	
	-- Pet icon/emoji placeholder
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 0.5, 0)
	iconLabel.Position = UDim2.new(0, 0, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = config.Icon or "🐾"
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextScaled = true
	iconLabel.ZIndex = 14
	iconLabel.Parent = itemFrame
	
	-- Pet name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0.2, 0)
	nameLabel.Position = UDim2.new(0, 4, 0.48, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 14
	nameLabel.Parent = itemFrame
	
	-- Status indicator
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -8, 0.15, 0)
	statusLabel.Position = UDim2.new(0, 4, 0.68, 0)
	statusLabel.BackgroundTransparency = 1
	if isEquipped then
		statusLabel.Text = "✓ Equipped"
		statusLabel.TextColor3 = THEME.TextGold
	elseif isInGarden then
		statusLabel.Text = "🌱 In Garden"
		statusLabel.TextColor3 = THEME.MossGreen
	else
		statusLabel.Text = string.format("%.1fx boost", actualBoost)
		statusLabel.TextColor3 = THEME.TextMoss
	end
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 10
	statusLabel.ZIndex = 14
	statusLabel.Parent = itemFrame
	
	-- Size/weight info
	local sizeLabel = Instance.new("TextLabel")
	sizeLabel.Size = UDim2.new(1, -8, 0.15, 0)
	sizeLabel.Position = UDim2.new(0, 4, 0.83, 0)
	sizeLabel.BackgroundTransparency = 1
	sizeLabel.Text = string.format("%.1f lbs", petWeight)
	sizeLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	sizeLabel.Font = Enum.Font.Gotham
	sizeLabel.TextSize = 10
	sizeLabel.ZIndex = 14
	sizeLabel.Parent = itemFrame
end

-- Create a pet item display for instance-based pets
local function createPetInstanceItem(petInstance, container, layoutOrder)
	local petType = petInstance.PetType
	local petId = petInstance.Id
	local petSize = petInstance.Size or 1
	local petWeight = petInstance.Weight or 1
	
	local config = Constants.PET_CONFIG[petType]
	if not config then return end
	local displayName = getPetDisplayName(petType)
	local rarityColor = getRarityColor(petType)
	
	local isEquipped = isPetEquipped(petId)
	local isInGarden = isPetInGarden(petId)
	
	-- Calculate actual boost based on weight
	local baseBoost = config.WaterBoost or 0
	local actualBoost = baseBoost * petWeight
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = petId
	itemFrame.Size = UDim2.new(1, 0, 0, 90)
	itemFrame.BackgroundColor3 = isEquipped and THEME.TealGem or (isInGarden and THEME.MossGreen or THEME.WoodPanel)
	itemFrame.BorderSizePixel = 0
	itemFrame.ZIndex = 11
	itemFrame.LayoutOrder = layoutOrder or 1
	itemFrame.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = itemFrame
	
	local gradient = Instance.new("UIGradient")
	if isEquipped then
		gradient.Color = ColorSequence.new(THEME.TealGem, THEME.ForestDeep)
	elseif isInGarden then
		gradient.Color = ColorSequence.new(THEME.MossGreen, THEME.ForestDeep)
	else
		gradient.Color = ColorSequence.new(THEME.WoodPanel, THEME.WoodBark)
	end
	gradient.Rotation = 90
	gradient.Parent = itemFrame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Color = rarityColor
	stroke.Transparency = 0.2
	stroke.Parent = itemFrame
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 8, 0, 8)
	icon.BackgroundTransparency = 1
	icon.Text = "🐾"
	icon.TextScaled = true
	icon.TextColor3 = rarityColor
	icon.Font = Enum.Font.GothamBold
	icon.ZIndex = 12
	icon.Parent = itemFrame
	
	-- Name with rarity color
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.35, 0, 0, 22)
	nameLabel.Position = UDim2.new(0.15, 0, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = rarityColor
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 12
	nameLabel.Parent = itemFrame
	
	-- Size/Weight stats
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(0.35, 0, 0, 16)
	statsLabel.Position = UDim2.new(0.15, 0, 0, 32)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = string.format("Size: %.2f | Weight: %.2f", petSize, petWeight)
	statsLabel.TextColor3 = THEME.TextMoss
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextSize = 12
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.ZIndex = 12
	statsLabel.Parent = itemFrame
	
	-- Boost info (affected by weight)
	local boostLabel = Instance.new("TextLabel")
	boostLabel.Size = UDim2.new(0.35, 0, 0, 16)
	boostLabel.Position = UDim2.new(0.15, 0, 0, 50)
	boostLabel.BackgroundTransparency = 1
	boostLabel.Text = string.format("Boost: %.1f%%", actualBoost * 100)
	boostLabel.TextColor3 = THEME.TealGlow
	boostLabel.Font = Enum.Font.Gotham
	boostLabel.TextSize = 12
	boostLabel.TextXAlignment = Enum.TextXAlignment.Left
	boostLabel.ZIndex = 12
	boostLabel.Parent = itemFrame
	
	-- Status indicator
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0.2, 0, 0, 18)
	statusLabel.Position = UDim2.new(0.15, 0, 0, 68)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 11
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.ZIndex = 12
	statusLabel.Parent = itemFrame
	
	if isEquipped then
		statusLabel.Text = "✓ EQUIPPED"
		statusLabel.TextColor3 = THEME.TealGlow
	elseif isInGarden then
		statusLabel.Text = "🏡 IN GARDEN"
		statusLabel.TextColor3 = THEME.MossGreen
	else
		statusLabel.Text = ""
	end
	
	-- Button container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Size = UDim2.new(0.35, 0, 0.8, 0)
	buttonContainer.Position = UDim2.new(0.62, 0, 0.1, 0)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.ZIndex = 12
	buttonContainer.Parent = itemFrame
	
	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Vertical
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Padding = UDim.new(0, 4)
	buttonLayout.Parent = buttonContainer
	
	-- Max caps
	local maxEquipped = Constants.MAX_EQUIPPED_PETS or 3
	local maxGarden = Constants.MAX_GARDEN_PETS or 7
	local currentEquipped = playerInventory.EquippedPets and #playerInventory.EquippedPets or 0
	local currentGarden = playerInventory.GardenPets and #playerInventory.GardenPets or 0
	
	-- Equip/Unequip button
	if isEquipped then
		local unequipButton = Instance.new("TextButton")
		unequipButton.Size = UDim2.new(1, 0, 0, 24)
		unequipButton.BackgroundColor3 = THEME.WoodBark
		unequipButton.Text = "Unequip"
		unequipButton.TextColor3 = THEME.TextLight
		unequipButton.Font = Enum.Font.GothamBold
		unequipButton.TextSize = 11
		unequipButton.ZIndex = 13
		unequipButton.LayoutOrder = 1
		unequipButton.Parent = buttonContainer
		
		Instance.new("UICorner", unequipButton).CornerRadius = UDim.new(0, 6)
		
		unequipButton.MouseButton1Click:Connect(function()
			playSound("ButtonClick")
			local unequipEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.UNEQUIP_PET)
			if unequipEvent then
				unequipEvent:FireServer(petId)
				playSound("PetUnequip")
				showNotification("Unequipped " .. displayName, THEME.WoodPanel, "🐾")
			end
		end)
	else
		local equipButton = Instance.new("TextButton")
		equipButton.Size = UDim2.new(1, 0, 0, 24)
		equipButton.BackgroundColor3 = currentEquipped < maxEquipped and THEME.TealGem or THEME.ForestDark
		equipButton.Text = currentEquipped < maxEquipped and "Equip" or ("Full " .. maxEquipped .. "/" .. maxEquipped)
		equipButton.TextColor3 = THEME.TextLight
		equipButton.Font = Enum.Font.GothamBold
		equipButton.TextSize = 11
		equipButton.ZIndex = 13
		equipButton.LayoutOrder = 1
		equipButton.Parent = buttonContainer
		
		Instance.new("UICorner", equipButton).CornerRadius = UDim.new(0, 6)
		
		if currentEquipped < maxEquipped then
			equipButton.MouseButton1Click:Connect(function()
				playSound("ButtonClick")
				local equipEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.EQUIP_PET)
				if equipEvent then
					equipEvent:FireServer(petId)
					playSound("PetEquip")
					showNotification("Equipped " .. displayName, THEME.TealGem, "🐾")
				end
			end)
		end
	end
	
	-- Garden add/remove button
	if isInGarden then
		local removeGardenButton = Instance.new("TextButton")
		removeGardenButton.Size = UDim2.new(1, 0, 0, 24)
		removeGardenButton.BackgroundColor3 = THEME.WoodBark
		removeGardenButton.Text = "Remove from Garden"
		removeGardenButton.TextColor3 = THEME.TextLight
		removeGardenButton.Font = Enum.Font.GothamBold
		removeGardenButton.TextSize = 10
		removeGardenButton.ZIndex = 13
		removeGardenButton.LayoutOrder = 2
		removeGardenButton.Parent = buttonContainer
		
		Instance.new("UICorner", removeGardenButton).CornerRadius = UDim.new(0, 6)
		
		removeGardenButton.MouseButton1Click:Connect(function()
			playSound("ButtonClick")
			local removeEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.REMOVE_GARDEN_PET)
			if removeEvent then
				removeEvent:FireServer(petId)
				showNotification("Removed from garden", THEME.WoodPanel, "🏡")
			end
		end)
	elseif not isEquipped then
		local addGardenButton = Instance.new("TextButton")
		addGardenButton.Size = UDim2.new(1, 0, 0, 24)
		addGardenButton.BackgroundColor3 = currentGarden < maxGarden and THEME.MossGreen or THEME.ForestDark
		addGardenButton.Text = currentGarden < maxGarden and "Add to Garden" or ("Garden Full " .. maxGarden .. "/" .. maxGarden)
		addGardenButton.TextColor3 = THEME.TextLight
		addGardenButton.Font = Enum.Font.GothamBold
		addGardenButton.TextSize = 10
		addGardenButton.ZIndex = 13
		addGardenButton.LayoutOrder = 2
		addGardenButton.Parent = buttonContainer
		
		Instance.new("UICorner", addGardenButton).CornerRadius = UDim.new(0, 6)
		
		if currentGarden < maxGarden then
			addGardenButton.MouseButton1Click:Connect(function()
				playSound("ButtonClick")
				local addEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.ADD_GARDEN_PET)
				if addEvent then
					addEvent:FireServer(petId)
					showNotification("Added to garden!", THEME.MossGreen, "🏡")
				end
			end)
		end
	end
end

-- Legacy function for compatibility (no longer used directly)
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
	local petsWindow = windowGroup and windowGroup:FindFirstChild("PetsWindow")
	if not petsWindow then return end
	
	local leftPanel = petsWindow:FindFirstChild("LeftPanel")
	local petsScroll = leftPanel and leftPanel:FindFirstChild("ScrollingFrame") or petsWindow:FindFirstChild("ScrollingFrame")
	if not petsScroll then 
		warn("[UIHandler] Could not find pets ScrollingFrame")
		return 
	end
	
	-- Clear existing
	for _, child in ipairs(petsScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end
	
	-- Add header with counts
	local maxEquipped = Constants.MAX_EQUIPPED_PETS or 3
	local maxGarden = Constants.MAX_GARDEN_PETS or 7
	local currentEquipped = playerInventory.EquippedPetIds and #playerInventory.EquippedPetIds or (playerInventory.EquippedPets and #playerInventory.EquippedPets or 0)
	local currentGarden = playerInventory.GardenPetIds and #playerInventory.GardenPetIds or (playerInventory.GardenPets and #playerInventory.GardenPets or 0)
	
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Name = "Header"
	headerLabel.Size = UDim2.new(1, 0, 0, 30)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = string.format("Equipped: %d/%d | Garden: %d/%d", currentEquipped, maxEquipped, currentGarden, maxGarden)
	headerLabel.TextColor3 = THEME.TextMoss
	headerLabel.Font = Enum.Font.Gotham
	headerLabel.TextSize = 14
	headerLabel.ZIndex = 12
	headerLabel.LayoutOrder = 0
	headerLabel.Parent = petsScroll
	
	-- Debug: Log pets data
	-- print("[UIHandler] Pets data:", playerInventory.Pets)
	
	-- Check if pets is an array (new system) or table (legacy)
	if playerInventory.Pets then
		local hasPets = false
		local layoutOrder = 1
		
		-- New instance-based system (array of {Id, PetType, Size, Weight})
		if type(playerInventory.Pets) == "table" then
			-- Check if it's an array with items
			local petsArray = playerInventory.Pets
			for i, petInstance in ipairs(petsArray) do
				if type(petInstance) == "table" and petInstance.Id and petInstance.PetType then
					createPetInstanceItem(petInstance, petsScroll, layoutOrder)
					layoutOrder = layoutOrder + 1
					hasPets = true
				end
			end
			
			-- If no items found via ipairs, try pairs for legacy format
			if not hasPets then
				for petType, owned in pairs(playerInventory.Pets) do
					if owned == true then
						createPetItem(petType, petsScroll)
						hasPets = true
					end
				end
			end
		end
		
		if not hasPets then
			-- Show "no pets" message
			local noPetsLabel = Instance.new("TextLabel")
			noPetsLabel.Name = "NoPets"
			noPetsLabel.Size = UDim2.new(1, 0, 0, 80)
			noPetsLabel.BackgroundTransparency = 1
			noPetsLabel.Text = "No pets owned yet!\n\nBuy eggs from the Pet Shop\nto hatch unique pets!"
			noPetsLabel.TextColor3 = THEME.TextMoss
			noPetsLabel.Font = Enum.Font.Gotham
			noPetsLabel.TextSize = 16
			noPetsLabel.ZIndex = 12
			noPetsLabel.LayoutOrder = 1
			noPetsLabel.Parent = petsScroll
		end
	else
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Name = "NoPetsInfo"
		infoLabel.Size = UDim2.new(1, 0, 0, 70)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "Buy eggs from the Pet Shop\nto hatch unique companions!"
		infoLabel.TextColor3 = THEME.TextMoss
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextSize = 16
		infoLabel.ZIndex = 12
		infoLabel.LayoutOrder = 1
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
	local totalValue = sellPrice * count
	local displayName = plantType:sub(1,1):upper() .. plantType:sub(2) .. " Fruit"
	
	-- Find and clone the template from the container
	local template = container:FindFirstChild("SellItemTemplate")
	if not template then
		warn("[UIHandler] SellItemTemplate not found in container, falling back to old method")
		-- Fallback: create basic frame
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = fruitName
		itemFrame.Size = UDim2.new(1, 0, 0, 80)
		itemFrame.BackgroundColor3 = THEME.WoodPanel
		itemFrame.BorderSizePixel = 0
		itemFrame.ZIndex = 11
		itemFrame.Parent = container
		return
	end
	
	-- Clone the template
	local itemCard = template:Clone()
	itemCard.Name = fruitName
	itemCard.Visible = true
	
	-- Update icon container
	local iconContainer = itemCard:FindFirstChild("IconContainer")
	if iconContainer then
		local fruitIcon = iconContainer:FindFirstChild("FruitIcon")
		if fruitIcon then
			fruitIcon.Text = config.Icon or "🍎"
		end
	end
	
	-- Update info container
	local infoContainer = itemCard:FindFirstChild("InfoContainer")
	if infoContainer then
		local nameLabel = infoContainer:FindFirstChild("FruitName")
		if nameLabel then
			nameLabel.Text = displayName
		end
		
		local countLabel = infoContainer:FindFirstChild("FruitCount")
		if countLabel then
			countLabel.Text = "Owned: " .. count
		end
	end
	
	-- Update action container
	local actionContainer = itemCard:FindFirstChild("ActionContainer")
	if actionContainer then
		local priceLabel = actionContainer:FindFirstChild("PriceLabel")
		if priceLabel then
			priceLabel.Text = "💰 " .. sellPrice .. " each"
		end
		
		local sellButton = actionContainer:FindFirstChild("SellButton")
		if sellButton then
			sellButton.MouseButton1Click:Connect(function()
				playSound("ButtonClick")
				local sellEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.SELL_FRUIT)
				if sellEvent then
					sellEvent:FireServer(fruitName, 1)
					playSound("Sell")
					showNotification("Sold 1x " .. displayName .. " for " .. sellPrice .. " coins", THEME.GoldLeaf, "💰")
				end
			end)
			
			-- Hover effects
			sellButton.MouseEnter:Connect(function()
				sellButton.BackgroundColor3 = THEME.SellButtonHover or THEME.TealGlow
			end)
			sellButton.MouseLeave:Connect(function()
				sellButton.BackgroundColor3 = THEME.GoldLeaf
			end)
		end
		
		local sellAllButton = actionContainer:FindFirstChild("SellAllButton")
		if sellAllButton then
			sellAllButton.MouseButton1Click:Connect(function()
				playSound("ButtonClick")
				local sellAllEvent = ReplicatedStorage:FindFirstChild("SellAllFruitsOfType")
				if sellAllEvent then
					sellAllEvent:FireServer(fruitName)
					playSound("Sell")
					showNotification("Sold " .. count .. "x " .. displayName .. " for " .. totalValue .. " coins", THEME.GoldLeaf, "💰")
				end
			end)
			
			-- Hover effects  
			sellAllButton.MouseEnter:Connect(function()
				sellAllButton.BackgroundColor3 = THEME.GoldAccent or THEME.TextGold
			end)
			sellAllButton.MouseLeave:Connect(function()
				sellAllButton.BackgroundColor3 = THEME.AmberGlow or THEME.WarningGold
			end)
		end
	end
	
	itemCard.Parent = container
end

-- Create sell item for instance-based fruits (with individual weights)
local function createFruitInstanceSellItem(fruitType, fruits, container)
	-- fruitType may already include "Fruit" suffix from inventory
	local plantType = fruitType:gsub("Fruit$", "")
	local config = Constants.PLANT_CONFIG[plantType]
	if not config or not config.FruitSellPrice then 
		warn("[UIHandler] No FruitSellPrice for:", fruitType)
		return 
	end

	local baseSellPrice = config.FruitSellPrice
	local displayName = plantType:sub(1,1):upper() .. plantType:sub(2) .. " Fruit"
	local count = #fruits
	
	-- Calculate total weight and average
	local totalWeight = 0
	for _, fruit in ipairs(fruits) do
		totalWeight = totalWeight + (fruit.Weight or 1)
	end
	local avgWeight = count > 0 and (totalWeight / count) or 1
	
	-- Calculate total value (price * weight for each)
	local totalValue = 0
	for _, fruit in ipairs(fruits) do
		totalValue = totalValue + math.floor(baseSellPrice * (fruit.Weight or 1))
	end
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = fruitType
	itemFrame.Size = UDim2.new(1, 0, 0, 95)
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
	icon.Size = UDim2.new(0, 55, 0.8, 0)
	icon.Position = UDim2.new(0, 5, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = config.Icon or "🍎"
	icon.TextScaled = true
	icon.TextColor3 = THEME.TextLight
	icon.Font = Enum.Font.GothamBold
	icon.ZIndex = 12
	icon.Parent = itemFrame
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.28, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0.13, 0, 0.08, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = THEME.TextLight
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 12
	nameLabel.Parent = itemFrame
	
	-- Count and weight info
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(0.28, 0, 0.25, 0)
	infoLabel.Position = UDim2.new(0.13, 0, 0.42, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = string.format("x%d (%.1f lbs avg)", count, avgWeight)
	infoLabel.TextColor3 = THEME.TextMoss
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.ZIndex = 12
	infoLabel.Parent = itemFrame
	
	-- Total weight label
	local weightLabel = Instance.new("TextLabel")
	weightLabel.Size = UDim2.new(0.28, 0, 0.22, 0)
	weightLabel.Position = UDim2.new(0.13, 0, 0.68, 0)
	weightLabel.BackgroundTransparency = 1
	weightLabel.Text = string.format("Total: %.1f lbs", totalWeight)
	weightLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	weightLabel.Font = Enum.Font.Gotham
	weightLabel.TextSize = 12
	weightLabel.TextXAlignment = Enum.TextXAlignment.Left
	weightLabel.ZIndex = 12
	weightLabel.Parent = itemFrame
	
	-- Price info
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.18, 0, 0.35, 0)
	priceLabel.Position = UDim2.new(0.42, 0, 0.15, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 " .. baseSellPrice .. "/lb"
	priceLabel.TextColor3 = THEME.TextGold
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextScaled = true
	priceLabel.ZIndex = 12
	priceLabel.Parent = itemFrame
	
	-- Total value label
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.18, 0, 0.25, 0)
	valueLabel.Position = UDim2.new(0.42, 0, 0.52, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "= " .. totalValue .. " 💰"
	valueLabel.TextColor3 = THEME.GoldLeaf
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextScaled = true
	valueLabel.ZIndex = 12
	valueLabel.Parent = itemFrame
	
	-- Sell 1 button (sells lightest/first)
	local sell1Button = Instance.new("TextButton")
	sell1Button.Size = UDim2.new(0.13, 0, 0.55, 0)
	sell1Button.Position = UDim2.new(0.62, 0, 0.22, 0)
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
		-- Sell the first fruit by ID
		if fruits[1] then
			local sellByIdEvent = ReplicatedStorage:FindFirstChild("SellFruitById")
			if sellByIdEvent then
				local fruitWeight = fruits[1].Weight or 1
				local salePrice = math.floor(baseSellPrice * fruitWeight)
				sellByIdEvent:FireServer(fruits[1].Id)
				playSound("Sell")
				showNotification(string.format("Sold %.1f lb %s for %d coins", fruitWeight, displayName, salePrice), THEME.GoldLeaf, "💰")
			end
		end
	end)
	
	-- Sell All button
	local sellAllButton = Instance.new("TextButton")
	sellAllButton.Size = UDim2.new(0.14, 0, 0.55, 0)
	sellAllButton.Position = UDim2.new(0.77, 0, 0.22, 0)
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
		local sellAllEvent = ReplicatedStorage:FindFirstChild("SellAllFruitsOfType")
		if sellAllEvent then
			sellAllEvent:FireServer(fruitType)
			playSound("Sell")
			showNotification(string.format("Sold %dx %s (%.1f lbs) for %d coins", count, displayName, totalWeight, totalValue), THEME.WarningGold, "💰")
		end
	end)
	
	-- Hover effects
	sell1Button.MouseEnter:Connect(function()
		sell1Button.BackgroundColor3 = THEME.SellButtonHover or THEME.LeafPanel
	end)
	sell1Button.MouseLeave:Connect(function()
		sell1Button.BackgroundColor3 = THEME.TealGem
	end)
	
	sellAllButton.MouseEnter:Connect(function()
		sellAllButton.BackgroundColor3 = THEME.GoldAccent or THEME.TextGold
	end)
	sellAllButton.MouseLeave:Connect(function()
		sellAllButton.BackgroundColor3 = THEME.GoldLeaf
	end)
end

updateSellShop = function()
	if not screenGui then return end
	local sellWindow = windowGroup and windowGroup:FindFirstChild("SellWindow")
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
		-- Check if using new instance-based system (array of {Id, Type, Weight})
		if type(playerInventory.Fruits) == "table" and #playerInventory.Fruits > 0 and playerInventory.Fruits[1].Id then
			-- Group fruits by type
			local fruitsByType = {}
			for _, fruit in ipairs(playerInventory.Fruits) do
				local fruitType = fruit.Type
				if not fruitsByType[fruitType] then
					fruitsByType[fruitType] = {}
				end
				table.insert(fruitsByType[fruitType], fruit)
			end
			-- Create sell item for each type
			for fruitType, fruits in pairs(fruitsByType) do
				createFruitInstanceSellItem(fruitType, fruits, sellScroll)
			end
		else
			-- Legacy count-based system
			for fruitName, count in pairs(playerInventory.Fruits) do
				if type(count) == "number" and count > 0 then
					createSellItem(fruitName, count, sellScroll)
				end
			end
		end
	end
end

-- Update shop right panel with grid inventory
updateShopInventoryGrid = function()
	if not screenGui then return end
	local shopWindow = windowGroup and windowGroup:FindFirstChild("ShopWindow")
	if not shopWindow then return end
	
	local rightPanel = shopWindow:FindFirstChild("RightPanel")
	local inventoryScroll = rightPanel and rightPanel:FindFirstChild("InventoryScroll")
	if not inventoryScroll then return end
	
	-- Clear existing items (preserve template)
	for _, child in ipairs(inventoryScroll:GetChildren()) do
		if child:IsA("Frame") and not string.find(child.Name, "Template") then
			child:Destroy()
		end
	end
	
	-- Add seeds from inventory as grid items
	if playerInventory.Seeds then
		for seedName, seedData in pairs(playerInventory.Seeds) do
			local count = seedData
			-- Handle both number counts and array of instances
			if type(seedData) == "table" then
				count = #seedData
			elseif type(seedData) ~= "number" then
				continue
			end
			if count > 0 then
				createInventoryItem(seedName, count, "Seed", inventoryScroll)
			end
		end
	end
end

-- Update sell right panel with grid inventory
updateSellInventoryGrid = function()
	if not screenGui then return end
	local sellWindow = windowGroup and windowGroup:FindFirstChild("SellWindow")
	if not sellWindow then return end
	
	local rightPanel = sellWindow:FindFirstChild("RightPanel")
	local inventoryScroll = rightPanel and rightPanel:FindFirstChild("InventoryScroll")
	if not inventoryScroll then return end
	
	-- Clear existing items (preserve template)
	for _, child in ipairs(inventoryScroll:GetChildren()) do
		if child:IsA("Frame") and not string.find(child.Name, "Template") then
			child:Destroy()
		end
	end
	
	-- Add fruits from inventory as grid items
	if playerInventory.Fruits then
		for fruitName, fruitData in pairs(playerInventory.Fruits) do
			local count = fruitData
			-- Handle both number counts and array of instances
			if type(fruitData) == "table" then
				count = #fruitData
			elseif type(fruitData) ~= "number" then
				continue
			end
			if count > 0 then
				createInventoryItem(fruitName, count, "Fruit", inventoryScroll)
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
	enforceToolSlots()
	
	-- Wait for UI to exist
	screenGui = playerGui:WaitForChild("FeyGardenUI", 10)
	if not screenGui then
		warn("[UIHandler] ❌ FeyGardenUI not found! Did you run the UISetup script?")
		warn("[UIHandler] Run this in Studio Command Bar: require(game.ReplicatedStorage.Setup.UISetup).CreateUI()")
		return
	end

	-- Root frame that contains grouped layers
	uiRoot = screenGui:WaitForChild("UIRoot", 5)
	if not uiRoot then
		warn("[UIHandler] ❌ UIRoot missing under FeyGardenUI; ensure UISetup.CreateUI ran.")
		return
	end
	
	-- =============================================================================
	-- WINDOW REFERENCES
	-- =============================================================================
	hudGroup = uiRoot:FindFirstChild("HUDGroup") or screenGui:FindFirstChild("HUDGroup")
	windowGroup = uiRoot:FindFirstChild("WindowGroup") or screenGui:FindFirstChild("WindowGroup")
	overlayGroup = uiRoot:FindFirstChild("OverlayGroup") or screenGui:FindFirstChild("OverlayGroup")

	local shopWindow = windowGroup and windowGroup:WaitForChild("ShopWindow", 5)
	local sellWindow = windowGroup and windowGroup:WaitForChild("SellWindow", 5)
	local petsWindow = windowGroup and windowGroup:WaitForChild("PetsWindow", 5)
	local inventoryWindow = windowGroup and windowGroup:WaitForChild("InventoryWindow", 5)
	local petShopWindow = windowGroup and windowGroup:WaitForChild("PetShopWindow", 5)
	
	-- =============================================================================
	-- NAVIGATION BUTTONS (Top Center)
	-- =============================================================================
	local navigationFrame = hudGroup and hudGroup:FindFirstChild("NavigationFrame") or (uiRoot and uiRoot:FindFirstChild("NavigationFrame")) or screenGui:WaitForChild("NavigationFrame", 5)
	if navigationFrame then
		-- Helper function to teleport player to a camera part location
		local function teleportToShop(cameraPartName)
			local player = game.Players.LocalPlayer
			local character = player.Character
			if not character then return false end
			
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then return false end
			
			local cameraPart = workspace:FindFirstChild(cameraPartName)
			if not cameraPart then
				warn("[UIHandler] Camera part not found:", cameraPartName)
				return false
			end
			
			-- Teleport player slightly in front of camera position, on the ground
			-- Camera usually looks at the shop, so we position player nearby
			local teleportPosition = cameraPart.Position + cameraPart.CFrame.LookVector * 3
			teleportPosition = Vector3.new(teleportPosition.X, cameraPart.Position.Y, teleportPosition.Z)
			humanoidRootPart.CFrame = CFrame.new(teleportPosition)
			
			return true
		end
		
		-- SEEDS Button - Teleports to shop
		local seedsButton = navigationFrame:FindFirstChild("SeedsButton")
		if seedsButton then
			seedsButton.MouseButton1Click:Connect(function()
				teleportToShop("ShopCamera")
				playSound("Click")
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
				
				-- Search for garden assigned to this player via OwnerUserId attribute
				for _, garden in ipairs(gardensFolder:GetChildren()) do
					if garden:IsA("Folder") then
						local ownerUserId = garden:GetAttribute("OwnerUserId")
						if ownerUserId == player.UserId then
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
				
				warn("[UIHandler] Could not find player's garden")
			end)
		end
		
		-- SELL Button - Teleports to sell shop
		local sellButton = navigationFrame:FindFirstChild("SellButton")
		if sellButton then
			sellButton.MouseButton1Click:Connect(function()
				teleportToShop("SellCamera")
				playSound("Click")
			end)
		end
		
		-- PETS Button - Teleports to pet shop
		local petsNavButton = navigationFrame:FindFirstChild("PetsButton")
		if petsNavButton then
			petsNavButton.MouseButton1Click:Connect(function()
				teleportToShop("PetCamera")
				playSound("Click")
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
	-- PETS WINDOW SETUP (Inventory Only - via PetsButton)
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
	
	-- =============================================================================
	-- PET SHOP WINDOW SETUP (Egg Shop + Inventory Preview - via Proximity)
	-- =============================================================================
	if petShopWindow then
		local petShopCloseButton = petShopWindow:FindFirstChild("CloseButton")
		if petShopCloseButton then
			petShopCloseButton.MouseButton1Click:Connect(function()
				petShopWindow.Visible = false
				NPCUIHandler.RestoreCamera()
				showHUD()
				playSound("WindowClose")
			end)
		end
	end
	
	-- Setup pets button (opens inventory only)
	local petsButton = findSideButton("PetsButton") or screenGui:WaitForChild("PetsButton", 5)
	if petsButton then
		petsButton.MouseButton1Click:Connect(function()
			if petsWindow then
				petsWindow.Visible = not petsWindow.Visible
				if petsWindow.Visible then
					updatePetsWindow()
					hideHUD()
					playSound("WindowOpen")
				else
					showHUD()
					playSound("WindowClose")
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
		end
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
		end
	end
	
	-- =============================================================================
	-- PROXIMITY PROMPTS FOR PET SHOP (Egg Shop + Pet Preview)
	-- =============================================================================
	local petShopPart = workspace:WaitForChild("PetShopPart", 10)
	if petShopPart then
		local prompt = petShopPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				if petShopWindow then
					NPCUIHandler.MoveCameraToNPC("PetCamera")
					updatePetShopWindow()
					petShopWindow.Visible = true
					hideHUD()
					playSound("WindowOpen")
				end
			end)
		end
	end
	
	-- =============================================================================
	-- INVENTORY WINDOW (Press B)
	-- =============================================================================
	if inventoryWindow then
		local invCloseButton = inventoryWindow:FindFirstChild("TitleBar") and inventoryWindow.TitleBar:FindFirstChild("CloseButton")
		if invCloseButton then
			invCloseButton.MouseButton1Click:Connect(function()
				inventoryWindow.Visible = false
				showHUD()
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
	-- TRADING SYSTEM SETUP
	-- =============================================================================
	local tradingWindow = windowGroup and windowGroup:FindFirstChild("TradingWindow")
	local tradeRequestPopup = windowGroup and windowGroup:FindFirstChild("TradeRequestPopup")
	local playerSelectWindow = windowGroup and windowGroup:FindFirstChild("PlayerSelectWindow")
	local tradeButton = findSideButton("TradeButton")
	
	-- Trading state
	local currentTradePartner = nil
	local currentTradeId = nil
	local myTradeOffer = {}
	local theirTradeOffer = {}
	local myConfirmed = false
	local theirConfirmed = false
	local pendingRequesterId = nil
	
	-- Remote events for trading
	local tradeRequestFunc = ReplicatedStorage:WaitForChild(Constants.EVENTS.TRADE_REQUEST, 5)
	local tradeResponseEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.TRADE_RESPONSE, 5)
	local tradeUpdateEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.TRADE_UPDATE, 5)
	local tradeConfirmEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.TRADE_CONFIRM, 5)
	local tradeCancelEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.TRADE_CANCEL, 5)
	local tradeCompleteEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.TRADE_COMPLETE, 5)
	local tradeIncomingEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.TRADE_INCOMING, 5)
	
	-- Helper to populate player list for trade selection
	local function populatePlayerList()
		if not playerSelectWindow then return end
		
		local playerList = playerSelectWindow:FindFirstChild("PlayerList")
		if not playerList then return end
		
		-- Clear existing
		for _, child in ipairs(playerList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		
		-- Add all other players
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				local playerBtn = Instance.new("TextButton")
				playerBtn.Name = otherPlayer.Name
				playerBtn.Size = UDim2.new(1, 0, 0, 40)
				playerBtn.BackgroundColor3 = THEME.LeafPanel
				playerBtn.Text = "👤 " .. otherPlayer.Name
				playerBtn.TextColor3 = THEME.TextLight
				playerBtn.Font = Enum.Font.GothamBold
				playerBtn.TextScaled = true
				playerBtn.Parent = playerList
				
				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 8)
				btnCorner.Parent = playerBtn
				
				playerBtn.MouseButton1Click:Connect(function()
					playerSelectWindow.Visible = false
					
					-- Send trade request
					if tradeRequestFunc then
						local result = tradeRequestFunc:InvokeServer(otherPlayer)
						if result and result.success then
							showNotification("Trade request sent to " .. otherPlayer.Name, THEME.TealGem, "🤝")
						else
							showNotification(result and result.message or "Failed to send trade request", THEME.AmberGlow, "❌")
						end
					end
				end)
			end
		end
	end
	
	-- Helper to update trade window display
	local function updateTradeDisplay()
		if not tradingWindow then return end
		
		local tradePanel = tradingWindow:FindFirstChild("TradePanel")
		if not tradePanel then return end
		
		-- Update partner label
		local partnerLabel = tradePanel:FindFirstChild("PartnerLabel")
		if partnerLabel and currentTradePartner then
			partnerLabel.Text = "Trading with: " .. currentTradePartner.Name
		end
		
		-- Update your offer display
		local yourOfferPanel = tradePanel:FindFirstChild("YourOfferPanel")
		if yourOfferPanel then
			local itemsScroll = yourOfferPanel:FindFirstChild("ItemsScroll")
			if itemsScroll then
				-- Clear existing
				for _, child in ipairs(itemsScroll:GetChildren()) do
					if child:IsA("Frame") or child:IsA("TextButton") then
						child:Destroy()
					end
				end
				
				-- Add items from myTradeOffer
				for i, item in ipairs(myTradeOffer) do
					if item.Type ~= "Coins" then
						local itemFrame = Instance.new("TextButton")
						itemFrame.Name = "Item" .. i
						itemFrame.Size = UDim2.new(0, 70, 0, 70)
						itemFrame.BackgroundColor3 = THEME.StonePanel
						itemFrame.Text = (item.SeedType or item.PetType or item.FruitType or "???")
						itemFrame.TextColor3 = THEME.TextLight
						itemFrame.Font = Enum.Font.Gotham
						itemFrame.TextScaled = true
						itemFrame.TextWrapped = true
						itemFrame.Parent = itemsScroll
						
						local itemCorner = Instance.new("UICorner")
						itemCorner.CornerRadius = UDim.new(0, 8)
						itemCorner.Parent = itemFrame
						
						-- Click to remove
						itemFrame.MouseButton1Click:Connect(function()
							if tradeUpdateEvent then
								tradeUpdateEvent:FireServer("remove", item)
							end
						end)
					end
				end
			end
			
			-- Update confirmation label
			local confirmedLabel = yourOfferPanel:FindFirstChild("ConfirmedLabel")
			if confirmedLabel then
				if myConfirmed then
					confirmedLabel.Text = "✅ Confirmed"
					confirmedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				else
					confirmedLabel.Text = "❌ Not Confirmed"
					confirmedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				end
			end
		end
		
		-- Update their offer display
		local theirOfferPanel = tradePanel:FindFirstChild("TheirOfferPanel")
		if theirOfferPanel then
			local itemsScroll = theirOfferPanel:FindFirstChild("ItemsScroll")
			if itemsScroll then
				-- Clear existing
				for _, child in ipairs(itemsScroll:GetChildren()) do
					if child:IsA("Frame") then
						child:Destroy()
					end
				end
				
				-- Add items from theirTradeOffer
				for i, item in ipairs(theirTradeOffer) do
					if item.Type ~= "Coins" then
						local itemFrame = Instance.new("Frame")
						itemFrame.Name = "Item" .. i
						itemFrame.Size = UDim2.new(0, 70, 0, 70)
						itemFrame.BackgroundColor3 = THEME.StonePanel
						itemFrame.Parent = itemsScroll
						
						local itemCorner = Instance.new("UICorner")
						itemCorner.CornerRadius = UDim.new(0, 8)
						itemCorner.Parent = itemFrame
						
						local itemLabel = Instance.new("TextLabel")
						itemLabel.Size = UDim2.new(1, 0, 1, 0)
						itemLabel.BackgroundTransparency = 1
						itemLabel.Text = (item.SeedType or item.PetType or item.FruitType or "???")
						itemLabel.TextColor3 = THEME.TextLight
						itemLabel.Font = Enum.Font.Gotham
						itemLabel.TextScaled = true
						itemLabel.TextWrapped = true
						itemLabel.Parent = itemFrame
					end
				end
			end
			
			-- Update their coins display
			local coinsLabel = theirOfferPanel:FindFirstChild("CoinsLabel")
			if coinsLabel then
				local theirCoins = 0
				for _, item in ipairs(theirTradeOffer) do
					if item.Type == "Coins" then
						theirCoins = item.Amount
						break
					end
				end
				coinsLabel.Text = "💰 " .. theirCoins .. " Coins"
			end
			
			-- Update confirmation label
			local confirmedLabel = theirOfferPanel:FindFirstChild("ConfirmedLabel")
			if confirmedLabel then
				if theirConfirmed then
					confirmedLabel.Text = "✅ Confirmed"
					confirmedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				else
					confirmedLabel.Text = "❌ Not Confirmed"
					confirmedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				end
			end
		end
		
		-- Update inventory for adding items
		local yourInventoryPanel = tradePanel:FindFirstChild("YourInventoryPanel")
		if yourInventoryPanel then
			local invScroll = yourInventoryPanel:FindFirstChild("InventoryScroll")
			if invScroll then
				-- Clear existing
				for _, child in ipairs(invScroll:GetChildren()) do
					if child:IsA("TextButton") then
						child:Destroy()
					end
				end
				
				-- Add seeds
				for _, seed in ipairs(playerInventory.Seeds or {}) do
					-- Check if already in offer
					local inOffer = false
					for _, item in ipairs(myTradeOffer) do
						if item.Id == seed.Id then
							inOffer = true
							break
						end
					end
					
					if not inOffer then
						local seedBtn = Instance.new("TextButton")
						seedBtn.Size = UDim2.new(0, 60, 0, 60)
						seedBtn.BackgroundColor3 = THEME.LeafPanel
						seedBtn.Text = seed.SeedType or "Seed"
						seedBtn.TextColor3 = THEME.TextLight
						seedBtn.Font = Enum.Font.Gotham
						seedBtn.TextScaled = true
						seedBtn.TextWrapped = true
						seedBtn.Parent = invScroll
						
						local btnCorner = Instance.new("UICorner")
						btnCorner.CornerRadius = UDim.new(0, 6)
						btnCorner.Parent = seedBtn
						
						seedBtn.MouseButton1Click:Connect(function()
							if tradeUpdateEvent then
								tradeUpdateEvent:FireServer("add", {
									Type = "Seed",
									Id = seed.Id,
									SeedType = seed.SeedType
								})
							end
						end)
					end
				end
				
				-- Add fruits
				for _, fruit in ipairs(playerInventory.Fruits or {}) do
					local inOffer = false
					for _, item in ipairs(myTradeOffer) do
						if item.Id == fruit.Id then
							inOffer = true
							break
						end
					end
					
					if not inOffer then
						local fruitBtn = Instance.new("TextButton")
						fruitBtn.Size = UDim2.new(0, 60, 0, 60)
						fruitBtn.BackgroundColor3 = THEME.AmberGlow
						fruitBtn.Text = fruit.FruitType or "Fruit"
						fruitBtn.TextColor3 = THEME.TextLight
						fruitBtn.Font = Enum.Font.Gotham
						fruitBtn.TextScaled = true
						fruitBtn.TextWrapped = true
						fruitBtn.Parent = invScroll
						
						local btnCorner = Instance.new("UICorner")
						btnCorner.CornerRadius = UDim.new(0, 6)
						btnCorner.Parent = fruitBtn
						
						fruitBtn.MouseButton1Click:Connect(function()
							if tradeUpdateEvent then
								tradeUpdateEvent:FireServer("add", {
									Type = "Fruit",
									Id = fruit.Id,
									FruitType = fruit.FruitType
								})
							end
						end)
					end
				end
				
				-- Add pets (not equipped)
				for _, pet in ipairs(playerInventory.Pets or {}) do
					if not isPetEquipped(pet.Id) and not isPetInGarden(pet.Id) then
						local inOffer = false
						for _, item in ipairs(myTradeOffer) do
							if item.Id == pet.Id then
								inOffer = true
								break
							end
						end
						
						if not inOffer then
							local petBtn = Instance.new("TextButton")
							petBtn.Size = UDim2.new(0, 60, 0, 60)
							petBtn.BackgroundColor3 = getRarityColor(pet.PetType)
							petBtn.Text = getPetDisplayName(pet.PetType)
							petBtn.TextColor3 = THEME.TextLight
							petBtn.Font = Enum.Font.Gotham
							petBtn.TextScaled = true
							petBtn.TextWrapped = true
							petBtn.Parent = invScroll
							
							local btnCorner = Instance.new("UICorner")
							btnCorner.CornerRadius = UDim.new(0, 6)
							btnCorner.Parent = petBtn
							
							petBtn.MouseButton1Click:Connect(function()
								if tradeUpdateEvent then
									tradeUpdateEvent:FireServer("add", {
										Type = "Pet",
										Id = pet.Id,
										PetType = pet.PetType
									})
								end
							end)
						end
					end
				end
			end
		end
	end
	
	-- Open trade window
	local function openTradeWindow(partner)
		currentTradePartner = partner
		myTradeOffer = {}
		theirTradeOffer = {}
		myConfirmed = false
		theirConfirmed = false
		
		if tradingWindow then
			updateTradeDisplay()
			tradingWindow.Visible = true
			hideHUD()
		end
	end
	
	-- Close trade window
	local function closeTradeWindow()
		if tradingWindow then
			tradingWindow.Visible = false
			showHUD()
		end
		currentTradePartner = nil
		currentTradeId = nil
		myTradeOffer = {}
		theirTradeOffer = {}
	end
	
	-- Trade button click - open player selection
	if tradeButton then
		tradeButton.MouseButton1Click:Connect(function()
			if playerSelectWindow then
				populatePlayerList()
				playerSelectWindow.Visible = true
				hideHUD()
			end
		end)
	end
	
	-- Player select window close
	if playerSelectWindow then
		local closeBtn = playerSelectWindow:FindFirstChild("CloseButton")
		if closeBtn then
			closeBtn.MouseButton1Click:Connect(function()
				playerSelectWindow.Visible = false
				showHUD()
			end)
		end
	end
	
	-- Trade window buttons
	if tradingWindow then
		local tradePanel = tradingWindow:FindFirstChild("TradePanel")
		if tradePanel then
			local actionPanel = tradePanel:FindFirstChild("ActionButtonsPanel")
			if actionPanel then
				local confirmBtn = actionPanel:FindFirstChild("ConfirmButton")
				local cancelBtn = actionPanel:FindFirstChild("CancelButton")
				
				if confirmBtn then
					confirmBtn.MouseButton1Click:Connect(function()
						if tradeConfirmEvent then
							tradeConfirmEvent:FireServer()
							myConfirmed = true
							updateTradeDisplay()
						end
					end)
				end
				
				if cancelBtn then
					cancelBtn.MouseButton1Click:Connect(function()
						if tradeCancelEvent then
							tradeCancelEvent:FireServer()
						end
						closeTradeWindow()
					end)
				end
			end
			
			-- Coins input
			local yourOfferPanel = tradePanel:FindFirstChild("YourOfferPanel")
			if yourOfferPanel then
				local coinsFrame = yourOfferPanel:FindFirstChild("CoinsFrame")
				if coinsFrame then
					local coinsInput = coinsFrame:FindFirstChild("CoinsInput")
					if coinsInput then
						coinsInput.FocusLost:Connect(function()
							local amount = tonumber(coinsInput.Text) or 0
							amount = math.max(0, math.floor(amount))
							coinsInput.Text = tostring(amount)
							
							if tradeUpdateEvent then
								tradeUpdateEvent:FireServer("setCoins", { Amount = amount })
							end
						end)
					end
				end
			end
		end
	end
	
	-- Trade request popup buttons
	if tradeRequestPopup then
		local acceptBtn = tradeRequestPopup:FindFirstChild("AcceptButton")
		local declineBtn = tradeRequestPopup:FindFirstChild("DeclineButton")
		local requesterIdValue = tradeRequestPopup:FindFirstChild("RequesterId")
		
		if acceptBtn then
			acceptBtn.MouseButton1Click:Connect(function()
				tradeRequestPopup.Visible = false
				if tradeResponseEvent and pendingRequesterId then
					tradeResponseEvent:FireServer(pendingRequesterId, true)
				end
			end)
		end
		
		if declineBtn then
			declineBtn.MouseButton1Click:Connect(function()
				tradeRequestPopup.Visible = false
				if tradeResponseEvent and pendingRequesterId then
					tradeResponseEvent:FireServer(pendingRequesterId, false)
				end
			end)
		end
	end
	
	-- Listen for incoming trade requests
	if tradeIncomingEvent then
		tradeIncomingEvent.OnClientEvent:Connect(function(data)
			if tradeRequestPopup then
				pendingRequesterId = data.requesterId
				
				local messageLabel = tradeRequestPopup:FindFirstChild("Message")
				if messageLabel then
					messageLabel.Text = data.requesterName .. " wants to trade with you!"
				end
				
				tradeRequestPopup.Visible = true
				playSound("WindowOpen")
			end
		end)
	end
	
	-- Listen for trade response (accepted/declined)
	if tradeResponseEvent then
		tradeResponseEvent.OnClientEvent:Connect(function(data)
			if data.accepted then
				-- Trade started!
				currentTradeId = data.tradeId
				openTradeWindow(data.partner)
				showNotification("Trade started with " .. data.partnerName, THEME.TealGem, "🤝")
			else
				showNotification(data.message or "Trade declined", THEME.AmberGlow, "❌")
			end
		end)
	end
	
	-- Listen for trade updates
	if tradeUpdateEvent then
		tradeUpdateEvent.OnClientEvent:Connect(function(data)
			-- Determine which offer is ours vs theirs
			if currentTradePartner then
				-- We need to figure out if we're player1 or player2
				-- The server sends offer1 and offer2
				-- For simplicity, we'll assume the order matches who started
				-- Actually, the server should send us our perspective
				-- Let's just use offer1 = requester, offer2 = target
				-- We'll handle this by checking if we initiated the trade
				myTradeOffer = data.offer1 or {}
				theirTradeOffer = data.offer2 or {}
				myConfirmed = data.confirmed1 or false
				theirConfirmed = data.confirmed2 or false
			end
			updateTradeDisplay()
		end)
	end
	
	-- Listen for trade cancel
	if tradeCancelEvent then
		tradeCancelEvent.OnClientEvent:Connect(function(data)
			closeTradeWindow()
			showNotification(data.reason or "Trade cancelled", THEME.AmberGlow, "❌")
		end)
	end
	
	-- Listen for trade complete
	if tradeCompleteEvent then
		tradeCompleteEvent.OnClientEvent:Connect(function(data)
			closeTradeWindow()
			if data.success then
				showNotification("Trade completed successfully!", THEME.TealGem, "✅")
			end
		end)
	end
	
	-- =============================================================================
	-- SHOP REFRESH TIMER
	-- =============================================================================
	local shopRefreshTimer = shopWindow and shopWindow:FindFirstChild("RefreshTimer")
	local getShopInventoryFunc = ReplicatedStorage:FindFirstChild(Constants.EVENTS.GET_SHOP_INVENTORY)
	local shopInventoryUpdateEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.SHOP_INVENTORY_UPDATE)
	
	-- Use module-scope shop inventory so populateShop sees server data
	currentShopInventory = currentShopInventory or {}
	local shopNextRefresh = 0
	
	-- Update shop timer display
	local function updateShopTimer()
		if not shopRefreshTimer then return end
		
		local remaining = math.max(0, shopNextRefresh - os.time())
		local hours = math.floor(remaining / 3600)
		local minutes = math.floor((remaining % 3600) / 60)
		local seconds = remaining % 60
		
		shopRefreshTimer.Text = string.format("🔄 Refreshes in: %02d:%02d:%02d", hours, minutes, seconds)
	end
	
	-- Start timer update loop
	task.spawn(function()
		while true do
			updateShopTimer()
			task.wait(1)
		end
	end)
	
	-- Listen for shop updates
	if shopInventoryUpdateEvent then
		shopInventoryUpdateEvent.OnClientEvent:Connect(function(data)
			currentShopInventory = data.inventory or {}
			shopNextRefresh = os.time() + (data.nextRefresh or 0)
			-- If shop window is open, refresh both the shop items and player inventory
			if shopWindow and shopWindow.Visible then
				populateShop() -- Refresh shop items with new stock
				updateShopInventoryGrid() -- Refresh player's inventory display
			end
		end)
	end
	
	-- Fetch initial shop data
	if getShopInventoryFunc then
		task.spawn(function()
			local data = getShopInventoryFunc:InvokeServer()
			if data then
				currentShopInventory = data.inventory or {}
				shopNextRefresh = os.time() + (data.nextRefresh or 0)
				-- Ensure the live shop UI shows the rotating catalog instead of the fallback
				populateShop()
				updateShopInventoryGrid()
			end
		end)
	end
	
	-- =============================================================================
	-- HOTBAR SETUP - Click slots to select
	-- =============================================================================
	local hotbarFrame = hudGroup and hudGroup:FindFirstChild("HotbarFrame") or (hudGroup and hudGroup:WaitForChild("HotbarFrame", 5))
	if hotbarFrame then
		local slotsContainer = hotbarFrame:FindFirstChild("Slots") or hotbarFrame
		for i = 1, 6 do
			local slot = slotsContainer:FindFirstChild("Slot" .. i)
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
	-- MOBILE BUTTONS (Root ScreenGui)
	-- =============================================================================
	-- Inventory button for mobile users and side panel
	local inventoryButton = findSideButton("InventoryButton")
	if not inventoryButton then
		local inventoryButtonFrame = screenGui:FindFirstChild("InventoryButton")
		if inventoryButtonFrame then
			local buttonChild = inventoryButtonFrame:FindFirstChildWhichIsA("GuiButton")
			if inventoryButtonFrame:IsA("GuiButton") then
				inventoryButton = inventoryButtonFrame
			else
				inventoryButton = buttonChild
			end
		end
	end

	if inventoryButton and inventoryButton:IsA("GuiButton") and inventoryWindow then
		inventoryButton.MouseButton1Click:Connect(function()
			playSound("ButtonClick")
			inventoryWindow.Visible = not inventoryWindow.Visible
			if inventoryWindow.Visible then
				updateFullInventory()
				hideHUD()
				playSound("WindowOpen")
			else
				showHUD()
				playSound("WindowClose")
			end
		end)
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
				hideHUD()
				playSound("WindowOpen")
			else
				showHUD()
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
	
	-- Signal that UI is fully ready
	UIHandler.IsReady = true
	UIHandler.ReadyEvent:Fire()
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

-- Open specific UI windows (called by NPCDialogueHandler)
function UIHandler.OpenShopWindow()
	if not screenGui then return end
	local shopWindow = windowGroup and windowGroup:FindFirstChild("ShopWindow")
	if shopWindow then
		NPCUIHandler.MoveCameraToNPC("ShopCamera")
		populateShop() -- Populate shop items (left panel)
		updateShopInventoryGrid() -- Update player inventory (right panel)
		shopWindow.Visible = true
		hideHUD()
		playSound("WindowOpen")
	end
end

function UIHandler.OpenSellWindow()
	if not screenGui then return end
	local sellWindow = windowGroup and windowGroup:FindFirstChild("SellWindow")
	if sellWindow then
		NPCUIHandler.MoveCameraToNPC("SellCamera")
		updateSellShop() -- Populate sell shop items (left panel)
		updateSellInventoryGrid() -- Update player inventory (right panel)
		sellWindow.Visible = true
		hideHUD()
		playSound("WindowOpen")
	end
end

function UIHandler.OpenPetShopWindow()
	if not screenGui then return end
	local petShopWindow = windowGroup and windowGroup:FindFirstChild("PetShopWindow")
	if petShopWindow then
		NPCUIHandler.MoveCameraToNPC("PetCamera")
		petShopWindow.Visible = true
		updatePetShopWindow()
		hideHUD()
		playSound("WindowOpen")
	end
end

function UIHandler.OpenGearShopWindow()
	if not screenGui then return end
	local gearShopWindow = windowGroup and windowGroup:FindFirstChild("GearShopWindow")
	if gearShopWindow then
		NPCUIHandler.MoveCameraToNPC("GearCamera")
		gearShopWindow.Visible = true
		updateGearShopWindow()
		hideHUD()
		playSound("WindowOpen")
	end
end

function UIHandler.OpenPetsWindow()
	if not screenGui then return end
	local petsWindow = windowGroup and windowGroup:FindFirstChild("PetsWindow")
	if petsWindow then
		petsWindow.Visible = true
		updatePetsWindow()
		hideHUD()
	end
end

return UIHandler
