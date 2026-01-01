--!strict
-- Styles.luau
-- Reusable UI styling helper functions
-- Apply corners, shadows, gradients, strokes consistently

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Theme = require(script.Parent:WaitForChild("Theme"))

local Styles = {}

-- =============================================================================
-- DEVICE AWARENESS (Lightweight responsiveness helpers)
-- =============================================================================

local SMALL_SCREEN_WIDTH = 1200
local MOBILE_SCALE = 0.85
local DESKTOP_SCALE = 1
local MOBILE_TOP_PADDING = 24

local function isSmallScreen(): boolean
	local camera = Workspace.CurrentCamera
	local viewportSize = camera and camera.ViewportSize or Vector2.new(0, 0)
	return UserInputService.TouchEnabled or viewportSize.X <= SMALL_SCREEN_WIDTH
end

function Styles.IsSmallScreen(): boolean
	return isSmallScreen()
end

function Styles.GetDeviceScale(): number
	return isSmallScreen() and MOBILE_SCALE or DESKTOP_SCALE
end

function Styles.GetTopPadding(): number
	return isSmallScreen() and MOBILE_TOP_PADDING or 0
end

-- =============================================================================
-- CORNER RADIUS
-- =============================================================================

function Styles.AddCorner(parent: GuiObject, radius: number?): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 18)
	corner.Parent = parent
	return corner
end

-- =============================================================================
-- SHADOW (Soft drop shadow effect)
-- =============================================================================

function Styles.AddShadow(parent: GuiObject, offset: number?): ImageLabel
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.Size = UDim2.new(1, 12, 1, 12)
	shadow.Position = UDim2.new(0, 0, 0, offset or 6)
	shadow.AnchorPoint = Vector2.new(0, 0)
	shadow.ZIndex = -10
	shadow.Parent = parent
	Styles.AddCorner(shadow, 18)
	return shadow
end

-- =============================================================================
-- GRADIENT
-- =============================================================================

function Styles.AddGradient(parent: GuiObject, color1: Color3, color2: Color3, rotation: number?): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(color1, color2)
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

function Styles.AddGradientSequence(parent: GuiObject, colorSequence: ColorSequence, rotation: number?): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = colorSequence
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

-- =============================================================================
-- STROKE (Border outline)
-- =============================================================================

function Styles.AddStroke(parent: GuiObject, color: Color3?, thickness: number?, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = thickness or 2
	stroke.Color = color or Theme.VineStroke
	stroke.Transparency = transparency or 0.25
	stroke.Parent = parent
	return stroke
end

-- =============================================================================
-- MAGICAL GLOW (Bioluminescent effect)
-- =============================================================================

function Styles.AddGlow(parent: GuiObject, color: Color3?): UIStroke
	local glow = Instance.new("UIStroke")
	glow.Name = "MagicalGlow"
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Thickness = 1.5
	glow.Color = color or Theme.TealGlow
	glow.Transparency = 0.6
	glow.Parent = parent
	return glow
end

-- =============================================================================
-- FRAME ART (9-slice window backgrounds)
-- =============================================================================

function Styles.ApplyFrameImage(parent: GuiObject, assetId: string?, sliceRect: Rect?, zOffset: number?): ImageLabel
	local bg = Instance.new("ImageLabel")
	bg.Name = "FrameArt"
	bg.BackgroundTransparency = 1
	bg.Image = assetId or Theme.FrameWindowTall

	local isWindow = bg.Image == Theme.FrameWindowTall or bg.Image == Theme.FrameWindowWide
	bg.ScaleType = isWindow and Enum.ScaleType.Stretch or Enum.ScaleType.Crop
	bg.Size = UDim2.new(1.4, 0, 1.4, 0)
	bg.Position = UDim2.new(0.5, 0, 0.5, 0)
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.ZIndex = (parent.ZIndex or 1) - 1 + (zOffset or 0)
	bg.Parent = parent
	parent.BackgroundTransparency = 1
	return bg
end

-- =============================================================================
-- ASPECT RATIO CONSTRAINT (For responsive square items)
-- =============================================================================

function Styles.AddAspectRatio(parent: GuiObject, ratio: number?): UIAspectRatioConstraint
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = ratio or 1
	aspect.AspectType = Enum.AspectType.FitWithinMaxSize
	aspect.DominantAxis = Enum.DominantAxis.Width
	aspect.Parent = parent
	return aspect
end

-- =============================================================================
-- SIZE CONSTRAINT (Min/Max bounds for responsive elements)
-- =============================================================================

function Styles.AddSizeConstraint(parent: GuiObject, minSize: Vector2?, maxSize: Vector2?): UISizeConstraint
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = minSize or Vector2.new(60, 60)
	constraint.MaxSize = maxSize or Vector2.new(120, 120)
	constraint.Parent = parent
	return constraint
end

-- =============================================================================
-- LIST LAYOUT (For scrolling containers)
-- =============================================================================

function Styles.AddListLayout(parent: GuiObject, padding: number?, direction: Enum.FillDirection?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, padding or 8)
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

-- =============================================================================
-- GRID LAYOUT (For inventory grids)
-- =============================================================================

function Styles.AddGridLayout(parent: GuiObject, cellSize: UDim2?, cellPadding: UDim2?): UIGridLayout
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = cellSize or UDim2.new(0, 90, 0, 90)
	grid.CellPadding = cellPadding or UDim2.new(0, 8, 0, 8)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = parent
	return grid
end

-- =============================================================================
-- PADDING
-- =============================================================================

function Styles.AddPadding(parent: GuiObject, padding: number?): UIPadding
	local p = padding or 10
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, p)
	uiPadding.PaddingBottom = UDim.new(0, p)
	uiPadding.PaddingLeft = UDim.new(0, p)
	uiPadding.PaddingRight = UDim.new(0, p)
	uiPadding.Parent = parent
	return uiPadding
end

-- =============================================================================
-- STYLED BUTTON (Complete button with all effects)
-- =============================================================================

function Styles.CreateStyledButton(name: string, size: UDim2, position: UDim2, text: string, parent: GuiObject?): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Theme.TealGem
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Theme.TextLight
	button.Font = Theme.FontPrimary
	button.TextScaled = true
	button.AutoButtonColor = false
	
	Styles.AddCorner(button, 12)
	Styles.AddStroke(button, Theme.TealGlow, 2, 0.3)
	Styles.AddGradient(button, Theme.TealGem, Theme.TealGlow, 90)
	
	if parent then
		button.Parent = parent
	end
	
	return button
end

-- =============================================================================
-- STYLED FRAME (Panel with consistent styling)
-- =============================================================================

function Styles.CreateStyledFrame(name: string, size: UDim2, position: UDim2, parent: GuiObject?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = Theme.WoodPanel
	frame.BorderSizePixel = 0
	
	Styles.AddCorner(frame, 18)
	Styles.AddStroke(frame, Theme.VineStroke, 2, 0.3)
	Styles.AddShadow(frame)
	
	if parent then
		frame.Parent = parent
	end
	
	return frame
end

return Styles
