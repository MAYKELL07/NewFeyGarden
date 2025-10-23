-- UIHandler.luau
-- Manages all UI elements including inventory, currency, weather, and shop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)

local UIHandler = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Player data cache
local playerCoins = 0
local playerInventory = {}
local currentWeather = "Sunny"
local selectedPlantType = nil

-- Helper function to find next available slot
local function getNextAvailableSlot()
	local Config = require(ReplicatedStorage.Shared.Config)
	local plotsFolder = game.Workspace:FindFirstChild(Config.World.PlotsFolder)
	if not plotsFolder then return 1 end
	
	-- Find player's plot
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("Owner") == player.UserId then
			-- Track which slots are occupied
			local occupiedSlots = {}
			for _, child in ipairs(plot:GetChildren()) do
				if child:IsA("Model") and child:GetAttribute("SlotIndex") then
					occupiedSlots[child:GetAttribute("SlotIndex")] = true
				end
			end
			
			-- Find first available slot
			for i = 1, Constants.MAX_PLANTS_PER_PLOT do
				if not occupiedSlots[i] then
					return i
				end
			end
			
			-- If all slots occupied, return 1
			return 1
		end
	end
	
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
	
	-- Shop Button (bottom right)
	local shopButton = Instance.new("TextButton")
	shopButton.Name = "ShopButton"
	shopButton.Size = UDim2.new(0, 150, 0, 60)
	shopButton.Position = UDim2.new(1, -160, 1, -70)
	shopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	shopButton.Text = "🛒 SHOP"
	shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopButton.TextScaled = true
	shopButton.Font = Enum.Font.SourceSansBold
	shopButton.Parent = screenGui
	
	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 8)
	shopCorner.Parent = shopButton
	
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
		priceLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
		priceLabel.Position = UDim2.new(0, 10, 0.5, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "💰 " .. config.Price .. " coins"
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
			local buyPetEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.BUY_PET)
			if buyPetEvent then
				buyPetEvent:FireServer(petType)
			end
		end)
	end
	
	-- Update canvas size
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
					selectedPlantType = plantType
					print("Selected:", plantType)
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

-- Initialize UI Handler
function UIHandler.Initialize()
	print("UIHandler initialized")
	
	-- Create UI
	local mainUI = createMainUI()
	createShopUI()
	
	-- Setup shop button
	local shopButton = mainUI:FindFirstChild("ShopButton")
	local shopWindow = mainUI:FindFirstChild("ShopWindow")
	
	if shopButton and shopWindow then
		shopButton.MouseButton1Click:Connect(function()
			shopWindow.Visible = not shopWindow.Visible
		end)
	end
	
	-- Listen for currency updates
	local updateCurrencyEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_CURRENCY)
	updateCurrencyEvent.OnClientEvent:Connect(updateCurrencyDisplay)
	
	-- Listen for inventory updates
	local updateInventoryEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_INVENTORY)
	updateInventoryEvent.OnClientEvent:Connect(updateInventoryDisplay)
	
	-- Listen for weather updates
	local weatherChangedEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED)
	weatherChangedEvent.OnClientEvent:Connect(updateWeatherDisplay)
	
	-- Plant seed on click
	local mouse = player:GetMouse()
	mouse.Button1Down:Connect(function()
		if not selectedPlantType then return end
		
		-- Don't plant if a tool is equipped
		local character = player.Character
		if character then
			local equippedTool = character:FindFirstChildOfClass("Tool")
			if equippedTool then return end -- Tool is equipped, let ToolClient handle it
		end
		
		local target = mouse.Target
		if target and target.Name == "Floor" and target.Parent:FindFirstChild("Sign") then
			-- Check if it's player's plot
			local plantSeedEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.PLANT_SEED)
			if plantSeedEvent then
				local nextSlot = getNextAvailableSlot()
				plantSeedEvent:FireServer(selectedPlantType, nextSlot)
			end
		end
	end)
end

return UIHandler
