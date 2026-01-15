-- PetHoverStats.client.luau
-- Feature 6: When hovering over a pet, show stats tooltip
-- Shows: Pet name (animal type), Age (level), hunger bar, progress to next level

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not sharedFolder then
	warn("[PetHoverStats] Shared folder not found")
	return
end

local Constants = require(sharedFolder:WaitForChild("Constants"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local PetHoverStats = {}

-- Theme colors
local THEME = {
	ForestDark = Color3.fromRGB(18, 10, 28),
	ForestDeep = Color3.fromRGB(28, 16, 40),
	TealGem = Color3.fromRGB(86, 108, 186),
	GoldLeaf = Color3.fromRGB(210, 168, 120),
	TextLight = Color3.fromRGB(228, 218, 240),
	TextGold = Color3.fromRGB(210, 190, 230),
	HealthGreen = Color3.fromRGB(100, 200, 100),
	HungerOrange = Color3.fromRGB(255, 180, 100),
	ExpBlue = Color3.fromRGB(100, 150, 255),
}

-- State
local tooltipUI = nil
local currentHoveredPet = nil

-- Create the tooltip UI
local function createTooltip()
	if tooltipUI then return tooltipUI end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PetHoverStatsUI"
	screenGui.DisplayOrder = 200
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main tooltip frame
	local tooltip = Instance.new("Frame")
	tooltip.Name = "Tooltip"
	tooltip.Size = UDim2.new(0, 200, 0, 160)
	tooltip.Position = UDim2.new(0, 0, 0, 0)
	tooltip.BackgroundColor3 = THEME.ForestDark
	tooltip.BackgroundTransparency = 0.1
	tooltip.BorderSizePixel = 0
	tooltip.Visible = false
	tooltip.ZIndex = 100
	tooltip.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = tooltip
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.TealGem
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = tooltip
	
	-- Pet name (animal type)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PetName"
	nameLabel.Size = UDim2.new(1, -20, 0, 28)
	nameLabel.Position = UDim2.new(0, 10, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Pet Name"
	nameLabel.TextColor3 = THEME.GoldLeaf
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 101
	nameLabel.Parent = tooltip
	
	-- Age (level) display
	local ageLabel = Instance.new("TextLabel")
	ageLabel.Name = "AgeLabel"
	ageLabel.Size = UDim2.new(1, -20, 0, 20)
	ageLabel.Position = UDim2.new(0, 10, 0, 36)
	ageLabel.BackgroundTransparency = 1
	ageLabel.Text = "Age: 1"
	ageLabel.TextColor3 = THEME.TextLight
	ageLabel.Font = Enum.Font.Gotham
	ageLabel.TextSize = 14
	ageLabel.TextXAlignment = Enum.TextXAlignment.Left
	ageLabel.ZIndex = 101
	ageLabel.Parent = tooltip
	
	-- Hunger section
	local hungerLabel = Instance.new("TextLabel")
	hungerLabel.Name = "HungerLabel"
	hungerLabel.Size = UDim2.new(0, 60, 0, 16)
	hungerLabel.Position = UDim2.new(0, 10, 0, 60)
	hungerLabel.BackgroundTransparency = 1
	hungerLabel.Text = "Hunger"
	hungerLabel.TextColor3 = THEME.TextGold
	hungerLabel.Font = Enum.Font.Gotham
	hungerLabel.TextSize = 12
	hungerLabel.TextXAlignment = Enum.TextXAlignment.Left
	hungerLabel.ZIndex = 101
	hungerLabel.Parent = tooltip
	
	-- Hunger bar background
	local hungerBarBg = Instance.new("Frame")
	hungerBarBg.Name = "HungerBarBg"
	hungerBarBg.Size = UDim2.new(1, -80, 0, 12)
	hungerBarBg.Position = UDim2.new(0, 70, 0, 62)
	hungerBarBg.BackgroundColor3 = THEME.ForestDeep
	hungerBarBg.BorderSizePixel = 0
	hungerBarBg.ZIndex = 101
	hungerBarBg.Parent = tooltip
	
	local hungerBarBgCorner = Instance.new("UICorner")
	hungerBarBgCorner.CornerRadius = UDim.new(0, 6)
	hungerBarBgCorner.Parent = hungerBarBg
	
	-- Hunger bar fill
	local hungerBarFill = Instance.new("Frame")
	hungerBarFill.Name = "HungerBarFill"
	hungerBarFill.Size = UDim2.new(0.8, 0, 1, 0)
	hungerBarFill.BackgroundColor3 = THEME.HungerOrange
	hungerBarFill.BorderSizePixel = 0
	hungerBarFill.ZIndex = 102
	hungerBarFill.Parent = hungerBarBg
	
	local hungerFillCorner = Instance.new("UICorner")
	hungerFillCorner.CornerRadius = UDim.new(0, 6)
	hungerFillCorner.Parent = hungerBarFill
	
	-- Level/Age progress section
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0, 60, 0, 16)
	levelLabel.Position = UDim2.new(0, 10, 0, 82)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Next Age"
	levelLabel.TextColor3 = THEME.TextGold
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextSize = 12
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.ZIndex = 101
	levelLabel.Parent = tooltip
	
	-- Level bar background
	local levelBarBg = Instance.new("Frame")
	levelBarBg.Name = "LevelBarBg"
	levelBarBg.Size = UDim2.new(1, -80, 0, 12)
	levelBarBg.Position = UDim2.new(0, 70, 0, 84)
	levelBarBg.BackgroundColor3 = THEME.ForestDeep
	levelBarBg.BorderSizePixel = 0
	levelBarBg.ZIndex = 101
	levelBarBg.Parent = tooltip
	
	local levelBarBgCorner = Instance.new("UICorner")
	levelBarBgCorner.CornerRadius = UDim.new(0, 6)
	levelBarBgCorner.Parent = levelBarBg
	
	-- Level bar fill
	local levelBarFill = Instance.new("Frame")
	levelBarFill.Name = "LevelBarFill"
	levelBarFill.Size = UDim2.new(0.5, 0, 1, 0)
	levelBarFill.BackgroundColor3 = THEME.ExpBlue
	levelBarFill.BorderSizePixel = 0
	levelBarFill.ZIndex = 102
	levelBarFill.Parent = levelBarBg
	
	local levelFillCorner = Instance.new("UICorner")
	levelFillCorner.CornerRadius = UDim.new(0, 6)
	levelFillCorner.Parent = levelBarFill
	
	-- Weight display
	local weightLabel = Instance.new("TextLabel")
	weightLabel.Name = "WeightLabel"
	weightLabel.Size = UDim2.new(1, -20, 0, 20)
	weightLabel.Position = UDim2.new(0, 10, 0, 105)
	weightLabel.BackgroundTransparency = 1
	weightLabel.Text = "Weight: 1.0"
	weightLabel.TextColor3 = THEME.TextLight
	weightLabel.Font = Enum.Font.Gotham
	weightLabel.TextSize = 12
	weightLabel.TextXAlignment = Enum.TextXAlignment.Left
	weightLabel.ZIndex = 101
	weightLabel.Parent = tooltip
	
	-- Stats info
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -20, 0, 20)
	statsLabel.Position = UDim2.new(0, 10, 0, 125)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "Boost: +10% growth"
	statsLabel.TextColor3 = THEME.TealGem
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextSize = 12
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.ZIndex = 101
	statsLabel.Parent = tooltip
	
	tooltipUI = screenGui
	return screenGui
end

-- Update tooltip with pet data
local function updateTooltip(petModel)
	if not tooltipUI then return end
	
	local tooltip = tooltipUI:FindFirstChild("Tooltip")
	if not tooltip then return end
	
	local petType = petModel:GetAttribute("PetType") or "Unknown"
	local petConfig = Constants.PET_CONFIG[petType]
	
	-- Get pet attributes (with defaults)
	local petAge = petModel:GetAttribute("Age") or petModel:GetAttribute("Level") or 1
	local petHunger = petModel:GetAttribute("Hunger") or 100 -- 0-100
	local petExp = petModel:GetAttribute("Experience") or 0
	local expToNextLevel = petModel:GetAttribute("ExpToNextLevel") or 100
	
	-- Get display name
	local displayName = petConfig and petConfig.DisplayName or petType
	
	-- Get boost percentage
	local boostPercent = 0
	if petConfig and petConfig.WaterBoost then
		boostPercent = math.floor((1 - petConfig.WaterBoost) * 100)
	end
	
	-- Update labels
	local nameLabel = tooltip:FindFirstChild("PetName")
	if nameLabel then
		nameLabel.Text = displayName
	end
	
	local ageLabel = tooltip:FindFirstChild("AgeLabel")
	if ageLabel then
		ageLabel.Text = "Age: " .. tostring(petAge)
	end
	
	-- Update hunger bar
	local hungerBarBg = tooltip:FindFirstChild("HungerBarBg")
	if hungerBarBg then
		local hungerFill = hungerBarBg:FindFirstChild("HungerBarFill")
		if hungerFill then
			local hungerPercent = math.clamp(petHunger / 100, 0, 1)
			hungerFill.Size = UDim2.new(hungerPercent, 0, 1, 0)
			
			-- Color based on hunger level
			if hungerPercent > 0.6 then
				hungerFill.BackgroundColor3 = THEME.HealthGreen
			elseif hungerPercent > 0.3 then
				hungerFill.BackgroundColor3 = THEME.HungerOrange
			else
				hungerFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
			end
		end
	end
	
	-- Update level progress bar
	local levelBarBg = tooltip:FindFirstChild("LevelBarBg")
	if levelBarBg then
		local levelFill = levelBarBg:FindFirstChild("LevelBarFill")
		if levelFill then
			local levelPercent = math.clamp(petExp / expToNextLevel, 0, 1)
			levelFill.Size = UDim2.new(levelPercent, 0, 1, 0)
		end
	end
	
	-- Update weight label
	local weightLabel = tooltip:FindFirstChild("WeightLabel")
	if weightLabel then
		local petWeight = petModel:GetAttribute("Weight") or 1
		weightLabel.Text = string.format("Weight: %.1f", petWeight)
	end
	
	-- Update stats label
	local statsLabel = tooltip:FindFirstChild("StatsLabel")
	if statsLabel then
		statsLabel.Text = "Boost: +" .. tostring(boostPercent) .. "% growth"
	end
end

-- Show tooltip at position
local function showTooltip(petModel, screenPosition)
	if not tooltipUI then
		createTooltip()
	end
	
	local tooltip = tooltipUI:FindFirstChild("Tooltip")
	if not tooltip then return end
	
	updateTooltip(petModel)
	
	-- Position tooltip near mouse but keep on screen
	local viewportSize = camera.ViewportSize
	local tooltipSize = tooltip.AbsoluteSize
	
	local posX = screenPosition.X + 15
	local posY = screenPosition.Y + 15
	
	-- Keep on screen
	if posX + tooltipSize.X > viewportSize.X then
		posX = screenPosition.X - tooltipSize.X - 15
	end
	if posY + tooltipSize.Y > viewportSize.Y then
		posY = screenPosition.Y - tooltipSize.Y - 15
	end
	
	tooltip.Position = UDim2.new(0, posX, 0, posY)
	
	if not tooltip.Visible then
		tooltip.Visible = true
		tooltip.BackgroundTransparency = 1
		TweenService:Create(tooltip, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.1
		}):Play()
	end
	
	currentHoveredPet = petModel
end

-- Hide tooltip
local function hideTooltip()
	if not tooltipUI then return end
	
	local tooltip = tooltipUI:FindFirstChild("Tooltip")
	if tooltip and tooltip.Visible then
		TweenService:Create(tooltip, TweenInfo.new(0.1), {
			BackgroundTransparency = 1
		}):Play()
		task.wait(0.1)
		tooltip.Visible = false
	end
	
	currentHoveredPet = nil
end

-- Check if a model is a pet
local function isPetModel(model)
	if not model or not model:IsA("Model") then return false end
	
	-- Check for PetType attribute
	if model:GetAttribute("PetType") then return true end
	
	-- Check if in Pets folder or has pet naming convention
	local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
	if petsFolder then
		for _, petTemplate in ipairs(petsFolder:GetChildren()) do
			if model.Name:find(petTemplate.Name) then
				return true
			end
		end
	end
	
	return false
end

-- Raycast from mouse to find pet
local function getHoveredPet()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local result = workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)
	
	if result and result.Instance then
		local hitPart = result.Instance
		local model = hitPart:FindFirstAncestorWhichIsA("Model")
		
		if model and isPetModel(model) then
			return model, mouseLocation
		end
	end
	
	return nil, mouseLocation
end

-- Update loop
local function update()
	local hoveredPet, mousePos = getHoveredPet()
	
	if hoveredPet then
		if hoveredPet ~= currentHoveredPet then
			showTooltip(hoveredPet, mousePos)
		else
			-- Update position as mouse moves
			local tooltip = tooltipUI and tooltipUI:FindFirstChild("Tooltip")
			if tooltip and tooltip.Visible then
				local viewportSize = camera.ViewportSize
				local tooltipSize = tooltip.AbsoluteSize
				
				local posX = mousePos.X + 15
				local posY = mousePos.Y + 15
				
				if posX + tooltipSize.X > viewportSize.X then
					posX = mousePos.X - tooltipSize.X - 15
				end
				if posY + tooltipSize.Y > viewportSize.Y then
					posY = mousePos.Y - tooltipSize.Y - 15
				end
				
				tooltip.Position = UDim2.new(0, posX, 0, posY)
			end
		end
	else
		if currentHoveredPet then
			hideTooltip()
		end
	end
end

-- Initialize
task.spawn(function()
	player.CharacterAdded:Wait()
	task.wait(0.5)
	
	createTooltip()
	
	RunService.Heartbeat:Connect(update)
end)

return PetHoverStats
