-- GardenBillboard.client.luau
-- Feature 7: Billboard GUI hovering over gardens showing "Your Garden" or owner name
-- Shows a circular badge with player avatar and text like in the screenshot

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not sharedFolder then
	warn("[GardenBillboard] Shared folder not found")
	return
end

local Config = require(sharedFolder:WaitForChild("Config"))

local player = Players.LocalPlayer

local GardenBillboard = {}

-- Theme colors
local THEME = {
	BackgroundCyan = Color3.fromRGB(80, 200, 220), -- Cyan background like the screenshot
	BorderDark = Color3.fromRGB(60, 60, 80),
	TextLight = Color3.fromRGB(255, 255, 255),
	TextDark = Color3.fromRGB(40, 40, 50),
}

-- Track billboards
local gardenBillboards = {}

-- Create billboard for a garden
local function createGardenBillboard(garden, ownerUserId, isYourGarden)
	-- Find the Center part in the garden
	local centerPart = garden:FindFirstChild("Center")
	
	if not centerPart or not centerPart:IsA("BasePart") then
		warn("[GardenBillboard] Center part not found in garden:", garden.Name)
		return nil
	end
	
	-- Remove existing billboard
	local existingBillboard = centerPart:FindFirstChild("GardenOwnerBillboard")
	if existingBillboard then
		existingBillboard:Destroy()
	end
	
	-- Create BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GardenOwnerBillboard"
	billboard.Size = UDim2.new(0, 180, 0, 70)
	billboard.StudsOffset = Vector3.new(0, 50, 0) -- High above the garden
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 150
	billboard.LightInfluence = 0
	billboard.Parent = centerPart
	
	-- Main container (pill shaped)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = THEME.BackgroundCyan
	container.BackgroundTransparency = 0
	container.Parent = billboard
	
	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0.5, 0)
	containerCorner.Parent = container
	
	-- Darker border/stroke
	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = THEME.BorderDark
	containerStroke.Thickness = 3
	containerStroke.Parent = container
	
	-- Avatar circle (left side)
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.new(0, 56, 0, 56)
	avatarFrame.Position = UDim2.new(0, 7, 0.5, 0)
	avatarFrame.AnchorPoint = Vector2.new(0, 0.5)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(200, 100, 80) -- Brick/terracotta background
	avatarFrame.Parent = container
	
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0.5, 0)
	avatarCorner.Parent = avatarFrame
	
	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = THEME.BorderDark
	avatarStroke.Thickness = 2
	avatarStroke.Parent = avatarFrame
	
	-- Avatar image
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.Size = UDim2.new(1, -6, 1, -6)
	avatarImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	avatarImage.AnchorPoint = Vector2.new(0.5, 0.5)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Image = ""
	avatarImage.Parent = avatarFrame
	
	local avatarImageCorner = Instance.new("UICorner")
	avatarImageCorner.CornerRadius = UDim.new(0.5, 0)
	avatarImageCorner.Parent = avatarImage
	
	-- Load avatar thumbnail
	task.spawn(function()
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(
				ownerUserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if success and result then
			avatarImage.Image = result
		end
	end)
	
	-- Text label (right side)
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "OwnerText"
	textLabel.Size = UDim2.new(1, -75, 1, 0)
	textLabel.Position = UDim2.new(0, 70, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 18
	textLabel.TextColor3 = THEME.TextDark
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Parent = container
	
	if isYourGarden then
		textLabel.Text = "Your Garden"
	else
		-- Get owner name
		local ownerName = "Unknown"
		local success = pcall(function()
			ownerName = Players:GetNameFromUserIdAsync(ownerUserId)
		end)
		textLabel.Text = ownerName .. "'s\nGarden"
	end
	
	return billboard
end

-- Setup billboards for all gardens
local function setupAllGardenBillboards()
	local gardensFolder = workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then
		warn("[GardenBillboard] Gardens folder not found:", Config.World.GardensFolder)
		return
	end
	
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local ownerUserId = garden:GetAttribute("OwnerUserId")
			
			if ownerUserId and ownerUserId > 0 then
				local isYourGarden = (ownerUserId == player.UserId)
				local billboard = createGardenBillboard(garden, ownerUserId, isYourGarden)
				
				if billboard then
					gardenBillboards[garden] = billboard
				end
			else
				-- Remove billboard if garden is unowned
				if gardenBillboards[garden] then
					gardenBillboards[garden]:Destroy()
					gardenBillboards[garden] = nil
				end
			end
		end
	end
end

-- Watch for garden ownership changes
local function watchGardenChanges()
	local gardensFolder = workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then return end
	
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			garden:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
				local ownerUserId = garden:GetAttribute("OwnerUserId")
				
				-- Remove old billboard
				if gardenBillboards[garden] then
					gardenBillboards[garden]:Destroy()
					gardenBillboards[garden] = nil
				end
				
				if ownerUserId and ownerUserId > 0 then
					task.wait(0.2) -- Wait for other data to settle
					local isYourGarden = (ownerUserId == player.UserId)
					local billboard = createGardenBillboard(garden, ownerUserId, isYourGarden)
					
					if billboard then
						gardenBillboards[garden] = billboard
					end
				end
			end)
		end
	end
	
	-- Watch for new gardens
	gardensFolder.ChildAdded:Connect(function(garden)
		if garden:IsA("Folder") then
			garden:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
				local ownerUserId = garden:GetAttribute("OwnerUserId")
				
				if gardenBillboards[garden] then
					gardenBillboards[garden]:Destroy()
					gardenBillboards[garden] = nil
				end
				
				if ownerUserId and ownerUserId > 0 then
					task.wait(0.2)
					local isYourGarden = (ownerUserId == player.UserId)
					local billboard = createGardenBillboard(garden, ownerUserId, isYourGarden)
					
					if billboard then
						gardenBillboards[garden] = billboard
					end
				end
			end)
		end
	end)
end

-- Initialize
task.spawn(function()
	player.CharacterAdded:Wait()
	task.wait(1)
	
	setupAllGardenBillboards()
	watchGardenChanges()
	
	-- Refresh periodically to catch late-joining players
	while true do
		task.wait(15)
		setupAllGardenBillboards()
	end
end)

return GardenBillboard
