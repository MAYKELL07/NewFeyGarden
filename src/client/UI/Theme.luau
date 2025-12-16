--!strict
-- Theme.luau
-- Centralized theme definition for all UI components
-- Colors, fonts, and asset references in one place

local Theme = {}

-- =============================================================================
-- COLOR PALETTE (Purple/Blue Fantasy Theme)
-- =============================================================================

-- Backgrounds: Deep plum nights
Theme.ForestDark = Color3.fromRGB(18, 10, 28)
Theme.ForestDeep = Color3.fromRGB(28, 16, 40)
Theme.WoodBark = Color3.fromRGB(72, 44, 33)
Theme.MossGreen = Color3.fromRGB(54, 24, 66)

-- Panels: Leaf + wood violet tones
Theme.WoodPanel = Color3.fromRGB(54, 24, 66)
Theme.StonePanel = Color3.fromRGB(70, 33, 76)
Theme.LeafPanel = Color3.fromRGB(96, 48, 103)

-- Accents: Mushroom blues + soft golds
Theme.TealGem = Color3.fromRGB(86, 108, 186)
Theme.TealGlow = Color3.fromRGB(130, 150, 220)
Theme.GoldLeaf = Color3.fromRGB(210, 168, 120)
Theme.AmberGlow = Color3.fromRGB(180, 120, 150)

-- Text: Lilac/off-white
Theme.TextLight = Color3.fromRGB(228, 218, 240)
Theme.TextGold = Color3.fromRGB(210, 190, 230)
Theme.TextMoss = Color3.fromRGB(182, 154, 210)

-- Borders: Vine strokes tinted
Theme.VineStroke = Color3.fromRGB(120, 80, 140)
Theme.GlowStroke = Color3.fromRGB(160, 140, 210)

-- UI Elements
Theme.Notification = Color3.fromRGB(86, 108, 186)
Theme.NotificationAlt = Color3.fromRGB(130, 150, 220)
Theme.PanelStroke = Color3.fromRGB(110, 70, 140)

-- Button States
Theme.SellButton = Color3.fromRGB(86, 108, 186)
Theme.SellButtonHover = Color3.fromRGB(110, 135, 210)
Theme.GoldAccent = Color3.fromRGB(230, 190, 100)
Theme.WarningGold = Color3.fromRGB(200, 160, 80)

-- Rarity Colors
Theme.RarityCommon = Color3.fromRGB(200, 200, 200)
Theme.RarityUncommon = Color3.fromRGB(120, 200, 120)
Theme.RarityRare = Color3.fromRGB(100, 150, 255)
Theme.RarityEpic = Color3.fromRGB(180, 100, 255)
Theme.RarityLegendary = Color3.fromRGB(255, 180, 50)

-- =============================================================================
-- FONTS
-- =============================================================================

Theme.FontPrimary = Enum.Font.GothamBold
Theme.FontSecondary = Enum.Font.GothamMedium
Theme.FontBody = Enum.Font.Gotham

-- =============================================================================
-- SIZING (Scale-based for responsiveness)
-- =============================================================================

Theme.CornerRadiusSmall = UDim.new(0, 8)
Theme.CornerRadiusMedium = UDim.new(0, 12)
Theme.CornerRadiusLarge = UDim.new(0, 18)

Theme.StrokeThicknessThin = 1
Theme.StrokeThicknessMedium = 2
Theme.StrokeThicknessThick = 3

-- =============================================================================
-- FRAME ART ASSETS
-- =============================================================================

Theme.FrameWindowTall = "rbxassetid://72140204040476"
Theme.FrameWindowWide = "rbxassetid://110769453800411"
Theme.FramePanelRect = "rbxassetid://77328240678206"
Theme.FramePanelSquare = "rbxassetid://125833347683847"

-- 9-slice rects (tune if edges warp)
Theme.SliceTall = Rect.new(90, 120, 630, 960)
Theme.SliceWide = Rect.new(90, 120, 630, 960)
Theme.SliceRect = Rect.new(90, 120, 630, 960)
Theme.SliceSquare = Rect.new(90, 120, 630, 960)

-- =============================================================================
-- GRADIENTS (Predefined color sequences)
-- =============================================================================

Theme.GradientTealBlue = ColorSequence.new(Theme.TealGem, Theme.TealGlow)
Theme.GradientPurple = ColorSequence.new(Theme.VineStroke, Theme.LeafPanel)
Theme.GradientGold = ColorSequence.new(Theme.GoldLeaf, Theme.GoldAccent)

return Theme
