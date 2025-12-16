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
		shadow.ZIndex = -10
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

	-- Frame art asset ids (provided)
	local FRAME_IMAGE_WINDOW_TALL = "rbxassetid://72140204040476"   -- File 1 (tall window)
	local FRAME_IMAGE_WINDOW_WIDE = "rbxassetid://110769453800411"  -- File 2 (wide window)
	local FRAME_IMAGE_PANEL_RECT = "rbxassetid://77328240678206"    -- File 3 (rect panel)
	local FRAME_IMAGE_PANEL_SQUARE = "rbxassetid://125833347683847" -- File 4 (square/rect panel)

	-- 9-slice defaults (tune if edges warp after upload)
	local FRAME_SLICE_TALL = Rect.new(90, 120, 630, 960)
	local FRAME_SLICE_WIDE = Rect.new(90, 120, 630, 960)
	local FRAME_SLICE_RECT = Rect.new(90, 120, 630, 960)
	local FRAME_SLICE_SQUARE = Rect.new(90, 120, 630, 960)

	local function applyFrameImage(parent, assetId, sliceRect, zOffset)
		local bg = Instance.new("ImageLabel")
		bg.Name = "FrameArt"
		bg.BackgroundTransparency = 1
		bg.Image = assetId or FRAME_IMAGE_WINDOW_TALL
		local isWindow = bg.Image == FRAME_IMAGE_WINDOW_TALL or bg.Image == FRAME_IMAGE_WINDOW_WIDE
		bg.ScaleType = isWindow and Enum.ScaleType.Stretch or Enum.ScaleType.Crop
		bg.Size = UDim2.new(1.4, 0, 1.4, 0)
		bg.Position = UDim2.new(0.5, 0, 0.5, 0)
		bg.AnchorPoint = Vector2.new(0.5, 0.5)
		bg.ZIndex = (parent.ZIndex or 1) - 1 + (zOffset or 0)
		bg.Parent = parent
		parent.BackgroundTransparency = 1
		return bg
	end

	-- FANTASY FRAME THEME (Purple/Blue palette from provided frame art)
	local theme = {
		-- Backgrounds: Deep midnight plum
		forestDark = Color3.fromRGB(18, 10, 28),       -- Inner background
		forestDeep = Color3.fromRGB(28, 16, 40),       -- Deeper shadowed plum
		woodBark = Color3.fromRGB(72, 44, 33),         -- Dark bark behind leaves
		mossGreen = Color3.fromRGB(54, 24, 66),        -- Repurposed as plum fill
		
		-- Panels: Leaf + wood tones (purple dominant)
		woodPanel = Color3.fromRGB(54, 24, 66),        -- Main panel plum
		stonePanel = Color3.fromRGB(70, 33, 76),       -- Muted violet stone
		leafPanel = Color3.fromRGB(96, 48, 103),       -- Highlighted leaf purple
		
		-- Accents: Mushroom blues and soft golds
		tealGem = Color3.fromRGB(86, 108, 186),        -- Blue-mushroom cap
		tealGlow = Color3.fromRGB(130, 150, 220),      -- Soft blue glow
		goldLeaf = Color3.fromRGB(210, 168, 120),      -- Warm subdued gold
		amberGlow = Color3.fromRGB(180, 120, 150),     -- Rose/amber accent
		
		-- Text: Cool lilac + off-white
		textLight = Color3.fromRGB(228, 218, 240),     -- Light lilac
		textGold = Color3.fromRGB(210, 190, 230),      -- Pale lavender/gold mix
		textMoss = Color3.fromRGB(182, 154, 210),      -- Muted lilac
		
		-- Borders: Vine strokes re-tinted
		vineStroke = Color3.fromRGB(120, 80, 140),
		glowStroke = Color3.fromRGB(160, 140, 210),
		
		-- UI Elements
		notification = Color3.fromRGB(86, 108, 186),
		notificationAlt = Color3.fromRGB(130, 150, 220),
		panelStroke = Color3.fromRGB(110, 70, 140),
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
	local seedsButton = Instance.new("ImageButton")
	seedsButton.Name = "SeedsButton"
	seedsButton.Size = UDim2.new(0, 170, 0, 70)
	seedsButton.Position = UDim2.new(0, 0, 0, 0)
	seedsButton.BackgroundColor3 = Color3.fromRGB(86, 108, 186)
	seedsButton.BorderSizePixel = 0
	seedsButton.Parent = navFrame

	local seedsBg = applyFrameImage(seedsButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(seedsButton, 15)
	addStroke(seedsButton, theme.tealGlow, 3, 0.2)
	addShadow(seedsButton)

	local seedsGradient = Instance.new("UIGradient")
	seedsGradient.Color = ColorSequence.new(Color3.fromRGB(86, 108, 186), Color3.fromRGB(130, 150, 220))
	seedsGradient.Rotation = 90
	seedsGradient.Parent = seedsBg

	local seedsLabel = Instance.new("TextLabel")
	seedsLabel.Name = "Label"
	seedsLabel.Size = UDim2.new(1, 0, 1, 0)
	seedsLabel.BackgroundTransparency = 1
	seedsLabel.Text = "SEEDS"
	seedsLabel.TextColor3 = theme.textLight
	seedsLabel.Font = Enum.Font.GothamBold
	seedsLabel.TextSize = 28
	seedsLabel.Parent = seedsButton
	
	-- Garden Button
	local gardenButton = Instance.new("ImageButton")
	gardenButton.Name = "GardenButton"
	gardenButton.Size = UDim2.new(0, 170, 0, 70)
	gardenButton.Position = UDim2.new(0, 190, 0, 0)
	gardenButton.BackgroundColor3 = Color3.fromRGB(120, 80, 140)
	gardenButton.BorderSizePixel = 0
	gardenButton.Parent = navFrame

	local gardenBg = applyFrameImage(gardenButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(gardenButton, 15)
	addStroke(gardenButton, Color3.fromRGB(150, 255, 120), 3, 0.2)
	addShadow(gardenButton)

	local gardenGradient = Instance.new("UIGradient")
	gardenGradient.Color = ColorSequence.new(Color3.fromRGB(120, 80, 140), Color3.fromRGB(96, 48, 103))
	gardenGradient.Rotation = 90
	gardenGradient.Parent = gardenBg

	local gardenLabel = Instance.new("TextLabel")
	gardenLabel.Name = "Label"
	gardenLabel.Size = UDim2.new(1, 0, 1, 0)
	gardenLabel.BackgroundTransparency = 1
	gardenLabel.Text = "GARDEN"
	gardenLabel.TextColor3 = theme.textLight
	gardenLabel.Font = Enum.Font.GothamBold
	gardenLabel.TextSize = 28
	gardenLabel.Parent = gardenButton
	
	-- Sell Button
	local sellButton = Instance.new("ImageButton")
	sellButton.Name = "SellButton"
	sellButton.Size = UDim2.new(0, 170, 0, 70)
	sellButton.Position = UDim2.new(0, 380, 0, 0)
	sellButton.BackgroundColor3 = Color3.fromRGB(210, 168, 120)
	sellButton.BorderSizePixel = 0
	sellButton.Parent = navFrame

	local sellBg = applyFrameImage(sellButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(sellButton, 15)
	addStroke(sellButton, Color3.fromRGB(255, 220, 140), 3, 0.2)
	addShadow(sellButton)

	local sellGradient = Instance.new("UIGradient")
	sellGradient.Color = ColorSequence.new(Color3.fromRGB(210, 168, 120), Color3.fromRGB(160, 120, 90))
	sellGradient.Rotation = 90
	sellGradient.Parent = sellBg

	local sellLabel = Instance.new("TextLabel")
	sellLabel.Name = "Label"
	sellLabel.Size = UDim2.new(1, 0, 1, 0)
	sellLabel.BackgroundTransparency = 1
	sellLabel.Text = "SELL"
	sellLabel.TextColor3 = Color3.fromRGB(40, 30, 20)
	sellLabel.Font = Enum.Font.GothamBold
	sellLabel.TextSize = 28
	sellLabel.Parent = sellButton
	
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
	
	local currencyBg = applyFrameImage(currencyFrame, FRAME_IMAGE_PANEL_RECT, FRAME_SLICE_RECT)
	addCorner(currencyFrame, 20)
	addShadow(currencyFrame)
	addGradient(currencyBg, theme.woodPanel, theme.woodBark, 45)
	addStroke(currencyFrame, theme.goldLeaf, 2.5, 0.15)
	
	-- Currency icon with provided coin image
	local coinIcon = Instance.new("ImageLabel")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0, 35, 0, 35)
	coinIcon.Position = UDim2.new(0, 8, 0.5, 0)
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Image = "rbxassetid://85348816613986"
	coinIcon.ScaleType = Enum.ScaleType.Fit
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
	
	local weatherBg = applyFrameImage(weatherFrame, FRAME_IMAGE_PANEL_RECT, FRAME_SLICE_RECT)
	addCorner(weatherFrame, 20)
	addShadow(weatherFrame)
	addGradient(weatherBg, theme.stonePanel, theme.forestDeep, 45)
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
	
	local hotbarBg = applyFrameImage(hotbarFrame, FRAME_IMAGE_PANEL_RECT, FRAME_SLICE_RECT)
	addCorner(hotbarFrame, 15)
	addShadow(hotbarFrame)
	addGradient(hotbarBg, theme.woodPanel, theme.woodBark, 90)
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
		local slotButton = Instance.new("ImageButton")
		slotButton.Name = "SlotButton"
		slotButton.Size = UDim2.new(1, 0, 1, 0)
		slotButton.BackgroundTransparency = 1
		slotButton.ZIndex = 2
		slotButton.Parent = slot

		local slotButtonLabel = Instance.new("TextLabel")
		slotButtonLabel.Name = "Label"
		slotButtonLabel.Size = UDim2.new(1, 0, 1, 0)
		slotButtonLabel.BackgroundTransparency = 1
		slotButtonLabel.Text = ""
		slotButtonLabel.Parent = slotButton
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
	inventoryWindow.BackgroundTransparency = 1
	inventoryWindow.BorderSizePixel = 0
	inventoryWindow.Visible = false
	inventoryWindow.Parent = screenGui

	applyFrameImage(inventoryWindow, FRAME_IMAGE_WINDOW_TALL, FRAME_SLICE_TALL)
	addShadow(inventoryWindow)
	
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
	invCloseButton.Parent = invTitleBar

	local invCloseBg = applyFrameImage(invCloseButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(invCloseButton, 12)
	addStroke(invCloseButton, theme.goldLeaf, 2, 0.3)

	invCloseButton.Text = "✕ Close"
	invCloseButton.TextColor3 = theme.textLight
	invCloseButton.Font = Enum.Font.GothamBold
	invCloseButton.TextSize = 16
	
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
		tabButton.Parent = tabContainer
		
		local tabBg = applyFrameImage(tabButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
		addCorner(tabButton, 12)
		addStroke(tabButton, theme.tealGem, 2, 0.3)
		addGradient(tabBg, theme.leafPanel, theme.mossGreen, 90)

		tabButton.Text = tabName
		tabButton.TextColor3 = theme.textMoss
		tabButton.Font = Enum.Font.GothamBold
		tabButton.TextSize = 18
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
	shopLeftPanel.BackgroundTransparency = 1
	shopLeftPanel.BorderSizePixel = 0
	shopLeftPanel.ZIndex = 11
	shopLeftPanel.Parent = shopWindow
	
	applyFrameImage(shopLeftPanel, FRAME_IMAGE_WINDOW_WIDE, FRAME_SLICE_WIDE, 0)
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
	shopCloseButton.ZIndex = 13
	shopCloseButton.Parent = shopWindow

	local shopCloseBg = applyFrameImage(shopCloseButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(shopCloseButton, 12)
	addStroke(shopCloseButton, theme.goldLeaf, 3, 0.3)
	addShadow(shopCloseButton)

	shopCloseButton.Text = "✖ CLOSE"
	shopCloseButton.TextColor3 = theme.textLight
	shopCloseButton.Font = Enum.Font.GothamBold
	shopCloseButton.TextSize = 18
	
	-- RIGHT PANEL - Player Inventory (35%)
	local shopRightPanel = Instance.new("Frame")
	shopRightPanel.Name = "RightPanel"
	shopRightPanel.Size = UDim2.new(0.35, -10, 1, -120)
	shopRightPanel.Position = UDim2.new(0.65, 0, 0, 60)
	shopRightPanel.BackgroundColor3 = theme.leafPanel
	shopRightPanel.BackgroundTransparency = 1
	shopRightPanel.BorderSizePixel = 0
	shopRightPanel.ZIndex = 11
	shopRightPanel.Parent = shopWindow
	
	applyFrameImage(shopRightPanel, FRAME_IMAGE_WINDOW_WIDE, FRAME_SLICE_WIDE, 0)
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
	sellLeftPanel.BackgroundTransparency = 1
	sellLeftPanel.BorderSizePixel = 0
	sellLeftPanel.ZIndex = 11
	sellLeftPanel.Parent = sellWindow
	
	applyFrameImage(sellLeftPanel, FRAME_IMAGE_WINDOW_WIDE, FRAME_SLICE_WIDE, 0)
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
	sellCloseButton.ZIndex = 13
	sellCloseButton.Parent = sellWindow

	local sellCloseBg = applyFrameImage(sellCloseButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(sellCloseButton, 12)
	addStroke(sellCloseButton, theme.goldLeaf, 3, 0.3)
	addShadow(sellCloseButton)

	sellCloseButton.Text = "✖ CLOSE"
	sellCloseButton.TextColor3 = theme.textLight
	sellCloseButton.Font = Enum.Font.GothamBold
	sellCloseButton.TextSize = 18
	
	-- RIGHT PANEL - Player's Fruits (35%)
	local sellRightPanel = Instance.new("Frame")
	sellRightPanel.Name = "RightPanel"
	sellRightPanel.Size = UDim2.new(0.35, -10, 1, -120)
	sellRightPanel.Position = UDim2.new(0.65, 0, 0, 60)
	sellRightPanel.BackgroundColor3 = theme.leafPanel
	sellRightPanel.BackgroundTransparency = 1
	sellRightPanel.BorderSizePixel = 0
	sellRightPanel.ZIndex = 11
	sellRightPanel.Parent = sellWindow
	
	applyFrameImage(sellRightPanel, FRAME_IMAGE_WINDOW_WIDE, FRAME_SLICE_WIDE, 0)
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

	applyFrameImage(petsWindow, FRAME_IMAGE_WINDOW_TALL, FRAME_SLICE_TALL)
	addShadow(petsWindow)
	
	-- Pets title bar
	local petsTitleBar = Instance.new("Frame")
	petsTitleBar.Name = "TitleBar"
	petsTitleBar.Size = UDim2.new(1, 0, 0.08, 0)
	petsTitleBar.Position = UDim2.new(0, 0, 0, 0)
	petsTitleBar.BackgroundColor3 = theme.woodPanel
	petsTitleBar.BorderSizePixel = 0
	petsTitleBar.ZIndex = 11
	petsTitleBar.Parent = petsWindow

	local petsTitleBg = applyFrameImage(petsTitleBar, FRAME_IMAGE_PANEL_RECT, FRAME_SLICE_RECT)
	addCorner(petsTitleBar, 20)
	addGradient(petsTitleBg, theme.woodPanel, theme.woodBark, 0)
	
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
	petsCloseButton.ZIndex = 12
	petsCloseButton.Parent = petsTitleBar

	local petsCloseBg = applyFrameImage(petsCloseButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(petsCloseButton, 12)
	addStroke(petsCloseButton, theme.goldLeaf, 2, 0.2)

	petsCloseButton.Text = "✖"
	petsCloseButton.TextColor3 = theme.textLight
	petsCloseButton.Font = Enum.Font.GothamBold
	petsCloseButton.TextScaled = true
	
	-- LEFT PANEL - Available Pets
	local petsLeftPanel = Instance.new("Frame")
	petsLeftPanel.Name = "LeftPanel"
	petsLeftPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	petsLeftPanel.Position = UDim2.new(0.01, 0, 0.1, 0)
	petsLeftPanel.BackgroundColor3 = theme.woodBark
	petsLeftPanel.BorderSizePixel = 0
	petsLeftPanel.ZIndex = 11
	petsLeftPanel.Parent = petsWindow
	
	applyFrameImage(petsLeftPanel, FRAME_IMAGE_WINDOW_WIDE, FRAME_SLICE_WIDE)
	addShadow(petsLeftPanel)
	
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
	
	applyFrameImage(petsRightPanel, FRAME_IMAGE_WINDOW_WIDE, FRAME_SLICE_WIDE)
	addShadow(petsRightPanel)
	
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
	local petsButton = Instance.new("ImageButton")
	petsButton.Name = "PetsButton"
	petsButton.Size = UDim2.new(0.09, 0, 0.09, 0)
	petsButton.Position = UDim2.new(0.905, 0, 0.86, 0)
	petsButton.AnchorPoint = Vector2.new(0.5, 0)
	petsButton.BackgroundColor3 = theme.leafPanel
	petsButton.ZIndex = 5
	petsButton.Parent = screenGui

	local petsBtnBg = applyFrameImage(petsButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(petsButton, 16)
	addShadow(petsButton)
	addGradient(petsBtnBg, theme.leafPanel, theme.mossGreen, 45)
	addStroke(petsButton, theme.tealGem, 2.5, 0.2)
	addGlow(petsButton, theme.glowStroke)

	local petsBtnLabel = Instance.new("TextLabel")
	petsBtnLabel.Name = "Label"
	petsBtnLabel.Size = UDim2.new(1, 0, 1, 0)
	petsBtnLabel.BackgroundTransparency = 1
	petsBtnLabel.Text = "🐾"
	petsBtnLabel.TextColor3 = theme.textLight
	petsBtnLabel.Font = Enum.Font.GothamBold
	petsBtnLabel.TextScaled = true
	petsBtnLabel.Parent = petsButton
	
	-- =============================================================================
	-- PET SHOP WINDOW (Separate from Inventory) - Egg Shop + Player Pets Preview
	-- =============================================================================
	local petShopWindow = Instance.new("Frame")
	petShopWindow.Name = "PetShopWindow"
	petShopWindow.Size = UDim2.new(1, 0, 1, 0)
	petShopWindow.Position = UDim2.new(0, 0, 0, 0)
	petShopWindow.BackgroundColor3 = theme.forestDeep
	petShopWindow.BackgroundTransparency = 1
	petShopWindow.BorderSizePixel = 0
	petShopWindow.Visible = false
	petShopWindow.ZIndex = 10
	petShopWindow.Parent = screenGui
	
	-- LEFT PANEL - Egg Shop (35%)
	local shopLeftPanel = Instance.new("Frame")
	shopLeftPanel.Name = "LeftPanel"
	shopLeftPanel.Size = UDim2.new(0.35, -10, 1, -120)
	shopLeftPanel.Position = UDim2.new(0, 10, 0, 60)
	shopLeftPanel.BackgroundColor3 = theme.woodBark
	shopLeftPanel.BackgroundTransparency = 1
	shopLeftPanel.BorderSizePixel = 0
	shopLeftPanel.ZIndex = 11
	shopLeftPanel.Parent = petShopWindow
	
	applyFrameImage(shopLeftPanel, FRAME_IMAGE_WINDOW_WIDE, FRAME_SLICE_WIDE, 0)
	addShadow(shopLeftPanel)
	
	local shopLeftTitle = Instance.new("TextLabel")
	shopLeftTitle.Name = "PanelTitle"
	shopLeftTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	shopLeftTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	shopLeftTitle.BackgroundTransparency = 1
	shopLeftTitle.Text = "🥚 Egg Shop"
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
	
	local eggShopScroll = Instance.new("ScrollingFrame")
	eggShopScroll.Name = "EggShopScroll"
	eggShopScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	eggShopScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	eggShopScroll.BackgroundTransparency = 1
	eggShopScroll.BorderSizePixel = 0
	eggShopScroll.ScrollBarThickness = 10
	eggShopScroll.ScrollBarImageColor3 = theme.tealGem
	eggShopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	eggShopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	eggShopScroll.ZIndex = 12
	eggShopScroll.Parent = shopLeftPanel
	
	local eggShopLayout = Instance.new("UIListLayout")
	eggShopLayout.Padding = UDim.new(0, 10)
	eggShopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	eggShopLayout.Parent = eggShopScroll
	
	local eggShopPadding = Instance.new("UIPadding")
	eggShopPadding.PaddingTop = UDim.new(0, 8)
	eggShopPadding.PaddingBottom = UDim.new(0, 8)
	eggShopPadding.PaddingLeft = UDim.new(0, 8)
	eggShopPadding.PaddingRight = UDim.new(0, 8)
	eggShopPadding.Parent = eggShopScroll
	
	-- MIDDLE PANEL - NPC Display (30%) - INVISIBLE SPACER
	local shopMiddlePanel = Instance.new("Frame")
	shopMiddlePanel.Name = "MiddlePanel"
	shopMiddlePanel.Size = UDim2.new(0.3, 0, 1, 0)
	shopMiddlePanel.Position = UDim2.new(0.35, 0, 0, 0)
	shopMiddlePanel.BackgroundTransparency = 1
	shopMiddlePanel.BorderSizePixel = 0
	shopMiddlePanel.ZIndex = 11
	shopMiddlePanel.Parent = petShopWindow
	
	-- Close button (top-right corner in spacing area)
	local petShopCloseButton = Instance.new("TextButton")
	petShopCloseButton.Name = "CloseButton"
	petShopCloseButton.Size = UDim2.new(0, 130, 0, 35)
	petShopCloseButton.Position = UDim2.new(1, -145, 0, 15)
	petShopCloseButton.BackgroundColor3 = theme.woodBark
	petShopCloseButton.ZIndex = 13
	petShopCloseButton.Parent = petShopWindow

	local petShopCloseBg = applyFrameImage(petShopCloseButton, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE)
	addCorner(petShopCloseButton, 12)
	addStroke(petShopCloseButton, theme.goldLeaf, 3, 0.3)
	addShadow(petShopCloseButton)

	petShopCloseButton.Text = "✖ CLOSE"
	petShopCloseButton.TextColor3 = theme.textLight
	petShopCloseButton.Font = Enum.Font.GothamBold
	petShopCloseButton.TextSize = 18
	
	-- RIGHT PANEL - Player's Pets Preview (35%)
	local shopRightPanel = Instance.new("Frame")
	shopRightPanel.Name = "RightPanel"
	shopRightPanel.Size = UDim2.new(0.35, -10, 1, -120)
	shopRightPanel.Position = UDim2.new(0.65, 0, 0, 60)
	shopRightPanel.BackgroundColor3 = theme.leafPanel
	shopRightPanel.BackgroundTransparency = 1
	shopRightPanel.BorderSizePixel = 0
	shopRightPanel.ZIndex = 11
	shopRightPanel.Parent = petShopWindow
	
	applyFrameImage(shopRightPanel, FRAME_IMAGE_WINDOW_WIDE, FRAME_SLICE_WIDE, 0)
	addShadow(shopRightPanel)
	
	local shopRightTitle = Instance.new("TextLabel")
	shopRightTitle.Name = "PanelTitle"
	shopRightTitle.Size = UDim2.new(0.9, 0, 0.08, 0)
	shopRightTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	shopRightTitle.BackgroundTransparency = 1
	shopRightTitle.Text = "🐾 My Pets"
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
	
	-- Pet inventory preview with grid layout
	local petPreviewScroll = Instance.new("ScrollingFrame")
	petPreviewScroll.Name = "PetPreviewScroll"
	petPreviewScroll.Size = UDim2.new(0.94, 0, 0.88, 0)
	petPreviewScroll.Position = UDim2.new(0.03, 0, 0.11, 0)
	petPreviewScroll.BackgroundTransparency = 1
	petPreviewScroll.BorderSizePixel = 0
	petPreviewScroll.ScrollBarThickness = 8
	petPreviewScroll.ScrollBarImageColor3 = theme.tealGem
	petPreviewScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	petPreviewScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	petPreviewScroll.ZIndex = 12
	petPreviewScroll.Parent = shopRightPanel
	
	-- Use Grid Layout for pets
	local petPreviewGrid = Instance.new("UIGridLayout")
	petPreviewGrid.Name = "GridLayout"
	petPreviewGrid.CellSize = UDim2.new(0, 130, 0, 130)
	petPreviewGrid.CellPadding = UDim2.new(0, 10, 0, 10)
	petPreviewGrid.SortOrder = Enum.SortOrder.Name
	petPreviewGrid.Parent = petPreviewScroll
	
	local petPreviewPadding = Instance.new("UIPadding")
	petPreviewPadding.PaddingTop = UDim.new(0, 10)
	petPreviewPadding.PaddingBottom = UDim.new(0, 10)
	petPreviewPadding.PaddingLeft = UDim.new(0, 10)
	petPreviewPadding.PaddingRight = UDim.new(0, 10)
	petPreviewPadding.Parent = petPreviewScroll
	
	-- =============================================================================
	-- TRADING WINDOW - Player to Player Trading
	-- =============================================================================
	local tradingWindow = Instance.new("Frame")
	tradingWindow.Name = "TradingWindow"
	tradingWindow.Size = UDim2.new(1, 0, 1, 0)
	tradingWindow.Position = UDim2.new(0, 0, 0, 0)
	tradingWindow.BackgroundColor3 = theme.forestDeep
	tradingWindow.BackgroundTransparency = 0.3
	tradingWindow.BorderSizePixel = 0
	tradingWindow.Visible = false
	tradingWindow.ZIndex = 100
	tradingWindow.Parent = screenGui
	
	-- Main trade panel (centered)
	local tradePanel = Instance.new("Frame")
	tradePanel.Name = "TradePanel"
	tradePanel.Size = UDim2.new(0.8, 0, 0.75, 0)
	tradePanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	tradePanel.AnchorPoint = Vector2.new(0.5, 0.5)
	tradePanel.BackgroundColor3 = theme.forestDark
	tradePanel.BorderSizePixel = 0
	tradePanel.ZIndex = 101
	tradePanel.Parent = tradingWindow
	
	local tradePanelCorner = Instance.new("UICorner")
	tradePanelCorner.CornerRadius = UDim.new(0, 20)
	tradePanelCorner.Parent = tradePanel
	
	local tradePanelStroke = Instance.new("UIStroke")
	tradePanelStroke.Color = theme.tealGem
	tradePanelStroke.Thickness = 3
	tradePanelStroke.Parent = tradePanel
	
	-- Trade title
	local tradeTitle = Instance.new("TextLabel")
	tradeTitle.Name = "TradeTitle"
	tradeTitle.Size = UDim2.new(1, 0, 0.08, 0)
	tradeTitle.Position = UDim2.new(0, 0, 0, 0)
	tradeTitle.BackgroundTransparency = 1
	tradeTitle.Text = "🤝 TRADE 🤝"
	tradeTitle.TextColor3 = theme.goldLeaf
	tradeTitle.Font = Enum.Font.GothamBold
	tradeTitle.TextScaled = true
	tradeTitle.ZIndex = 102
	tradeTitle.Parent = tradePanel
	
	local tradeTitleStroke = Instance.new("UIStroke")
	tradeTitleStroke.Color = theme.forestDark
	tradeTitleStroke.Thickness = 2
	tradeTitleStroke.Parent = tradeTitle
	
	-- Partner name label
	local partnerLabel = Instance.new("TextLabel")
	partnerLabel.Name = "PartnerLabel"
	partnerLabel.Size = UDim2.new(1, 0, 0.04, 0)
	partnerLabel.Position = UDim2.new(0, 0, 0.08, 0)
	partnerLabel.BackgroundTransparency = 1
	partnerLabel.Text = "Trading with: ..."
	partnerLabel.TextColor3 = theme.textLight
	partnerLabel.Font = Enum.Font.Gotham
	partnerLabel.TextScaled = true
	partnerLabel.ZIndex = 102
	partnerLabel.Parent = tradePanel
	
	-- Your offer panel (left side)
	local yourOfferPanel = Instance.new("Frame")
	yourOfferPanel.Name = "YourOfferPanel"
	yourOfferPanel.Size = UDim2.new(0.45, 0, 0.6, 0)
	yourOfferPanel.Position = UDim2.new(0.025, 0, 0.14, 0)
	yourOfferPanel.BackgroundColor3 = theme.forestDeep
	yourOfferPanel.BorderSizePixel = 0
	yourOfferPanel.ZIndex = 102
	yourOfferPanel.Parent = tradePanel
	
	local yourOfferCorner = Instance.new("UICorner")
	yourOfferCorner.CornerRadius = UDim.new(0, 12)
	yourOfferCorner.Parent = yourOfferPanel
	
	local yourOfferTitle = Instance.new("TextLabel")
	yourOfferTitle.Name = "Title"
	yourOfferTitle.Size = UDim2.new(1, 0, 0.1, 0)
	yourOfferTitle.Position = UDim2.new(0, 0, 0, 0)
	yourOfferTitle.BackgroundTransparency = 1
	yourOfferTitle.Text = "📦 Your Offer"
	yourOfferTitle.TextColor3 = theme.mossGreen
	yourOfferTitle.Font = Enum.Font.GothamBold
	yourOfferTitle.TextScaled = true
	yourOfferTitle.ZIndex = 103
	yourOfferTitle.Parent = yourOfferPanel
	
	-- Your offer items scroll
	local yourOfferScroll = Instance.new("ScrollingFrame")
	yourOfferScroll.Name = "ItemsScroll"
	yourOfferScroll.Size = UDim2.new(0.94, 0, 0.65, 0)
	yourOfferScroll.Position = UDim2.new(0.03, 0, 0.11, 0)
	yourOfferScroll.BackgroundTransparency = 1
	yourOfferScroll.BorderSizePixel = 0
	yourOfferScroll.ScrollBarThickness = 6
	yourOfferScroll.ScrollBarImageColor3 = theme.tealGem
	yourOfferScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	yourOfferScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	yourOfferScroll.ZIndex = 103
	yourOfferScroll.Parent = yourOfferPanel
	
	local yourOfferGrid = Instance.new("UIGridLayout")
	yourOfferGrid.Name = "GridLayout"
	yourOfferGrid.CellSize = UDim2.new(0, 70, 0, 70)
	yourOfferGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	yourOfferGrid.SortOrder = Enum.SortOrder.LayoutOrder
	yourOfferGrid.Parent = yourOfferScroll
	
	-- Coins input for your offer
	local yourCoinsFrame = Instance.new("Frame")
	yourCoinsFrame.Name = "CoinsFrame"
	yourCoinsFrame.Size = UDim2.new(0.94, 0, 0.12, 0)
	yourCoinsFrame.Position = UDim2.new(0.03, 0, 0.77, 0)
	yourCoinsFrame.BackgroundColor3 = theme.forestDark
	yourCoinsFrame.BorderSizePixel = 0
	yourCoinsFrame.ZIndex = 103
	yourCoinsFrame.Parent = yourOfferPanel
	
	local yourCoinsCorner = Instance.new("UICorner")
	yourCoinsCorner.CornerRadius = UDim.new(0, 8)
	yourCoinsCorner.Parent = yourCoinsFrame
	
	local yourCoinsLabel = Instance.new("TextLabel")
	yourCoinsLabel.Name = "Label"
	yourCoinsLabel.Size = UDim2.new(0.4, 0, 1, 0)
	yourCoinsLabel.Position = UDim2.new(0, 0, 0, 0)
	yourCoinsLabel.BackgroundTransparency = 1
	yourCoinsLabel.Text = "💰 Coins:"
	yourCoinsLabel.TextColor3 = theme.goldLeaf
	yourCoinsLabel.Font = Enum.Font.GothamBold
	yourCoinsLabel.TextScaled = true
	yourCoinsLabel.ZIndex = 104
	yourCoinsLabel.Parent = yourCoinsFrame
	
	local yourCoinsInput = Instance.new("TextBox")
	yourCoinsInput.Name = "CoinsInput"
	yourCoinsInput.Size = UDim2.new(0.55, 0, 0.8, 0)
	yourCoinsInput.Position = UDim2.new(0.42, 0, 0.1, 0)
	yourCoinsInput.BackgroundColor3 = theme.forestDeep
	yourCoinsInput.Text = "0"
	yourCoinsInput.PlaceholderText = "0"
	yourCoinsInput.TextColor3 = theme.textLight
	yourCoinsInput.Font = Enum.Font.GothamBold
	yourCoinsInput.TextScaled = true
	yourCoinsInput.ClearTextOnFocus = false
	yourCoinsInput.ZIndex = 104
	yourCoinsInput.Parent = yourCoinsFrame
	
	local yourCoinsInputCorner = Instance.new("UICorner")
	yourCoinsInputCorner.CornerRadius = UDim.new(0, 6)
	yourCoinsInputCorner.Parent = yourCoinsInput
	
	-- Confirmed indicator for your side
	local yourConfirmedLabel = Instance.new("TextLabel")
	yourConfirmedLabel.Name = "ConfirmedLabel"
	yourConfirmedLabel.Size = UDim2.new(1, 0, 0.08, 0)
	yourConfirmedLabel.Position = UDim2.new(0, 0, 0.91, 0)
	yourConfirmedLabel.BackgroundTransparency = 1
	yourConfirmedLabel.Text = "❌ Not Confirmed"
	yourConfirmedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	yourConfirmedLabel.Font = Enum.Font.GothamBold
	yourConfirmedLabel.TextScaled = true
	yourConfirmedLabel.ZIndex = 103
	yourConfirmedLabel.Parent = yourOfferPanel
	
	-- Their offer panel (right side)
	local theirOfferPanel = Instance.new("Frame")
	theirOfferPanel.Name = "TheirOfferPanel"
	theirOfferPanel.Size = UDim2.new(0.45, 0, 0.6, 0)
	theirOfferPanel.Position = UDim2.new(0.525, 0, 0.14, 0)
	theirOfferPanel.BackgroundColor3 = theme.forestDeep
	theirOfferPanel.BorderSizePixel = 0
	theirOfferPanel.ZIndex = 102
	theirOfferPanel.Parent = tradePanel
	
	local theirOfferCorner = Instance.new("UICorner")
	theirOfferCorner.CornerRadius = UDim.new(0, 12)
	theirOfferCorner.Parent = theirOfferPanel
	
	local theirOfferTitle = Instance.new("TextLabel")
	theirOfferTitle.Name = "Title"
	theirOfferTitle.Size = UDim2.new(1, 0, 0.1, 0)
	theirOfferTitle.Position = UDim2.new(0, 0, 0, 0)
	theirOfferTitle.BackgroundTransparency = 1
	theirOfferTitle.Text = "📦 Their Offer"
	theirOfferTitle.TextColor3 = theme.amberGlow
	theirOfferTitle.Font = Enum.Font.GothamBold
	theirOfferTitle.TextScaled = true
	theirOfferTitle.ZIndex = 103
	theirOfferTitle.Parent = theirOfferPanel
	
	-- Their offer items scroll
	local theirOfferScroll = Instance.new("ScrollingFrame")
	theirOfferScroll.Name = "ItemsScroll"
	theirOfferScroll.Size = UDim2.new(0.94, 0, 0.75, 0)
	theirOfferScroll.Position = UDim2.new(0.03, 0, 0.11, 0)
	theirOfferScroll.BackgroundTransparency = 1
	theirOfferScroll.BorderSizePixel = 0
	theirOfferScroll.ScrollBarThickness = 6
	theirOfferScroll.ScrollBarImageColor3 = theme.tealGem
	theirOfferScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	theirOfferScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	theirOfferScroll.ZIndex = 103
	theirOfferScroll.Parent = theirOfferPanel
	
	local theirOfferGrid = Instance.new("UIGridLayout")
	theirOfferGrid.Name = "GridLayout"
	theirOfferGrid.CellSize = UDim2.new(0, 70, 0, 70)
	theirOfferGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	theirOfferGrid.SortOrder = Enum.SortOrder.LayoutOrder
	theirOfferGrid.Parent = theirOfferScroll
	
	-- Their coins display
	local theirCoinsLabel = Instance.new("TextLabel")
	theirCoinsLabel.Name = "CoinsLabel"
	theirCoinsLabel.Size = UDim2.new(0.94, 0, 0.1, 0)
	theirCoinsLabel.Position = UDim2.new(0.03, 0, 0.87, 0)
	theirCoinsLabel.BackgroundTransparency = 1
	theirCoinsLabel.Text = "💰 0 Coins"
	theirCoinsLabel.TextColor3 = theme.goldLeaf
	theirCoinsLabel.Font = Enum.Font.GothamBold
	theirCoinsLabel.TextScaled = true
	theirCoinsLabel.ZIndex = 103
	theirCoinsLabel.Parent = theirOfferPanel
	
	-- Confirmed indicator for their side
	local theirConfirmedLabel = Instance.new("TextLabel")
	theirConfirmedLabel.Name = "ConfirmedLabel"
	theirConfirmedLabel.Size = UDim2.new(1, 0, 0.08, 0)
	theirConfirmedLabel.Position = UDim2.new(0, 0, 0.91, 0)
	theirConfirmedLabel.BackgroundTransparency = 1
	theirConfirmedLabel.Text = "❌ Not Confirmed"
	theirConfirmedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	theirConfirmedLabel.Font = Enum.Font.GothamBold
	theirConfirmedLabel.TextScaled = true
	theirConfirmedLabel.ZIndex = 103
	theirConfirmedLabel.Parent = theirOfferPanel
	
	-- Your inventory panel (bottom left)
	local yourInventoryPanel = Instance.new("Frame")
	yourInventoryPanel.Name = "YourInventoryPanel"
	yourInventoryPanel.Size = UDim2.new(0.45, 0, 0.2, 0)
	yourInventoryPanel.Position = UDim2.new(0.025, 0, 0.76, 0)
	yourInventoryPanel.BackgroundColor3 = theme.forestDark
	yourInventoryPanel.BorderSizePixel = 0
	yourInventoryPanel.ZIndex = 102
	yourInventoryPanel.Parent = tradePanel
	
	local yourInvCorner = Instance.new("UICorner")
	yourInvCorner.CornerRadius = UDim.new(0, 12)
	yourInvCorner.Parent = yourInventoryPanel
	
	local yourInvTitle = Instance.new("TextLabel")
	yourInvTitle.Name = "Title"
	yourInvTitle.Size = UDim2.new(1, 0, 0.2, 0)
	yourInvTitle.Position = UDim2.new(0, 0, 0, 0)
	yourInvTitle.BackgroundTransparency = 1
	yourInvTitle.Text = "📋 Your Inventory (Click to add)"
	yourInvTitle.TextColor3 = theme.textMoss
	yourInvTitle.Font = Enum.Font.Gotham
	yourInvTitle.TextScaled = true
	yourInvTitle.ZIndex = 103
	yourInvTitle.Parent = yourInventoryPanel
	
	local yourInvScroll = Instance.new("ScrollingFrame")
	yourInvScroll.Name = "InventoryScroll"
	yourInvScroll.Size = UDim2.new(0.96, 0, 0.75, 0)
	yourInvScroll.Position = UDim2.new(0.02, 0, 0.22, 0)
	yourInvScroll.BackgroundTransparency = 1
	yourInvScroll.BorderSizePixel = 0
	yourInvScroll.ScrollBarThickness = 4
	yourInvScroll.ScrollBarImageColor3 = theme.tealGem
	yourInvScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	yourInvScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	yourInvScroll.ZIndex = 103
	yourInvScroll.Parent = yourInventoryPanel
	
	local yourInvLayout = Instance.new("UIListLayout")
	yourInvLayout.FillDirection = Enum.FillDirection.Horizontal
	yourInvLayout.Padding = UDim.new(0, 6)
	yourInvLayout.SortOrder = Enum.SortOrder.LayoutOrder
	yourInvLayout.Parent = yourInvScroll
	
	-- Action buttons (bottom right)
	local actionButtonsPanel = Instance.new("Frame")
	actionButtonsPanel.Name = "ActionButtonsPanel"
	actionButtonsPanel.Size = UDim2.new(0.45, 0, 0.2, 0)
	actionButtonsPanel.Position = UDim2.new(0.525, 0, 0.76, 0)
	actionButtonsPanel.BackgroundTransparency = 1
	actionButtonsPanel.BorderSizePixel = 0
	actionButtonsPanel.ZIndex = 102
	actionButtonsPanel.Parent = tradePanel
	
	-- Confirm button
	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "ConfirmButton"
	confirmButton.Size = UDim2.new(0.45, 0, 0.4, 0)
	confirmButton.Position = UDim2.new(0.025, 0, 0.3, 0)
	confirmButton.BackgroundColor3 = theme.mossGreen
	confirmButton.Text = "✅ CONFIRM"
	confirmButton.TextColor3 = theme.forestDark
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.TextScaled = true
	confirmButton.ZIndex = 103
	confirmButton.Parent = actionButtonsPanel
	
	local confirmButtonCorner = Instance.new("UICorner")
	confirmButtonCorner.CornerRadius = UDim.new(0, 10)
	confirmButtonCorner.Parent = confirmButton
	
	-- Cancel button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0.45, 0, 0.4, 0)
	cancelButton.Position = UDim2.new(0.525, 0, 0.3, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	cancelButton.Text = "❌ CANCEL"
	cancelButton.TextColor3 = theme.textLight
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.TextScaled = true
	cancelButton.ZIndex = 103
	cancelButton.Parent = actionButtonsPanel
	
	local cancelButtonCorner = Instance.new("UICorner")
	cancelButtonCorner.CornerRadius = UDim.new(0, 10)
	cancelButtonCorner.Parent = cancelButton
	
	-- Status label
	local tradeStatusLabel = Instance.new("TextLabel")
	tradeStatusLabel.Name = "StatusLabel"
	tradeStatusLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	tradeStatusLabel.Position = UDim2.new(0.05, 0, 0.75, 0)
	tradeStatusLabel.BackgroundTransparency = 1
	tradeStatusLabel.Text = "Add items to trade"
	tradeStatusLabel.TextColor3 = theme.textMoss
	tradeStatusLabel.Font = Enum.Font.Gotham
	tradeStatusLabel.TextScaled = true
	tradeStatusLabel.ZIndex = 103
	tradeStatusLabel.Parent = actionButtonsPanel
	
	-- =============================================================================
	-- TRADE REQUEST POPUP
	-- =============================================================================
	local tradeRequestPopup = Instance.new("Frame")
	tradeRequestPopup.Name = "TradeRequestPopup"
	tradeRequestPopup.Size = UDim2.new(0.35, 0, 0.18, 0)
	tradeRequestPopup.Position = UDim2.new(0.5, 0, 0.35, 0)
	tradeRequestPopup.AnchorPoint = Vector2.new(0.5, 0.5)
	tradeRequestPopup.BackgroundColor3 = theme.forestDark
	tradeRequestPopup.BorderSizePixel = 0
	tradeRequestPopup.Visible = false
	tradeRequestPopup.ZIndex = 200
	tradeRequestPopup.Parent = screenGui
	
	local tradePopupCorner = Instance.new("UICorner")
	tradePopupCorner.CornerRadius = UDim.new(0, 16)
	tradePopupCorner.Parent = tradeRequestPopup
	
	local tradePopupStroke = Instance.new("UIStroke")
	tradePopupStroke.Color = theme.goldLeaf
	tradePopupStroke.Thickness = 3
	tradePopupStroke.Parent = tradeRequestPopup
	
	local tradePopupTitle = Instance.new("TextLabel")
	tradePopupTitle.Name = "Title"
	tradePopupTitle.Size = UDim2.new(1, 0, 0.3, 0)
	tradePopupTitle.Position = UDim2.new(0, 0, 0.05, 0)
	tradePopupTitle.BackgroundTransparency = 1
	tradePopupTitle.Text = "🤝 Trade Request"
	tradePopupTitle.TextColor3 = theme.goldLeaf
	tradePopupTitle.Font = Enum.Font.GothamBold
	tradePopupTitle.TextScaled = true
	tradePopupTitle.ZIndex = 201
	tradePopupTitle.Parent = tradeRequestPopup
	
	local tradePopupMessage = Instance.new("TextLabel")
	tradePopupMessage.Name = "Message"
	tradePopupMessage.Size = UDim2.new(0.9, 0, 0.25, 0)
	tradePopupMessage.Position = UDim2.new(0.05, 0, 0.35, 0)
	tradePopupMessage.BackgroundTransparency = 1
	tradePopupMessage.Text = "PlayerName wants to trade with you!"
	tradePopupMessage.TextColor3 = theme.textLight
	tradePopupMessage.Font = Enum.Font.Gotham
	tradePopupMessage.TextScaled = true
	tradePopupMessage.ZIndex = 201
	tradePopupMessage.Parent = tradeRequestPopup
	
	local acceptTradeButton = Instance.new("TextButton")
	acceptTradeButton.Name = "AcceptButton"
	acceptTradeButton.Size = UDim2.new(0.4, 0, 0.25, 0)
	acceptTradeButton.Position = UDim2.new(0.075, 0, 0.65, 0)
	acceptTradeButton.BackgroundColor3 = theme.mossGreen
	acceptTradeButton.Text = "✅ Accept"
	acceptTradeButton.TextColor3 = theme.forestDark
	acceptTradeButton.Font = Enum.Font.GothamBold
	acceptTradeButton.TextScaled = true
	acceptTradeButton.ZIndex = 201
	acceptTradeButton.Parent = tradeRequestPopup
	
	local acceptTradeCorner = Instance.new("UICorner")
	acceptTradeCorner.CornerRadius = UDim.new(0, 8)
	acceptTradeCorner.Parent = acceptTradeButton
	
	local declineTradeButton = Instance.new("TextButton")
	declineTradeButton.Name = "DeclineButton"
	declineTradeButton.Size = UDim2.new(0.4, 0, 0.25, 0)
	declineTradeButton.Position = UDim2.new(0.525, 0, 0.65, 0)
	declineTradeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	declineTradeButton.Text = "❌ Decline"
	declineTradeButton.TextColor3 = theme.textLight
	declineTradeButton.Font = Enum.Font.GothamBold
	declineTradeButton.TextScaled = true
	declineTradeButton.ZIndex = 201
	declineTradeButton.Parent = tradeRequestPopup
	
	local declineTradeCorner = Instance.new("UICorner")
	declineTradeCorner.CornerRadius = UDim.new(0, 8)
	declineTradeCorner.Parent = declineTradeButton
	
	-- Hidden field to store requester ID
	local requesterIdValue = Instance.new("StringValue")
	requesterIdValue.Name = "RequesterId"
	requesterIdValue.Value = ""
	requesterIdValue.Parent = tradeRequestPopup
	
	-- =============================================================================
	-- TRADE BUTTON (in hotbar area or player list)
	-- =============================================================================
	local hotbarFrame = screenGui:FindFirstChild("HotbarFrame")
	local tradeButton = Instance.new("TextButton")
	tradeButton.Name = "TradeButton"
	tradeButton.Size = UDim2.new(0, 120, 0, 40)
	tradeButton.Position = UDim2.new(1, -140, 0.5, -20)
	tradeButton.BackgroundColor3 = theme.tealGem
	tradeButton.Text = "🤝 Trade"
	tradeButton.TextColor3 = theme.textLight
	tradeButton.Font = Enum.Font.GothamBold
	tradeButton.TextScaled = true
	tradeButton.ZIndex = 15
	tradeButton.Parent = hotbarFrame
	
	local tradeButtonCorner = Instance.new("UICorner")
	tradeButtonCorner.CornerRadius = UDim.new(0, 10)
	tradeButtonCorner.Parent = tradeButton
	
	-- =============================================================================
	-- PLAYER SELECT WINDOW (for trade target selection)
	-- =============================================================================
	local playerSelectWindow = Instance.new("Frame")
	playerSelectWindow.Name = "PlayerSelectWindow"
	playerSelectWindow.Size = UDim2.new(0.3, 0, 0.5, 0)
	playerSelectWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	playerSelectWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	playerSelectWindow.BackgroundColor3 = theme.forestDark
	playerSelectWindow.BorderSizePixel = 0
	playerSelectWindow.Visible = false
	playerSelectWindow.ZIndex = 150
	playerSelectWindow.Parent = screenGui
	
	local playerSelectCorner = Instance.new("UICorner")
	playerSelectCorner.CornerRadius = UDim.new(0, 16)
	playerSelectCorner.Parent = playerSelectWindow
	
	local playerSelectStroke = Instance.new("UIStroke")
	playerSelectStroke.Color = theme.tealGem
	playerSelectStroke.Thickness = 3
	playerSelectStroke.Parent = playerSelectWindow
	
	local playerSelectTitle = Instance.new("TextLabel")
	playerSelectTitle.Name = "Title"
	playerSelectTitle.Size = UDim2.new(1, 0, 0.1, 0)
	playerSelectTitle.Position = UDim2.new(0, 0, 0, 0)
	playerSelectTitle.BackgroundTransparency = 1
	playerSelectTitle.Text = "👥 Select Player to Trade"
	playerSelectTitle.TextColor3 = theme.goldLeaf
	playerSelectTitle.Font = Enum.Font.GothamBold
	playerSelectTitle.TextScaled = true
	playerSelectTitle.ZIndex = 151
	playerSelectTitle.Parent = playerSelectWindow
	
	local playerSelectScroll = Instance.new("ScrollingFrame")
	playerSelectScroll.Name = "PlayerList"
	playerSelectScroll.Size = UDim2.new(0.9, 0, 0.75, 0)
	playerSelectScroll.Position = UDim2.new(0.05, 0, 0.12, 0)
	playerSelectScroll.BackgroundTransparency = 1
	playerSelectScroll.BorderSizePixel = 0
	playerSelectScroll.ScrollBarThickness = 6
	playerSelectScroll.ScrollBarImageColor3 = theme.tealGem
	playerSelectScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playerSelectScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	playerSelectScroll.ZIndex = 151
	playerSelectScroll.Parent = playerSelectWindow
	
	local playerSelectLayout = Instance.new("UIListLayout")
	playerSelectLayout.Padding = UDim.new(0, 8)
	playerSelectLayout.SortOrder = Enum.SortOrder.Name
	playerSelectLayout.Parent = playerSelectScroll
	
	local playerSelectClose = Instance.new("TextButton")
	playerSelectClose.Name = "CloseButton"
	playerSelectClose.Size = UDim2.new(0.9, 0, 0.08, 0)
	playerSelectClose.Position = UDim2.new(0.05, 0, 0.9, 0)
	playerSelectClose.BackgroundColor3 = theme.forestDeep
	playerSelectClose.Text = "Cancel"
	playerSelectClose.TextColor3 = theme.textLight
	playerSelectClose.Font = Enum.Font.GothamBold
	playerSelectClose.TextScaled = true
	playerSelectClose.ZIndex = 151
	playerSelectClose.Parent = playerSelectWindow
	
	local playerSelectCloseCorner = Instance.new("UICorner")
	playerSelectCloseCorner.CornerRadius = UDim.new(0, 8)
	playerSelectCloseCorner.Parent = playerSelectClose
	
	-- =============================================================================
	-- SHOP REFRESH TIMER (add to shop window)
	-- =============================================================================
	local shopRefreshTimer = Instance.new("TextLabel")
	shopRefreshTimer.Name = "RefreshTimer"
	shopRefreshTimer.Size = UDim2.new(0.3, 0, 0.05, 0)
	shopRefreshTimer.Position = UDim2.new(0.35, 0, 0.02, 0)
	shopRefreshTimer.BackgroundTransparency = 1
	shopRefreshTimer.Text = "🔄 Refreshes in: 00:00:00"
	shopRefreshTimer.TextColor3 = theme.tealGem
	shopRefreshTimer.Font = Enum.Font.Gotham
	shopRefreshTimer.TextScaled = true
	shopRefreshTimer.ZIndex = 12
	shopRefreshTimer.Parent = shopWindow
	
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

