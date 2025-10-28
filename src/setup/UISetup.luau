-- UISetup.luau (ModuleScript)
-- RUN THIS ONCE IN STUDIO COMMAND BAR:
-- require(game.ReplicatedStorage.Setup.UISetup).CreateUI()
-- Creates the UI structure in StarterGui that clients will use
-- Theme: Mystical Garden with nature-inspired colors

local UISetup = {}

function UISetup.CreateUI()
	local StarterGui = game:GetService("StarterGui")
	
	-- Remove existing UI if present
	local existingUI = StarterGui:FindFirstChild("FeyGardenUI")
	if existingUI then
		existingUI:Destroy()
		warn("[UISetup] Removed existing FeyGardenUI")
	end
	
	-- Create main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FeyGardenUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = StarterGui
	
	-- Helper function to create UICorner
	local function addCorner(parent, radius)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, radius or 12)
		corner.Parent = parent
		return corner
	end
	
	-- Helper function to create shadow effect
	local function addShadow(parent)
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.BackgroundTransparency = 1
		shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		shadow.ImageTransparency = 0.7
		shadow.Size = UDim2.new(1, 8, 1, 8)
		shadow.Position = UDim2.new(0, 0, 0, 4)
		shadow.AnchorPoint = Vector2.new(0, 0)
		shadow.ZIndex = parent.ZIndex - 1
		shadow.Parent = parent
		addCorner(shadow, 12)
		return shadow
	end
	
	-- Helper function to create gradient
	local function addGradient(parent, color1, color2, rotation)
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(color1, color2)
		gradient.Rotation = rotation or 90
		gradient.Parent = parent
		return gradient
	end
	
	print("[UISetup] Creating FeyGarden UI...")
	
	-- =============================================================================
	-- CURRENCY FRAME (Top Right)
	-- =============================================================================
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.Size = UDim2.new(0.15, 0, 0.08, 0)
	currencyFrame.Position = UDim2.new(0.84, 0, 0.02, 0)
	currencyFrame.AnchorPoint = Vector2.new(0.5, 0)
	currencyFrame.BackgroundColor3 = Color3.fromRGB(45, 35, 55) -- Deep purple
	currencyFrame.BorderSizePixel = 0
	currencyFrame.Parent = screenGui
	
	addCorner(currencyFrame, 16)
	addShadow(currencyFrame)
	addGradient(currencyFrame, Color3.fromRGB(45, 35, 55), Color3.fromRGB(35, 25, 45), 45)
	
	-- Currency icon
	local coinIcon = Instance.new("TextLabel")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0.3, 0, 0.7, 0)
	coinIcon.Position = UDim2.new(0.05, 0, 0.15, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "💰"
	coinIcon.TextScaled = true
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = currencyFrame
	
	-- Currency label
	local coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(0.6, 0, 0.7, 0)
	coinLabel.Position = UDim2.new(0.38, 0, 0.15, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Text = "0"
	coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextScaled = true
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = currencyFrame
	
	-- =============================================================================
	-- WEATHER FRAME (Top Left)
	-- =============================================================================
	local weatherFrame = Instance.new("Frame")
	weatherFrame.Name = "WeatherFrame"
	weatherFrame.Size = UDim2.new(0.15, 0, 0.08, 0)
	weatherFrame.Position = UDim2.new(0.16, 0, 0.02, 0)
	weatherFrame.AnchorPoint = Vector2.new(0.5, 0)
	weatherFrame.BackgroundColor3 = Color3.fromRGB(50, 60, 70) -- Blue-grey
	weatherFrame.BorderSizePixel = 0
	weatherFrame.Parent = screenGui
	
	addCorner(weatherFrame, 16)
	addShadow(weatherFrame)
	addGradient(weatherFrame, Color3.fromRGB(50, 60, 70), Color3.fromRGB(40, 50, 60), 45)
	
	-- Weather label
	local weatherLabel = Instance.new("TextLabel")
	weatherLabel.Name = "WeatherLabel"
	weatherLabel.Size = UDim2.new(0.9, 0, 0.7, 0)
	weatherLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
	weatherLabel.AnchorPoint = Vector2.new(0.5, 0)
	weatherLabel.BackgroundTransparency = 1
	weatherLabel.Text = "☀️ Sunny"
	weatherLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
	weatherLabel.Font = Enum.Font.GothamBold
	weatherLabel.TextScaled = true
	weatherLabel.Parent = weatherFrame
	
	-- =============================================================================
	-- INVENTORY FRAME - Seeds (Bottom Left)
	-- =============================================================================
	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0.35, 0, 0.12, 0)
	inventoryFrame.Position = UDim2.new(0.01, 0, 0.86, 0)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(35, 45, 35) -- Forest green
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Parent = screenGui
	
	addCorner(inventoryFrame, 16)
	addShadow(inventoryFrame)
	addGradient(inventoryFrame, Color3.fromRGB(35, 45, 35), Color3.fromRGB(25, 35, 25), 90)
	
	-- Title
	local seedTitle = Instance.new("TextLabel")
	seedTitle.Name = "Title"
	seedTitle.Size = UDim2.new(0.95, 0, 0.2, 0)
	seedTitle.Position = UDim2.new(0.025, 0, 0.05, 0)
	seedTitle.BackgroundTransparency = 1
	seedTitle.Text = "🌱 Seeds"
	seedTitle.TextColor3 = Color3.fromRGB(150, 255, 150)
	seedTitle.Font = Enum.Font.GothamBold
	seedTitle.TextScaled = true
	seedTitle.TextXAlignment = Enum.TextXAlignment.Left
	seedTitle.Parent = inventoryFrame
	
	-- Scrolling container
	local seedContainer = Instance.new("ScrollingFrame")
	seedContainer.Name = "SeedContainer"
	seedContainer.Size = UDim2.new(0.95, 0, 0.7, 0)
	seedContainer.Position = UDim2.new(0.025, 0, 0.28, 0)
	seedContainer.BackgroundTransparency = 1
	seedContainer.BorderSizePixel = 0
	seedContainer.ScrollBarThickness = 6
	seedContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 80)
	seedContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
	seedContainer.CanvasSize = UDim2.new(0, 0, 1, 0)
	seedContainer.Parent = inventoryFrame
	
	local seedLayout = Instance.new("UIListLayout")
	seedLayout.FillDirection = Enum.FillDirection.Horizontal
	seedLayout.Padding = UDim.new(0, 8)
	seedLayout.SortOrder = Enum.SortOrder.LayoutOrder
	seedLayout.Parent = seedContainer
	
	local seedPadding = Instance.new("UIPadding")
	seedPadding.PaddingLeft = UDim.new(0, 4)
	seedPadding.PaddingRight = UDim.new(0, 4)
	seedPadding.Parent = seedContainer
	
	-- =============================================================================
	-- FRUITS FRAME (Below Seeds)
	-- =============================================================================
	local fruitsFrame = Instance.new("Frame")
	fruitsFrame.Name = "FruitsFrame"
	fruitsFrame.Size = UDim2.new(0.35, 0, 0.12, 0)
	fruitsFrame.Position = UDim2.new(0.01, 0, 0.73, 0)
	fruitsFrame.BackgroundColor3 = Color3.fromRGB(55, 35, 45) -- Berry purple
	fruitsFrame.BorderSizePixel = 0
	fruitsFrame.Parent = screenGui
	
	addCorner(fruitsFrame, 16)
	addShadow(fruitsFrame)
	addGradient(fruitsFrame, Color3.fromRGB(55, 35, 45), Color3.fromRGB(45, 25, 35), 90)
	
	-- Title
	local fruitTitle = Instance.new("TextLabel")
	fruitTitle.Name = "Title"
	fruitTitle.Size = UDim2.new(0.95, 0, 0.2, 0)
	fruitTitle.Position = UDim2.new(0.025, 0, 0.05, 0)
	fruitTitle.BackgroundTransparency = 1
	fruitTitle.Text = "🍎 Fruits"
	fruitTitle.TextColor3 = Color3.fromRGB(255, 150, 200)
	fruitTitle.Font = Enum.Font.GothamBold
	fruitTitle.TextScaled = true
	fruitTitle.TextXAlignment = Enum.TextXAlignment.Left
	fruitTitle.Parent = fruitsFrame
	
	-- Scrolling container
	local fruitsContainer = Instance.new("ScrollingFrame")
	fruitsContainer.Name = "FruitsContainer"
	fruitsContainer.Size = UDim2.new(0.95, 0, 0.7, 0)
	fruitsContainer.Position = UDim2.new(0.025, 0, 0.28, 0)
	fruitsContainer.BackgroundTransparency = 1
	fruitsContainer.BorderSizePixel = 0
	fruitsContainer.ScrollBarThickness = 6
	fruitsContainer.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 100)
	fruitsContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
	fruitsContainer.CanvasSize = UDim2.new(0, 0, 1, 0)
	fruitsContainer.Parent = fruitsFrame
	
	local fruitLayout = Instance.new("UIListLayout")
	fruitLayout.FillDirection = Enum.FillDirection.Horizontal
	fruitLayout.Padding = UDim.new(0, 8)
	fruitLayout.SortOrder = Enum.SortOrder.LayoutOrder
	fruitLayout.Parent = fruitsContainer
	
	local fruitPadding = Instance.new("UIPadding")
	fruitPadding.PaddingLeft = UDim.new(0, 4)
	fruitPadding.PaddingRight = UDim.new(0, 4)
	fruitPadding.Parent = fruitsContainer
	
	-- =============================================================================
	-- SHOP WINDOW (Modal)
	-- =============================================================================
	local shopWindow = Instance.new("Frame")
	shopWindow.Name = "ShopWindow"
	shopWindow.Size = UDim2.new(0.5, 0, 0.7, 0)
	shopWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shopWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	shopWindow.BackgroundColor3 = Color3.fromRGB(45, 35, 55)
	shopWindow.BorderSizePixel = 0
	shopWindow.Visible = false
	shopWindow.ZIndex = 10
	shopWindow.Parent = screenGui
	
	addCorner(shopWindow, 20)
	addShadow(shopWindow)
	addGradient(shopWindow, Color3.fromRGB(45, 35, 55), Color3.fromRGB(35, 25, 45), 135)
	
	-- Shop title
	local shopTitle = Instance.new("TextLabel")
	shopTitle.Name = "Title"
	shopTitle.Size = UDim2.new(0.9, 0, 0.1, 0)
	shopTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "🏪 Garden Shop"
	shopTitle.TextColor3 = Color3.fromRGB(200, 255, 200)
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.TextScaled = true
	shopTitle.ZIndex = 11
	shopTitle.Parent = shopWindow
	
	-- Close button
	local shopCloseButton = Instance.new("TextButton")
	shopCloseButton.Name = "CloseButton"
	shopCloseButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	shopCloseButton.Position = UDim2.new(0.9, 0, 0.05, 0)
	shopCloseButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	shopCloseButton.Text = "✖"
	shopCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopCloseButton.Font = Enum.Font.GothamBold
	shopCloseButton.TextScaled = true
	shopCloseButton.ZIndex = 11
	shopCloseButton.Parent = shopWindow
	
	addCorner(shopCloseButton, 8)
	
	-- Shop scrolling frame
	local shopScroll = Instance.new("ScrollingFrame")
	shopScroll.Name = "ScrollingFrame"
	shopScroll.Size = UDim2.new(0.9, 0, 0.75, 0)
	shopScroll.Position = UDim2.new(0.05, 0, 0.18, 0)
	shopScroll.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
	shopScroll.BorderSizePixel = 0
	shopScroll.ScrollBarThickness = 8
	shopScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 80, 120)
	shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopScroll.ZIndex = 11
	shopScroll.Parent = shopWindow
	
	addCorner(shopScroll, 12)
	
	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 10)
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Parent = shopScroll
	
	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingTop = UDim.new(0, 10)
	shopPadding.PaddingBottom = UDim.new(0, 10)
	shopPadding.PaddingLeft = UDim.new(0, 10)
	shopPadding.PaddingRight = UDim.new(0, 10)
	shopPadding.Parent = shopScroll
	
	-- =============================================================================
	-- SELL WINDOW (Modal)
	-- =============================================================================
	local sellWindow = Instance.new("Frame")
	sellWindow.Name = "SellWindow"
	sellWindow.Size = UDim2.new(0.5, 0, 0.7, 0)
	sellWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	sellWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	sellWindow.BackgroundColor3 = Color3.fromRGB(50, 40, 35) -- Warm brown
	sellWindow.BorderSizePixel = 0
	sellWindow.Visible = false
	sellWindow.ZIndex = 10
	sellWindow.Parent = screenGui
	
	addCorner(sellWindow, 20)
	addShadow(sellWindow)
	addGradient(sellWindow, Color3.fromRGB(50, 40, 35), Color3.fromRGB(40, 30, 25), 135)
	
	-- Sell title
	local sellTitle = Instance.new("TextLabel")
	sellTitle.Name = "Title"
	sellTitle.Size = UDim2.new(0.9, 0, 0.1, 0)
	sellTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
	sellTitle.BackgroundTransparency = 1
	sellTitle.Text = "💰 Fruit Market"
	sellTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
	sellTitle.Font = Enum.Font.GothamBold
	sellTitle.TextScaled = true
	sellTitle.ZIndex = 11
	sellTitle.Parent = sellWindow
	
	-- Close button
	local sellCloseButton = Instance.new("TextButton")
	sellCloseButton.Name = "CloseButton"
	sellCloseButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	sellCloseButton.Position = UDim2.new(0.9, 0, 0.05, 0)
	sellCloseButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	sellCloseButton.Text = "✖"
	sellCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellCloseButton.Font = Enum.Font.GothamBold
	sellCloseButton.TextScaled = true
	sellCloseButton.ZIndex = 11
	sellCloseButton.Parent = sellWindow
	
	addCorner(sellCloseButton, 8)
	
	-- Sell scrolling frame
	local sellScroll = Instance.new("ScrollingFrame")
	sellScroll.Name = "ScrollingFrame"
	sellScroll.Size = UDim2.new(0.9, 0, 0.75, 0)
	sellScroll.Position = UDim2.new(0.05, 0, 0.18, 0)
	sellScroll.BackgroundColor3 = Color3.fromRGB(35, 30, 25)
	sellScroll.BorderSizePixel = 0
	sellScroll.ScrollBarThickness = 8
	sellScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 80)
	sellScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sellScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	sellScroll.ZIndex = 11
	sellScroll.Parent = sellWindow
	
	addCorner(sellScroll, 12)
	
	local sellLayout = Instance.new("UIListLayout")
	sellLayout.Padding = UDim.new(0, 10)
	sellLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sellLayout.Parent = sellScroll
	
	local sellPadding = Instance.new("UIPadding")
	sellPadding.PaddingTop = UDim.new(0, 10)
	sellPadding.PaddingBottom = UDim.new(0, 10)
	sellPadding.PaddingLeft = UDim.new(0, 10)
	sellPadding.PaddingRight = UDim.new(0, 10)
	sellPadding.Parent = sellScroll
	
	-- =============================================================================
	-- PETS WINDOW (Modal)
	-- =============================================================================
	local petsWindow = Instance.new("Frame")
	petsWindow.Name = "PetsWindow"
	petsWindow.Size = UDim2.new(0.4, 0, 0.6, 0)
	petsWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	petsWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	petsWindow.BackgroundColor3 = Color3.fromRGB(40, 45, 50) -- Cool grey
	petsWindow.BorderSizePixel = 0
	petsWindow.Visible = false
	petsWindow.ZIndex = 10
	petsWindow.Parent = screenGui
	
	addCorner(petsWindow, 20)
	addShadow(petsWindow)
	addGradient(petsWindow, Color3.fromRGB(40, 45, 50), Color3.fromRGB(30, 35, 40), 135)
	
	-- Pets title
	local petsTitle = Instance.new("TextLabel")
	petsTitle.Name = "Title"
	petsTitle.Size = UDim2.new(0.9, 0, 0.1, 0)
	petsTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
	petsTitle.BackgroundTransparency = 1
	petsTitle.Text = "🐾 My Pets"
	petsTitle.TextColor3 = Color3.fromRGB(200, 220, 255)
	petsTitle.Font = Enum.Font.GothamBold
	petsTitle.TextScaled = true
	petsTitle.ZIndex = 11
	petsTitle.Parent = petsWindow
	
	-- Close button
	local petsCloseButton = Instance.new("TextButton")
	petsCloseButton.Name = "CloseButton"
	petsCloseButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	petsCloseButton.Position = UDim2.new(0.9, 0, 0.05, 0)
	petsCloseButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	petsCloseButton.Text = "✖"
	petsCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	petsCloseButton.Font = Enum.Font.GothamBold
	petsCloseButton.TextScaled = true
	petsCloseButton.ZIndex = 11
	petsCloseButton.Parent = petsWindow
	
	addCorner(petsCloseButton, 8)
	
	-- Pets scrolling frame
	local petsScroll = Instance.new("ScrollingFrame")
	petsScroll.Name = "ScrollingFrame"
	petsScroll.Size = UDim2.new(0.9, 0, 0.75, 0)
	petsScroll.Position = UDim2.new(0.05, 0, 0.18, 0)
	petsScroll.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
	petsScroll.BorderSizePixel = 0
	petsScroll.ScrollBarThickness = 8
	petsScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 120, 140)
	petsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	petsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	petsScroll.ZIndex = 11
	petsScroll.Parent = petsWindow
	
	addCorner(petsScroll, 12)
	
	local petsLayout = Instance.new("UIListLayout")
	petsLayout.Padding = UDim.new(0, 10)
	petsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	petsLayout.Parent = petsScroll
	
	local petsPadding = Instance.new("UIPadding")
	petsPadding.PaddingTop = UDim.new(0, 10)
	petsPadding.PaddingBottom = UDim.new(0, 10)
	petsPadding.PaddingLeft = UDim.new(0, 10)
	petsPadding.PaddingRight = UDim.new(0, 10)
	petsPadding.Parent = petsScroll
	
	-- Pets toggle button (Bottom Right)
	local petsButton = Instance.new("TextButton")
	petsButton.Name = "PetsButton"
	petsButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	petsButton.Position = UDim2.new(0.91, 0, 0.86, 0)
	petsButton.AnchorPoint = Vector2.new(0.5, 0)
	petsButton.BackgroundColor3 = Color3.fromRGB(100, 120, 150)
	petsButton.Text = "🐾"
	petsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	petsButton.Font = Enum.Font.GothamBold
	petsButton.TextScaled = true
	petsButton.ZIndex = 5
	petsButton.Parent = screenGui
	
	addCorner(petsButton, 12)
	addShadow(petsButton)
	addGradient(petsButton, Color3.fromRGB(100, 120, 150), Color3.fromRGB(80, 100, 130), 45)
	
	-- =============================================================================
	-- NOTIFICATION CONTAINER
	-- =============================================================================
	local notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.Size = UDim2.new(0.3, 0, 0.4, 0)
	notificationContainer.Position = UDim2.new(0.5, 0, 0.3, 0)
	notificationContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.ZIndex = 50
	notificationContainer.Parent = screenGui
	
	local notifLayout = Instance.new("UIListLayout")
	notifLayout.Padding = UDim.new(0, 10)
	notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	notifLayout.Parent = notificationContainer
	
	print("[UISetup] ✅ FeyGardenUI created successfully!")
	print("[UISetup] UI Structure:")
	print("  - CurrencyFrame (coins display)")
	print("  - WeatherFrame (weather display)")
	print("  - InventoryFrame (seeds)")
	print("  - FruitsFrame (harvested fruits)")
	print("  - ShopWindow (buy seeds & pets)")
	print("  - SellWindow (sell fruits)")
	print("  - PetsWindow (equip/unequip pets)")
	print("  - PetsButton (toggle pets window)")
	print("  - NotificationContainer (feedback messages)")
	print("[UISetup] Ready for client scripts to use!")
end

return UISetup
