--!strict
-- Window.luau
-- Base window component with title bar, close button, and content area

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent.Parent:WaitForChild("Styles"))

local Window = {}

export type WindowConfig = {
	Name: string,
	Title: string,
	Size: UDim2?,
	Position: UDim2?,
	OnClose: (() -> ())?,
	UseFrameArt: boolean?,
}

-- Create a styled window
function Window.Create(config: WindowConfig, parent: GuiObject): Frame
	local scale = Styles.GetDeviceScale()
	local topPadding = Styles.GetTopPadding()
	local size = config.Size or UDim2.new(0, 400, 0, 500)
	local position = config.Position or UDim2.new(0.5, 0, 0.5, topPadding)
	
	-- Main window frame
	local window = Instance.new("Frame")
	window.Name = config.Name
	window.Size = size
	window.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + topPadding)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.BackgroundColor3 = Theme.ForestDark
	window.BorderSizePixel = 0
	window.Visible = false
	window.ZIndex = 100
	
	Styles.AddCorner(window, 20)
	Styles.AddStroke(window, Theme.VineStroke, 3, 0.2)
	Styles.AddShadow(window, 8)

	if scale ~= 1 then
		local uiScale = Instance.new("UIScale")
		uiScale.Scale = scale
		uiScale.Parent = window
	end
	
	-- Apply frame art if requested
	if config.UseFrameArt then
		Styles.ApplyFrameImage(window, Theme.FrameWindowTall)
	else
		Styles.AddGradient(window, Theme.ForestDark, Theme.ForestDeep, 90)
	end
	
	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Theme.WoodPanel
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 101
	titleBar.Parent = window
	
	-- Round only top corners
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 20)
	titleCorner.Parent = titleBar
	
	-- Bottom edge to make it flush
	local titleEdge = Instance.new("Frame")
	titleEdge.Name = "Edge"
	titleEdge.Size = UDim2.new(1, 0, 0, 20)
	titleEdge.Position = UDim2.new(0, 0, 1, -10)
	titleEdge.BackgroundColor3 = Theme.WoodPanel
	titleEdge.BorderSizePixel = 0
	titleEdge.ZIndex = 100
	titleEdge.Parent = titleBar
	
	Styles.AddGradient(titleBar, Theme.WoodPanel, Theme.StonePanel, 90)
	
	-- Title text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = config.Title
	titleLabel.TextColor3 = Theme.TextLight
	titleLabel.Font = Theme.FontPrimary
	titleLabel.TextSize = 24
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 102
	titleLabel.Parent = titleBar
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 36, 0, 36)
	closeButton.Position = UDim2.new(1, -43, 0.5, 0)
	closeButton.AnchorPoint = Vector2.new(0, 0.5)
	closeButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Theme.TextLight
	closeButton.Font = Theme.FontPrimary
	closeButton.TextSize = 20
	closeButton.AutoButtonColor = false
	closeButton.ZIndex = 102
	closeButton.Parent = titleBar
	
	Styles.AddCorner(closeButton, 8)
	
	closeButton.MouseEnter:Connect(function()
		closeButton.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
	end)
	
	closeButton.MouseLeave:Connect(function()
		closeButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
	end)
	
	closeButton.Activated:Connect(function()
		Window.Hide(window)
		if config.OnClose then
			config.OnClose()
		end
	end)
	
	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -70)
	content.Position = UDim2.new(0, 10, 0, 55)
	content.BackgroundTransparency = 1
	content.ZIndex = 101
	content.Parent = window
	
	window.Parent = parent
	
	return window
end

-- Show window with animation
function Window.Show(window: Frame)
	window.Visible = true
	window.BackgroundTransparency = 1
	window.Position = UDim2.new(0.5, 0, 0.6, 0)
	
	local tween = TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()
end

-- Hide window with animation
function Window.Hide(window: Frame)
	local tween = TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.6, 0)
	})
	tween:Play()
	tween.Completed:Connect(function()
		window.Visible = false
	end)
end

-- Toggle window visibility
function Window.Toggle(window: Frame)
	if window.Visible then
		Window.Hide(window)
	else
		Window.Show(window)
	end
end

-- Get the content frame of a window
function Window.GetContent(window: Frame): Frame?
	return window:FindFirstChild("Content") :: Frame?
end

return Window
