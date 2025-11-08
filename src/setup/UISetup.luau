-- UISetup.luau (ModuleScript)
-- RUN THIS ONCE IN STUDIO COMMAND BAR:
-- require(game.ReplicatedStorage.Setup.UISetup).CreateUI()
-- Creates the UI structure in StarterGui that clients will use
-- Theme: Enchanted Forest - Hand-painted fantasy with deep forest tones and magical glows
-- Based on fantasy_ui_design_doc.md

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
	
	-- Helper function to create organic rounded corners (wood/vine aesthetic)
	local function addCorner(parent, radius)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, radius or 18)
		corner.Parent = parent
		return corner
	end
	
	-- Helper function to create soft shadow (lifted from background)
	local function addShadow(parent)
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.BackgroundTransparency = 1
		shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		shadow.ImageTransparency = 0.5
		shadow.Size = UDim2.new(1, 12, 1, 12)
		shadow.Position = UDim2.new(0, 0, 0, 6)
		shadow.AnchorPoint = Vector2.new(0, 0)
		shadow.ZIndex = parent.ZIndex - 1
		shadow.Parent = parent
		addCorner(shadow, 18)
		return shadow
	end
	
	-- Helper function to create natural gradients (wood/moss)
	local function addGradient(parent, color1, color2, rotation)
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(color1, color2)
		gradient.Rotation = rotation or 90
		gradient.Parent = parent
		return gradient
	end

	-- Helper function to add vine/leaf stroke outline
	local function addStroke(parent, color, thickness, transparency)
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Thickness = thickness or 2
		stroke.Color = color or Color3.fromRGB(88, 160, 108)
		stroke.Transparency = transparency or 0.25
		stroke.Parent = parent
		return stroke
	end
	
	-- Helper to add magical glow effect (bioluminescence)
	local function addGlow(parent, color)
		local glow = Instance.new("UIStroke")
		glow.Name = "MagicalGlow"
		glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		glow.Thickness = 1.5
		glow.Color = color or Color3.fromRGB(140, 255, 200)
		glow.Transparency = 0.6
		glow.Parent = parent
		return glow
	end

	-- FANTASY ENCHANTED FOREST THEME
	-- Deep forest tones (dark blues, greens, browns) with gold/teal accents
	local theme = {
		-- Backgrounds: Deep forest night
		forestDark = Color3.fromRGB(18, 28, 35),       -- Dark forest background
		forestDeep = Color3.fromRGB(25, 38, 45),        -- Deep wood
		woodBark = Color3.fromRGB(42, 35, 28),          -- Matte wood brown
		mossGreen = Color3.fromRGB(35, 52, 42),         -- Moss overlay
		
		-- Panels: Organic wood and stone
		woodPanel = Color3.fromRGB(52, 45, 38),         -- Weathered wood panel
		stonePanel = Color3.fromRGB(48, 58, 62),        -- Ancient stone
		leafPanel = Color3.fromRGB(40, 58, 48),         -- Leaf-covered surface
		
		-- Accents: Magical glows and natural gems
		tealGem = Color3.fromRGB(88, 160, 140),         -- Teal gem accent
		tealGlow = Color3.fromRGB(110, 190, 170),       -- Teal glow hover
		goldLeaf = Color3.fromRGB(235, 185, 95),        -- Gold leaf accent
		amberGlow = Color3.fromRGB(255, 200, 120),      -- Amber magical glow
		
		-- Text: Off-white and pale colors for contrast
		textLight = Color3.fromRGB(245, 238, 220),      -- Pale yellow-white
		textGold = Color3.fromRGB(240, 200, 130),       -- Golden text
		textMoss = Color3.fromRGB(180, 220, 190),       -- Moss green text
		
		-- Borders: Natural vine and leaf strokes
		vineStroke = Color3.fromRGB(88, 160, 108),      -- Vine green
		glowStroke = Color3.fromRGB(140, 255, 200),     -- Bioluminescent glow
	}
	
	print("[UISetup] Creating Enchanted Forest UI...")
	
	-- =============================================================================
	-- CURRENCY FRAME (Top Right) - Golden Coin Pouch
	-- =============================================================================
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.Size = UDim2.new(0.16, 0, 0.09, 0)
	currencyFrame.Position = UDim2.new(0.83, 0, 0.02, 0)
	currencyFrame.AnchorPoint = Vector2.new(0.5, 0)
	currencyFrame.BackgroundColor3 = theme.woodPanel
	currencyFrame.BorderSizePixel = 0
	currencyFrame.Parent = screenGui
	
	addCorner(currencyFrame, 20)
	addShadow(currencyFrame)
	addGradient(currencyFrame, theme.woodPanel, theme.woodBark, 45)
	addStroke(currencyFrame, theme.goldLeaf, 2.5, 0.15)
	
	-- Currency icon with magical glow
	local coinIcon = Instance.new("TextLabel")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0.32, 0, 0.7, 0)
	coinIcon.Position = UDim2.new(0.05, 0, 0.15, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "💰"
	coinIcon.TextScaled = true
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = currencyFrame
	
	-- Currency label with golden text
	local coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(0.58, 0, 0.7, 0)
	coinLabel.Position = UDim2.new(0.4, 0, 0.15, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Text = "0"
	coinLabel.TextColor3 = theme.textGold
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextScaled = true
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = currencyFrame
	
	-- Add text stroke for better readability
	local coinStroke = Instance.new("UIStroke")
	coinStroke.Color = theme.forestDark
	coinStroke.Thickness = 2
	coinStroke.Parent = coinLabel
	
	-- =============================================================================
	-- WEATHER FRAME (Top Left) - Sky Crystal
	-- =============================================================================
	local weatherFrame = Instance.new("Frame")
	weatherFrame.Name = "WeatherFrame"
	weatherFrame.Size = UDim2.new(0.16, 0, 0.09, 0)
	weatherFrame.Position = UDim2.new(0.17, 0, 0.02, 0)
	weatherFrame.AnchorPoint = Vector2.new(0.5, 0)
	weatherFrame.BackgroundColor3 = theme.stonePanel
	weatherFrame.BorderSizePixel = 0
	weatherFrame.Parent = screenGui
	
	addCorner(weatherFrame, 20)
	addShadow(weatherFrame)
	addGradient(weatherFrame, theme.stonePanel, theme.forestDeep, 45)
	addStroke(weatherFrame, theme.tealGem, 2.5, 0.15)
	addGlow(weatherFrame, theme.glowStroke)
	
	-- Weather label with mystical glow
	local weatherLabel = Instance.new("TextLabel")
	weatherLabel.Name = "WeatherLabel"
	weatherLabel.Size = UDim2.new(0.9, 0, 0.7, 0)
	weatherLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
	weatherLabel.AnchorPoint = Vector2.new(0.5, 0)
	weatherLabel.BackgroundTransparency = 1
	weatherLabel.Text = "☀️ Sunny"
	weatherLabel.TextColor3 = theme.textLight
	weatherLabel.Font = Enum.Font.GothamBold
	weatherLabel.TextScaled = true
	weatherLabel.Parent = weatherFrame
	
	local weatherStroke = Instance.new("UIStroke")
	weatherStroke.Color = theme.forestDark
	weatherStroke.Thickness = 2
	weatherStroke.Parent = weatherLabel
	
	-- =============================================================================
	-- INVENTORY FRAME - Seeds (Bottom Left) - Seed Pouch with Vines
	-- =============================================================================
	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0.36, 0, 0.13, 0)
	inventoryFrame.Position = UDim2.new(0.01, 0, 0.86, 0)
	inventoryFrame.BackgroundColor3 = theme.leafPanel
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Parent = screenGui
	
	addCorner(inventoryFrame, 22)
	addShadow(inventoryFrame)
	addGradient(inventoryFrame, theme.leafPanel, theme.mossGreen, 90)
	addStroke(inventoryFrame, theme.vineStroke, 2.5, 0.2)
	
	-- Title with nature motif
	local seedTitle = Instance.new("TextLabel")
	seedTitle.Name = "Title"
	seedTitle.Size = UDim2.new(0.95, 0, 0.22, 0)
	seedTitle.Position = UDim2.new(0.025, 0, 0.05, 0)
	seedTitle.BackgroundTransparency = 1
	seedTitle.Text = "🌱 Seeds"
	seedTitle.TextColor3 = theme.textMoss
	seedTitle.Font = Enum.Font.GothamBold
	seedTitle.TextScaled = true
	seedTitle.TextXAlignment = Enum.TextXAlignment.Left
	seedTitle.Parent = inventoryFrame
	
	local seedTitleStroke = Instance.new("UIStroke")
	seedTitleStroke.Color = theme.forestDark
	seedTitleStroke.Thickness = 2
	seedTitleStroke.Parent = seedTitle
	
	-- Scrolling container
	local seedContainer = Instance.new("ScrollingFrame")
	seedContainer.Name = "SeedContainer"
	seedContainer.Size = UDim2.new(0.95, 0, 0.68, 0)
	seedContainer.Position = UDim2.new(0.025, 0, 0.30, 0)
	seedContainer.BackgroundTransparency = 1
	seedContainer.BorderSizePixel = 0
	seedContainer.ScrollBarThickness = 7
	seedContainer.ScrollBarImageColor3 = theme.tealGem
	seedContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
	seedContainer.CanvasSize = UDim2.new(0, 0, 1, 0)
	seedContainer.Parent = inventoryFrame
	
	local seedLayout = Instance.new("UIListLayout")
	seedLayout.FillDirection = Enum.FillDirection.Horizontal
	seedLayout.Padding = UDim.new(0, 10)
	seedLayout.SortOrder = Enum.SortOrder.LayoutOrder
	seedLayout.Parent = seedContainer
	
	local seedPadding = Instance.new("UIPadding")
	seedPadding.PaddingLeft = UDim.new(0, 5)
	seedPadding.PaddingRight = UDim.new(0, 5)
	seedPadding.Parent = seedContainer
	
	-- =============================================================================
	-- FRUITS FRAME (Below Seeds) - Berry Basket
	-- =============================================================================
	local fruitsFrame = Instance.new("Frame")
	fruitsFrame.Name = "FruitsFrame"
	fruitsFrame.Size = UDim2.new(0.36, 0, 0.13, 0)
	fruitsFrame.Position = UDim2.new(0.01, 0, 0.72, 0)
	fruitsFrame.BackgroundColor3 = theme.woodPanel
	fruitsFrame.BorderSizePixel = 0
	fruitsFrame.Parent = screenGui
	
	addCorner(fruitsFrame, 22)
	addShadow(fruitsFrame)
	addGradient(fruitsFrame, theme.woodPanel, theme.woodBark, 90)
	addStroke(fruitsFrame, theme.goldLeaf, 2.5, 0.2)
	
	-- Title
	local fruitTitle = Instance.new("TextLabel")
	fruitTitle.Name = "Title"
	fruitTitle.Size = UDim2.new(0.95, 0, 0.22, 0)
	fruitTitle.Position = UDim2.new(0.025, 0, 0.05, 0)
	fruitTitle.BackgroundTransparency = 1
	fruitTitle.Text = "🍎 Fruits"
	fruitTitle.TextColor3 = theme.textGold
	fruitTitle.Font = Enum.Font.GothamBold
	fruitTitle.TextScaled = true
	fruitTitle.TextXAlignment = Enum.TextXAlignment.Left
	fruitTitle.Parent = fruitsFrame
	
	local fruitTitleStroke = Instance.new("UIStroke")
	fruitTitleStroke.Color = theme.forestDark
	fruitTitleStroke.Thickness = 2
	fruitTitleStroke.Parent = fruitTitle
	
	-- Scrolling container
	local fruitsContainer = Instance.new("ScrollingFrame")
	fruitsContainer.Name = "FruitsContainer"
	fruitsContainer.Size = UDim2.new(0.95, 0, 0.68, 0)
	fruitsContainer.Position = UDim2.new(0.025, 0, 0.30, 0)
	fruitsContainer.BackgroundTransparency = 1
	fruitsContainer.BorderSizePixel = 0
	fruitsContainer.ScrollBarThickness = 7
	fruitsContainer.ScrollBarImageColor3 = theme.goldLeaf
	fruitsContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
	fruitsContainer.CanvasSize = UDim2.new(0, 0, 1, 0)
	fruitsContainer.Parent = fruitsFrame
	
	local fruitLayout = Instance.new("UIListLayout")
	fruitLayout.FillDirection = Enum.FillDirection.Horizontal
	fruitLayout.Padding = UDim.new(0, 10)
	fruitLayout.SortOrder = Enum.SortOrder.LayoutOrder
	fruitLayout.Parent = fruitsContainer
	
	local fruitPadding = Instance.new("UIPadding")
	fruitPadding.PaddingLeft = UDim.new(0, 5)
	fruitPadding.PaddingRight = UDim.new(0, 5)
	fruitPadding.Parent = fruitsContainer
	
	-- =============================================================================
	-- SHOP WINDOW (Modal) - 3 Column Layout: Store | NPC | Inventory
	-- =============================================================================
	local shopWindow = Instance.new("Frame")
	shopWindow.Name = "ShopWindow"
	shopWindow.Size = UDim2.new(0.85, 0, 0.8, 0)
	shopWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shopWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	shopWindow.BackgroundColor3 = theme.forestDeep
	shopWindow.BorderSizePixel = 0
	shopWindow.Visible = false
	shopWindow.ZIndex = 10
	shopWindow.Parent = screenGui
	
	addCorner(shopWindow, 28)
	addShadow(shopWindow)
	addGradient(shopWindow, theme.forestDeep, theme.forestDark, 135)
	addStroke(shopWindow, theme.tealGem, 3, 0.15)
	addGlow(shopWindow, theme.glowStroke)
	
	-- Shop title bar
	local shopTitleBar = Instance.new("Frame")
	shopTitleBar.Name = "TitleBar"
	shopTitleBar.Size = UDim2.new(1, 0, 0.08, 0)
	shopTitleBar.Position = UDim2.new(0, 0, 0, 0)
	shopTitleBar.BackgroundColor3 = theme.woodPanel
	shopTitleBar.BorderSizePixel = 0
	shopTitleBar.ZIndex = 11
	shopTitleBar.Parent = shopWindow
	
	addCorner(shopTitleBar, 28)
	addGradient(shopTitleBar, theme.woodPanel, theme.woodBark, 0)
	
	-- Shop title
	local shopTitle = Instance.new("TextLabel")
	shopTitle.Name = "Title"
	shopTitle.Size = UDim2.new(0.6, 0, 1, 0)
	shopTitle.Position = UDim2.new(0.2, 0, 0, 0)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "🏪 Garden Shop"
	shopTitle.TextColor3 = theme.textGold
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.TextScaled = true
	shopTitle.ZIndex = 12
	shopTitle.Parent = shopTitleBar
	
	local shopTitleStroke = Instance.new("UIStroke")
	shopTitleStroke.Color = theme.forestDark
	shopTitleStroke.Thickness = 3
	shopTitleStroke.Parent = shopTitle
	
	-- Close button
	local shopCloseButton = Instance.new("TextButton")
	shopCloseButton.Name = "CloseButton"
	shopCloseButton.Size = UDim2.new(0.06, 0, 0.7, 0)
	shopCloseButton.Position = UDim2.new(0.93, 0, 0.15, 0)
	shopCloseButton.BackgroundColor3 = theme.woodBark
	shopCloseButton.Text = "✖"
	shopCloseButton.TextColor3 = theme.textLight
	shopCloseButton.Font = Enum.Font.GothamBold
	shopCloseButton.TextScaled = true
	shopCloseButton.ZIndex = 12
	shopCloseButton.Parent = shopTitleBar
	
	addCorner(shopCloseButton, 12)
	addStroke(shopCloseButton, theme.goldLeaf, 2, 0.2)
	
	-- LEFT PANEL - Store Items
	local shopLeftPanel = Instance.new("Frame")
	shopLeftPanel.Name = "LeftPanel"
	shopLeftPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	shopLeftPanel.Position = UDim2.new(0.01, 0, 0.1, 0)
	shopLeftPanel.BackgroundColor3 = theme.woodBark
	shopLeftPanel.BorderSizePixel = 0
	shopLeftPanel.ZIndex = 11
	shopLeftPanel.Parent = shopWindow
	
	addCorner(shopLeftPanel, 20)
	addStroke(shopLeftPanel, theme.vineStroke, 2, 0.35)
	addGradient(shopLeftPanel, theme.woodBark, theme.forestDark, 90)
	
	local shopLeftTitle = Instance.new("TextLabel")
	shopLeftTitle.Name = "PanelTitle"
	shopLeftTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	shopLeftTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	shopLeftTitle.BackgroundTransparency = 1
	shopLeftTitle.Text = "🛒 Store"
	shopLeftTitle.TextColor3 = theme.textGold
	shopLeftTitle.Font = Enum.Font.GothamBold
	shopLeftTitle.TextScaled = true
	shopLeftTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopLeftTitle.ZIndex = 12
	shopLeftTitle.Parent = shopLeftPanel
	
	local shopScroll = Instance.new("ScrollingFrame")
	shopScroll.Name = "ScrollingFrame"
	shopScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	shopScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	shopScroll.BackgroundTransparency = 1
	shopScroll.BorderSizePixel = 0
	shopScroll.ScrollBarThickness = 8
	shopScroll.ScrollBarImageColor3 = theme.tealGem
	shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopScroll.ZIndex = 12
	shopScroll.Parent = shopLeftPanel
	
	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 8)
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Parent = shopScroll
	
	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingTop = UDim.new(0, 5)
	shopPadding.PaddingBottom = UDim.new(0, 5)
	shopPadding.PaddingLeft = UDim.new(0, 5)
	shopPadding.PaddingRight = UDim.new(0, 5)
	shopPadding.Parent = shopScroll
	
	-- MIDDLE PANEL - NPC Display (Hidden/Transparent - no context)
	local shopMiddlePanel = Instance.new("Frame")
	shopMiddlePanel.Name = "MiddlePanel"
	shopMiddlePanel.Size = UDim2.new(0, 0, 0.88, 0)
	shopMiddlePanel.Position = UDim2.new(0.5, 0, 0.1, 0)
	shopMiddlePanel.BackgroundTransparency = 1
	shopMiddlePanel.BorderSizePixel = 0
	shopMiddlePanel.Visible = false
	shopMiddlePanel.ZIndex = 11
	shopMiddlePanel.Parent = shopWindow
	
	-- RIGHT PANEL - Player Inventory
	local shopRightPanel = Instance.new("Frame")
	shopRightPanel.Name = "RightPanel"
	shopRightPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	shopRightPanel.Position = UDim2.new(0.51, 0, 0.1, 0)
	shopRightPanel.BackgroundColor3 = theme.leafPanel
	shopRightPanel.BorderSizePixel = 0
	shopRightPanel.ZIndex = 11
	shopRightPanel.Parent = shopWindow
	
	addCorner(shopRightPanel, 20)
	addStroke(shopRightPanel, theme.vineStroke, 2, 0.35)
	addGradient(shopRightPanel, theme.leafPanel, theme.mossGreen, 90)
	
	local shopRightTitle = Instance.new("TextLabel")
	shopRightTitle.Name = "PanelTitle"
	shopRightTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	shopRightTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	shopRightTitle.BackgroundTransparency = 1
	shopRightTitle.Text = "🎒 My Inventory"
	shopRightTitle.TextColor3 = theme.textMoss
	shopRightTitle.Font = Enum.Font.GothamBold
	shopRightTitle.TextScaled = true
	shopRightTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopRightTitle.ZIndex = 12
	shopRightTitle.Parent = shopRightPanel
	
	-- Inventory container for seeds
	local shopInventoryScroll = Instance.new("ScrollingFrame")
	shopInventoryScroll.Name = "InventoryScroll"
	shopInventoryScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	shopInventoryScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	shopInventoryScroll.BackgroundTransparency = 1
	shopInventoryScroll.BorderSizePixel = 0
	shopInventoryScroll.ScrollBarThickness = 8
	shopInventoryScroll.ScrollBarImageColor3 = theme.tealGem
	shopInventoryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopInventoryScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopInventoryScroll.ZIndex = 12
	shopInventoryScroll.Parent = shopRightPanel
	
	local inventoryLayout = Instance.new("UIListLayout")
	inventoryLayout.Padding = UDim.new(0, 8)
	inventoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	inventoryLayout.Parent = shopInventoryScroll
	
	local inventoryPadding = Instance.new("UIPadding")
	inventoryPadding.PaddingTop = UDim.new(0, 5)
	inventoryPadding.PaddingBottom = UDim.new(0, 5)
	inventoryPadding.PaddingLeft = UDim.new(0, 5)
	inventoryPadding.PaddingRight = UDim.new(0, 5)
	inventoryPadding.Parent = shopInventoryScroll
	
	-- =============================================================================
	-- SELL WINDOW (Modal) - 3 Column Layout: Sellable Items | NPC | Fruits Owned
	-- =============================================================================
	local sellWindow = Instance.new("Frame")
	sellWindow.Name = "SellWindow"
	sellWindow.Size = UDim2.new(0.85, 0, 0.8, 0)
	sellWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	sellWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	sellWindow.BackgroundColor3 = theme.forestDeep
	sellWindow.BorderSizePixel = 0
	sellWindow.Visible = false
	sellWindow.ZIndex = 10
	sellWindow.Parent = screenGui
	
	addCorner(sellWindow, 28)
	addShadow(sellWindow)
	addGradient(sellWindow, theme.forestDeep, theme.forestDark, 135)
	addStroke(sellWindow, theme.goldLeaf, 3, 0.15)
	addGlow(sellWindow, theme.amberGlow)
	
	-- Sell title bar
	local sellTitleBar = Instance.new("Frame")
	sellTitleBar.Name = "TitleBar"
	sellTitleBar.Size = UDim2.new(1, 0, 0.08, 0)
	sellTitleBar.Position = UDim2.new(0, 0, 0, 0)
	sellTitleBar.BackgroundColor3 = theme.woodPanel
	sellTitleBar.BorderSizePixel = 0
	sellTitleBar.ZIndex = 11
	sellTitleBar.Parent = sellWindow
	
	addCorner(sellTitleBar, 28)
	addGradient(sellTitleBar, theme.woodPanel, theme.woodBark, 0)
	
	-- Sell title
	local sellTitle = Instance.new("TextLabel")
	sellTitle.Name = "Title"
	sellTitle.Size = UDim2.new(0.6, 0, 1, 0)
	sellTitle.Position = UDim2.new(0.2, 0, 0, 0)
	sellTitle.BackgroundTransparency = 1
	sellTitle.Text = "💰 Fruit Market"
	sellTitle.TextColor3 = theme.textGold
	sellTitle.Font = Enum.Font.GothamBold
	sellTitle.TextScaled = true
	sellTitle.ZIndex = 12
	sellTitle.Parent = sellTitleBar
	
	local sellTitleStroke = Instance.new("UIStroke")
	sellTitleStroke.Color = theme.forestDark
	sellTitleStroke.Thickness = 3
	sellTitleStroke.Parent = sellTitle
	
	-- Close button
	local sellCloseButton = Instance.new("TextButton")
	sellCloseButton.Name = "CloseButton"
	sellCloseButton.Size = UDim2.new(0.06, 0, 0.7, 0)
	sellCloseButton.Position = UDim2.new(0.93, 0, 0.15, 0)
	sellCloseButton.BackgroundColor3 = theme.woodBark
	sellCloseButton.Text = "✖"
	sellCloseButton.TextColor3 = theme.textLight
	sellCloseButton.Font = Enum.Font.GothamBold
	sellCloseButton.TextScaled = true
	sellCloseButton.ZIndex = 12
	sellCloseButton.Parent = sellTitleBar
	
	addCorner(sellCloseButton, 12)
	addStroke(sellCloseButton, theme.goldLeaf, 2, 0.2)
	
	-- LEFT PANEL - Sellable Fruits
	local sellLeftPanel = Instance.new("Frame")
	sellLeftPanel.Name = "LeftPanel"
	sellLeftPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	sellLeftPanel.Position = UDim2.new(0.01, 0, 0.1, 0)
	sellLeftPanel.BackgroundColor3 = theme.woodBark
	sellLeftPanel.BorderSizePixel = 0
	sellLeftPanel.ZIndex = 11
	sellLeftPanel.Parent = sellWindow
	
	addCorner(sellLeftPanel, 20)
	addStroke(sellLeftPanel, theme.goldLeaf, 2, 0.3)
	addGradient(sellLeftPanel, theme.woodBark, theme.forestDark, 90)
	
	local sellLeftTitle = Instance.new("TextLabel")
	sellLeftTitle.Name = "PanelTitle"
	sellLeftTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	sellLeftTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	sellLeftTitle.BackgroundTransparency = 1
	sellLeftTitle.Text = "💎 Sell Fruits"
	sellLeftTitle.TextColor3 = theme.textGold
	sellLeftTitle.Font = Enum.Font.GothamBold
	sellLeftTitle.TextScaled = true
	sellLeftTitle.TextXAlignment = Enum.TextXAlignment.Left
	sellLeftTitle.ZIndex = 12
	sellLeftTitle.Parent = sellLeftPanel
	
	local sellScroll = Instance.new("ScrollingFrame")
	sellScroll.Name = "ScrollingFrame"
	sellScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	sellScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	sellScroll.BackgroundTransparency = 1
	sellScroll.BorderSizePixel = 0
	sellScroll.ScrollBarThickness = 8
	sellScroll.ScrollBarImageColor3 = theme.goldLeaf
	sellScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sellScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	sellScroll.ZIndex = 12
	sellScroll.Parent = sellLeftPanel
	
	local sellLayout = Instance.new("UIListLayout")
	sellLayout.Padding = UDim.new(0, 8)
	sellLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sellLayout.Parent = sellScroll
	
	local sellPadding = Instance.new("UIPadding")
	sellPadding.PaddingTop = UDim.new(0, 5)
	sellPadding.PaddingBottom = UDim.new(0, 5)
	sellPadding.PaddingLeft = UDim.new(0, 5)
	sellPadding.PaddingRight = UDim.new(0, 5)
	sellPadding.Parent = sellScroll
	
	-- MIDDLE PANEL - NPC Merchant (Hidden/Transparent - no context)
	local sellMiddlePanel = Instance.new("Frame")
	sellMiddlePanel.Name = "MiddlePanel"
	sellMiddlePanel.Size = UDim2.new(0, 0, 0.88, 0)
	sellMiddlePanel.Position = UDim2.new(0.5, 0, 0.1, 0)
	sellMiddlePanel.BackgroundTransparency = 1
	sellMiddlePanel.BorderSizePixel = 0
	sellMiddlePanel.Visible = false
	sellMiddlePanel.ZIndex = 11
	sellMiddlePanel.Parent = sellWindow
	
	-- RIGHT PANEL - Player's Fruits
	local sellRightPanel = Instance.new("Frame")
	sellRightPanel.Name = "RightPanel"
	sellRightPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	sellRightPanel.Position = UDim2.new(0.51, 0, 0.1, 0)
	sellRightPanel.BackgroundColor3 = theme.leafPanel
	sellRightPanel.BorderSizePixel = 0
	sellRightPanel.ZIndex = 11
	sellRightPanel.Parent = sellWindow
	
	addCorner(sellRightPanel, 20)
	addStroke(sellRightPanel, theme.goldLeaf, 2, 0.3)
	addGradient(sellRightPanel, theme.leafPanel, theme.mossGreen, 90)
	
	local sellRightTitle = Instance.new("TextLabel")
	sellRightTitle.Name = "PanelTitle"
	sellRightTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	sellRightTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	sellRightTitle.BackgroundTransparency = 1
	sellRightTitle.Text = "🍎 My Fruits"
	sellRightTitle.TextColor3 = theme.textMoss
	sellRightTitle.Font = Enum.Font.GothamBold
	sellRightTitle.TextScaled = true
	sellRightTitle.TextXAlignment = Enum.TextXAlignment.Left
	sellRightTitle.ZIndex = 12
	sellRightTitle.Parent = sellRightPanel
	
	-- Fruit inventory display
	local sellInventoryScroll = Instance.new("ScrollingFrame")
	sellInventoryScroll.Name = "InventoryScroll"
	sellInventoryScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	sellInventoryScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	sellInventoryScroll.BackgroundTransparency = 1
	sellInventoryScroll.BorderSizePixel = 0
	sellInventoryScroll.ScrollBarThickness = 8
	sellInventoryScroll.ScrollBarImageColor3 = theme.goldLeaf
	sellInventoryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sellInventoryScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	sellInventoryScroll.ZIndex = 12
	sellInventoryScroll.Parent = sellRightPanel
	
	local sellInventoryLayout = Instance.new("UIListLayout")
	sellInventoryLayout.Padding = UDim.new(0, 8)
	sellInventoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sellInventoryLayout.Parent = sellInventoryScroll
	
	local sellInventoryPadding = Instance.new("UIPadding")
	sellInventoryPadding.PaddingTop = UDim.new(0, 5)
	sellInventoryPadding.PaddingBottom = UDim.new(0, 5)
	sellInventoryPadding.PaddingLeft = UDim.new(0, 5)
	sellInventoryPadding.PaddingRight = UDim.new(0, 5)
	sellInventoryPadding.Parent = sellInventoryScroll
	
	-- =============================================================================
	-- PETS WINDOW (Modal) - 2 Column Layout: Available Pets | Equipped Pet
	-- =============================================================================
	local petsWindow = Instance.new("Frame")
	petsWindow.Name = "PetsWindow"
	petsWindow.Size = UDim2.new(0.7, 0, 0.75, 0)
	petsWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	petsWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	petsWindow.BackgroundColor3 = theme.forestDeep
	petsWindow.BorderSizePixel = 0
	petsWindow.Visible = false
	petsWindow.ZIndex = 10
	petsWindow.Parent = screenGui
	
	addCorner(petsWindow, 28)
	addShadow(petsWindow)
	addGradient(petsWindow, theme.forestDeep, theme.forestDark, 135)
	addStroke(petsWindow, theme.tealGem, 3, 0.15)
	addGlow(petsWindow, theme.glowStroke)
	
	-- Pets title bar
	local petsTitleBar = Instance.new("Frame")
	petsTitleBar.Name = "TitleBar"
	petsTitleBar.Size = UDim2.new(1, 0, 0.08, 0)
	petsTitleBar.Position = UDim2.new(0, 0, 0, 0)
	petsTitleBar.BackgroundColor3 = theme.woodPanel
	petsTitleBar.BorderSizePixel = 0
	petsTitleBar.ZIndex = 11
	petsTitleBar.Parent = petsWindow
	
	addCorner(petsTitleBar, 28)
	addGradient(petsTitleBar, theme.woodPanel, theme.woodBark, 0)
	
	-- Pets title
	local petsTitle = Instance.new("TextLabel")
	petsTitle.Name = "Title"
	petsTitle.Size = UDim2.new(0.6, 0, 1, 0)
	petsTitle.Position = UDim2.new(0.2, 0, 0, 0)
	petsTitle.BackgroundTransparency = 1
	petsTitle.Text = "🐾 Pet Companions"
	petsTitle.TextColor3 = theme.textGold
	petsTitle.Font = Enum.Font.GothamBold
	petsTitle.TextScaled = true
	petsTitle.ZIndex = 12
	petsTitle.Parent = petsTitleBar
	
	local petsTitleStroke = Instance.new("UIStroke")
	petsTitleStroke.Color = theme.forestDark
	petsTitleStroke.Thickness = 3
	petsTitleStroke.Parent = petsTitle
	
	-- Close button
	local petsCloseButton = Instance.new("TextButton")
	petsCloseButton.Name = "CloseButton"
	petsCloseButton.Size = UDim2.new(0.06, 0, 0.7, 0)
	petsCloseButton.Position = UDim2.new(0.93, 0, 0.15, 0)
	petsCloseButton.BackgroundColor3 = theme.woodBark
	petsCloseButton.Text = "✖"
	petsCloseButton.TextColor3 = theme.textLight
	petsCloseButton.Font = Enum.Font.GothamBold
	petsCloseButton.TextScaled = true
	petsCloseButton.ZIndex = 12
	petsCloseButton.Parent = petsTitleBar
	
	addCorner(petsCloseButton, 12)
	addStroke(petsCloseButton, theme.goldLeaf, 2, 0.2)
	
	-- LEFT PANEL - Available Pets
	local petsLeftPanel = Instance.new("Frame")
	petsLeftPanel.Name = "LeftPanel"
	petsLeftPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	petsLeftPanel.Position = UDim2.new(0.01, 0, 0.1, 0)
	petsLeftPanel.BackgroundColor3 = theme.woodBark
	petsLeftPanel.BorderSizePixel = 0
	petsLeftPanel.ZIndex = 11
	petsLeftPanel.Parent = petsWindow
	
	addCorner(petsLeftPanel, 20)
	addStroke(petsLeftPanel, theme.tealGem, 2, 0.3)
	addGradient(petsLeftPanel, theme.woodBark, theme.forestDark, 90)
	
	local petsLeftTitle = Instance.new("TextLabel")
	petsLeftTitle.Name = "PanelTitle"
	petsLeftTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	petsLeftTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	petsLeftTitle.BackgroundTransparency = 1
	petsLeftTitle.Text = "🦊 Available Pets"
	petsLeftTitle.TextColor3 = theme.textGold
	petsLeftTitle.Font = Enum.Font.GothamBold
	petsLeftTitle.TextScaled = true
	petsLeftTitle.TextXAlignment = Enum.TextXAlignment.Left
	petsLeftTitle.ZIndex = 12
	petsLeftTitle.Parent = petsLeftPanel
	
	local petsScroll = Instance.new("ScrollingFrame")
	petsScroll.Name = "ScrollingFrame"
	petsScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	petsScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	petsScroll.BackgroundTransparency = 1
	petsScroll.BorderSizePixel = 0
	petsScroll.ScrollBarThickness = 8
	petsScroll.ScrollBarImageColor3 = theme.tealGem
	petsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	petsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	petsScroll.ZIndex = 12
	petsScroll.Parent = petsLeftPanel
	
	local petsLayout = Instance.new("UIListLayout")
	petsLayout.Padding = UDim.new(0, 8)
	petsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	petsLayout.Parent = petsScroll
	
	local petsPadding = Instance.new("UIPadding")
	petsPadding.PaddingTop = UDim.new(0, 5)
	petsPadding.PaddingBottom = UDim.new(0, 5)
	petsPadding.PaddingLeft = UDim.new(0, 5)
	petsPadding.PaddingRight = UDim.new(0, 5)
	petsPadding.Parent = petsScroll
	
	-- RIGHT PANEL - Equipped Pet Display
	local petsRightPanel = Instance.new("Frame")
	petsRightPanel.Name = "RightPanel"
	petsRightPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	petsRightPanel.Position = UDim2.new(0.51, 0, 0.1, 0)
	petsRightPanel.BackgroundColor3 = theme.leafPanel
	petsRightPanel.BorderSizePixel = 0
	petsRightPanel.ZIndex = 11
	petsRightPanel.Parent = petsWindow
	
	addCorner(petsRightPanel, 20)
	addStroke(petsRightPanel, theme.tealGem, 2, 0.3)
	addGradient(petsRightPanel, theme.leafPanel, theme.mossGreen, 90)
	
	local petsRightTitle = Instance.new("TextLabel")
	petsRightTitle.Name = "PanelTitle"
	petsRightTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	petsRightTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	petsRightTitle.BackgroundTransparency = 1
	petsRightTitle.Text = "⭐ Equipped Pet"
	petsRightTitle.TextColor3 = theme.textMoss
	petsRightTitle.Font = Enum.Font.GothamBold
	petsRightTitle.TextScaled = true
	petsRightTitle.TextXAlignment = Enum.TextXAlignment.Left
	petsRightTitle.ZIndex = 12
	petsRightTitle.Parent = petsRightPanel
	
	-- Equipped pet display area
	local equippedPetDisplay = Instance.new("Frame")
	equippedPetDisplay.Name = "EquippedPetDisplay"
	equippedPetDisplay.Size = UDim2.new(0.9, 0, 0.9, 0)
	equippedPetDisplay.Position = UDim2.new(0.05, 0, 0.09, 0)
	equippedPetDisplay.BackgroundTransparency = 1
	equippedPetDisplay.ZIndex = 12
	equippedPetDisplay.Parent = petsRightPanel
	
	-- Placeholder for equipped pet (will be populated by UIHandler)
	local equippedPetLabel = Instance.new("TextLabel")
	equippedPetLabel.Name = "PlaceholderLabel"
	equippedPetLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
	equippedPetLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
	equippedPetLabel.BackgroundTransparency = 1
	equippedPetLabel.Text = "No pet equipped\n\n🐾\n\nSelect a pet from the left!"
	equippedPetLabel.TextColor3 = theme.textMoss
	equippedPetLabel.Font = Enum.Font.Gotham
	equippedPetLabel.TextSize = 18
	equippedPetLabel.TextWrapped = true
	equippedPetLabel.TextYAlignment = Enum.TextYAlignment.Center
	equippedPetLabel.ZIndex = 13
	equippedPetLabel.Parent = equippedPetDisplay
	
	-- Pets toggle button (Bottom Right) - Magical Paw Crystal
	local petsButton = Instance.new("TextButton")
	petsButton.Name = "PetsButton"
	petsButton.Size = UDim2.new(0.09, 0, 0.09, 0)
	petsButton.Position = UDim2.new(0.905, 0, 0.86, 0)
	petsButton.AnchorPoint = Vector2.new(0.5, 0)
	petsButton.BackgroundColor3 = theme.leafPanel
	petsButton.Text = "🐾"
	petsButton.TextColor3 = theme.textLight
	petsButton.Font = Enum.Font.GothamBold
	petsButton.TextScaled = true
	petsButton.ZIndex = 5
	petsButton.Parent = screenGui
	
	addCorner(petsButton, 16)
	addShadow(petsButton)
	addGradient(petsButton, theme.leafPanel, theme.mossGreen, 45)
	addStroke(petsButton, theme.tealGem, 2.5, 0.2)
	addGlow(petsButton, theme.glowStroke)
	
	-- =============================================================================
	-- NOTIFICATION CONTAINER - Floating Messages
	-- =============================================================================
	local notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.Size = UDim2.new(0.32, 0, 0.45, 0)
	notificationContainer.Position = UDim2.new(0.5, 0, 0.28, 0)
	notificationContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.ZIndex = 50
	notificationContainer.Parent = screenGui
	
	local notifLayout = Instance.new("UIListLayout")
	notifLayout.Padding = UDim.new(0, 12)
	notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	notifLayout.Parent = notificationContainer
	
	print("[UISetup] ✅ Enchanted Forest UI created successfully!")
	print("[UISetup] Theme: Deep forest tones with magical glows")
	print("[UISetup] UI Structure:")
	print("  - CurrencyFrame (golden coin pouch)")
	print("  - WeatherFrame (sky crystal)")
	print("  - InventoryFrame (seed pouch with vines)")
	print("  - FruitsFrame (berry basket)")
	print("  - ShopWindow (enchanted merchant's stand)")
	print("  - SellWindow (fruit market stand)")
	print("  - PetsWindow (companion sanctuary)")
	print("  - PetsButton (magical paw crystal)")
	print("  - NotificationContainer (floating messages)")
	print("[UISetup] Use ProximityPrompts on ShopPart, SellPart, and PetShopPart to open windows!")
	print("[UISetup] Ready for client scripts to use!")
end

return UISetup
