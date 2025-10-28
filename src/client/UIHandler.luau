-- UIHandler.luau
-- Manages all UI elements including inventory, currency, weather, and shop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Config = require(ReplicatedStorage.Shared.Config)

local UIHandler = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Player data cache
local playerCoins = 0
local playerInventory = {
	Seeds = {},
	Pets = {},
	EquippedPet = nil
}
local currentWeather = "Sunny"
local selectedPlantType = nil

-- Helper function to find player's assigned garden
local function getPlayerGarden()
	local Config = require(ReplicatedStorage.Shared.Config)
	local gardensFolder = game.Workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then 
		warn("[getPlayerGarden] Gardens folder not found in Workspace")
		return nil 
	end
	
	-- Check each garden's OwnerUserId attribute (more reliable than sign text)
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local ownerId = garden:GetAttribute("OwnerUserId")
			if ownerId == player.UserId then
				print(string.format("[getPlayerGarden] ✓ Found garden: %s (OwnerUserId: %d)", garden.Name, ownerId))
				return garden
			end
		end
	end
	
	print(string.format("[getPlayerGarden] No garden found for UserId: %d", player.UserId))
	return nil
end

-- Helper function to find next available slot in player's garden
local function getNextAvailableSlot()
	local Config = require(ReplicatedStorage.Shared.Config)
	local garden = getPlayerGarden()
	if not garden then return 1 end
	
	-- Find Plots folder within garden
	local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
	if not plotsFolder then return 1 end
	
	-- Track which slots are occupied
	local occupiedSlots = {}
	
	-- Check each PlantAnchor for existing plants
	for i = 1, Config.Garden.SlotsPerGarden do
		local anchorName = Config.Garden.PlantAnchorPrefix .. tostring(i)
		local anchor = plotsFolder:FindFirstChild(anchorName)
		if anchor then
			-- Check if anchor has a plant model
			for _, child in ipairs(anchor:GetChildren()) do
				if child:IsA("Model") and child:GetAttribute("PlantType") then
					occupiedSlots[i] = true
					break
				end
			end
		end
	end
	
	-- Find first available slot
	for i = 1, Config.Garden.SlotsPerGarden do
		if not occupiedSlots[i] then
			return i
		end
	end
	
	-- If all slots occupied, return 1 (server will handle the error)
	return 1
end

-- Create main UI
local function createMainUI()
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FeyGardenUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Currency Display (top right)
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.Size = UDim2.new(0, 200, 0, 50)
	currencyFrame.Position = UDim2.new(1, -210, 0, 10)
	currencyFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	currencyFrame.BorderSizePixel = 0
	currencyFrame.Parent = screenGui
	
	local currencyCorner = Instance.new("UICorner")
	currencyCorner.CornerRadius = UDim.new(0, 8)
	currencyCorner.Parent = currencyFrame
	
	local coinIcon = Instance.new("TextLabel")
	coinIcon.Size = UDim2.new(0, 40, 1, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "💰"
	coinIcon.TextScaled = true
	coinIcon.Parent = currencyFrame
	
	local coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(1, -45, 1, 0)
	coinLabel.Position = UDim2.new(0, 45, 0, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Text = "0"
	coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	coinLabel.TextScaled = true
	coinLabel.Font = Enum.Font.SourceSansBold
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = currencyFrame
	
	-- Weather Display (top left)
	local weatherFrame = Instance.new("Frame")
	weatherFrame.Name = "WeatherFrame"
	weatherFrame.Size = UDim2.new(0, 180, 0, 50)
	weatherFrame.Position = UDim2.new(0, 10, 0, 10)
	weatherFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	weatherFrame.BorderSizePixel = 0
	weatherFrame.Parent = screenGui
	
	local weatherCorner = Instance.new("UICorner")
	weatherCorner.CornerRadius = UDim.new(0, 8)
	weatherCorner.Parent = weatherFrame
	
	local weatherLabel = Instance.new("TextLabel")
	weatherLabel.Name = "WeatherLabel"
	weatherLabel.Size = UDim2.new(1, 0, 1, 0)
	weatherLabel.BackgroundTransparency = 1
	weatherLabel.Text = "☀️ Sunny"
	weatherLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	weatherLabel.TextScaled = true
	weatherLabel.Font = Enum.Font.SourceSansBold
	weatherLabel.Parent = weatherFrame
	
	-- Inventory Frame (bottom left)
	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0, 400, 0, 100)
	inventoryFrame.Position = UDim2.new(0, 10, 1, -110)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Parent = screenGui
	
	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 8)
	invCorner.Parent = inventoryFrame
	
	local invTitle = Instance.new("TextLabel")
	invTitle.Size = UDim2.new(1, 0, 0, 25)
	invTitle.BackgroundTransparency = 1
	invTitle.Text = "Seeds Inventory"
	invTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	invTitle.Font = Enum.Font.SourceSansBold
	invTitle.TextSize = 18
	invTitle.Parent = inventoryFrame
	
	-- Seed slots
	local seedContainer = Instance.new("Frame")
	seedContainer.Name = "SeedContainer"
	seedContainer.Size = UDim2.new(1, -20, 1, -35)
	seedContainer.Position = UDim2.new(0, 10, 0, 30)
	seedContainer.BackgroundTransparency = 1
	seedContainer.Parent = inventoryFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = seedContainer
	
	-- Fruits Inventory Frame (bottom left, below seeds)
	local fruitsFrame = Instance.new("Frame")
	fruitsFrame.Name = "FruitsFrame"
	fruitsFrame.Size = UDim2.new(0, 400, 0, 100)
	fruitsFrame.Position = UDim2.new(0, 10, 1, -220)
	fruitsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	fruitsFrame.BorderSizePixel = 0
	fruitsFrame.Parent = screenGui
	
	local fruitsCorner = Instance.new("UICorner")
	fruitsCorner.CornerRadius = UDim.new(0, 8)
	fruitsCorner.Parent = fruitsFrame
	
	local fruitsTitle = Instance.new("TextLabel")
	fruitsTitle.Size = UDim2.new(1, 0, 0, 25)
	fruitsTitle.BackgroundTransparency = 1
	fruitsTitle.Text = "Fruits Inventory"
	fruitsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	fruitsTitle.Font = Enum.Font.SourceSansBold
	fruitsTitle.TextSize = 18
	fruitsTitle.Parent = fruitsFrame
	
	-- Fruits container
	local fruitsContainer = Instance.new("Frame")
	fruitsContainer.Name = "FruitsContainer"
	fruitsContainer.Size = UDim2.new(1, -20, 1, -35)
	fruitsContainer.Position = UDim2.new(0, 10, 0, 30)
	fruitsContainer.BackgroundTransparency = 1
	fruitsContainer.Parent = fruitsFrame
	
	local fruitsLayout = Instance.new("UIListLayout")
	fruitsLayout.FillDirection = Enum.FillDirection.Horizontal
	fruitsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	fruitsLayout.Padding = UDim.new(0, 10)
	fruitsLayout.Parent = fruitsContainer
	
	return screenGui
end

-- Create shop UI
local function createShopUI()
	local screenGui = playerGui:FindFirstChild("FeyGardenUI")
	if not screenGui then return end
	
	-- Shop Window
	local shopWindow = Instance.new("Frame")
	shopWindow.Name = "ShopWindow"
	shopWindow.Size = UDim2.new(0, 500, 0, 400)
	shopWindow.Position = UDim2.new(0.5, -250, 0.5, -200)
	shopWindow.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	shopWindow.Visible = false
	shopWindow.Parent = screenGui
	
	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 12)
	shopCorner.Parent = shopWindow
	
	-- Title
	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.new(1, 0, 0, 50)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "🌿 Seed & Pet Shop 🐾"
	shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopTitle.Font = Enum.Font.SourceSansBold
	shopTitle.TextSize = 24
	shopTitle.Parent = shopWindow
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.TextSize = 20
	closeButton.Parent = shopWindow
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		shopWindow.Visible = false
	end)
	
	-- Items container
	local itemsContainer = Instance.new("ScrollingFrame")
	itemsContainer.Size = UDim2.new(1, -20, 1, -70)
	itemsContainer.Position = UDim2.new(0, 10, 0, 55)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.BorderSizePixel = 0
	itemsContainer.ScrollBarThickness = 8
	itemsContainer.Parent = shopWindow
	
	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.Padding = UDim.new(0, 10)
	itemsLayout.Parent = itemsContainer
	
	-- Add seed items
	for plantType, config in pairs(Constants.PLANT_CONFIG) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Size = UDim2.new(1, -10, 0, 80)
		itemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		itemFrame.Parent = itemsContainer
		
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 8)
		itemCorner.Parent = itemFrame
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "🌱 " .. plantType .. " Seed"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.TextSize = 18
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemFrame
		
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
		priceLabel.Position = UDim2.new(0, 10, 0.5, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "💰 " .. config.SeedPrice .. " coins"
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		priceLabel.Font = Enum.Font.SourceSans
		priceLabel.TextSize = 16
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = itemFrame
		
		local buyButton = Instance.new("TextButton")
		buyButton.Size = UDim2.new(0, 100, 0, 60)
		buyButton.Position = UDim2.new(1, -110, 0.5, -30)
		buyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		buyButton.Text = "BUY"
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.Font = Enum.Font.SourceSansBold
		buyButton.TextSize = 18
		buyButton.Parent = itemFrame
		
		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyButton
		
		buyButton.MouseButton1Click:Connect(function()
			local buySeedEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_SEED)
			if buySeedEvent then
				buySeedEvent:FireServer(plantType, 1)
			end
		end)
	end
	
	-- Add pet items
	for petType, config in pairs(Constants.PET_CONFIG) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = petType .. "PetFrame"
		itemFrame.Size = UDim2.new(1, -10, 0, 80)
		itemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		itemFrame.Parent = itemsContainer
		
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 8)
		itemCorner.Parent = itemFrame
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "🐾 " .. petType .. " Pet"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.TextSize = 18
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemFrame
		
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
		priceLabel.Position = UDim2.new(0, 10, 0.5, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "💰 " .. config.Price .. " coins"
		priceLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		priceLabel.Font = Enum.Font.SourceSans
		priceLabel.TextSize = 16
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = itemFrame
		
		local actionButton = Instance.new("TextButton")
		actionButton.Name = "ActionButton"
		actionButton.Size = UDim2.new(0, 100, 0, 60)
		actionButton.Position = UDim2.new(1, -110, 0.5, -30)
		actionButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		actionButton.Text = "BUY"
		actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		actionButton.Font = Enum.Font.SourceSansBold
		actionButton.TextSize = 18
		actionButton.Parent = itemFrame
		
		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = actionButton
		
		-- Store reference for updating later
		itemFrame:SetAttribute("PetType", petType)
		
		actionButton.MouseButton1Click:Connect(function()
			local isOwned = playerInventory.Pets and playerInventory.Pets[petType]
			
			if isOwned then
				-- Equip the pet
				local equipPetEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.EQUIP_PET)
				if equipPetEvent then
					equipPetEvent:FireServer(petType)
				end
			else
				-- Buy the pet
				local buyPetEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_PET)
				if buyPetEvent then
					buyPetEvent:FireServer(petType)
				end
			end
		end)
	end
	
	-- Update canvas size
	itemsContainer.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y)
	itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		itemsContainer.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y)
	end)
end

-- Create sell shop UI
local function createSellShopUI()
	local screenGui = playerGui:FindFirstChild("FeyGardenUI")
	if not screenGui then return end
	
	-- Sell Shop Window
	local sellWindow = Instance.new("Frame")
	sellWindow.Name = "SellWindow"
	sellWindow.Size = UDim2.new(0, 500, 0, 400)
	sellWindow.Position = UDim2.new(0.5, -250, 0.5, -200)
	sellWindow.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	sellWindow.Visible = false
	sellWindow.Parent = screenGui
	
	local sellCorner = Instance.new("UICorner")
	sellCorner.CornerRadius = UDim.new(0, 12)
	sellCorner.Parent = sellWindow
	
	-- Title
	local sellTitle = Instance.new("TextLabel")
	sellTitle.Size = UDim2.new(1, 0, 0, 50)
	sellTitle.BackgroundTransparency = 1
	sellTitle.Text = "🍎 Sell Fruits"
	sellTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellTitle.Font = Enum.Font.SourceSansBold
	sellTitle.TextSize = 24
	sellTitle.Parent = sellWindow
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = sellWindow
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		sellWindow.Visible = false
	end)
	
	-- Scrolling frame for fruits
	local itemsContainer = Instance.new("ScrollingFrame")
	itemsContainer.Size = UDim2.new(1, -20, 1, -70)
	itemsContainer.Position = UDim2.new(0, 10, 0, 60)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.ScrollBarThickness = 6
	itemsContainer.Parent = sellWindow
	
	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.Padding = UDim.new(0, 10)
	itemsLayout.Parent = itemsContainer
	
	-- Update canvas size dynamically
	itemsContainer.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y)
	itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		itemsContainer.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y)
	end)
end

-- Update currency display
local function updateCurrencyDisplay(coins, isTotal)
	local screenGui = playerGui:FindFirstChild("FeyGardenUI")
	if not screenGui then return end
	
	local coinLabel = screenGui.CurrencyFrame:FindFirstChild("CoinLabel")
	if not coinLabel then return end
	
	if isTotal then
		playerCoins = coins
	else
		playerCoins = playerCoins + coins
	end
	
	coinLabel.Text = tostring(playerCoins)
end

-- Update inventory display
local function updateInventoryDisplay(inventory)
	playerInventory = inventory
	
	local screenGui = playerGui:FindFirstChild("FeyGardenUI")
	if not screenGui then return end
	
	-- Check if selected seed still exists with count > 0, if not unselect
	if selectedPlantType then
		local seedCount = inventory.Seeds and inventory.Seeds[selectedPlantType] or 0
		if seedCount <= 0 then
			selectedPlantType = nil
			print("[UIHandler] 🌱 Auto-unselected seed (count is 0)")
		end
	end
	
	-- Update seed inventory display
	local seedContainer = screenGui.InventoryFrame:FindFirstChild("SeedContainer")
	if not seedContainer then return end
	
	-- Clear existing items
	for _, child in ipairs(seedContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Add seed items
	if inventory.Seeds then
		for plantType, count in pairs(inventory.Seeds) do
			-- Only show seeds with count > 0
			if count and count > 0 then
				local config = Constants.PLANT_CONFIG[plantType]
				if config then
					local seedFrame = Instance.new("Frame")
					seedFrame.Name = plantType
					seedFrame.Size = UDim2.new(0, 80, 1, 0)
					seedFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					seedFrame.Parent = seedContainer
					
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 8)
					corner.Parent = seedFrame
					
					local button = Instance.new("TextButton")
					button.Size = UDim2.new(1, 0, 0.7, 0)
					button.BackgroundTransparency = 1
					button.Text = "🌱"
					button.TextScaled = true
					button.Parent = seedFrame
					
					button.MouseButton1Click:Connect(function()
						-- Toggle selection: if already selected, unselect it
						if selectedPlantType == plantType then
							selectedPlantType = nil
							print("[UIHandler] 🌱 SEED UNSELECTED")
							-- Reset all highlights
							for _, child in ipairs(seedContainer:GetChildren()) do
								if child:IsA("Frame") then
									child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
								end
							end
						else
							selectedPlantType = plantType
							print(string.format("[UIHandler] 🌱 SEED SELECTED: %s (Count: %d)", plantType, count))
							
							-- Visual feedback - highlight selected seed
							for _, child in ipairs(seedContainer:GetChildren()) do
								if child:IsA("Frame") then
									child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
								end
							end
							seedFrame.BackgroundColor3 = Color3.fromRGB(100, 150, 100) -- Highlight selected
						end
					end)
					
					local countLabel = Instance.new("TextLabel")
					countLabel.Size = UDim2.new(1, 0, 0.3, 0)
					countLabel.Position = UDim2.new(0, 0, 0.7, 0)
					countLabel.BackgroundTransparency = 1
					countLabel.Text = tostring(count)
					countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					countLabel.Font = Enum.Font.SourceSansBold
					countLabel.TextScaled = true
					countLabel.Parent = seedFrame
				end
			end
		end
	end
	
	-- Update fruits inventory display
	local fruitsContainer = screenGui.FruitsFrame:FindFirstChild("FruitsContainer")
	if fruitsContainer then
		-- Clear existing items
		for _, child in ipairs(fruitsContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		-- Add fruit items
		if inventory.Fruits then
			for fruitName, count in pairs(inventory.Fruits) do
				-- Only show fruits with count > 0
				if count and count > 0 then
					local fruitFrame = Instance.new("Frame")
					fruitFrame.Name = fruitName
					fruitFrame.Size = UDim2.new(0, 80, 1, 0)
					fruitFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					fruitFrame.Parent = fruitsContainer
					
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 8)
					corner.Parent = fruitFrame
					
					local icon = Instance.new("TextLabel")
					icon.Size = UDim2.new(1, 0, 0.7, 0)
					icon.BackgroundTransparency = 1
					icon.Text = "🍎"
					icon.TextScaled = true
					icon.Parent = fruitFrame
					
					local countLabel = Instance.new("TextLabel")
					countLabel.Size = UDim2.new(1, 0, 0.3, 0)
					countLabel.Position = UDim2.new(0, 0, 0.7, 0)
					countLabel.BackgroundTransparency = 1
					countLabel.Text = tostring(count)
					countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					countLabel.Font = Enum.Font.SourceSansBold
					countLabel.TextScaled = true
					countLabel.Parent = fruitFrame
				end
			end
		end
	end
end

-- Update weather display
local function updateWeatherDisplay(weather)
	currentWeather = weather
	
	local screenGui = playerGui:FindFirstChild("FeyGardenUI")
	if not screenGui then return end
	
	local weatherLabel = screenGui.WeatherFrame:FindFirstChild("WeatherLabel")
	if not weatherLabel then return end
	
	local weatherIcons = {
		[Constants.WEATHER_TYPES.SUNNY] = "☀️",
		[Constants.WEATHER_TYPES.RAINY] = "🌧️",
		[Constants.WEATHER_TYPES.STORMY] = "⛈️"
	}
	
	local icon = weatherIcons[weather] or "☀️"
	weatherLabel.Text = icon .. " " .. weather
end

-- Update shop pet display based on ownership
local function updateShopPetDisplay()
	local screenGui = playerGui:FindFirstChild("FeyGardenUI")
	if not screenGui then return end
	
	local shopWindow = screenGui:FindFirstChild("ShopWindow")
	if not shopWindow then return end
	
	local itemsContainer = shopWindow:FindFirstChild("ScrollingFrame")
	if not itemsContainer then return end
	
	-- Update each pet item frame
	for _, itemFrame in ipairs(itemsContainer:GetChildren()) do
		if itemFrame:IsA("Frame") and itemFrame:GetAttribute("PetType") then
			local petType = itemFrame:GetAttribute("PetType")
			local actionButton = itemFrame:FindFirstChild("ActionButton")
			local priceLabel = itemFrame:FindFirstChild("PriceLabel")
			
			if actionButton and priceLabel then
				local isOwned = playerInventory.Pets and playerInventory.Pets[petType]
				local isEquipped = playerInventory.EquippedPet == petType
				
				if isOwned then
					-- Player owns this pet
					if isEquipped then
						actionButton.Text = "EQUIPPED"
						actionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
						priceLabel.Text = "✓ Currently Active"
						priceLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
						itemFrame.BackgroundColor3 = Color3.fromRGB(50, 90, 50) -- Highlight
					else
						actionButton.Text = "EQUIP"
						actionButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
						priceLabel.Text = "✓ Owned"
						priceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
						itemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
					end
				else
					-- Player doesn't own this pet
					local config = Constants.PET_CONFIG[petType]
					actionButton.Text = "BUY"
					actionButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
					if config then
						priceLabel.Text = "💰 " .. config.Price .. " coins"
						priceLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
					end
					itemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
				end
			end
		end
	end
end

-- Update sell shop display with player's fruits
local function updateSellShopDisplay()
	local screenGui = playerGui:FindFirstChild("FeyGardenUI")
	if not screenGui then return end
	
	local sellWindow = screenGui:FindFirstChild("SellWindow")
	if not sellWindow then return end
	
	local itemsContainer = sellWindow:FindFirstChild("ScrollingFrame")
	if not itemsContainer then return end
	
	-- Clear existing items
	for _, child in ipairs(itemsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Add fruit items from inventory
	if playerInventory.Fruits then
		for fruitName, count in pairs(playerInventory.Fruits) do
			if count > 0 then
				-- Get the plant type from fruit name (remove "Fruit" suffix)
				local plantType = fruitName:gsub("Fruit$", "")
				local config = Constants.PLANT_CONFIG[plantType]
				
				if config and config.FruitSellPrice then
					local itemFrame = Instance.new("Frame")
					itemFrame.Name = fruitName
					itemFrame.Size = UDim2.new(1, 0, 0, 80)
					itemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
					itemFrame.Parent = itemsContainer
					
					local itemCorner = Instance.new("UICorner")
					itemCorner.CornerRadius = UDim.new(0, 8)
					itemCorner.Parent = itemFrame
					
					-- Icon
					local icon = Instance.new("TextLabel")
					icon.Size = UDim2.new(0, 60, 0, 60)
					icon.Position = UDim2.new(0, 10, 0.5, -30)
					icon.BackgroundTransparency = 1
					icon.Text = "🍎"
					icon.TextScaled = true
					icon.Parent = itemFrame
					
					-- Name and count
					local nameLabel = Instance.new("TextLabel")
					nameLabel.Size = UDim2.new(0, 200, 0, 30)
					nameLabel.Position = UDim2.new(0, 80, 0, 10)
					nameLabel.BackgroundTransparency = 1
					nameLabel.Text = fruitName .. " x" .. count
					nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					nameLabel.Font = Enum.Font.SourceSansBold
					nameLabel.TextSize = 18
					nameLabel.TextXAlignment = Enum.TextXAlignment.Left
					nameLabel.Parent = itemFrame
					
					-- Price per unit
					local priceLabel = Instance.new("TextLabel")
					priceLabel.Size = UDim2.new(0, 200, 0, 20)
					priceLabel.Position = UDim2.new(0, 80, 0, 45)
					priceLabel.BackgroundTransparency = 1
					priceLabel.Text = "💰 " .. config.FruitSellPrice .. " coins each"
					priceLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
					priceLabel.Font = Enum.Font.SourceSans
					priceLabel.TextSize = 14
					priceLabel.TextXAlignment = Enum.TextXAlignment.Left
					priceLabel.Parent = itemFrame
					
					-- Sell All button
					local sellAllButton = Instance.new("TextButton")
					sellAllButton.Size = UDim2.new(0, 100, 0, 35)
					sellAllButton.Position = UDim2.new(1, -110, 0.5, -17.5)
					sellAllButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
					sellAllButton.Text = "SELL ALL"
					sellAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
					sellAllButton.Font = Enum.Font.SourceSansBold
					sellAllButton.TextSize = 16
					sellAllButton.Parent = itemFrame
					
					local sellAllCorner = Instance.new("UICorner")
					sellAllCorner.CornerRadius = UDim.new(0, 8)
					sellAllCorner.Parent = sellAllButton
					
					sellAllButton.MouseButton1Click:Connect(function()
						local sellFruitEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.SELL_FRUIT)
						if sellFruitEvent then
							sellFruitEvent:FireServer(fruitName, count)
						end
					end)
				end
			end
		end
	end
end

-- Initialize UI Handler
function UIHandler.Initialize()
	print("UIHandler initialized")
	
	-- Create UI
	local mainUI = createMainUI()
	createShopUI()
	createSellShopUI()
	
	-- Setup ProximityPrompt for shop
	local shopPart = workspace:WaitForChild(Config.World.ShopPartName, 10)
	local shopWindow = mainUI:FindFirstChild("ShopWindow")
	
	if shopPart and shopWindow then
		local proximityPrompt = shopPart:FindFirstChildOfClass("ProximityPrompt")
		
		if proximityPrompt then
			proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
				if playerWhoTriggered == player then
					shopWindow.Visible = not shopWindow.Visible
					print("[UIHandler] Shop toggled via ProximityPrompt")
				end
			end)
		else
			warn("[UIHandler] No ProximityPrompt found on " .. Config.World.ShopPartName)
		end
	else
		if not shopPart then
			warn("[UIHandler] ShopPart not found in workspace: " .. Config.World.ShopPartName)
		end
	end
	
	-- Setup ProximityPrompt for sell shop
	local sellPart = workspace:WaitForChild(Config.World.SellPartName, 10)
	local sellWindow = mainUI:FindFirstChild("SellWindow")
	
	if sellPart and sellWindow then
		local proximityPrompt = sellPart:FindFirstChildOfClass("ProximityPrompt")
		
		if proximityPrompt then
			proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
				if playerWhoTriggered == player then
					sellWindow.Visible = not sellWindow.Visible
					if sellWindow.Visible then
						updateSellShopDisplay() -- Update fruits when opening sell shop
					end
					print("[UIHandler] Sell shop toggled via ProximityPrompt")
				end
			end)
		else
			warn("[UIHandler] No ProximityPrompt found on " .. Config.World.SellPartName)
		end
	else
		if not sellPart then
			warn("[UIHandler] SellPart not found in workspace: " .. Config.World.SellPartName)
		end
	end
	
	-- Listen for currency updates
	local updateCurrencyEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_CURRENCY, 10)
	if updateCurrencyEvent then
		updateCurrencyEvent.OnClientEvent:Connect(updateCurrencyDisplay)
	else
		warn("UpdateCurrency RemoteEvent not found!")
	end
	
	-- Listen for inventory updates
	local updateInventoryEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_INVENTORY, 10)
	if updateInventoryEvent then
		updateInventoryEvent.OnClientEvent:Connect(function(inventory)
			updateInventoryDisplay(inventory)
			updateShopPetDisplay() -- Update pet buttons when inventory changes
			updateSellShopDisplay() -- Update sell shop when inventory changes
		end)
	else
		warn("UpdateInventory RemoteEvent not found!")
	end
	
	-- Listen for weather updates
	local weatherChangedEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED, 10)
	if weatherChangedEvent then
		weatherChangedEvent.OnClientEvent:Connect(updateWeatherDisplay)
	else
		warn("WeatherChanged RemoteEvent not found!")
	end
	
	-- Setup ClickDetector connections for PlantAnchors
	local Config = require(ReplicatedStorage.Shared.Config)
	local function setupGardenClicks(garden)
		print(string.format("[UIHandler] Setting up garden clicks for: %s", garden.Name))
		
		local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
		if not plotsFolder then 
			warn(string.format("[UIHandler] No Plots folder found in %s", garden.Name))
			return 
		end
		
		print(string.format("[UIHandler] Found Plots folder, setting up %d anchors", Config.Garden.SlotsPerGarden))
		local setupCount = 0
		
		for i = 1, Config.Garden.SlotsPerGarden do
			local anchorName = Config.Garden.PlantAnchorPrefix .. tostring(i)
			local anchor = plotsFolder:FindFirstChild(anchorName)
			
			if not anchor then
				warn(string.format("[UIHandler] Anchor not found: %s", anchorName))
			elseif not anchor:IsA("BasePart") then
				warn(string.format("[UIHandler] %s is not a BasePart, it's a %s", anchorName, anchor.ClassName))
			else
				local clickDetector = anchor:FindFirstChildOfClass("ClickDetector")
				if not clickDetector then
					warn(string.format("[UIHandler] No ClickDetector found on %s", anchorName))
				else
					clickDetector.MouseClick:Connect(function(playerWhoClicked)
						print(string.format("[UIHandler] 🖱️ CLICK DETECTED on %s by %s", anchor.Name, playerWhoClicked.Name))
						
						if playerWhoClicked ~= player then 
							print(string.format("[UIHandler] ❌ Click was by different player: %s (expected %s)", playerWhoClicked.Name, player.Name))
							return 
						end
						
						print(string.format("[UIHandler] ✓ Click is by local player"))
						
						-- Check if player has a seed selected
						if not selectedPlantType then
							warn("[UIHandler] ❌ No seed selected! Click a seed in your inventory first.")
							return
						end
						
						print(string.format("[UIHandler] ✓ Selected plant type: %s", selectedPlantType))
						
						-- Check if a tool is equipped
						local character = player.Character
						if character then
							local equippedTool = character:FindFirstChildOfClass("Tool")
							if equippedTool then 
								print(string.format("[UIHandler] ❌ Tool equipped: %s - not planting", equippedTool.Name))
								return 
							end
						end
						
						print("[UIHandler] ✓ No tool equipped")
						
						-- Find which slot this anchor is
						local slotIndex = tonumber(string.match(anchor.Name, "%d+"))
						if not slotIndex then 
							warn(string.format("[UIHandler] ❌ Could not extract slot number from %s", anchor.Name))
							return 
						end
						
						print(string.format("[UIHandler] ✓ Slot index: %d", slotIndex))
						
						-- Send plant request to server
						local plantSeedEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.PLANT_SEED)
						if not plantSeedEvent then
							warn("[UIHandler] ❌ PlantSeed event not found!")
							return
						end
						
						print(string.format("[UIHandler] 🌱 SENDING PLANT REQUEST - Slot: %d, Plant: %s", slotIndex, selectedPlantType))
						plantSeedEvent:FireServer(slotIndex, selectedPlantType)
					end)
					setupCount = setupCount + 1
					print(string.format("[UIHandler] ✓ Connected ClickDetector for %s", anchorName))
				end
			end
		end
		
		print(string.format("[UIHandler] ✅ Setup complete - %d/%d anchors connected", setupCount, Config.Garden.SlotsPerGarden))
	end
	
	-- Setup clicks for player's garden when they get one
	print("[UIHandler] Waiting for player garden assignment...")
	task.spawn(function()
		local attempts = 0
		while true do
			task.wait(1)
			attempts = attempts + 1
			local garden = getPlayerGarden()
			if garden then
				print(string.format("[UIHandler] ✅ Found player garden after %d attempts: %s", attempts, garden.Name))
				setupGardenClicks(garden)
				break
			else
				if attempts % 5 == 0 then
					print(string.format("[UIHandler] Still waiting for garden assignment (attempt %d)...", attempts))
				end
			end
		end
	end)
end

-- Listen for harvest fruit events
local harvestFruitEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.HARVEST_FRUIT)
if harvestFruitEvent then
	harvestFruitEvent.OnClientEvent:Connect(function(fruitName, amount)
		print(string.format("[UIHandler] 🍎 Harvested %dx %s!", amount, fruitName))
		
		-- Show notification
		local screenGui = playerGui:FindFirstChild("FeyGardenUI")
		if screenGui then
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0, 300, 0, 50)
			notification.Position = UDim2.new(0.5, -150, 0.3, 0)
			notification.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
			notification.TextColor3 = Color3.fromRGB(255, 255, 255)
			notification.Text = string.format("+ %dx %s", amount, fruitName)
			notification.Font = Enum.Font.GothamBold
			notification.TextScaled = true
			notification.Parent = screenGui
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 12)
			corner.Parent = notification
			
			-- Animate and remove
			task.spawn(function()
				task.wait(2)
				notification:Destroy()
			end)
		end
	end)
end

return UIHandler
