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
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = StarterGui
	
	-- =============================================================================
	-- LOADING SCREEN (Full Screen Overlay)
	-- =============================================================================
	local loadingScreen = Instance.new("Frame")
	loadingScreen.Name = "LoadingScreen"
	loadingScreen.Size = UDim2.new(1, 0, 1, 0)
	loadingScreen.Position = UDim2.new(0, 0, 0, 0)
	loadingScreen.BackgroundColor3 = Color3.fromRGB(15, 25, 20) -- Very dark forest
	loadingScreen.BorderSizePixel = 0
	loadingScreen.ZIndex = 1000 -- On top of everything
	loadingScreen.Visible = true
	loadingScreen.Parent = screenGui
	
	-- Background gradient
	local loadingGradient = Instance.new("UIGradient")
	loadingGradient.Color = ColorSequence.new(Color3.fromRGB(15, 25, 20), Color3.fromRGB(25, 40, 30))
	loadingGradient.Rotation = 45
	loadingGradient.Parent = loadingScreen
	
	-- Game title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0.6, 0, 0.15, 0)
	titleLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🌿 FEY GARDEN 🌿"
	titleLabel.TextColor3 = Color3.fromRGB(180, 240, 200) -- Magical glow green
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextScaled = true
	titleLabel.ZIndex = 1001
	titleLabel.Parent = loadingScreen
	
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(88, 160, 140)
	titleStroke.Thickness = 3
	titleStroke.Parent = titleLabel
	
	-- Loading text
	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Name = "LoadingLabel"
	loadingLabel.Size = UDim2.new(0.4, 0, 0.05, 0)
	loadingLabel.Position = UDim2.new(0.5, 0, 0.55, 0)
	loadingLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Text = "Loading..."
	loadingLabel.TextColor3 = Color3.fromRGB(245, 238, 220)
	loadingLabel.Font = Enum.Font.Gotham
	loadingLabel.TextSize = 20
	loadingLabel.ZIndex = 1001
	loadingLabel.Parent = loadingScreen
	
	-- Progress bar background
	local progressBarBg = Instance.new("Frame")
	progressBarBg.Name = "ProgressBarBg"
	progressBarBg.Size = UDim2.new(0.5, 0, 0.03, 0)
	progressBarBg.Position = UDim2.new(0.5, 0, 0.62, 0)
	progressBarBg.AnchorPoint = Vector2.new(0.5, 0.5)
	progressBarBg.BackgroundColor3 = Color3.fromRGB(35, 60, 45)
	progressBarBg.BorderSizePixel = 0
	progressBarBg.ZIndex = 1001
	progressBarBg.Parent = loadingScreen
	
	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 20)
	progressBarCorner.Parent = progressBarBg
	
	local progressBarStroke = Instance.new("UIStroke")
	progressBarStroke.Color = Color3.fromRGB(88, 160, 140)
	progressBarStroke.Thickness = 2
	progressBarStroke.Transparency = 0.3
	progressBarStroke.Parent = progressBarBg
	
	-- Progress bar fill
	local progressBarFill = Instance.new("Frame")
	progressBarFill.Name = "ProgressBarFill"
	progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	progressBarFill.Position = UDim2.new(0, 0, 0, 0)
	progressBarFill.BackgroundColor3 = Color3.fromRGB(110, 190, 170)
	progressBarFill.BorderSizePixel = 0
	progressBarFill.ZIndex = 1002
	progressBarFill.Parent = progressBarBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 20)
	fillCorner.Parent = progressBarFill
	
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new(Color3.fromRGB(88, 160, 140), Color3.fromRGB(140, 255, 200))
	fillGradient.Rotation = 0
	fillGradient.Parent = progressBarFill
	
	-- Percentage text
	local percentLabel = Instance.new("TextLabel")
	percentLabel.Name = "PercentLabel"
	percentLabel.Size = UDim2.new(1, 0, 1, 0)
	percentLabel.Position = UDim2.new(0, 0, 0, 0)
	percentLabel.BackgroundTransparency = 1
	percentLabel.Text = "0%"
	percentLabel.TextColor3 = Color3.fromRGB(245, 238, 220)
	percentLabel.Font = Enum.Font.GothamBold
	percentLabel.TextSize = 16
	percentLabel.ZIndex = 1003
	percentLabel.Parent = progressBarBg
	
	-- Tip text
	local tipLabel = Instance.new("TextLabel")
	tipLabel.Name = "TipLabel"
	tipLabel.Size = UDim2.new(0.6, 0, 0.08, 0)
	tipLabel.Position = UDim2.new(0.5, 0, 0.75, 0)
	tipLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	tipLabel.BackgroundTransparency = 1
	tipLabel.Text = "💡 Tip: Water your plants during rainy weather for bonus growth!"
	tipLabel.TextColor3 = Color3.fromRGB(180, 220, 190)
	tipLabel.Font = Enum.Font.GothamMedium
	tipLabel.TextSize = 16
	tipLabel.TextWrapped = true
	tipLabel.ZIndex = 1001
	tipLabel.Parent = loadingScreen
	
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
		forestDark = Color3.fromRGB(25, 50, 35),       -- Dark forest background
		forestDeep = Color3.fromRGB(35, 60, 45),        -- Deep wood
		woodBark = Color3.fromRGB(50, 60, 45),          -- Matte wood brown
		mossGreen = Color3.fromRGB(45, 70, 55),         -- Moss overlay
		
		-- Panels: Organic wood and stone
		woodPanel = Color3.fromRGB(60, 70, 55),         -- Weathered wood panel
		stonePanel = Color3.fromRGB(60, 75, 65),        -- Ancient stone
		leafPanel = Color3.fromRGB(50, 75, 60),         -- Leaf-covered surface
		
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
	
	-- =============================================================================
	-- TOP CENTER NAVIGATION BUTTONS
	-- =============================================================================
	local navFrame = Instance.new("Frame")
	navFrame.Name = "NavigationFrame"
	navFrame.Size = UDim2.new(0, 550, 0, 70)
	navFrame.Position = UDim2.new(0.5, 0, 0, 15)
	navFrame.AnchorPoint = Vector2.new(0.5, 0)
	navFrame.BackgroundTransparency = 1
	navFrame.Parent = screenGui
	
	-- Seeds Button
	local seedsButton = Instance.new("TextButton")
	seedsButton.Name = "SeedsButton"
	seedsButton.Size = UDim2.new(0, 170, 0, 70)
	seedsButton.Position = UDim2.new(0, 0, 0, 0)
	seedsButton.BackgroundColor3 = Color3.fromRGB(88, 180, 140)
	seedsButton.BorderSizePixel = 0
	seedsButton.Text = "SEEDS"
	seedsButton.TextColor3 = theme.textLight
	seedsButton.Font = Enum.Font.GothamBold
	seedsButton.TextSize = 28
	seedsButton.Parent = navFrame
	
	addCorner(seedsButton, 15)
	addStroke(seedsButton, theme.tealGlow, 3, 0.2)
	addShadow(seedsButton)
	
	local seedsGradient = Instance.new("UIGradient")
	seedsGradient.Color = ColorSequence.new(Color3.fromRGB(88, 180, 140), Color3.fromRGB(60, 140, 100))
	seedsGradient.Rotation = 90
	seedsGradient.Parent = seedsButton
	
	-- Garden Button
	local gardenButton = Instance.new("TextButton")
	gardenButton.Name = "GardenButton"
	gardenButton.Size = UDim2.new(0, 170, 0, 70)
	gardenButton.Position = UDim2.new(0, 190, 0, 0)
	gardenButton.BackgroundColor3 = Color3.fromRGB(120, 200, 90)
	gardenButton.BorderSizePixel = 0
	gardenButton.Text = "GARDEN"
	gardenButton.TextColor3 = theme.textLight
	gardenButton.Font = Enum.Font.GothamBold
	gardenButton.TextSize = 28
	gardenButton.Parent = navFrame
	
	addCorner(gardenButton, 15)
	addStroke(gardenButton, Color3.fromRGB(150, 255, 120), 3, 0.2)
	addShadow(gardenButton)
	
	local gardenGradient = Instance.new("UIGradient")
	gardenGradient.Color = ColorSequence.new(Color3.fromRGB(120, 200, 90), Color3.fromRGB(80, 160, 60))
	gardenGradient.Rotation = 90
	gardenGradient.Parent = gardenButton
	
	-- Sell Button
	local sellButton = Instance.new("TextButton")
	sellButton.Name = "SellButton"
	sellButton.Size = UDim2.new(0, 170, 0, 70)
	sellButton.Position = UDim2.new(0, 380, 0, 0)
	sellButton.BackgroundColor3 = Color3.fromRGB(235, 185, 95)
	sellButton.BorderSizePixel = 0
	sellButton.Text = "SELL"
	sellButton.TextColor3 = Color3.fromRGB(40, 30, 20)
	sellButton.Font = Enum.Font.GothamBold
	sellButton.TextSize = 28
	sellButton.Parent = navFrame
	
	addCorner(sellButton, 15)
	addStroke(sellButton, Color3.fromRGB(255, 220, 140), 3, 0.2)
	addShadow(sellButton)
	
	local sellGradient = Instance.new("UIGradient")
	sellGradient.Color = ColorSequence.new(Color3.fromRGB(235, 185, 95), Color3.fromRGB(200, 150, 70))
	sellGradient.Rotation = 90
	sellGradient.Parent = sellButton
	
	-- =============================================================================
	-- CURRENCY FRAME (Bottom Left) - Golden Coin Purse
	-- =============================================================================
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.Size = UDim2.new(0, 200, 0, 60)
	currencyFrame.Position = UDim2.new(0, 15, 1, -75)
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
	coinIcon.Size = UDim2.new(0, 35, 0, 35)
	coinIcon.Position = UDim2.new(0, 8, 0.5, 0)
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "💰"
	coinIcon.TextScaled = true
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = currencyFrame
	
	-- Currency label with golden text
	local coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(0, 125, 0, 35)
	coinLabel.Position = UDim2.new(0, 48, 0.5, 0)
	coinLabel.AnchorPoint = Vector2.new(0, 0.5)
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
	weatherFrame.Size = UDim2.new(0, 180, 0, 50)
	weatherFrame.Position = UDim2.new(0, 10, 0, 10)
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
	weatherLabel.Size = UDim2.new(1, -20, 1, -10)
	weatherLabel.Position = UDim2.new(0, 10, 0, 5)
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
	-- HOTBAR (Bottom Center) - 6 Inventory Slots
	-- =============================================================================
	local hotbarFrame = Instance.new("Frame")
	hotbarFrame.Name = "HotbarFrame"
	hotbarFrame.Size = UDim2.new(0, 420, 0, 70)
	hotbarFrame.Position = UDim2.new(0.5, 0, 1, -80)
	hotbarFrame.AnchorPoint = Vector2.new(0.5, 0)
	hotbarFrame.BackgroundColor3 = theme.woodPanel
	hotbarFrame.BorderSizePixel = 0
	hotbarFrame.Parent = screenGui
	
	addCorner(hotbarFrame, 15)
	addShadow(hotbarFrame)
	addGradient(hotbarFrame, theme.woodPanel, theme.woodBark, 90)
	addStroke(hotbarFrame, theme.goldLeaf, 2.5, 0.2)
	
	-- Create 6 hotbar slots
	for i = 1, 6 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(0, 60, 0, 60)
		slot.Position = UDim2.new(0, 5 + (i - 1) * 68, 0, 5)
		slot.BackgroundColor3 = theme.forestDeep
		slot.BorderSizePixel = 0
		slot.Parent = hotbarFrame
		
		addCorner(slot, 10)
		addStroke(slot, theme.tealGem, 2, 0.3)
		
		-- Slot number
		local slotNum = Instance.new("TextLabel")
		slotNum.Name = "SlotNumber"
		slotNum.Size = UDim2.new(0, 18, 0, 18)
		slotNum.Position = UDim2.new(0, 2, 0, 2)
		slotNum.BackgroundTransparency = 1
		slotNum.Text = tostring(i)
		slotNum.TextColor3 = theme.textLight
		slotNum.Font = Enum.Font.GothamBold
		slotNum.TextSize = 12
		slotNum.Parent = slot
		
		local numStroke = Instance.new("UIStroke")
		numStroke.Color = theme.forestDark
		numStroke.Thickness = 2
		numStroke.Parent = slotNum
		
		-- Item icon
		local itemIcon = Instance.new("TextLabel")
		itemIcon.Name = "ItemIcon"
		itemIcon.Size = UDim2.new(0, 35, 0, 35)
		itemIcon.Position = UDim2.new(0.5, 0, 0.45, 0)
		itemIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		itemIcon.BackgroundTransparency = 1
		itemIcon.Text = ""
		itemIcon.TextScaled = true
		itemIcon.Font = Enum.Font.GothamBold
		itemIcon.Parent = slot
		
		-- Item count
		local itemCount = Instance.new("TextLabel")
		itemCount.Name = "ItemCount"
		itemCount.Size = UDim2.new(0, 25, 0, 18)
		itemCount.Position = UDim2.new(1, -27, 1, -20)
		itemCount.BackgroundTransparency = 1
		itemCount.Text = ""
		itemCount.TextColor3 = theme.textLight
		itemCount.Font = Enum.Font.GothamBold
		itemCount.TextSize = 14
		itemCount.TextXAlignment = Enum.TextXAlignment.Right
		itemCount.Parent = slot
		
		local countStroke = Instance.new("UIStroke")
		countStroke.Color = theme.forestDark
		countStroke.Thickness = 2
		countStroke.Parent = itemCount
		
		-- Make slot clickable
		local slotButton = Instance.new("TextButton")
		slotButton.Name = "SlotButton"
		slotButton.Size = UDim2.new(1, 0, 1, 0)
		slotButton.BackgroundTransparency = 1
		slotButton.Text = ""
		slotButton.ZIndex = 2
		slotButton.Parent = slot
	end
	
	-- =============================================================================
	-- INVENTORY WINDOW (Press B) - Full Backpack
	-- =============================================================================
	local inventoryWindow = Instance.new("Frame")
	inventoryWindow.Name = "InventoryWindow"
	inventoryWindow.Size = UDim2.new(0, 600, 0, 450)
	inventoryWindow.Position = UDim2.new(0.5, 0, 0.5, -50)
	inventoryWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	inventoryWindow.BackgroundColor3 = theme.woodPanel
	inventoryWindow.BorderSizePixel = 0
	inventoryWindow.Visible = false
	inventoryWindow.Parent = screenGui
	
	addCorner(inventoryWindow, 25)
	addShadow(inventoryWindow)
	addGradient(inventoryWindow, theme.woodPanel, theme.forestDeep, 45)
	addStroke(inventoryWindow, theme.goldLeaf, 3, 0.2)
	
	-- Title bar
	local invTitleBar = Instance.new("Frame")
	invTitleBar.Name = "TitleBar"
	invTitleBar.Size = UDim2.new(1, 0, 0, 60)
	invTitleBar.BackgroundColor3 = theme.forestDeep
	invTitleBar.BorderSizePixel = 0
	invTitleBar.Parent = inventoryWindow
	
	addCorner(invTitleBar, 25)
	
	local invTitle = Instance.new("TextLabel")
	invTitle.Name = "Title"
	invTitle.Size = UDim2.new(0, 300, 0, 40)
	invTitle.Position = UDim2.new(0, 20, 0, 10)
	invTitle.BackgroundTransparency = 1
	invTitle.Text = "� Inventory"
	invTitle.TextColor3 = theme.textGold
	invTitle.Font = Enum.Font.GothamBold
	invTitle.TextSize = 28
	invTitle.TextXAlignment = Enum.TextXAlignment.Left
	invTitle.Parent = invTitleBar
	
	local invTitleStroke = Instance.new("UIStroke")
	invTitleStroke.Color = theme.forestDark
	invTitleStroke.Thickness = 2
	invTitleStroke.Parent = invTitle
	
	-- Close button
	local invCloseButton = Instance.new("TextButton")
	invCloseButton.Name = "CloseButton"
	invCloseButton.Size = UDim2.new(0, 130, 0, 35)
	invCloseButton.Position = UDim2.new(1, -145, 0, 13)
	invCloseButton.BackgroundColor3 = theme.woodBark
	invCloseButton.Text = "✕ Close"
	invCloseButton.TextColor3 = theme.textLight
	invCloseButton.Font = Enum.Font.GothamBold
	invCloseButton.TextSize = 16
	invCloseButton.Parent = invTitleBar
	
	addCorner(invCloseButton, 12)
	addStroke(invCloseButton, theme.goldLeaf, 2, 0.3)
	
	-- Tab buttons
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, -40, 0, 50)
	tabContainer.Position = UDim2.new(0, 20, 0, 70)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = inventoryWindow
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 10)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabContainer
	
	local tabs = {"Seeds", "Fruits", "All"}
	for i, tabName in ipairs(tabs) do
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tabName .. "Tab"
		tabButton.Size = UDim2.new(0, 150, 0, 40)
		tabButton.BackgroundColor3 = theme.leafPanel
		tabButton.Text = tabName
		tabButton.TextColor3 = theme.textMoss
		tabButton.Font = Enum.Font.GothamBold
		tabButton.TextSize = 18
		tabButton.Parent = tabContainer
		
		addCorner(tabButton, 12)
		addStroke(tabButton, theme.tealGem, 2, 0.3)
	end
	
	-- Inventory grid container
	local invGridScroll = Instance.new("ScrollingFrame")
	invGridScroll.Name = "GridContainer"
	invGridScroll.Size = UDim2.new(1, -40, 1, -150)
	invGridScroll.Position = UDim2.new(0, 20, 0, 130)
	invGridScroll.BackgroundTransparency = 1
	invGridScroll.BorderSizePixel = 0
	invGridScroll.ScrollBarThickness = 10
	invGridScroll.ScrollBarImageColor3 = theme.goldLeaf
	invGridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	invGridScroll.Parent = inventoryWindow
	
	local invGridLayout = Instance.new("UIGridLayout")
	invGridLayout.CellSize = UDim2.new(0, 90, 0, 90)
	invGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	invGridLayout.SortOrder = Enum.SortOrder.Name
	invGridLayout.Parent = invGridScroll
	
	local invPadding = Instance.new("UIPadding")
	invPadding.PaddingLeft = UDim.new(0, 10)
	invPadding.PaddingRight = UDim.new(0, 10)
	invPadding.PaddingTop = UDim.new(0, 10)
	invPadding.Parent = invGridScroll
	
	-- =============================================================================
	-- SHOP WINDOW (Modal) - 3 Column Fullscreen: Store | NPC | Inventory
	-- =============================================================================
	local shopWindow = Instance.new("Frame")
	shopWindow.Name = "ShopWindow"
	shopWindow.Size = UDim2.new(1, 0, 1, 0)
	shopWindow.Position = UDim2.new(0, 0, 0, 0)
	shopWindow.BackgroundColor3 = theme.forestDeep
	shopWindow.BackgroundTransparency = 1
	shopWindow.BorderSizePixel = 0
	shopWindow.Visible = false
	shopWindow.ZIndex = 10
	shopWindow.Parent = screenGui
	
	-- LEFT PANEL - Store Items (35%)
	local shopLeftPanel = Instance.new("Frame")
	shopLeftPanel.Name = "LeftPanel"
	shopLeftPanel.Size = UDim2.new(0.35, -10, 1, -120)
	shopLeftPanel.Position = UDim2.new(0, 10, 0, 60)
	shopLeftPanel.BackgroundColor3 = theme.woodBark
	shopLeftPanel.BorderSizePixel = 0
	shopLeftPanel.ZIndex = 11
	shopLeftPanel.Parent = shopWindow
	
	-- Rounded corners only on top-right and bottom-right
	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 25)
	leftCorner.Parent = shopLeftPanel
	
	addStroke(shopLeftPanel, theme.vineStroke, 3, 0.35)
	addGradient(shopLeftPanel, theme.woodBark, theme.forestDark, 90)
	addShadow(shopLeftPanel)
	
	local shopLeftTitle = Instance.new("TextLabel")
	shopLeftTitle.Name = "PanelTitle"
	shopLeftTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	shopLeftTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	shopLeftTitle.BackgroundTransparency = 1
	shopLeftTitle.Text = "🛒 Store Items"
	shopLeftTitle.TextColor3 = theme.textGold
	shopLeftTitle.Font = Enum.Font.GothamBold
	shopLeftTitle.TextScaled = true
	shopLeftTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopLeftTitle.ZIndex = 12
	shopLeftTitle.Parent = shopLeftPanel
	
	local shopLeftTitleStroke = Instance.new("UIStroke")
	shopLeftTitleStroke.Color = theme.forestDark
	shopLeftTitleStroke.Thickness = 2
	shopLeftTitleStroke.Parent = shopLeftTitle
	
	local shopScroll = Instance.new("ScrollingFrame")
	shopScroll.Name = "ScrollingFrame"
	shopScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	shopScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	shopScroll.BackgroundTransparency = 1
	shopScroll.BorderSizePixel = 0
	shopScroll.ScrollBarThickness = 10
	shopScroll.ScrollBarImageColor3 = theme.tealGem
	shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopScroll.ZIndex = 12
	shopScroll.Parent = shopLeftPanel
	
	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 10)
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Parent = shopScroll
	
	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingTop = UDim.new(0, 8)
	shopPadding.PaddingBottom = UDim.new(0, 8)
	shopPadding.PaddingLeft = UDim.new(0, 8)
	shopPadding.PaddingRight = UDim.new(0, 8)
	shopPadding.Parent = shopScroll
	
	-- MIDDLE PANEL - NPC Display (30%) - INVISIBLE SPACER
	local shopMiddlePanel = Instance.new("Frame")
	shopMiddlePanel.Name = "MiddlePanel"
	shopMiddlePanel.Size = UDim2.new(0.3, 0, 1, 0)
	shopMiddlePanel.Position = UDim2.new(0.35, 0, 0, 0)
	shopMiddlePanel.BackgroundTransparency = 1
	shopMiddlePanel.BorderSizePixel = 0
	shopMiddlePanel.ZIndex = 11
	shopMiddlePanel.Parent = shopWindow
	
	-- Close button (top-right corner in spacing area)
	local shopCloseButton = Instance.new("TextButton")
	shopCloseButton.Name = "CloseButton"
	shopCloseButton.Size = UDim2.new(0, 130, 0, 35)
	shopCloseButton.Position = UDim2.new(1, -145, 0, 15)
	shopCloseButton.BackgroundColor3 = theme.woodBark
	shopCloseButton.Text = "✖ CLOSE"
	shopCloseButton.TextColor3 = theme.textLight
	shopCloseButton.Font = Enum.Font.GothamBold
	shopCloseButton.TextSize = 18
	shopCloseButton.ZIndex = 13
	shopCloseButton.Parent = shopWindow
	
	addCorner(shopCloseButton, 12)
	addStroke(shopCloseButton, theme.goldLeaf, 3, 0.3)
	addShadow(shopCloseButton)
	
	-- RIGHT PANEL - Player Inventory (35%)
	local shopRightPanel = Instance.new("Frame")
	shopRightPanel.Name = "RightPanel"
	shopRightPanel.Size = UDim2.new(0.35, -10, 1, -120)
	shopRightPanel.Position = UDim2.new(0.65, 0, 0, 60)
	shopRightPanel.BackgroundColor3 = theme.leafPanel
	shopRightPanel.BorderSizePixel = 0
	shopRightPanel.ZIndex = 11
	shopRightPanel.Parent = shopWindow
	
	-- Rounded corners only on top-left and bottom-left
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 25)
	rightCorner.Parent = shopRightPanel
	
	addStroke(shopRightPanel, theme.vineStroke, 3, 0.35)
	addGradient(shopRightPanel, theme.leafPanel, theme.mossGreen, 90)
	addShadow(shopRightPanel)
	
	local shopRightTitle = Instance.new("TextLabel")
	shopRightTitle.Name = "PanelTitle"
	shopRightTitle.Size = UDim2.new(0.9, 0, 0.08, 0)
	shopRightTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	shopRightTitle.BackgroundTransparency = 1
	shopRightTitle.Text = "🎒 My Seeds"
	shopRightTitle.TextColor3 = theme.textMoss
	shopRightTitle.Font = Enum.Font.GothamBold
	shopRightTitle.TextScaled = true
	shopRightTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopRightTitle.ZIndex = 12
	shopRightTitle.Parent = shopRightPanel
	
	local shopRightTitleStroke = Instance.new("UIStroke")
	shopRightTitleStroke.Color = theme.forestDark
	shopRightTitleStroke.Thickness = 2
	shopRightTitleStroke.Parent = shopRightTitle
	
	-- Grid container for seeds inventory (like hotbar style)
	local shopInventoryScroll = Instance.new("ScrollingFrame")
	shopInventoryScroll.Name = "InventoryScroll"
	shopInventoryScroll.Size = UDim2.new(0.94, 0, 0.88, 0)
	shopInventoryScroll.Position = UDim2.new(0.03, 0, 0.11, 0)
	shopInventoryScroll.BackgroundTransparency = 1
	shopInventoryScroll.BorderSizePixel = 0
	shopInventoryScroll.ScrollBarThickness = 8
	shopInventoryScroll.ScrollBarImageColor3 = theme.tealGem
	shopInventoryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopInventoryScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopInventoryScroll.ZIndex = 12
	shopInventoryScroll.Parent = shopRightPanel
	
	-- Use Grid Layout instead of List Layout
	local inventoryGrid = Instance.new("UIGridLayout")
	inventoryGrid.Name = "GridLayout"
	inventoryGrid.CellSize = UDim2.new(0, 130, 0, 130)
	inventoryGrid.CellPadding = UDim2.new(0, 10, 0, 10)
	inventoryGrid.SortOrder = Enum.SortOrder.Name
	inventoryGrid.Parent = shopInventoryScroll
	
	local inventoryPadding = Instance.new("UIPadding")
	inventoryPadding.PaddingTop = UDim.new(0, 10)
	inventoryPadding.PaddingBottom = UDim.new(0, 10)
	inventoryPadding.PaddingLeft = UDim.new(0, 10)
	inventoryPadding.PaddingRight = UDim.new(0, 10)
	inventoryPadding.Parent = shopInventoryScroll
	
	-- =============================================================================
	-- SELL WINDOW (Modal) - 3 Column Fullscreen: Sellable | NPC | Fruits Owned
	-- =============================================================================
	local sellWindow = Instance.new("Frame")
	sellWindow.Name = "SellWindow"
	sellWindow.Size = UDim2.new(1, 0, 1, 0)
	sellWindow.Position = UDim2.new(0, 0, 0, 0)
	sellWindow.BackgroundColor3 = theme.forestDeep
	sellWindow.BackgroundTransparency = 1
	sellWindow.BorderSizePixel = 0
	sellWindow.Visible = false
	sellWindow.ZIndex = 10
	sellWindow.Parent = screenGui
	
	-- LEFT PANEL - Sellable Fruits (35%)
	local sellLeftPanel = Instance.new("Frame")
	sellLeftPanel.Name = "LeftPanel"
	sellLeftPanel.Size = UDim2.new(0.35, -10, 1, -120)
	sellLeftPanel.Position = UDim2.new(0, 10, 0, 60)
	sellLeftPanel.BackgroundColor3 = theme.woodBark
	sellLeftPanel.BorderSizePixel = 0
	sellLeftPanel.ZIndex = 11
	sellLeftPanel.Parent = sellWindow
	
	local sellLeftCorner = Instance.new("UICorner")
	sellLeftCorner.CornerRadius = UDim.new(0, 25)
	sellLeftCorner.Parent = sellLeftPanel
	
	addStroke(sellLeftPanel, theme.goldLeaf, 3, 0.3)
	addGradient(sellLeftPanel, theme.woodBark, theme.forestDark, 90)
	addShadow(sellLeftPanel)
	
	local sellLeftTitle = Instance.new("TextLabel")
	sellLeftTitle.Name = "PanelTitle"
	sellLeftTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	sellLeftTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	sellLeftTitle.BackgroundTransparency = 1
	sellLeftTitle.Text = "� Sell Your Harvest"
	sellLeftTitle.TextColor3 = theme.textGold
	sellLeftTitle.Font = Enum.Font.GothamBold
	sellLeftTitle.TextScaled = true
	sellLeftTitle.TextXAlignment = Enum.TextXAlignment.Left
	sellLeftTitle.ZIndex = 12
	sellLeftTitle.Parent = sellLeftPanel
	
	local sellLeftTitleStroke = Instance.new("UIStroke")
	sellLeftTitleStroke.Color = theme.forestDark
	sellLeftTitleStroke.Thickness = 2
	sellLeftTitleStroke.Parent = sellLeftTitle
	
	local sellScroll = Instance.new("ScrollingFrame")
	sellScroll.Name = "ScrollingFrame"
	sellScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	sellScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	sellScroll.BackgroundTransparency = 1
	sellScroll.BorderSizePixel = 0
	sellScroll.ScrollBarThickness = 10
	sellScroll.ScrollBarImageColor3 = theme.goldLeaf
	sellScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sellScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	sellScroll.ZIndex = 12
	sellScroll.Parent = sellLeftPanel
	
	local sellLayout = Instance.new("UIListLayout")
	sellLayout.Padding = UDim.new(0, 10)
	sellLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sellLayout.Parent = sellScroll
	
	local sellPadding = Instance.new("UIPadding")
	sellPadding.PaddingTop = UDim.new(0, 8)
	sellPadding.PaddingBottom = UDim.new(0, 8)
	sellPadding.PaddingLeft = UDim.new(0, 8)
	sellPadding.PaddingRight = UDim.new(0, 8)
	sellPadding.Parent = sellScroll
	
	-- MIDDLE PANEL - NPC Merchant (30%) - INVISIBLE SPACER
	local sellMiddlePanel = Instance.new("Frame")
	sellMiddlePanel.Name = "MiddlePanel"
	sellMiddlePanel.Size = UDim2.new(0.3, 0, 1, 0)
	sellMiddlePanel.Position = UDim2.new(0.35, 0, 0, 0)
	sellMiddlePanel.BackgroundTransparency = 1
	sellMiddlePanel.BorderSizePixel = 0
	sellMiddlePanel.ZIndex = 11
	sellMiddlePanel.Parent = sellWindow
	
	-- Close button (top-right corner in spacing area)
	local sellCloseButton = Instance.new("TextButton")
	sellCloseButton.Name = "CloseButton"
	sellCloseButton.Size = UDim2.new(0, 130, 0, 35)
	sellCloseButton.Position = UDim2.new(1, -145, 0, 15)
	sellCloseButton.BackgroundColor3 = theme.woodBark
	sellCloseButton.Text = "✖ CLOSE"
	sellCloseButton.TextColor3 = theme.textLight
	sellCloseButton.Font = Enum.Font.GothamBold
	sellCloseButton.TextSize = 18
	sellCloseButton.ZIndex = 13
	sellCloseButton.Parent = sellWindow
	
	addCorner(sellCloseButton, 12)
	addStroke(sellCloseButton, theme.goldLeaf, 3, 0.3)
	addShadow(sellCloseButton)
	addStroke(sellCloseButton, theme.goldLeaf, 3, 0.3)
	addShadow(sellCloseButton)
	
	-- RIGHT PANEL - Player's Fruits (35%)
	local sellRightPanel = Instance.new("Frame")
	sellRightPanel.Name = "RightPanel"
	sellRightPanel.Size = UDim2.new(0.35, -10, 1, -120)
	sellRightPanel.Position = UDim2.new(0.65, 0, 0, 60)
	sellRightPanel.BackgroundColor3 = theme.leafPanel
	sellRightPanel.BorderSizePixel = 0
	sellRightPanel.ZIndex = 11
	sellRightPanel.Parent = sellWindow
	
	local sellRightCorner = Instance.new("UICorner")
	sellRightCorner.CornerRadius = UDim.new(0, 25)
	sellRightCorner.Parent = sellRightPanel
	
	addStroke(sellRightPanel, theme.goldLeaf, 3, 0.3)
	addGradient(sellRightPanel, theme.leafPanel, theme.mossGreen, 90)
	addShadow(sellRightPanel)
	
	local sellRightTitle = Instance.new("TextLabel")
	sellRightTitle.Name = "PanelTitle"
	sellRightTitle.Size = UDim2.new(0.9, 0, 0.08, 0)
	sellRightTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	sellRightTitle.BackgroundTransparency = 1
	sellRightTitle.Text = "🍎 My Fruits"
	sellRightTitle.TextColor3 = theme.textMoss
	sellRightTitle.Font = Enum.Font.GothamBold
	sellRightTitle.TextScaled = true
	sellRightTitle.TextXAlignment = Enum.TextXAlignment.Left
	sellRightTitle.ZIndex = 12
	sellRightTitle.Parent = sellRightPanel
	
	local sellRightTitleStroke = Instance.new("UIStroke")
	sellRightTitleStroke.Color = theme.forestDark
	sellRightTitleStroke.Thickness = 2
	sellRightTitleStroke.Parent = sellRightTitle
	
	-- Fruit inventory display with grid layout
	local sellInventoryScroll = Instance.new("ScrollingFrame")
	sellInventoryScroll.Name = "InventoryScroll"
	sellInventoryScroll.Size = UDim2.new(0.94, 0, 0.88, 0)
	sellInventoryScroll.Position = UDim2.new(0.03, 0, 0.11, 0)
	sellInventoryScroll.BackgroundTransparency = 1
	sellInventoryScroll.BorderSizePixel = 0
	sellInventoryScroll.ScrollBarThickness = 8
	sellInventoryScroll.ScrollBarImageColor3 = theme.goldLeaf
	sellInventoryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sellInventoryScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	sellInventoryScroll.ZIndex = 12
	sellInventoryScroll.Parent = sellRightPanel
	
	-- Use Grid Layout for fruits
	local sellInventoryGrid = Instance.new("UIGridLayout")
	sellInventoryGrid.Name = "GridLayout"
	sellInventoryGrid.CellSize = UDim2.new(0, 130, 0, 130)
	sellInventoryGrid.CellPadding = UDim2.new(0, 10, 0, 10)
	sellInventoryGrid.SortOrder = Enum.SortOrder.Name
	sellInventoryGrid.Parent = sellInventoryScroll
	
	local sellInventoryPadding = Instance.new("UIPadding")
	sellInventoryPadding.PaddingTop = UDim.new(0, 10)
	sellInventoryPadding.PaddingBottom = UDim.new(0, 10)
	sellInventoryPadding.PaddingLeft = UDim.new(0, 10)
	sellInventoryPadding.PaddingRight = UDim.new(0, 10)
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
end

return UISetup
