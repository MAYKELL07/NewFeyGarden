-- TutorialUI.client.luau
-- Tutorial system with step-by-step GUI instructions

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TutorialUI = {}

-- Tutorial steps
local tutorialSteps = {
	{
		Title = "Welcome to FeyGarden!",
		Description = "Let's learn how to grow magical plants and build your mystical garden!",
		Icon = "🌿",
		Duration = 5
	},
	{
		Title = "Step 1: Buy Seeds",
		Description = "Visit the Seed Shop (🌱) to purchase magical seeds. Start with cheap seeds like Lumut!",
		Icon = "🛒",
		Highlight = "SeedShop",
		Duration = 8
	},
	{
		Title = "Step 2: Select Your Seed",
		Description = "Check your seed inventory at the bottom-left. Click a seed to select it for planting!",
		Icon = "👆",
		Highlight = "InventoryFrame",
		Duration = 8
	},
	{
		Title = "Step 3: Plant the Seed",
		Description = "Use your Shovel tool to dig and plant the seed in your garden plot!",
		Icon = "🏺",
		Duration = 8
	},
	{
		Title = "Step 4: Water Your Plants",
		Description = "Use the Watering Can to water your planted seeds. Watered plants grow faster!",
		Icon = "💧",
		Duration = 8
	},
	{
		Title = "Step 5: Wait for Growth",
		Description = "Plants go through stages: Seed → Sprout → Bloom. Different plants take different times!",
		Icon = "⏳",
		Duration = 8
	},
	{
		Title = "Step 6: Harvest Fruits",
		Description = "Click on fully-grown plants to harvest fruits. You get 1 fruit per plant!",
		Icon = "🍎",
		Duration = 8
	},
	{
		Title = "Step 7: Sell Fruits",
		Description = "Visit the Fruit Market (🍎) to sell your fruits and earn coins!",
		Icon = "💰",
		Highlight = "FruitSeller",
		Duration = 8
	},
	{
		Title = "Step 8: Get a Pet (Optional)",
		Description = "Visit the Pet Store (🐾) to buy pets that boost plant growth speed!",
		Icon = "🐾",
		Highlight = "PetStore",
		Duration = 8
	},
	{
		Title = "Tutorial Complete!",
		Description = "You're ready to become a master gardener! Keep growing and earning coins!",
		Icon = "✨",
		Duration = 6
	}
}

local currentStep = 1
local tutorialActive = false
local tutorialFrame = nil

-- Initialize Tutorial UI
function TutorialUI.Initialize()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TutorialInterface"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100 -- On top of everything
	screenGui.Parent = playerGui
	
	-- Tutorial Frame (top-center)
	tutorialFrame = Instance.new("Frame")
	tutorialFrame.Name = "TutorialFrame"
	tutorialFrame.Size = UDim2.new(0.5, 0, 0.2, 0)
	tutorialFrame.Position = UDim2.new(0.25, 0, -0.25, 0) -- Start off-screen
	tutorialFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	tutorialFrame.BackgroundTransparency = 0.1
	tutorialFrame.BorderSizePixel = 0
	tutorialFrame.Visible = false
	tutorialFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = tutorialFrame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 50))
	})
	gradient.Rotation = 45
	gradient.Parent = tutorialFrame
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.15, 0, 0.4, 0)
	icon.Position = UDim2.new(0.05, 0, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 48
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.Text = "🌿"
	icon.Parent = tutorialFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.75, 0, 0.3, 0)
	title.Position = UDim2.new(0.22, 0, 0.1, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(150, 255, 150)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Tutorial Step"
	title.Parent = tutorialFrame
	
	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(0.75, 0, 0.5, 0)
	description.Position = UDim2.new(0.22, 0, 0.42, 0)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextSize = 16
	description.TextColor3 = Color3.fromRGB(255, 255, 255)
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Text = "Tutorial description goes here..."
	description.Parent = tutorialFrame
	
	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0.9, 0, 0.05, 0)
	progressBg.Position = UDim2.new(0.05, 0, 0.92, 0)
	progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = tutorialFrame
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(1, 0)
	progressCorner.Parent = progressBg
	
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0.1, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(150, 255, 150)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBg
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = progressBar
	
	-- Skip button
	local skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0.15, 0, 0.25, 0)
	skipButton.Position = UDim2.new(0.83, 0, 0.05, 0)
	skipButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	skipButton.BorderSizePixel = 0
	skipButton.Font = Enum.Font.GothamBold
	skipButton.TextSize = 14
	skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipButton.Text = "Skip"
	skipButton.Parent = tutorialFrame
	
	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 8)
	skipCorner.Parent = skipButton
	
	skipButton.MouseButton1Click:Connect(function()
		TutorialUI.Stop()
	end)
	
	print("[TutorialUI] Interface initialized")
end

-- Show tutorial step
function TutorialUI.ShowStep(stepIndex)
	if not tutorialFrame then return end
	
	local step = tutorialSteps[stepIndex]
	if not step then return end
	
	-- Update content
	tutorialFrame.Icon.Text = step.Icon
	tutorialFrame.Title.Text = step.Title
	tutorialFrame.Description.Text = step.Description
	
	-- Update progress bar
	local progress = stepIndex / #tutorialSteps
	local progressBar = tutorialFrame.ProgressBg.ProgressBar
	local tween = TweenService:Create(progressBar, TweenInfo.new(0.5), {
		Size = UDim2.new(progress, 0, 1, 0)
	})
	tween:Play()
	
	-- Show frame if hidden
	if not tutorialFrame.Visible then
		tutorialFrame.Visible = true
		local tween = TweenService:Create(tutorialFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.25, 0, 0.05, 0)
		})
		tween:Play()
	end
	
	print("[TutorialUI] Showing step:", stepIndex, "-", step.Title)
end

-- Start tutorial
function TutorialUI.Start()
	if tutorialActive then return end
	
	tutorialActive = true
	currentStep = 1
	
	TutorialUI.ShowStep(currentStep)
	
	-- Auto-advance through steps
	task.spawn(function()
		while tutorialActive and currentStep <= #tutorialSteps do
			local step = tutorialSteps[currentStep]
			task.wait(step.Duration or 5)
			
			if tutorialActive then
				currentStep = currentStep + 1
				if currentStep <= #tutorialSteps then
					TutorialUI.ShowStep(currentStep)
				else
					TutorialUI.Stop()
				end
			end
		end
	end)
	
	print("[TutorialUI] Tutorial started")
end

-- Stop tutorial
function TutorialUI.Stop()
	if not tutorialActive then return end
	
	tutorialActive = false
	
	if tutorialFrame then
		local tween = TweenService:Create(tutorialFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.25, 0, -0.25, 0)
		})
		tween:Play()
		tween.Completed:Connect(function()
			tutorialFrame.Visible = false
		end)
	end
	
	print("[TutorialUI] Tutorial stopped")
end

-- Check if should show tutorial (for new players)
function TutorialUI.CheckShowTutorial()
	-- Could check player data to see if they've completed tutorial before
	-- For now, show for everyone
	task.wait(3) -- Wait a bit after joining
	TutorialUI.Start()
end

return TutorialUI
