-- UISetup.luau (ModuleScript)
-- RUN THIS ONCE IN STUDIO COMMAND BAR:
-- require(game.ReplicatedStorage.Setup.UISetup).CreateUI()
-- Creates the UI structure in StarterGui that clients will use
-- Theme: Enchanted Forest - Hand-painted fantasy with deep forest tones and magical glows
-- Based on fantasy_ui_design_doc.md
-- Supports PC and Mobile layouts with responsive scaling

local UISetup = {}

-- =============================================================================
-- CONFIGURATION (UI/UX Best Practices)
-- =============================================================================
local CONFIG = {
	-- Item card sizes (compact for better visibility)
	PC_ITEM_CELL_SIZE = UDim2.new(0, 100, 0, 120),
	MOBILE_ITEM_CELL_SIZE = UDim2.new(0, 80, 0, 100),
	
	-- Grid padding
	GRID_CELL_PADDING = UDim2.new(0, 8, 0, 8),
	
	-- Inventory grid sizes
	PC_INVENTORY_CELL_SIZE = UDim2.new(0, 80, 0, 80),
	MOBILE_INVENTORY_CELL_SIZE = UDim2.new(0, 65, 0, 65),
	
	-- Shop panel sizes (relative)
	SHOP_PANEL_WIDTH = 0.32,
	
	-- Minimum screen width to consider as PC
	PC_MIN_WIDTH = 800,
	
	-- SCREEN SAFE ZONES (keep UI inside 90% of screen)
	SAFE_ZONE_PADDING = 0.05, -- 5% margin on each side = 90% usable
	
	-- BUTTON FEEDBACK (visual juice)
	BUTTON_HOVER_BRIGHTNESS = 1.15, -- 15% brighter on hover
	BUTTON_CLICK_SCALE = 0.95, -- Scale down 5% on click
	BUTTON_TRANSITION_TIME = 0.1, -- Fast feedback
	
	-- ACCESSIBILITY
	MIN_TOUCH_SIZE = 44, -- Minimum 44px for touch targets
	TEXT_STROKE_THICKNESS = 2, -- Readable text stroke
	HIGH_CONTRAST_STROKE = Color3.fromRGB(0, 0, 0), -- Black stroke for contrast
}

-- =============================================================================
-- UI SECTION BUILDERS (Split CreateUI to avoid local variable limit)
-- =============================================================================
local UIBuilders = {}

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

	-- Root aspect box to keep layout consistent across devices
	local uiRoot = Instance.new("Frame")
	uiRoot.Name = "UIRoot"
	uiRoot.Size = UDim2.new(1, 0, 1, 0)
	uiRoot.Position = UDim2.new(0.5, 0, 0.5, 0)
	uiRoot.AnchorPoint = Vector2.new(0.5, 0.5)
	uiRoot.BackgroundTransparency = 1
	uiRoot.Parent = screenGui

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 16 / 9
	aspect.AspectType = Enum.AspectType.FitWithinMaxSize
	aspect.DominantAxis = Enum.DominantAxis.Width
	aspect.Parent = uiRoot

	-- Group frames for HUD, windows, and overlays
	local hudGroup = Instance.new("Frame")
	hudGroup.Name = "HUDGroup"
	hudGroup.Size = UDim2.new(1, 0, 1, 0)
	hudGroup.BackgroundTransparency = 1
	hudGroup.ZIndex = 5
	hudGroup.Parent = uiRoot

	local windowGroup = Instance.new("Frame")
	windowGroup.Name = "WindowGroup"
	windowGroup.Size = UDim2.new(1, 0, 1, 0)
	windowGroup.BackgroundTransparency = 1
	windowGroup.ZIndex = 20
	windowGroup.Parent = uiRoot

	local overlayGroup = Instance.new("Frame")
	overlayGroup.Name = "OverlayGroup"
	overlayGroup.Size = UDim2.new(1, 0, 1, 0)
	overlayGroup.BackgroundTransparency = 1
	overlayGroup.ZIndex = 100
	overlayGroup.Parent = uiRoot

	-- =============================================================================
	-- NPC DIALOGUE CONTAINER (ScreenGui for BillboardGuis to be clickable)
	-- =============================================================================
	local npcDialogueGui = Instance.new("ScreenGui")
	npcDialogueGui.Name = "NPCDialogueContainer"
	npcDialogueGui.ResetOnSpawn = false
	npcDialogueGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	npcDialogueGui.IgnoreGuiInset = true
	npcDialogueGui.DisplayOrder = 50
	npcDialogueGui.Parent = StarterGui
	
	-- =============================================================================
	-- LOADING SCREEN (Full Screen Overlay)
	-- Transparent background since camera has blur effect
	-- Starts invisible - client script makes it visible first
	-- =============================================================================
	local loadingScreen = Instance.new("Frame")
	loadingScreen.Name = "LoadingScreen"
	loadingScreen.Size = UDim2.new(1, 0, 1, 0)
	loadingScreen.Position = UDim2.new(0, 0, 0, 0)
	loadingScreen.BackgroundTransparency = 1 -- Transparent since camera has blur
	loadingScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Fallback color
	loadingScreen.BorderSizePixel = 0
	loadingScreen.ZIndex = 1000 -- On top of everything
	loadingScreen.Visible = false -- Script makes this visible first
	loadingScreen.Parent = overlayGroup
	
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
	
	-- =========================================================================
	-- UI FEEDBACK HELPERS (Hover/Click visual juice)
	-- =========================================================================
	
	-- Add hover and click feedback to any button (CRITICAL: Feedback is King)
	local function addButtonFeedback(button: TextButton | ImageButton, options: {hoverColor: Color3?, clickScale: number?}?)
		options = options or {}
		local originalColor = button.BackgroundColor3
		local originalSize = button.Size
		local hoverBrightness = CONFIG.BUTTON_HOVER_BRIGHTNESS
		local clickScale = options.clickScale or CONFIG.BUTTON_CLICK_SCALE
		
		-- Calculate brighter color for hover
		local function brighten(color: Color3, factor: number): Color3
			return Color3.new(
				math.clamp(color.R * factor, 0, 1),
				math.clamp(color.G * factor, 0, 1),
				math.clamp(color.B * factor, 0, 1)
			)
		end
		
		local hoverColor = options.hoverColor or brighten(originalColor, hoverBrightness)
		
		-- Store original values as attributes for runtime reference
		button:SetAttribute("OriginalColor", originalColor)
		button:SetAttribute("HoverColor", hoverColor)
		button:SetAttribute("ClickScale", clickScale)
		button:SetAttribute("HasFeedback", true)
		
		-- Add UIScale for click animation if not present
		local uiScale = button:FindFirstChild("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Name = "UIScale"
			uiScale.Scale = 1
			uiScale.Parent = button
		end
		
		return button
	end
	
	-- Add accessibility-friendly icon + text label (don't rely on color alone)
	local function addAccessibleLabel(parent, iconEmoji: string, text: string, textColor: Color3)
		local container = Instance.new("Frame")
		container.Name = "AccessibleLabel"
		container.Size = UDim2.new(1, 0, 0, 40)
		container.BackgroundTransparency = 1
		container.Parent = parent

		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0.2, 0, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = iconEmoji
		icon.TextScaled = true
		icon.Font = Enum.Font.GothamBold
		icon.TextColor3 = textColor
		icon.Parent = container
		
		-- Text label
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(0.75, 0, 1, 0)
		label.Position = UDim2.new(0.25, 0, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = textColor
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container
		
		-- High contrast stroke for readability
		local stroke = Instance.new("UIStroke")
		stroke.Color = CONFIG.HIGH_CONTRAST_STROKE
		stroke.Thickness = CONFIG.TEXT_STROKE_THICKNESS
		stroke.Parent = label
		
		return container
	end
	
	-- Ensure minimum touch target size for accessibility (no size constraints to avoid box art distortion)
	local function ensureMinTouchSize(_element)
		return nil
	end

	-- Frame art asset ids (provided)
	local FRAME_IMAGE_WINDOW_TALL = "rbxassetid://72140204040476"   -- File 1 (tall window)
	local FRAME_IMAGE_WINDOW_WIDE = "rbxassetid://110769453800411"  -- File 2 (wide window)
	local FRAME_IMAGE_PANEL_RECT = "rbxassetid://77328240678206"    -- File 3 (rect panel)
	local FRAME_IMAGE_PANEL_SQUARE = "rbxassetid://125833347683847" -- File 4 (square/rect panel)

	-- New fantasy box assets (plain, no extra gradient/stroke)
	local BOX_BIG_SQUARE = "rbxassetid://127057870020428"
	local BOX_PORTRAIT_PAGE = "rbxassetid://128212287368223"
	local BOX_SMALL_SQUARE = "rbxassetid://140498152022385"
	local BOX_TEXT_RECT = "rbxassetid://108042948747763"
	local BOX_TEXT_RECT_2 = "rbxassetid://86627713332359"
	local BOX_TEXT_RECT_3 = "rbxassetid://121216410953651"

	-- 9-slice defaults (tune if edges warp after upload)
	local FRAME_SLICE_TALL = Rect.new(90, 120, 630, 960)
	local FRAME_SLICE_WIDE = Rect.new(90, 120, 630, 960)
	local FRAME_SLICE_RECT = Rect.new(90, 120, 630, 960)
	local FRAME_SLICE_SQUARE = Rect.new(90, 120, 630, 960)

	-- Plain box applicator for the new art (1.4x size with Crop for clean edges)
	local function applyBoxImage(parent, assetId)
		local bg = Instance.new("ImageLabel")
		bg.Name = "BoxArt"
		bg.BackgroundTransparency = 1
		bg.Image = assetId
		bg.ScaleType = Enum.ScaleType.Crop
		bg.Size = UDim2.new(1.4, 0, 1.4, 0)
		bg.Position = UDim2.new(0.5, 0, 0.5, 0)
		bg.AnchorPoint = Vector2.new(0.5, 0.5)
		bg.ZIndex = (parent.ZIndex or 1) - 1
		bg.Parent = parent
		parent.BackgroundTransparency = 1
		return bg
	end

	-- PetsWindow-style background (exact look + placement), used for all WindowGroup windows.
	local function applyPetsWindowBackground(parent)
		local bg = Instance.new("ImageLabel")
		bg.Name = "Background"
		bg.BackgroundTransparency = 1
		bg.Image = BOX_BIG_SQUARE -- same asset as PetsWindow
		bg.Size = UDim2.new(2, 0, 1.6, 0)
		bg.Position = UDim2.new(0.49, 0, 0.5, 30)
		bg.AnchorPoint = Vector2.new(0.5, 0.5)
		bg.ScaleType = Enum.ScaleType.Stretch
		-- Keep the exact look, but ensure it sits just behind the window's contents.
		bg.ZIndex = (parent.ZIndex or 1) - 1
		bg.Parent = parent
		parent.BackgroundTransparency = 1
		return bg
	end

	local function applyFrameImage(parent, assetId, sliceRect, zOffset)
		local bg = Instance.new("ImageLabel")
		bg.Name = "FrameArt"
		bg.BackgroundTransparency = 1
		bg.Image = assetId or FRAME_IMAGE_WINDOW_TALL
		bg.ScaleType = Enum.ScaleType.Crop
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
		
		-- Rarity colors
		rarityCommon = Color3.fromRGB(180, 180, 180),
		rarityUncommon = Color3.fromRGB(100, 200, 100),
		rarityRare = Color3.fromRGB(100, 150, 255),
		rarityEpic = Color3.fromRGB(180, 100, 255),
		rarityLegendary = Color3.fromRGB(255, 180, 50),
	}
	
	-- =============================================================================
	-- TEMPLATE CREATOR FUNCTIONS (Reusable UI components)
	-- Templates are added directly to scrolling frames (invisible, for cloning)
	-- =============================================================================
	
	-- -----------------------------------------------------------------------------
	-- SHOP ITEM CARD TEMPLATE (Compact, well-scaled for visibility)
	-- Used in: SeedShop, PetShop (Eggs), SellWindow
	-- -----------------------------------------------------------------------------
	local function createShopItemTemplate()
		local itemCard = Instance.new("Frame")
		itemCard.Name = "ShopItemTemplate"
		itemCard.Size = UDim2.new(1, -10, 0, 110) -- Full width with padding, compact height
		itemCard.BackgroundColor3 = theme.forestDeep
		itemCard.BorderSizePixel = 0
		
		addCorner(itemCard, 12)
		addStroke(itemCard, theme.tealGem, 2, 0.4)
		
		-- Aspect ratio for consistent scaling
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.AspectRatio = 3.5 -- Wide format for list layout
		aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
		aspectRatio.DominantAxis = Enum.DominantAxis.Width
		aspectRatio.Parent = itemCard
		
		-- Left side: Item icon container
		local iconContainer = Instance.new("Frame")
		iconContainer.Name = "IconContainer"
		iconContainer.Size = UDim2.new(0.25, 0, 0.85, 0)
		iconContainer.Position = UDim2.new(0.02, 0, 0.075, 0)
		iconContainer.BackgroundColor3 = theme.forestDark
		iconContainer.BorderSizePixel = 0
		iconContainer.Parent = itemCard
		addCorner(iconContainer, 8)
		
		-- Icon aspect ratio to keep it square
		local iconAspect = Instance.new("UIAspectRatioConstraint")
		iconAspect.AspectRatio = 1
		iconAspect.AspectType = Enum.AspectType.FitWithinMaxSize
		iconAspect.DominantAxis = Enum.DominantAxis.Height
		iconAspect.Parent = iconContainer
		
		local itemIcon = Instance.new("TextLabel")
		itemIcon.Name = "ItemIcon"
		itemIcon.Size = UDim2.new(0.9, 0, 0.9, 0)
		itemIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		itemIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		itemIcon.BackgroundTransparency = 1
		itemIcon.Text = "🌱"
		itemIcon.TextScaled = true
		itemIcon.Font = Enum.Font.GothamBold
		itemIcon.TextColor3 = theme.textLight
		itemIcon.Parent = iconContainer
		
		-- Middle: Item info
		local infoContainer = Instance.new("Frame")
		infoContainer.Name = "InfoContainer"
		infoContainer.Size = UDim2.new(0.45, 0, 0.85, 0)
		infoContainer.Position = UDim2.new(0.28, 0, 0.075, 0)
		infoContainer.BackgroundTransparency = 1
		infoContainer.Parent = itemCard
		
		local itemName = Instance.new("TextLabel")
		itemName.Name = "ItemName"
		itemName.Size = UDim2.new(1, 0, 0.35, 0)
		itemName.Position = UDim2.new(0, 0, 0.05, 0)
		itemName.BackgroundTransparency = 1
		itemName.Text = "Item Name"
		itemName.TextColor3 = theme.textLight
		itemName.Font = Enum.Font.GothamBold
		itemName.TextScaled = true
		itemName.TextXAlignment = Enum.TextXAlignment.Left
		itemName.Parent = infoContainer
		
		local itemNameStroke = Instance.new("UIStroke")
		itemNameStroke.Color = theme.forestDark
		itemNameStroke.Thickness = 1
		itemNameStroke.Parent = itemName
		
		local itemRarity = Instance.new("TextLabel")
		itemRarity.Name = "ItemRarity"
		itemRarity.Size = UDim2.new(0.6, 0, 0.22, 0)
		itemRarity.Position = UDim2.new(0, 0, 0.42, 0)
		itemRarity.BackgroundTransparency = 1
		itemRarity.Text = "Common"
		itemRarity.TextColor3 = theme.rarityCommon
		itemRarity.Font = Enum.Font.Gotham
		itemRarity.TextScaled = true
		itemRarity.TextXAlignment = Enum.TextXAlignment.Left
		itemRarity.Parent = infoContainer
		
		local itemStock = Instance.new("TextLabel")
		itemStock.Name = "ItemStock"
		itemStock.Size = UDim2.new(1, 0, 0.22, 0)
		itemStock.Position = UDim2.new(0, 0, 0.68, 0)
		itemStock.BackgroundTransparency = 1
		itemStock.Text = "Stock: 10"
		itemStock.TextColor3 = theme.textMoss
		itemStock.Font = Enum.Font.Gotham
		itemStock.TextScaled = true
		itemStock.TextXAlignment = Enum.TextXAlignment.Left
		itemStock.Parent = infoContainer
		
		-- Right side: Price and Buy button
		local actionContainer = Instance.new("Frame")
		actionContainer.Name = "ActionContainer"
		actionContainer.Size = UDim2.new(0.24, 0, 0.85, 0)
		actionContainer.Position = UDim2.new(0.74, 0, 0.075, 0)
		actionContainer.BackgroundTransparency = 1
		actionContainer.Parent = itemCard
		
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(1, 0, 0.35, 0)
		priceLabel.Position = UDim2.new(0, 0, 0.05, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "💰 100"
		priceLabel.TextColor3 = theme.goldLeaf
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.TextScaled = true
		priceLabel.Parent = actionContainer
		
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0.95, 0, 0.45, 0)
		buyButton.Position = UDim2.new(0.025, 0, 0.5, 0)
		buyButton.BackgroundColor3 = theme.tealGem
		buyButton.Text = "🛒 BUY" -- Icon + text for accessibility
		buyButton.TextColor3 = theme.textLight
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextScaled = true
		buyButton.Parent = actionContainer
		addCorner(buyButton, 8)
		addStroke(buyButton, theme.tealGlow, 2, 0.3)
		addButtonFeedback(buyButton)
		
		-- High contrast stroke for readability
		local buyTextStroke = Instance.new("UIStroke")
		buyTextStroke.Color = theme.forestDark
		buyTextStroke.Thickness = 1
		buyTextStroke.Parent = buyButton
		
		return itemCard
	end
	
	-- -----------------------------------------------------------------------------
	-- INVENTORY ITEM TEMPLATE (Grid cell for inventory/equipped items)
	-- Used in: Shop inventory panel, Sell inventory panel, Pet inventory
	-- -----------------------------------------------------------------------------
	local function createInventoryItemTemplate()
		local invItem = Instance.new("Frame")
		invItem.Name = "InventoryItemTemplate"
		invItem.Size = UDim2.new(0, 80, 0, 80)
		invItem.BackgroundColor3 = theme.forestDeep
		invItem.BorderSizePixel = 0
		
		addCorner(invItem, 10)
		addStroke(invItem, theme.vineStroke, 2, 0.4)
		
		-- Aspect ratio to keep items square
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.AspectRatio = 1
		aspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
		aspectRatio.DominantAxis = Enum.DominantAxis.Width
		aspectRatio.Parent = invItem
		
		-- Item icon
		local itemIcon = Instance.new("TextLabel")
		itemIcon.Name = "ItemIcon"
		itemIcon.Size = UDim2.new(0.7, 0, 0.55, 0)
		itemIcon.Position = UDim2.new(0.5, 0, 0.35, 0)
		itemIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		itemIcon.BackgroundTransparency = 1
		itemIcon.Text = "🌱"
		itemIcon.TextScaled = true
		itemIcon.Font = Enum.Font.GothamBold
		itemIcon.TextColor3 = theme.textLight
		itemIcon.Parent = invItem
		
		-- Item count badge (bottom right)
		local countBadge = Instance.new("Frame")
		countBadge.Name = "CountBadge"
		countBadge.Size = UDim2.new(0.45, 0, 0.25, 0)
		countBadge.Position = UDim2.new(0.95, 0, 0.95, 0)
		countBadge.AnchorPoint = Vector2.new(1, 1)
		countBadge.BackgroundColor3 = theme.forestDark
		countBadge.BorderSizePixel = 0
		countBadge.Parent = invItem
		addCorner(countBadge, 6)
		
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(1, 0, 1, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = "x1"
		countLabel.TextColor3 = theme.textLight
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextScaled = true
		countLabel.Parent = countBadge
		
		-- Item name (top, small text)
		local itemName = Instance.new("TextLabel")
		itemName.Name = "ItemName"
		itemName.Size = UDim2.new(0.9, 0, 0.22, 0)
		itemName.Position = UDim2.new(0.5, 0, 0.68, 0)
		itemName.AnchorPoint = Vector2.new(0.5, 0)
		itemName.BackgroundTransparency = 1
		itemName.Text = "Seed"
		itemName.TextColor3 = theme.textMoss
		itemName.Font = Enum.Font.Gotham
		itemName.TextScaled = true
		itemName.TextTruncate = Enum.TextTruncate.AtEnd
		itemName.Parent = invItem
		
		-- Click button overlay
		local clickButton = Instance.new("TextButton")
		clickButton.Name = "ClickButton"
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.ZIndex = 2
		clickButton.Parent = invItem
		
		return invItem
	end
	
	-- -----------------------------------------------------------------------------
	-- EGG ITEM TEMPLATE (Larger card for egg shop with rarity chances)
	-- Used in: Pet Shop egg section
	-- -----------------------------------------------------------------------------
	local function createEggItemTemplate()
		local eggCard = Instance.new("Frame")
		eggCard.Name = "EggItemTemplate"
		eggCard.Size = UDim2.new(1, -10, 0, 140)
		eggCard.BackgroundColor3 = theme.forestDeep
		eggCard.BorderSizePixel = 0
		
		addCorner(eggCard, 14)
		addStroke(eggCard, theme.amberGlow, 2, 0.3)
		
		-- Aspect ratio
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.AspectRatio = 3
		aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
		aspectRatio.DominantAxis = Enum.DominantAxis.Width
		aspectRatio.Parent = eggCard
		
		-- Left: Egg icon
		local iconContainer = Instance.new("Frame")
		iconContainer.Name = "IconContainer"
		iconContainer.Size = UDim2.new(0.22, 0, 0.8, 0)
		iconContainer.Position = UDim2.new(0.02, 0, 0.1, 0)
		iconContainer.BackgroundColor3 = theme.forestDark
		iconContainer.BorderSizePixel = 0
		iconContainer.Parent = eggCard
		addCorner(iconContainer, 10)
		
		local iconAspect = Instance.new("UIAspectRatioConstraint")
		iconAspect.AspectRatio = 1
		iconAspect.AspectType = Enum.AspectType.FitWithinMaxSize
		iconAspect.DominantAxis = Enum.DominantAxis.Height
		iconAspect.Parent = iconContainer
		
		local eggIcon = Instance.new("TextLabel")
		eggIcon.Name = "EggIcon"
		eggIcon.Size = UDim2.new(0.85, 0, 0.85, 0)
		eggIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		eggIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		eggIcon.BackgroundTransparency = 1
		eggIcon.Text = "🥚"
		eggIcon.TextScaled = true
		eggIcon.Font = Enum.Font.GothamBold
		eggIcon.TextColor3 = theme.textLight
		eggIcon.Parent = iconContainer
		
		-- Middle: Egg info and chances
		local infoContainer = Instance.new("Frame")
		infoContainer.Name = "InfoContainer"
		infoContainer.Size = UDim2.new(0.48, 0, 0.85, 0)
		infoContainer.Position = UDim2.new(0.26, 0, 0.075, 0)
		infoContainer.BackgroundTransparency = 1
		infoContainer.Parent = eggCard
		
		local eggName = Instance.new("TextLabel")
		eggName.Name = "EggName"
		eggName.Size = UDim2.new(1, 0, 0.28, 0)
		eggName.Position = UDim2.new(0, 0, 0.02, 0)
		eggName.BackgroundTransparency = 1
		eggName.Text = "Mystery Egg"
		eggName.TextColor3 = theme.textGold
		eggName.Font = Enum.Font.GothamBold
		eggName.TextScaled = true
		eggName.TextXAlignment = Enum.TextXAlignment.Left
		eggName.Parent = infoContainer
		
		local eggNameStroke = Instance.new("UIStroke")
		eggNameStroke.Color = theme.forestDark
		eggNameStroke.Thickness = 1
		eggNameStroke.Parent = eggName
		
		-- Chance labels container
		local chancesContainer = Instance.new("Frame")
		chancesContainer.Name = "ChancesContainer"
		chancesContainer.Size = UDim2.new(1, 0, 0.65, 0)
		chancesContainer.Position = UDim2.new(0, 0, 0.32, 0)
		chancesContainer.BackgroundTransparency = 1
		chancesContainer.Parent = infoContainer
		
		local chancesLayout = Instance.new("UIListLayout")
		chancesLayout.FillDirection = Enum.FillDirection.Vertical
		chancesLayout.Padding = UDim.new(0, 2)
		chancesLayout.SortOrder = Enum.SortOrder.LayoutOrder
		chancesLayout.Parent = chancesContainer
		
		-- Placeholder chance labels (will be populated dynamically)
		for i, rarity in ipairs({"Common", "Uncommon", "Rare"}) do
			local chanceLabel = Instance.new("TextLabel")
			chanceLabel.Name = rarity .. "Chance"
			chanceLabel.Size = UDim2.new(1, 0, 0, 16)
			chanceLabel.BackgroundTransparency = 1
			chanceLabel.Text = rarity .. ": 50%"
			chanceLabel.TextColor3 = theme["rarity" .. rarity] or theme.textMoss
			chanceLabel.Font = Enum.Font.Gotham
			chanceLabel.TextSize = 12
			chanceLabel.TextXAlignment = Enum.TextXAlignment.Left
			chanceLabel.LayoutOrder = i
			chanceLabel.Parent = chancesContainer
		end
		
		-- Right: Price and Buy
		local actionContainer = Instance.new("Frame")
		actionContainer.Name = "ActionContainer"
		actionContainer.Size = UDim2.new(0.22, 0, 0.85, 0)
		actionContainer.Position = UDim2.new(0.76, 0, 0.075, 0)
		actionContainer.BackgroundTransparency = 1
		actionContainer.Parent = eggCard
		
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(1, 0, 0.3, 0)
		priceLabel.Position = UDim2.new(0, 0, 0.05, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "💰 500"
		priceLabel.TextColor3 = theme.goldLeaf
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.TextScaled = true
		priceLabel.Parent = actionContainer
		
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0.95, 0, 0.4, 0)
		buyButton.Position = UDim2.new(0.025, 0, 0.55, 0)
		buyButton.BackgroundColor3 = theme.amberGlow
		buyButton.Text = "🥚 BUY" -- Icon + text for accessibility
		buyButton.TextColor3 = theme.forestDark
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextScaled = true
		buyButton.Parent = actionContainer
		addCorner(buyButton, 8)
		addStroke(buyButton, theme.goldLeaf, 2, 0.3)
		addButtonFeedback(buyButton)
		
		return eggCard
	end
	
	-- -----------------------------------------------------------------------------
	-- PET ITEM TEMPLATE (For pet inventory display with stats)
	-- Used in: Pet inventory, Pet shop owned pets section
	-- -----------------------------------------------------------------------------
	local function createPetItemTemplate()
		local petCard = Instance.new("Frame")
		petCard.Name = "PetItemTemplate"
		petCard.Size = UDim2.new(0, 90, 0, 110)
		petCard.BackgroundColor3 = theme.forestDeep
		petCard.BorderSizePixel = 0
		
		addCorner(petCard, 10)
		addStroke(petCard, theme.tealGem, 2, 0.4)
		
		-- Pet icon
		local petIcon = Instance.new("TextLabel")
		petIcon.Name = "PetIcon"
		petIcon.Size = UDim2.new(0.75, 0, 0.45, 0)
		petIcon.Position = UDim2.new(0.5, 0, 0.28, 0)
		petIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		petIcon.BackgroundTransparency = 1
		petIcon.Text = "🐱"
		petIcon.TextScaled = true
		petIcon.Font = Enum.Font.GothamBold
		petIcon.TextColor3 = theme.textLight
		petIcon.Parent = petCard
		
		-- Pet name
		local petName = Instance.new("TextLabel")
		petName.Name = "PetName"
		petName.Size = UDim2.new(0.9, 0, 0.18, 0)
		petName.Position = UDim2.new(0.5, 0, 0.52, 0)
		petName.AnchorPoint = Vector2.new(0.5, 0)
		petName.BackgroundTransparency = 1
		petName.Text = "Cat"
		petName.TextColor3 = theme.textLight
		petName.Font = Enum.Font.GothamBold
		petName.TextScaled = true
		petName.TextTruncate = Enum.TextTruncate.AtEnd
		petName.Parent = petCard
		
		-- Boost stat
		local boostLabel = Instance.new("TextLabel")
		boostLabel.Name = "BoostLabel"
		boostLabel.Size = UDim2.new(0.9, 0, 0.14, 0)
		boostLabel.Position = UDim2.new(0.5, 0, 0.72, 0)
		boostLabel.AnchorPoint = Vector2.new(0.5, 0)
		boostLabel.BackgroundTransparency = 1
		boostLabel.Text = "+10% Growth"
		boostLabel.TextColor3 = theme.tealGlow
		boostLabel.Font = Enum.Font.Gotham
		boostLabel.TextScaled = true
		boostLabel.Parent = petCard
		
		-- Equip/Unequip button
		local equipButton = Instance.new("TextButton")
		equipButton.Name = "EquipButton"
		equipButton.Size = UDim2.new(0.85, 0, 0.16, 0)
		equipButton.Position = UDim2.new(0.5, 0, 0.88, 0)
		equipButton.AnchorPoint = Vector2.new(0.5, 0)
		equipButton.BackgroundColor3 = theme.tealGem
		equipButton.Text = "⭐ EQUIP" -- Icon + text for accessibility
		equipButton.TextColor3 = theme.textLight
		equipButton.Font = Enum.Font.GothamBold
		equipButton.TextScaled = true
		equipButton.Parent = petCard
		addCorner(equipButton, 6)
		addButtonFeedback(equipButton)
		
		return petCard
	end
	
	-- -----------------------------------------------------------------------------
	-- SELL ITEM TEMPLATE (For sellable fruits with sell price)
	-- Used in: Sell window fruit list
	-- -----------------------------------------------------------------------------
	local function createSellItemTemplate()
		local sellCard = Instance.new("Frame")
		sellCard.Name = "SellItemTemplate"
		sellCard.Size = UDim2.new(1, -10, 0, 100)
		sellCard.BackgroundColor3 = theme.forestDeep
		sellCard.BorderSizePixel = 0
		
		addCorner(sellCard, 12)
		addStroke(sellCard, theme.goldLeaf, 2, 0.4)
		
		-- Aspect ratio
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.AspectRatio = 4
		aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
		aspectRatio.DominantAxis = Enum.DominantAxis.Width
		aspectRatio.Parent = sellCard
		
		-- Left: Fruit icon
		local iconContainer = Instance.new("Frame")
		iconContainer.Name = "IconContainer"
		iconContainer.Size = UDim2.new(0.2, 0, 0.8, 0)
		iconContainer.Position = UDim2.new(0.02, 0, 0.1, 0)
		iconContainer.BackgroundColor3 = theme.forestDark
		iconContainer.BorderSizePixel = 0
		iconContainer.Parent = sellCard
		addCorner(iconContainer, 8)
		
		local iconAspect = Instance.new("UIAspectRatioConstraint")
		iconAspect.AspectRatio = 1
		iconAspect.AspectType = Enum.AspectType.FitWithinMaxSize
		iconAspect.DominantAxis = Enum.DominantAxis.Height
		iconAspect.Parent = iconContainer
		
		local fruitIcon = Instance.new("TextLabel")
		fruitIcon.Name = "FruitIcon"
		fruitIcon.Size = UDim2.new(0.85, 0, 0.85, 0)
		fruitIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		fruitIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		fruitIcon.BackgroundTransparency = 1
		fruitIcon.Text = "🍎"
		fruitIcon.TextScaled = true
		fruitIcon.Font = Enum.Font.GothamBold
		fruitIcon.TextColor3 = theme.textLight
		fruitIcon.Parent = iconContainer
		
		-- Middle: Fruit info
		local infoContainer = Instance.new("Frame")
		infoContainer.Name = "InfoContainer"
		infoContainer.Size = UDim2.new(0.38, 0, 0.8, 0)
		infoContainer.Position = UDim2.new(0.24, 0, 0.1, 0)
		infoContainer.BackgroundTransparency = 1
		infoContainer.Parent = sellCard
		
		local fruitName = Instance.new("TextLabel")
		fruitName.Name = "FruitName"
		fruitName.Size = UDim2.new(1, 0, 0.4, 0)
		fruitName.Position = UDim2.new(0, 0, 0.1, 0)
		fruitName.BackgroundTransparency = 1
		fruitName.Text = "Apple"
		fruitName.TextColor3 = theme.textLight
		fruitName.Font = Enum.Font.GothamBold
		fruitName.TextScaled = true
		fruitName.TextXAlignment = Enum.TextXAlignment.Left
		fruitName.Parent = infoContainer
		
		local fruitCount = Instance.new("TextLabel")
		fruitCount.Name = "FruitCount"
		fruitCount.Size = UDim2.new(1, 0, 0.35, 0)
		fruitCount.Position = UDim2.new(0, 0, 0.55, 0)
		fruitCount.BackgroundTransparency = 1
		fruitCount.Text = "Owned: 5"
		fruitCount.TextColor3 = theme.textMoss
		fruitCount.Font = Enum.Font.Gotham
		fruitCount.TextScaled = true
		fruitCount.TextXAlignment = Enum.TextXAlignment.Left
		fruitCount.Parent = infoContainer
		
		-- Right: Price and Sell
		local actionContainer = Instance.new("Frame")
		actionContainer.Name = "ActionContainer"
		actionContainer.Size = UDim2.new(0.34, 0, 0.8, 0)
		actionContainer.Position = UDim2.new(0.64, 0, 0.1, 0)
		actionContainer.BackgroundTransparency = 1
		actionContainer.Parent = sellCard
		
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(1, 0, 0.35, 0)
		priceLabel.Position = UDim2.new(0, 0, 0.05, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "💰 +25"
		priceLabel.TextColor3 = theme.goldLeaf
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.TextScaled = true
		priceLabel.Parent = actionContainer
		
		local sellButton = Instance.new("TextButton")
		sellButton.Name = "SellButton"
		sellButton.Size = UDim2.new(0.48, 0, 0.45, 0)
		sellButton.Position = UDim2.new(0, 0, 0.5, 0)
		sellButton.BackgroundColor3 = theme.goldLeaf
		sellButton.Text = "💰 SELL" -- Icon + text
		sellButton.TextColor3 = theme.forestDark
		sellButton.Font = Enum.Font.GothamBold
		sellButton.TextScaled = true
		sellButton.Parent = actionContainer
		addCorner(sellButton, 8)
		addButtonFeedback(sellButton)
		
		-- Sell All is destructive - isolated with different color (visual hierarchy)
		local sellAllButton = Instance.new("TextButton")
		sellAllButton.Name = "SellAllButton"
		sellAllButton.Size = UDim2.new(0.48, 0, 0.45, 0)
		sellAllButton.Position = UDim2.new(0.52, 0, 0.5, 0)
		sellAllButton.BackgroundColor3 = theme.amberGlow
		sellAllButton.Text = "📦 ALL" -- Different icon for distinction
		sellAllButton.TextColor3 = theme.forestDark
		sellAllButton.Font = Enum.Font.GothamBold
		sellAllButton.TextScaled = true
		sellAllButton.Parent = actionContainer
		addCorner(sellAllButton, 8)
		addButtonFeedback(sellAllButton)
		
		return sellCard
	end
	
	-- Store template creators for later insertion into scrolling frames
	-- Templates will be added directly to their respective scrolling frames
	-- and made invisible (they serve as clone sources)
	local templateCreators = {
		ShopItem = createShopItemTemplate,
		InventoryItem = createInventoryItemTemplate,
		EggItem = createEggItemTemplate,
		PetItem = createPetItemTemplate,
		SellItem = createSellItemTemplate,
	}
	
	-- Helper to add template to a scrolling frame (invisible, for cloning)
	local function addTemplateToScrollFrame(scrollFrame: ScrollingFrame, templateName: string)
		local creator = templateCreators[templateName]
		if creator then
			local template = creator()
			template.Name = templateName .. "Template"
			template.Visible = false -- Hidden - used for cloning only
			template.Parent = scrollFrame
		end
	end

	-- Keeps scrolling frames sized to their content so scrollbars always appear
	-- If minYScale is provided, the canvas will be at least minYScale * frameHeight,
	-- and will grow further only if content exceeds that baseline.
	-- If minYScale is nil, preserves legacy behavior.
	local function bindCanvasSize(scrollFrame: ScrollingFrame, layout: UIGridLayout | UIListLayout, padding: UIPadding?, minYScale: number?)
		local function updateCanvas()
			local contentSize = layout.AbsoluteContentSize
			local paddingX = 0
			local paddingY = 0
			if padding then
				paddingX = (padding.PaddingLeft.Offset or 0) + (padding.PaddingRight.Offset or 0)
				paddingY = (padding.PaddingTop.Offset or 0) + (padding.PaddingBottom.Offset or 0)
			end
			local currentCanvas = scrollFrame.CanvasSize
			if minYScale == nil then
				-- Legacy: always includes content + extra baseline scroll space.
				scrollFrame.CanvasSize = UDim2.new(currentCanvas.X.Scale, contentSize.X + paddingX, 2, contentSize.Y + paddingY)
				return
			end

			local baselinePixels = minYScale * scrollFrame.AbsoluteSize.Y
			local contentPixels = contentSize.Y + paddingY
			local extraPixels = math.max(0, contentPixels - baselinePixels)
			scrollFrame.CanvasSize = UDim2.new(currentCanvas.X.Scale, contentSize.X + paddingX, minYScale, extraPixels)
		end

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
		scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
		updateCanvas()
	end
	
	-- =============================================================================
	-- TOP CENTER NAVIGATION BUTTONS
	-- F-PATTERN: Important tabs at top for easy scanning
	-- SAFE ZONE: Top-center with margin
	-- =============================================================================
	local navFrame = Instance.new("Frame")
	navFrame.Name = "NavigationFrame"
	navFrame.Size = UDim2.new(0.42, 0, 0.08, 0)
	navFrame.Position = UDim2.new(0.5, 0, 0.08, 0)
	navFrame.AnchorPoint = Vector2.new(0.5, 0)
	navFrame.BackgroundTransparency = 1
	navFrame.Parent = hudGroup
	
	-- Size constraint for readability
	
	-- Use UIListLayout for responsive button layout
	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.Padding = UDim.new(0, 12)
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Parent = navFrame
	
	-- Seeds Button (PRIMARY ACTION - largest/brightest per visual hierarchy)
	local seedsButton = Instance.new("ImageButton")
	seedsButton.Name = "SeedsButton"
	seedsButton.Size = UDim2.new(0, 160, 0, 55)
	seedsButton.LayoutOrder = 1
	seedsButton.BackgroundTransparency = 1
	seedsButton.Parent = navFrame
	
	ensureMinTouchSize(seedsButton)
	addButtonFeedback(seedsButton)

	applyBoxImage(seedsButton, BOX_TEXT_RECT_3)

	local seedsLabel = Instance.new("TextLabel")
	seedsLabel.Name = "Label"
	seedsLabel.Size = UDim2.new(1, 0, 1, 0)
	seedsLabel.BackgroundTransparency = 1
	seedsLabel.Text = "🌱 SEEDS" -- Icon + text for accessibility
	seedsLabel.TextColor3 = theme.textLight
	seedsLabel.Font = Enum.Font.GothamBold
	seedsLabel.TextScaled = true
	seedsLabel.Parent = seedsButton
	
	local seedsLabelStroke = Instance.new("UIStroke")
	seedsLabelStroke.Color = theme.forestDark
	seedsLabelStroke.Thickness = 2
	seedsLabelStroke.Parent = seedsLabel
	
	-- Garden Button
	local gardenButton = Instance.new("ImageButton")
	gardenButton.Name = "GardenButton"
	gardenButton.Size = UDim2.new(0, 160, 0, 55)
	gardenButton.LayoutOrder = 2
	gardenButton.BackgroundTransparency = 1
	gardenButton.Parent = navFrame
	
	ensureMinTouchSize(gardenButton)
	addButtonFeedback(gardenButton)

	applyBoxImage(gardenButton, BOX_TEXT_RECT_3)

	local gardenLabel = Instance.new("TextLabel")
	gardenLabel.Name = "Label"
	gardenLabel.Size = UDim2.new(1, 0, 1, 0)
	gardenLabel.BackgroundTransparency = 1
	gardenLabel.Text = "🏡 GARDEN" -- Icon + text for accessibility
	gardenLabel.TextColor3 = theme.textLight
	gardenLabel.Font = Enum.Font.GothamBold
	gardenLabel.TextScaled = true
	gardenLabel.Parent = gardenButton
	
	local gardenLabelStroke = Instance.new("UIStroke")
	gardenLabelStroke.Color = theme.forestDark
	gardenLabelStroke.Thickness = 2
	gardenLabelStroke.Parent = gardenLabel
	
	-- Sell Button
	local sellButton = Instance.new("ImageButton")
	sellButton.Name = "SellButton"
	sellButton.Size = UDim2.new(0, 160, 0, 55)
	sellButton.LayoutOrder = 3
	sellButton.BackgroundTransparency = 1
	sellButton.Parent = navFrame
	
	ensureMinTouchSize(sellButton)
	addButtonFeedback(sellButton)

	applyBoxImage(sellButton, BOX_TEXT_RECT_3)

	local sellLabel = Instance.new("TextLabel")
	sellLabel.Name = "Label"
	sellLabel.Size = UDim2.new(1, 0, 1, 0)
	sellLabel.BackgroundTransparency = 1
	sellLabel.Text = "💰 SELL" -- Icon + text for accessibility
	sellLabel.TextColor3 = theme.textLight
	sellLabel.Font = Enum.Font.GothamBold
	sellLabel.TextScaled = true
	sellLabel.Parent = sellButton
	
	local sellLabelStroke = Instance.new("UIStroke")
	sellLabelStroke.Color = theme.forestDark
	sellLabelStroke.Thickness = 2
	sellLabelStroke.Parent = sellLabel
	
	-- =============================================================================
	-- CURRENCY FRAME (Bottom Left) - Golden Coin Purse
	-- CORNER ANCHOR: Bottom-Left (critical info, visible at a glance)
	-- SAFE ZONE: 5% margin from edges
	-- =============================================================================
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.Size = UDim2.new(0.11, 0, 0.07, 0)
	currencyFrame.Position = UDim2.new(0.02, 0, 0.9, 0)
	currencyFrame.AnchorPoint = Vector2.new(0, 1)
	currencyFrame.BackgroundTransparency = 1
	currencyFrame.Parent = hudGroup
	
	-- Minimum size constraint for readability

	applyBoxImage(currencyFrame, BOX_TEXT_RECT)
	
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
	-- SIDE PANEL (Top Right) - Trade / Weather / Pets
	-- =============================================================================
	local sidePanel = Instance.new("Frame")
	sidePanel.Name = "SidePanel"
	sidePanel.Size = UDim2.new(0.16, 0, 0.22, 0)
	sidePanel.Position = UDim2.new(0, 0, 0.5, 0)
	sidePanel.AnchorPoint = Vector2.new(0, 0.5)
	sidePanel.BackgroundTransparency = 1
	sidePanel.Parent = hudGroup

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.FillDirection = Enum.FillDirection.Vertical
	sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sideLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	sideLayout.Padding = UDim.new(0.1, 0)
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = sidePanel

	local function createSideButton(name, text, layoutOrder)
		local button = Instance.new("ImageButton")
		button.Name = name
		button.Size = UDim2.new(0.76, 0, 0, 38)
		button.BackgroundTransparency = 1
		button.LayoutOrder = layoutOrder
		button.Parent = sidePanel

		ensureMinTouchSize(button)
		addButtonFeedback(button)

		local scale = button:FindFirstChild("UIScale")
		if scale then
			scale:Destroy()
		end
		applyBoxImage(button, BOX_TEXT_RECT_2)

		local label = Instance.new("TextLabel")
		label.Name = name == "WeatherButton" and "WeatherLabel" or "Label"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = theme.textLight
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = button

		local stroke = Instance.new("UIStroke")
		stroke.Color = theme.forestDark
		stroke.Thickness = 2
		stroke.Parent = label

		return button
	end

	createSideButton("InventoryButton", "🎒 INVENTORY", 0)
	createSideButton("TradeButton", "🤝 TRADE", 1)

	local weatherFrame = Instance.new("Frame")
	weatherFrame.Name = "WeatherFrame"
	weatherFrame.Size = UDim2.new(0.76, 0, 0, 38)
	weatherFrame.BackgroundTransparency = 1
	weatherFrame.LayoutOrder = 2
	weatherFrame.Parent = sidePanel

	applyBoxImage(weatherFrame, BOX_TEXT_RECT_2)

	local weatherLabel = Instance.new("TextLabel")
	weatherLabel.Name = "WeatherLabel"
	weatherLabel.Size = UDim2.new(1, 0, 1, 0)
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

	createSideButton("PetsButton", "🐾 Pets", 3)
	
	-- =============================================================================
	-- HOTBAR (Bottom Center) - 6 Inventory Slots
	-- CORNER ANCHOR: Bottom-Center (standard for action bar)
	-- SAFE ZONE: 5% from bottom edge
	-- =============================================================================
	local HOTBAR_BASE_ZINDEX = 50
	local hotbarFrame = Instance.new("Frame")
	hotbarFrame.Name = "HotbarFrame"
	hotbarFrame.Size = UDim2.new(0.34, 0, 0.09, 0)
	-- Bottom padding via scale (roughly 5-10px depending on resolution)
	hotbarFrame.Position = UDim2.new(0.5, 0, 0.99, 0)
	hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
	hotbarFrame.BackgroundTransparency = 1
	hotbarFrame.ZIndex = HOTBAR_BASE_ZINDEX
	hotbarFrame.Parent = hudGroup

	-- Box art sits behind the slot strip, slightly larger for a framed look
	local hotbarBox = Instance.new("ImageLabel")
	hotbarBox.Name = "BoxArt"
	hotbarBox.Size = UDim2.new(0.848, 0, 2.545, 0)
	hotbarBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	hotbarBox.AnchorPoint = Vector2.new(0.5, 0.5)
	hotbarBox.BackgroundTransparency = 1
	hotbarBox.Image = BOX_TEXT_RECT_3
	hotbarBox.ZIndex = HOTBAR_BASE_ZINDEX
	hotbarBox.ScaleType = Enum.ScaleType.Stretch
	hotbarBox.Parent = hotbarFrame

	local hotbarSlots = Instance.new("Frame")
	hotbarSlots.Name = "Slots"
	hotbarSlots.Size = UDim2.new(1, 0, 1, 0)
	hotbarSlots.Position = UDim2.new(0.5, 0, 0.5, 0)
	hotbarSlots.AnchorPoint = Vector2.new(0.5, 0.5)
	hotbarSlots.BackgroundTransparency = 1
	hotbarSlots.ZIndex = HOTBAR_BASE_ZINDEX + 1
	hotbarSlots.Parent = hotbarFrame

	local hotbarLayout = Instance.new("UIListLayout")
	hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
	hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hotbarLayout.Padding = UDim.new(0, 8)
	hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hotbarLayout.Parent = hotbarSlots

	local hotbarPadding = Instance.new("UIPadding")
	hotbarPadding.PaddingLeft = UDim.new(0.01, 0)
	hotbarPadding.PaddingRight = UDim.new(0.01, 0)
	hotbarPadding.PaddingTop = UDim.new(0.1, 0)
	hotbarPadding.PaddingBottom = UDim.new(0.1, 0)
	hotbarPadding.Parent = hotbarSlots

	-- Create 6 hotbar slots
	for i = 1, 6 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(0, 56, 0, 56)
		slot.BackgroundColor3 = theme.forestDeep
		slot.BorderSizePixel = 0
		slot.LayoutOrder = i
		slot.ZIndex = HOTBAR_BASE_ZINDEX + 2
		slot.Parent = hotbarSlots
		
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
		slotNum.ZIndex = HOTBAR_BASE_ZINDEX + 3
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
		itemIcon.ZIndex = HOTBAR_BASE_ZINDEX + 3
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
		itemCount.ZIndex = HOTBAR_BASE_ZINDEX + 3
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
		slotButton.ZIndex = HOTBAR_BASE_ZINDEX + 4
		slotButton.Parent = slot

		local slotButtonLabel = Instance.new("TextLabel")
		slotButtonLabel.Name = "Label"
		slotButtonLabel.Size = UDim2.new(1, 0, 1, 0)
		slotButtonLabel.BackgroundTransparency = 1
		slotButtonLabel.Text = ""
		slotButtonLabel.ZIndex = HOTBAR_BASE_ZINDEX + 4
		slotButtonLabel.Parent = slotButton
	end
	
	-- =============================================================================
	-- INVENTORY WINDOW (Press B) - Full Backpack
	-- =============================================================================
	local inventoryWindow = Instance.new("Frame")
	inventoryWindow.Name = "InventoryWindow"
	-- Match PetsWindow centered modal layout
	inventoryWindow.Size = UDim2.new(0.7, 0, 0.75, 0)
	inventoryWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	inventoryWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	inventoryWindow.BackgroundTransparency = 1
	inventoryWindow.Visible = false
	inventoryWindow.Parent = windowGroup

	applyPetsWindowBackground(inventoryWindow)
	
	-- Title bar
	local invTitleBar = Instance.new("Frame")
	invTitleBar.Name = "TitleBar"
	invTitleBar.Size = UDim2.new(0.698, 0, 0.004, 60)
	invTitleBar.Position = UDim2.new(0.15, 0, -0.11, 0)
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

	addCorner(invCloseButton, 12)
	addStroke(invCloseButton, theme.goldLeaf, 2, 0.3)
	addGradient(invCloseButton, theme.woodBark, theme.mossGreen, 90)

	invCloseButton.Text = "✕ Close"
	invCloseButton.TextColor3 = theme.textLight
	invCloseButton.Font = Enum.Font.GothamBold
	invCloseButton.TextSize = 16
	
	-- Tab buttons
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(0.7, 0, 0, 50)
	tabContainer.Position = UDim2.new(0.15, 0, 0, 70)
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
		addCorner(tabButton, 12)
		addStroke(tabButton, theme.tealGem, 2, 0.3)
		addGradient(tabButton, theme.leafPanel, theme.mossGreen, 90)

		tabButton.Text = tabName
		tabButton.TextColor3 = theme.textMoss
		tabButton.Font = Enum.Font.GothamBold
		tabButton.TextSize = 18
	end
	
	-- Inventory grid container
	local invGridScroll = Instance.new("ScrollingFrame")
	invGridScroll.Name = "GridContainer"
	invGridScroll.Size = UDim2.new(0.7, 0, 1, -150)
	invGridScroll.Position = UDim2.new(0.15, 0, 0, 130)
	invGridScroll.BackgroundTransparency = 1
	invGridScroll.BorderSizePixel = 0
	invGridScroll.ScrollBarThickness = 10
	invGridScroll.ScrollBarImageColor3 = theme.goldLeaf
	invGridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	invGridScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	invGridScroll.Parent = inventoryWindow
	
	local invGridLayout = Instance.new("UIGridLayout")
	invGridLayout.CellSize = UDim2.new(0, 80, 0, 80) -- Compact size
	invGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	invGridLayout.SortOrder = Enum.SortOrder.Name
	invGridLayout.FillDirection = Enum.FillDirection.Horizontal
	invGridLayout.FillDirectionMaxCells = 0 -- Auto-fit columns
	invGridLayout.Parent = invGridScroll
	
	local invPadding = Instance.new("UIPadding")
	invPadding.PaddingLeft = UDim.new(0, 4)
	invPadding.PaddingRight = UDim.new(0, 4)
	invPadding.PaddingTop = UDim.new(0, 8)
	invPadding.PaddingBottom = UDim.new(0, 8)
	invPadding.Parent = invGridScroll
	
	-- Add template for cloning (invisible)
	addTemplateToScrollFrame(invGridScroll, "InventoryItem")
	
	-- ============================================================================= (Modal) - 3 Column Fullscreen: Store | NPC | Inventory
	-- =============================================================================
	local shopWindow = Instance.new("Frame")
	shopWindow.Name = "ShopWindow"
	-- Match PetsWindow centered modal layout
	shopWindow.Size = UDim2.new(0.7, 0, 0.75, 0)
	shopWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shopWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	shopWindow.BackgroundTransparency = 1
	shopWindow.Visible = false
	shopWindow.ZIndex = 10
	shopWindow.Parent = screenGui

	applyPetsWindowBackground(shopWindow)

	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingTop = UDim.new(0, 0)
	shopPadding.PaddingBottom = UDim.new(0, 0)
	shopPadding.Parent = shopWindow
	
	-- Single centered window: keep store list, remove right inventory panel
	local shopLeftPanel = Instance.new("Frame")
	shopLeftPanel.Name = "LeftPanel"
	shopLeftPanel.Size = UDim2.new(0.96, 0, 0.9, 0)
	shopLeftPanel.Position = UDim2.new(0.02, 0, 0.08, 0)
	shopLeftPanel.BackgroundTransparency = 1
	shopLeftPanel.BorderSizePixel = 0
	shopLeftPanel.ZIndex = 11
	shopLeftPanel.Parent = shopWindow

	-- No per-panel box art; window uses PetsWindow-style background.
	
	local shopLeftTitle = Instance.new("TextLabel")
	shopLeftTitle.Name = "PanelTitle"
	shopLeftTitle.Size = UDim2.new(0.9, 0, 0.05, 0)
	shopLeftTitle.Position = UDim2.new(0.05, 0, 0.015, 0)
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
	shopScroll.BackgroundColor3 = theme.forestDark
	shopScroll.BackgroundTransparency = 0.3
	shopScroll.BorderSizePixel = 0
	shopScroll.Active = true
	shopScroll.ScrollingEnabled = true
	shopScroll.ScrollBarThickness = 10
	shopScroll.ScrollBarImageColor3 = theme.tealGem
	shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	shopScroll.ZIndex = 12
	shopScroll.Parent = shopLeftPanel
	
	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 10)
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Parent = shopScroll
	
	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingTop = UDim.new(0, 8)
	shopPadding.PaddingBottom = UDim.new(0, 8)
	shopPadding.PaddingLeft = UDim.new(0, 4)
	shopPadding.PaddingRight = UDim.new(0, 4)
	shopPadding.Parent = shopScroll
	
	-- Add template for cloning (invisible)
	addTemplateToScrollFrame(shopScroll, "ShopItem")
	bindCanvasSize(shopScroll, shopLayout, shopPadding, 5)
	
	-- Close button (top-right corner)
	local shopCloseButton = Instance.new("TextButton")
	shopCloseButton.Name = "CloseButton"
	shopCloseButton.Size = UDim2.new(0, 120, 0, 40)
	shopCloseButton.Position = UDim2.new(0.98, 0, 0.02, 0)
	shopCloseButton.AnchorPoint = Vector2.new(1, 0)
	shopCloseButton.BackgroundColor3 = Color3.fromRGB(120, 50, 50) -- Muted red for close
	shopCloseButton.ZIndex = 13
	shopCloseButton.Parent = shopWindow

	-- Simple themed style, no custom image for close button
	addCorner(shopCloseButton, 12)
	addStroke(shopCloseButton, theme.goldLeaf, 2, 0.3)
	addButtonFeedback(shopCloseButton)
	ensureMinTouchSize(shopCloseButton)

	shopCloseButton.Text = "✖ CLOSE"
	shopCloseButton.TextColor3 = theme.textLight
	shopCloseButton.Font = Enum.Font.GothamBold
	shopCloseButton.TextScaled = true
	
	local shopCloseStroke = Instance.new("UIStroke")
	shopCloseStroke.Color = theme.forestDark
	shopCloseStroke.Thickness = 1
	shopCloseStroke.Parent = shopCloseButton
	
	-- =============================================================================
	-- SELL WINDOW (Modal) - 3 Column Fullscreen: Sellable | NPC | Fruits Owned
	-- =============================================================================
	local sellWindow = Instance.new("Frame")
	sellWindow.Name = "SellWindow"
	-- Match PetsWindow centered modal layout
	sellWindow.Size = UDim2.new(0.7, 0, 0.75, 0)
	sellWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	sellWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	sellWindow.BackgroundTransparency = 1
	sellWindow.Visible = false
	sellWindow.ZIndex = 10
	sellWindow.Parent = screenGui

	applyPetsWindowBackground(sellWindow)

	local sellPadding = Instance.new("UIPadding")
	sellPadding.PaddingTop = UDim.new(0, 0)
	sellPadding.PaddingBottom = UDim.new(0, 0)
	sellPadding.Parent = sellWindow
	
	-- Single centered window: keep sell list, remove right inventory panel
	local sellLeftPanel = Instance.new("Frame")
	sellLeftPanel.Name = "LeftPanel"
	sellLeftPanel.Size = UDim2.new(0.96, 0, 0.9, 0)
	sellLeftPanel.Position = UDim2.new(0.02, 0, 0.08, 0)
	sellLeftPanel.BackgroundTransparency = 1
	sellLeftPanel.BorderSizePixel = 0
	sellLeftPanel.ZIndex = 11
	sellLeftPanel.Parent = sellWindow

	-- No per-panel box art; window uses PetsWindow-style background.
	
	local sellLeftTitle = Instance.new("TextLabel")
	sellLeftTitle.Name = "PanelTitle"
	sellLeftTitle.Size = UDim2.new(0.9, 0, 0.05, 0)
	sellLeftTitle.Position = UDim2.new(0.05, 0, 0.015, 0)
	sellLeftTitle.BackgroundTransparency = 1
	sellLeftTitle.Text = "💰 Sell Your Harvest"
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
	sellScroll.BackgroundColor3 = theme.forestDark
	sellScroll.BackgroundTransparency = 0.3
	sellScroll.BorderSizePixel = 0
	sellScroll.Active = true
	sellScroll.ScrollingEnabled = true
	sellScroll.ScrollBarThickness = 10
	sellScroll.ScrollBarImageColor3 = theme.goldLeaf
	sellScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sellScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	sellScroll.ZIndex = 12
	sellScroll.Parent = sellLeftPanel
	
	local sellLayout = Instance.new("UIListLayout")
	sellLayout.Padding = UDim.new(0, 10)
	sellLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sellLayout.Parent = sellScroll
	
	local sellPadding = Instance.new("UIPadding")
	sellPadding.PaddingTop = UDim.new(0, 8)
	sellPadding.PaddingBottom = UDim.new(0, 8)
	sellPadding.PaddingLeft = UDim.new(0, 4)
	sellPadding.PaddingRight = UDim.new(0, 4)
	sellPadding.Parent = sellScroll
	
	-- Add template for cloning (invisible)
	addTemplateToScrollFrame(sellScroll, "SellItem")
	bindCanvasSize(sellScroll, sellLayout, sellPadding)
	
	-- Close button (top-right corner)
	local sellCloseButton = Instance.new("TextButton")
	sellCloseButton.Name = "CloseButton"
	sellCloseButton.Size = UDim2.new(0, 120, 0, 40)
	sellCloseButton.Position = UDim2.new(0.98, 0, 0.02, 0)
	sellCloseButton.AnchorPoint = Vector2.new(1, 0)
	sellCloseButton.BackgroundColor3 = Color3.fromRGB(120, 50, 50) -- Muted red
	sellCloseButton.ZIndex = 13
	sellCloseButton.Parent = sellWindow

	-- Simple themed style, no custom image for close button
	addCorner(sellCloseButton, 12)
	addStroke(sellCloseButton, theme.goldLeaf, 2, 0.3)
	addButtonFeedback(sellCloseButton)
	ensureMinTouchSize(sellCloseButton)

	sellCloseButton.Text = "✖ CLOSE"
	sellCloseButton.TextColor3 = theme.textLight
	sellCloseButton.Font = Enum.Font.GothamBold
	sellCloseButton.TextScaled = true
	
	local sellCloseStroke = Instance.new("UIStroke")
	sellCloseStroke.Color = theme.forestDark
	sellCloseStroke.Thickness = 1
	sellCloseStroke.Parent = sellCloseButton
	
	-- =============================================================================
	-- PETS WINDOW (Modal) - 2 Column Layout: Available Pets | Equipped Pet
	-- =============================================================================
	local petsWindow = Instance.new("Frame")
	petsWindow.Name = "PetsWindow"
	petsWindow.Size = UDim2.new(0.7, 0, 0.75, 0)
	petsWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	petsWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	petsWindow.BackgroundTransparency = 1
	petsWindow.Visible = false
	petsWindow.ZIndex = 10
	petsWindow.Parent = screenGui

	applyPetsWindowBackground(petsWindow)
	
	-- Pets title bar - simple themed style, no custom image
	local petsTitleBar = Instance.new("Frame")
	petsTitleBar.Name = "TitleBar"
	petsTitleBar.Size = UDim2.new(1, 0, 0.08, 0)
	petsTitleBar.Position = UDim2.new(0, 0, 0, 0)
	petsTitleBar.BackgroundColor3 = theme.woodPanel
	petsTitleBar.BorderSizePixel = 0
	petsTitleBar.ZIndex = 11
	petsTitleBar.Parent = petsWindow

	addCorner(petsTitleBar, 20)
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
	
	-- Close button - simple themed style, no custom image
	local petsCloseButton = Instance.new("TextButton")
	petsCloseButton.Name = "CloseButton"
	petsCloseButton.Size = UDim2.new(0.06, 0, 0.7, 0)
	petsCloseButton.Position = UDim2.new(0.93, 0, 0.15, 0)
	petsCloseButton.BackgroundColor3 = Color3.fromRGB(120, 50, 50) -- Muted red for close
	petsCloseButton.ZIndex = 12
	petsCloseButton.Parent = petsTitleBar

	addCorner(petsCloseButton, 12)
	addStroke(petsCloseButton, theme.goldLeaf, 2, 0.2)
	addButtonFeedback(petsCloseButton)

	petsCloseButton.Text = "✖"
	petsCloseButton.TextColor3 = theme.textLight
	petsCloseButton.Font = Enum.Font.GothamBold
	petsCloseButton.TextScaled = true
	
	-- LEFT PANEL - Available Pets (no box art, scroll has background)
	local petsLeftPanel = Instance.new("Frame")
	petsLeftPanel.Name = "LeftPanel"
	petsLeftPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	petsLeftPanel.Position = UDim2.new(0.01, 0, 0.1, 0)
	petsLeftPanel.BackgroundTransparency = 1
	petsLeftPanel.BorderSizePixel = 0
	petsLeftPanel.ZIndex = 11
	petsLeftPanel.Parent = petsWindow
	
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
	petsScroll.BackgroundColor3 = theme.forestDark
	petsScroll.BackgroundTransparency = 0.3 -- 0.7 opacity
	petsScroll.BorderSizePixel = 0
	petsScroll.ScrollBarThickness = 8
	petsScroll.ScrollBarImageColor3 = theme.tealGem
	petsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	petsScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	petsScroll.ZIndex = 12
	petsScroll.Parent = petsLeftPanel
	
	addCorner(petsScroll, 12)
	
	local petsLayout = Instance.new("UIListLayout")
	petsLayout.Padding = UDim.new(0, 8)
	petsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	petsLayout.Parent = petsScroll
	
	local petsPadding = Instance.new("UIPadding")
	petsPadding.PaddingTop = UDim.new(0, 5)
	petsPadding.PaddingBottom = UDim.new(0, 5)
	petsPadding.PaddingLeft = UDim.new(0, 3)
	petsPadding.PaddingRight = UDim.new(0, 3)
	petsPadding.Parent = petsScroll
	
	-- Add template for cloning (invisible)
	addTemplateToScrollFrame(petsScroll, "PetItem")
	bindCanvasSize(petsScroll, petsLayout, petsPadding)
	
	-- RIGHT PANEL - Equipped Pet Display
	local petsRightPanel = Instance.new("Frame")
	petsRightPanel.Name = "RightPanel"
	petsRightPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	petsRightPanel.Position = UDim2.new(0.51, 0, 0.1, 0)
	petsRightPanel.BackgroundTransparency = 1
	petsRightPanel.BorderSizePixel = 0
	petsRightPanel.ZIndex = 11
	petsRightPanel.Parent = petsWindow
	-- No box art - using transparent panel
	
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
	
	-- Equipped pet display area (with 0.7 opacity background)
	local equippedPetDisplay = Instance.new("Frame")
	equippedPetDisplay.Name = "EquippedPetDisplay"
	equippedPetDisplay.Size = UDim2.new(0.9, 0, 0.9, 0)
	equippedPetDisplay.Position = UDim2.new(0.05, 0, 0.09, 0)
	equippedPetDisplay.BackgroundColor3 = theme.forestDark
	equippedPetDisplay.BackgroundTransparency = 0.3 -- 0.7 opacity
	equippedPetDisplay.ZIndex = 12
	equippedPetDisplay.Parent = petsRightPanel
	
	addCorner(equippedPetDisplay, 12)
	
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
	
	-- =============================================================================
	-- PET SHOP WINDOW (Separate from Inventory) - Egg Shop + Player Pets Preview
	-- =============================================================================
	local petShopWindow = Instance.new("Frame")
	petShopWindow.Name = "PetShopWindow"
	-- Match PetsWindow centered modal layout
	petShopWindow.Size = UDim2.new(0.7, 0, 0.75, 0)
	petShopWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	petShopWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	petShopWindow.BackgroundTransparency = 1
	petShopWindow.Visible = false
	petShopWindow.ZIndex = 10
	petShopWindow.Parent = screenGui

	applyPetsWindowBackground(petShopWindow)

	local petShopPadding = Instance.new("UIPadding")
	petShopPadding.PaddingTop = UDim.new(0, 0)
	petShopPadding.PaddingBottom = UDim.new(0, 0)
	petShopPadding.Parent = petShopWindow
	
	-- 2-panel centered layout (like PetsWindow)
	local shopLeftPanel = Instance.new("Frame")
	shopLeftPanel.Name = "LeftPanel"
	shopLeftPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	shopLeftPanel.Position = UDim2.new(0.01, 0, 0.1, 0)
	shopLeftPanel.BackgroundTransparency = 1
	shopLeftPanel.BorderSizePixel = 0
	shopLeftPanel.ZIndex = 11
	shopLeftPanel.Parent = petShopWindow

	-- No per-panel box art; window uses PetsWindow-style background.
	
	local shopLeftTitle = Instance.new("TextLabel")
	shopLeftTitle.Name = "PanelTitle"
	shopLeftTitle.Size = UDim2.new(0.9, 0, 0.05, 0)
	shopLeftTitle.Position = UDim2.new(0.05, 0, 0.015, 0)
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
	eggShopScroll.BackgroundColor3 = theme.forestDark
	eggShopScroll.BackgroundTransparency = 0.3
	eggShopScroll.BorderSizePixel = 0
	eggShopScroll.Active = true
	eggShopScroll.ScrollingEnabled = true
	eggShopScroll.ScrollBarThickness = 10
	eggShopScroll.ScrollBarImageColor3 = theme.tealGem
	eggShopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	eggShopScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	eggShopScroll.ZIndex = 12
	eggShopScroll.Parent = shopLeftPanel
	
	local eggShopLayout = Instance.new("UIListLayout")
	eggShopLayout.Padding = UDim.new(0, 10)
	eggShopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	eggShopLayout.Parent = eggShopScroll
	
	local eggShopPadding = Instance.new("UIPadding")
	eggShopPadding.PaddingTop = UDim.new(0, 8)
	eggShopPadding.PaddingBottom = UDim.new(0, 8)
	eggShopPadding.PaddingLeft = UDim.new(0, 4)
	eggShopPadding.PaddingRight = UDim.new(0, 4)
	eggShopPadding.Parent = eggShopScroll
	
	-- Add template for cloning (invisible)
	addTemplateToScrollFrame(eggShopScroll, "EggItem")
	bindCanvasSize(eggShopScroll, eggShopLayout, eggShopPadding)
	
	-- Close button (top-right corner)
	local petShopCloseButton = Instance.new("TextButton")
	petShopCloseButton.Name = "CloseButton"
	petShopCloseButton.Size = UDim2.new(0, 120, 0, 40)
	petShopCloseButton.Position = UDim2.new(0.98, 0, 0.02, 0)
	petShopCloseButton.AnchorPoint = Vector2.new(1, 0)
	petShopCloseButton.BackgroundColor3 = Color3.fromRGB(120, 50, 50) -- Muted red
	petShopCloseButton.ZIndex = 13
	petShopCloseButton.Parent = petShopWindow

	-- Simple themed style, no custom image for close button
	addCorner(petShopCloseButton, 12)
	addStroke(petShopCloseButton, theme.goldLeaf, 2, 0.3)
	addButtonFeedback(petShopCloseButton)
	ensureMinTouchSize(petShopCloseButton)

	petShopCloseButton.Text = "✖ CLOSE"
	petShopCloseButton.TextColor3 = theme.textLight
	petShopCloseButton.Font = Enum.Font.GothamBold
	petShopCloseButton.TextScaled = true
	
	local petShopCloseStroke = Instance.new("UIStroke")
	petShopCloseStroke.Color = theme.forestDark
	petShopCloseStroke.Thickness = 1
	petShopCloseStroke.Parent = petShopCloseButton
	
	-- RIGHT PANEL - Player's Pets Preview
	local shopRightPanel = Instance.new("Frame")
	shopRightPanel.Name = "RightPanel"
	shopRightPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	shopRightPanel.Position = UDim2.new(0.51, 0, 0.1, 0)
	shopRightPanel.BackgroundTransparency = 1
	shopRightPanel.BorderSizePixel = 0
	shopRightPanel.ZIndex = 11
	shopRightPanel.Parent = petShopWindow

	-- No per-panel box art; window uses PetsWindow-style background.
	
	local shopRightTitle = Instance.new("TextLabel")
	shopRightTitle.Name = "PanelTitle"
	shopRightTitle.Size = UDim2.new(0.9, 0, 0.05, 0)
	shopRightTitle.Position = UDim2.new(0.05, 0, 0.015, 0)
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
	petPreviewScroll.BackgroundColor3 = theme.forestDark
	petPreviewScroll.BackgroundTransparency = 0.3
	petPreviewScroll.BorderSizePixel = 0
	petPreviewScroll.Active = true
	petPreviewScroll.ScrollingEnabled = true
	petPreviewScroll.ScrollBarThickness = 8
	petPreviewScroll.ScrollBarImageColor3 = theme.tealGem
	petPreviewScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	petPreviewScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	petPreviewScroll.ZIndex = 12
	petPreviewScroll.Parent = shopRightPanel
	
	-- Use Grid Layout for pets - Compact size
	local petPreviewGrid = Instance.new("UIGridLayout")
	petPreviewGrid.Name = "GridLayout"
	petPreviewGrid.CellSize = UDim2.new(0, 90, 0, 110) -- Compact size for pets with stats
	petPreviewGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	petPreviewGrid.SortOrder = Enum.SortOrder.Name
	petPreviewGrid.FillDirection = Enum.FillDirection.Horizontal
	petPreviewGrid.FillDirectionMaxCells = 0 -- Auto-fit
	petPreviewGrid.Parent = petPreviewScroll
	
	local petPreviewPadding = Instance.new("UIPadding")
	petPreviewPadding.PaddingTop = UDim.new(0, 8)
	petPreviewPadding.PaddingBottom = UDim.new(0, 8)
	petPreviewPadding.PaddingLeft = UDim.new(0, 4)
	petPreviewPadding.PaddingRight = UDim.new(0, 4)
	petPreviewPadding.Parent = petPreviewScroll

	bindCanvasSize(petPreviewScroll, petPreviewGrid, petPreviewPadding)
	
	-- Build trading UI in a separate scope to reduce local count
	UIBuilders.CreateTradingUI(screenGui, shopWindow, theme, addCorner, addStroke, addButtonFeedback, ensureMinTouchSize, applyPetsWindowBackground, applyFrameImage, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE, BOX_TEXT_RECT_2)

	-- Build gear shop UI in a separate scope
	UIBuilders.CreateGearShopUI(screenGui, theme, addCorner, addStroke, addButtonFeedback, ensureMinTouchSize, applyPetsWindowBackground, addTemplateToScrollFrame)

	-- Final grouping pass to keep root tidy
	local hudNames = {
		"CurrencyFrame",
		"HotbarFrame",
		"NavigationFrame",
		"NotificationContainer",
		"SidePanel",
	}

	local windowNames = {
		"InventoryWindow",
		"ShopWindow",
		"SellWindow",
		"PetShopWindow",
		"GearShopWindow",
		"PetsWindow",
		"TradingWindow",
		"TradeRequestPopup",
		"PlayerSelectWindow",
	}

	local overlayNames = {
		"LoadingScreen",
	}

	local function moveByName(names: {string}, target: Instance?)
		if not target then
			return
		end
		for _, name in names do
			local child = screenGui:FindFirstChild(name)
			if child then
				child.Parent = target
			end
		end
	end

	moveByName(hudNames, hudGroup)
	moveByName(windowNames, windowGroup)
	moveByName(overlayNames, overlayGroup)
	
	warn("[UISetup] UI created successfully with Templates folder and UI/UX best practices")
end

-- =============================================================================
-- TRADING UI BUILDER (Separate function to avoid local variable limit)
-- =============================================================================
function UIBuilders.CreateTradingUI(screenGui, shopWindow, theme, addCorner, addStroke, addButtonFeedback, ensureMinTouchSize, applyPetsWindowBackground, applyFrameImage, FRAME_IMAGE_PANEL_SQUARE, FRAME_SLICE_SQUARE, BOX_TEXT_RECT_2)
	-- TRADING WINDOW - Player to Player Trading
	local tradingWindow = Instance.new("Frame")
	tradingWindow.Name = "TradingWindow"
	tradingWindow.Size = UDim2.new(0.7, 0, 0.75, 0)
	tradingWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	tradingWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	tradingWindow.BackgroundTransparency = 1
	tradingWindow.Visible = false
	tradingWindow.ZIndex = 10
	tradingWindow.Parent = screenGui

	applyPetsWindowBackground(tradingWindow)
	
	-- Main trade panel (centered)
	local tradePanel = Instance.new("Frame")
	tradePanel.Name = "TradePanel"
	tradePanel.Size = UDim2.new(0.96, 0, 0.9, 0)
	tradePanel.Position = UDim2.new(0.02, 0, 0.08, 0)
	tradePanel.AnchorPoint = Vector2.new(0, 0)
	tradePanel.BackgroundTransparency = 1
	tradePanel.ZIndex = 11
	tradePanel.Parent = tradingWindow
	
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
	tradeTitle.ZIndex = 12
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
	partnerLabel.ZIndex = 12
	partnerLabel.Parent = tradePanel
	
	-- Your offer panel (left side)
	local yourOfferPanel = Instance.new("Frame")
	yourOfferPanel.Name = "YourOfferPanel"
	yourOfferPanel.Size = UDim2.new(0.45, 0, 0.6, 0)
	yourOfferPanel.Position = UDim2.new(0.025, 0, 0.14, 0)
	yourOfferPanel.BackgroundColor3 = theme.forestDeep
	yourOfferPanel.BorderSizePixel = 0
	yourOfferPanel.ZIndex = 12
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
	yourOfferTitle.ZIndex = 13
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
	yourOfferScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	yourOfferScroll.ZIndex = 13
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
	yourCoinsFrame.ZIndex = 13
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
	yourCoinsLabel.ZIndex = 14
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
	yourCoinsInput.ZIndex = 14
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
	yourConfirmedLabel.ZIndex = 13
	yourConfirmedLabel.Parent = yourOfferPanel
	
	-- Their offer panel (right side)
	local theirOfferPanel = Instance.new("Frame")
	theirOfferPanel.Name = "TheirOfferPanel"
	theirOfferPanel.Size = UDim2.new(0.45, 0, 0.6, 0)
	theirOfferPanel.Position = UDim2.new(0.525, 0, 0.14, 0)
	theirOfferPanel.BackgroundColor3 = theme.forestDeep
	theirOfferPanel.BorderSizePixel = 0
	theirOfferPanel.ZIndex = 12
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
	theirOfferTitle.ZIndex = 13
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
	theirOfferScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	theirOfferScroll.ZIndex = 13
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
	theirCoinsLabel.ZIndex = 13
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
	theirConfirmedLabel.ZIndex = 13
	theirConfirmedLabel.Parent = theirOfferPanel
	
	-- Your inventory panel (bottom left)
	local yourInventoryPanel = Instance.new("Frame")
	yourInventoryPanel.Name = "YourInventoryPanel"
	yourInventoryPanel.Size = UDim2.new(0.45, 0, 0.2, 0)
	yourInventoryPanel.Position = UDim2.new(0.025, 0, 0.76, 0)
	yourInventoryPanel.BackgroundColor3 = theme.forestDark
	yourInventoryPanel.BorderSizePixel = 0
	yourInventoryPanel.ZIndex = 12
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
	yourInvTitle.ZIndex = 13
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
	yourInvScroll.ZIndex = 13
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
	actionButtonsPanel.ZIndex = 12
	actionButtonsPanel.Parent = tradePanel
	
	-- Confirm button (PRIMARY ACTION - largest/brightest)
	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "ConfirmButton"
	confirmButton.Size = UDim2.new(0.45, 0, 0.45, 0)
	confirmButton.Position = UDim2.new(0.025, 0, 0.25, 0)
	confirmButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100) -- Bright green for primary
	confirmButton.Text = "✅ CONFIRM"
	confirmButton.TextColor3 = theme.textLight
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.TextScaled = true
	confirmButton.ZIndex = 13
	confirmButton.Parent = actionButtonsPanel
	
	local confirmButtonCorner = Instance.new("UICorner")
	confirmButtonCorner.CornerRadius = UDim.new(0, 10)
	confirmButtonCorner.Parent = confirmButton
	
	local confirmStroke = Instance.new("UIStroke")
	confirmStroke.Color = Color3.fromRGB(120, 220, 140)
	confirmStroke.Thickness = 2
	confirmStroke.Parent = confirmButton
	
	addButtonFeedback(confirmButton)
	ensureMinTouchSize(confirmButton)
	
	-- Cancel button (DESTRUCTIVE - isolated, muted color)
	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0.45, 0, 0.45, 0)
	cancelButton.Position = UDim2.new(0.525, 0, 0.25, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60) -- Muted red for destructive
	cancelButton.Text = "❌ CANCEL"
	cancelButton.TextColor3 = theme.textLight
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.TextScaled = true
	cancelButton.ZIndex = 13
	cancelButton.Parent = actionButtonsPanel
	
	local cancelButtonCorner = Instance.new("UICorner")
	cancelButtonCorner.CornerRadius = UDim.new(0, 10)
	cancelButtonCorner.Parent = cancelButton
	
	addButtonFeedback(cancelButton)
	ensureMinTouchSize(cancelButton)
	
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
	tradeStatusLabel.ZIndex = 13
	tradeStatusLabel.Parent = actionButtonsPanel
	
	-- =============================================================================
	-- TRADE REQUEST POPUP
	-- =============================================================================
	local tradeRequestPopup = Instance.new("Frame")
	tradeRequestPopup.Name = "TradeRequestPopup"
	tradeRequestPopup.Size = UDim2.new(0.35, 0, 0.18, 0)
	tradeRequestPopup.Position = UDim2.new(0.5, 0, 0.35, 0)
	tradeRequestPopup.AnchorPoint = Vector2.new(0.5, 0.5)
	tradeRequestPopup.BackgroundTransparency = 1
	tradeRequestPopup.BorderSizePixel = 0
	tradeRequestPopup.Visible = false
	tradeRequestPopup.ZIndex = 10
	tradeRequestPopup.Parent = screenGui

	applyPetsWindowBackground(tradeRequestPopup)
	
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
	tradePopupTitle.ZIndex = 12
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
	tradePopupMessage.ZIndex = 12
	tradePopupMessage.Parent = tradeRequestPopup
	
	-- Accept button (PRIMARY ACTION)
	local acceptTradeButton = Instance.new("TextButton")
	acceptTradeButton.Name = "AcceptButton"
	acceptTradeButton.Size = UDim2.new(0.4, 0, 0.28, 0)
	acceptTradeButton.Position = UDim2.new(0.075, 0, 0.62, 0)
	acceptTradeButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100) -- Bright green
	acceptTradeButton.Text = "✅ Accept"
	acceptTradeButton.TextColor3 = theme.textLight
	acceptTradeButton.Font = Enum.Font.GothamBold
	acceptTradeButton.TextScaled = true
	acceptTradeButton.ZIndex = 12
	acceptTradeButton.Parent = tradeRequestPopup
	
	local acceptTradeCorner = Instance.new("UICorner")
	acceptTradeCorner.CornerRadius = UDim.new(0, 8)
	acceptTradeCorner.Parent = acceptTradeButton
	
	addButtonFeedback(acceptTradeButton)
	ensureMinTouchSize(acceptTradeButton)
	
	-- Decline button (DESTRUCTIVE - isolated)
	local declineTradeButton = Instance.new("TextButton")
	declineTradeButton.Name = "DeclineButton"
	declineTradeButton.Size = UDim2.new(0.4, 0, 0.28, 0)
	declineTradeButton.Position = UDim2.new(0.525, 0, 0.62, 0)
	declineTradeButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60) -- Muted red
	declineTradeButton.Text = "❌ Decline"
	declineTradeButton.TextColor3 = theme.textLight
	declineTradeButton.Font = Enum.Font.GothamBold
	declineTradeButton.TextScaled = true
	declineTradeButton.ZIndex = 12
	declineTradeButton.Parent = tradeRequestPopup
	
	local declineTradeCorner = Instance.new("UICorner")
	declineTradeCorner.CornerRadius = UDim.new(0, 8)
	declineTradeCorner.Parent = declineTradeButton
	
	addButtonFeedback(declineTradeButton)
	ensureMinTouchSize(declineTradeButton)
	
	-- Hidden field to store requester ID
	do
		local requesterIdValue = Instance.new("StringValue")
		requesterIdValue.Name = "RequesterId"
		requesterIdValue.Value = ""
		requesterIdValue.Parent = tradeRequestPopup
	end
	
	-- =============================================================================
	-- PLAYER SELECT WINDOW (for trade target selection)
	-- =============================================================================
	do
		local psWindow = Instance.new("Frame")
		psWindow.Name = "PlayerSelectWindow"
		psWindow.Size = UDim2.new(0.3, 0, 0.5, 0)
		psWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
		psWindow.AnchorPoint = Vector2.new(0.5, 0.5)
		psWindow.BackgroundTransparency = 1
		psWindow.BorderSizePixel = 0
		psWindow.Visible = false
		psWindow.ZIndex = 10
		psWindow.Parent = screenGui

		applyPetsWindowBackground(psWindow)
		
		addCorner(psWindow, 16)
		addStroke(psWindow, theme.tealGem, 3, 0)
		
		local psTitle = Instance.new("TextLabel")
		psTitle.Name = "Title"
		psTitle.Size = UDim2.new(1, 0, 0.1, 0)
		psTitle.Position = UDim2.new(0, 0, 0, 0)
		psTitle.BackgroundTransparency = 1
		psTitle.Text = "👥 Select Player to Trade"
		psTitle.TextColor3 = theme.goldLeaf
		psTitle.Font = Enum.Font.GothamBold
		psTitle.TextScaled = true
		psTitle.ZIndex = 12
		psTitle.Parent = psWindow
		
		local psScroll = Instance.new("ScrollingFrame")
		psScroll.Name = "PlayerList"
		psScroll.Size = UDim2.new(0.9, 0, 0.75, 0)
		psScroll.Position = UDim2.new(0.05, 0, 0.12, 0)
		psScroll.BackgroundTransparency = 1
		psScroll.BorderSizePixel = 0
		psScroll.ScrollBarThickness = 6
		psScroll.ScrollBarImageColor3 = theme.tealGem
		psScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		psScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
		psScroll.ZIndex = 12
		psScroll.Parent = psWindow
		
		local psLayout = Instance.new("UIListLayout")
		psLayout.Padding = UDim.new(0, 8)
		psLayout.SortOrder = Enum.SortOrder.Name
		psLayout.Parent = psScroll
		
		local psClose = Instance.new("TextButton")
		psClose.Name = "CloseButton"
		psClose.Size = UDim2.new(0.9, 0, 0.08, 0)
		psClose.Position = UDim2.new(0.05, 0, 0.9, 0)
		psClose.BackgroundColor3 = theme.forestDeep
		psClose.Text = "❌ Cancel"
		psClose.TextColor3 = theme.textLight
		psClose.Font = Enum.Font.GothamBold
		psClose.TextScaled = true
		psClose.ZIndex = 12
		psClose.Parent = psWindow
		
		addCorner(psClose, 8)
		addButtonFeedback(psClose)
	end
	
	-- =============================================================================
	-- SHOP REFRESH TIMER (add to shop window)
	-- =============================================================================
	do
		local refreshTimer = Instance.new("TextLabel")
		refreshTimer.Name = "RefreshTimer"
		refreshTimer.Size = UDim2.new(0.3, 0, 0.05, 0)
		refreshTimer.Position = UDim2.new(0.35, 0, 0.02, 0)
		refreshTimer.BackgroundTransparency = 1
		refreshTimer.Text = "🔄 Refreshes in: 00:00:00"
		refreshTimer.TextColor3 = theme.tealGem
		refreshTimer.Font = Enum.Font.Gotham
		refreshTimer.TextScaled = true
		refreshTimer.ZIndex = 12
		refreshTimer.Parent = shopWindow
	end

	-- =============================================================================
	-- NOTIFICATION CONTAINER - Floating Messages
	-- SAFE ZONE: Centered, away from edges
	-- =============================================================================
	do
		local notifContainer = Instance.new("Frame")
		notifContainer.Name = "NotificationContainer"
		notifContainer.Size = UDim2.new(0.32, 0, 0.45, 0)
		notifContainer.Position = UDim2.new(0.5, 0, 0.28, 0)
		notifContainer.AnchorPoint = Vector2.new(0.5, 0.5)
		notifContainer.BackgroundTransparency = 1
		notifContainer.ZIndex = 50
		notifContainer.Parent = screenGui

		local notifListLayout = Instance.new("UIListLayout")
		notifListLayout.Padding = UDim.new(0, 12)
		notifListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		notifListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		notifListLayout.Parent = notifContainer
	end
end -- End of UIBuilders.CreateTradingUI

-- =============================================================================
-- TEMPLATE UTILITIES (For client code to clone and use templates)
-- =============================================================================

-- Get a template by name from the UI
function UISetup.GetTemplate(templateName: string): Frame?
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local feyGardenUI = playerGui:FindFirstChild("FeyGardenUI")
	if not feyGardenUI then
		warn("[UISetup] FeyGardenUI not found in PlayerGui")
		return nil
	end
	
	local templates = feyGardenUI:FindFirstChild("Templates")
	if not templates then
		warn("[UISetup] Templates folder not found")
		return nil
	end
	
	local template = templates:FindFirstChild(templateName)
	if not template then
		warn("[UISetup] Template not found: " .. templateName)
		return nil
	end
	
	return template:Clone()
end

-- Template names for reference
UISetup.TemplateNames = {
	ShopItem = "ShopItemTemplate",
	InventoryItem = "InventoryItemTemplate",
	EggItem = "EggItemTemplate",
	PetItem = "PetItemTemplate",
	SellItem = "SellItemTemplate",
}

-- Configuration export for client-side layout adjustments
UISetup.Config = {
	-- Grid cell sizes
	PC_ITEM_CELL_SIZE = UDim2.new(0, 100, 0, 120),
	MOBILE_ITEM_CELL_SIZE = UDim2.new(0, 80, 0, 100),
	PC_INVENTORY_CELL_SIZE = UDim2.new(0, 85, 0, 85),
	MOBILE_INVENTORY_CELL_SIZE = UDim2.new(0, 65, 0, 65),
	GRID_CELL_PADDING = UDim2.new(0, 8, 0, 8),
	
	-- Breakpoint for PC vs Mobile detection
	PC_MIN_WIDTH = 800,
	
	-- Safe zones
	SAFE_ZONE_PADDING = 0.05,
	
	-- Button feedback
	BUTTON_HOVER_BRIGHTNESS = 1.15,
	BUTTON_CLICK_SCALE = 0.95,
	BUTTON_TRANSITION_TIME = 0.1,
	
	-- Accessibility
	MIN_TOUCH_SIZE = 44,
}

-- Check if device is PC (large screen) or Mobile
function UISetup.IsPCLayout(): boolean
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize.X >= UISetup.Config.PC_MIN_WIDTH
	end
	return true -- Default to PC
end

-- =============================================================================
-- GEAR SHOP UI BUILDER (Tools and Equipment)
-- =============================================================================
function UIBuilders.CreateGearShopUI(screenGui, theme, addCorner, addStroke, addButtonFeedback, ensureMinTouchSize, applyPetsWindowBackground, addTemplateToScrollFrame)
	local gearShopWindow = Instance.new("Frame")
	gearShopWindow.Name = "GearShopWindow"
	-- Match PetsWindow centered modal layout
	gearShopWindow.Size = UDim2.new(0.7, 0, 0.75, 0)
	gearShopWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	gearShopWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	gearShopWindow.BackgroundTransparency = 1
	gearShopWindow.Visible = false
	gearShopWindow.ZIndex = 10
	gearShopWindow.Parent = screenGui

	applyPetsWindowBackground(gearShopWindow)

	local gearShopPadding = Instance.new("UIPadding")
	gearShopPadding.PaddingTop = UDim.new(0, 0)
	gearShopPadding.PaddingBottom = UDim.new(0, 0)
	gearShopPadding.Parent = gearShopWindow
	
	-- 2-panel centered layout (like PetsWindow)
	local gearLeftPanel = Instance.new("Frame")
	gearLeftPanel.Name = "LeftPanel"
	gearLeftPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	gearLeftPanel.Position = UDim2.new(0.01, 0, 0.1, 0)
	gearLeftPanel.BackgroundTransparency = 1
	gearLeftPanel.BorderSizePixel = 0
	gearLeftPanel.ZIndex = 11
	gearLeftPanel.Parent = gearShopWindow

	-- No per-panel box art; window uses PetsWindow-style background.
	
	local gearLeftTitle = Instance.new("TextLabel")
	gearLeftTitle.Name = "PanelTitle"
	gearLeftTitle.Size = UDim2.new(0.9, 0, 0.05, 0)
	gearLeftTitle.Position = UDim2.new(0.05, 0, 0.015, 0)
	gearLeftTitle.BackgroundTransparency = 1
	gearLeftTitle.Text = "🔧 Gear Shop"
	gearLeftTitle.TextColor3 = theme.textGold
	gearLeftTitle.Font = Enum.Font.GothamBold
	gearLeftTitle.TextScaled = true
	gearLeftTitle.TextXAlignment = Enum.TextXAlignment.Left
	gearLeftTitle.ZIndex = 12
	gearLeftTitle.Parent = gearLeftPanel
	
	local gearLeftTitleStroke = Instance.new("UIStroke")
	gearLeftTitleStroke.Color = theme.forestDark
	gearLeftTitleStroke.Thickness = 2
	gearLeftTitleStroke.Parent = gearLeftTitle
	
	local gearShopScroll = Instance.new("ScrollingFrame")
	gearShopScroll.Name = "GearShopScroll"
	gearShopScroll.Size = UDim2.new(0.94, 0, 0.9, 0)
	gearShopScroll.Position = UDim2.new(0.03, 0, 0.09, 0)
	gearShopScroll.BackgroundColor3 = theme.forestDark
	gearShopScroll.BackgroundTransparency = 0.3
	gearShopScroll.BorderSizePixel = 0
	gearShopScroll.Active = true
	gearShopScroll.ScrollingEnabled = true
	gearShopScroll.ScrollBarThickness = 10
	gearShopScroll.ScrollBarImageColor3 = theme.tealGem
	gearShopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gearShopScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	gearShopScroll.ZIndex = 12
	gearShopScroll.Parent = gearLeftPanel
	
	local gearShopLayout = Instance.new("UIListLayout")
	gearShopLayout.Padding = UDim.new(0, 10)
	gearShopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gearShopLayout.Parent = gearShopScroll
	
	local gearShopScrollPadding = Instance.new("UIPadding")
	gearShopScrollPadding.PaddingTop = UDim.new(0, 8)
	gearShopScrollPadding.PaddingBottom = UDim.new(0, 8)
	gearShopScrollPadding.PaddingLeft = UDim.new(0, 4)
	gearShopScrollPadding.PaddingRight = UDim.new(0, 4)
	gearShopScrollPadding.Parent = gearShopScroll
	
	-- Add template for cloning
	addTemplateToScrollFrame(gearShopScroll, "GearItem")
	
	-- Close button (top-right corner)
	local gearCloseButton = Instance.new("TextButton")
	gearCloseButton.Name = "CloseButton"
	gearCloseButton.Size = UDim2.new(0, 120, 0, 40)
	gearCloseButton.Position = UDim2.new(0.98, 0, 0.02, 0)
	gearCloseButton.AnchorPoint = Vector2.new(1, 0)
	gearCloseButton.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	gearCloseButton.ZIndex = 13
	gearCloseButton.Parent = gearShopWindow

	addCorner(gearCloseButton, 12)
	addStroke(gearCloseButton, theme.goldLeaf, 2, 0.3)
	addButtonFeedback(gearCloseButton)
	ensureMinTouchSize(gearCloseButton)

	gearCloseButton.Text = "✖ CLOSE"
	gearCloseButton.TextColor3 = theme.textLight
	gearCloseButton.Font = Enum.Font.GothamBold
	gearCloseButton.TextScaled = true
	
	local gearCloseStroke = Instance.new("UIStroke")
	gearCloseStroke.Color = theme.forestDark
	gearCloseStroke.Thickness = 1
	gearCloseStroke.Parent = gearCloseButton
	
	-- RIGHT PANEL - Player's Owned Gear
	local gearRightPanel = Instance.new("Frame")
	gearRightPanel.Name = "RightPanel"
	gearRightPanel.Size = UDim2.new(0.48, 0, 0.88, 0)
	gearRightPanel.Position = UDim2.new(0.51, 0, 0.1, 0)
	gearRightPanel.BackgroundTransparency = 1
	gearRightPanel.BorderSizePixel = 0
	gearRightPanel.ZIndex = 11
	gearRightPanel.Parent = gearShopWindow

	-- No per-panel box art; window uses PetsWindow-style background.
	
	local gearRightTitle = Instance.new("TextLabel")
	gearRightTitle.Name = "PanelTitle"
	gearRightTitle.Size = UDim2.new(0.9, 0, 0.05, 0)
	gearRightTitle.Position = UDim2.new(0.05, 0, 0.015, 0)
	gearRightTitle.BackgroundTransparency = 1
	gearRightTitle.Text = "🎒 My Gear"
	gearRightTitle.TextColor3 = theme.textMoss
	gearRightTitle.Font = Enum.Font.GothamBold
	gearRightTitle.TextScaled = true
	gearRightTitle.TextXAlignment = Enum.TextXAlignment.Left
	gearRightTitle.ZIndex = 12
	gearRightTitle.Parent = gearRightPanel
	
	local gearRightTitleStroke = Instance.new("UIStroke")
	gearRightTitleStroke.Color = theme.forestDark
	gearRightTitleStroke.Thickness = 2
	gearRightTitleStroke.Parent = gearRightTitle
	
	-- Owned gear display with grid layout
	local gearInventoryScroll = Instance.new("ScrollingFrame")
	gearInventoryScroll.Name = "GearInventoryScroll"
	gearInventoryScroll.Size = UDim2.new(0.94, 0, 0.88, 0)
	gearInventoryScroll.Position = UDim2.new(0.03, 0, 0.11, 0)
	gearInventoryScroll.BackgroundColor3 = theme.forestDark
	gearInventoryScroll.BackgroundTransparency = 0.3
	gearInventoryScroll.BorderSizePixel = 0
	gearInventoryScroll.Active = true
	gearInventoryScroll.ScrollingEnabled = true
	gearInventoryScroll.ScrollBarThickness = 8
	gearInventoryScroll.ScrollBarImageColor3 = theme.tealGem
	gearInventoryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gearInventoryScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
	gearInventoryScroll.ZIndex = 12
	gearInventoryScroll.Parent = gearRightPanel
	
	-- Use Grid Layout for gear
	local gearInventoryGrid = Instance.new("UIGridLayout")
	gearInventoryGrid.Name = "GridLayout"
	gearInventoryGrid.CellSize = UDim2.new(0, 90, 0, 110)
	gearInventoryGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	gearInventoryGrid.SortOrder = Enum.SortOrder.Name
	gearInventoryGrid.FillDirection = Enum.FillDirection.Horizontal
	gearInventoryGrid.FillDirectionMaxCells = 0
	gearInventoryGrid.Parent = gearInventoryScroll
	
	local gearInventoryPadding = Instance.new("UIPadding")
	gearInventoryPadding.PaddingTop = UDim.new(0, 8)
	gearInventoryPadding.PaddingBottom = UDim.new(0, 8)
	gearInventoryPadding.PaddingLeft = UDim.new(0, 4)
	gearInventoryPadding.PaddingRight = UDim.new(0, 4)
	gearInventoryPadding.Parent = gearInventoryScroll
	
	-- Add template for owned gear items
	addTemplateToScrollFrame(gearInventoryScroll, "OwnedGearItem")
end

-- =============================================================================
-- RUNTIME BUTTON FEEDBACK HANDLER
-- Call this on buttons to apply hover/click visual effects
-- =============================================================================
function UISetup.ApplyButtonFeedback(button: TextButton | ImageButton)
	local TweenService = game:GetService("TweenService")
	
	-- Check if button has feedback attributes
	if not button:GetAttribute("HasFeedback") then return end
	
	local originalColor = button:GetAttribute("OriginalColor")
	local hoverColor = button:GetAttribute("HoverColor")
	local clickScale = button:GetAttribute("ClickScale") or 0.95
	local transitionTime = UISetup.Config.BUTTON_TRANSITION_TIME
	
	local uiScale = button:FindFirstChild("UIScale")
	
	-- Hover effect (brighten)
	button.MouseEnter:Connect(function()
		if hoverColor then
			TweenService:Create(button, TweenInfo.new(transitionTime), {
				BackgroundColor3 = hoverColor
			}):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		if originalColor then
			TweenService:Create(button, TweenInfo.new(transitionTime), {
				BackgroundColor3 = originalColor
			}):Play()
		end
		-- Reset scale on leave
		if uiScale then
			TweenService:Create(uiScale, TweenInfo.new(transitionTime), {
				Scale = 1
			}):Play()
		end
	end)
	
	-- Click effect (scale down)
	button.MouseButton1Down:Connect(function()
		if uiScale then
			TweenService:Create(uiScale, TweenInfo.new(transitionTime / 2), {
				Scale = clickScale
			}):Play()
		end
	end)
	
	button.MouseButton1Up:Connect(function()
		if uiScale then
			TweenService:Create(uiScale, TweenInfo.new(transitionTime), {
				Scale = 1
			}):Play()
		end
	end)
end

-- Apply feedback to all buttons with HasFeedback attribute in a container
function UISetup.InitializeButtonFeedback(container: Instance)
	for _, descendant in ipairs(container:GetDescendants()) do
		if (descendant:IsA("TextButton") or descendant:IsA("ImageButton")) 
			and descendant:GetAttribute("HasFeedback") then
			UISetup.ApplyButtonFeedback(descendant)
		end
	end
end

return UISetup

