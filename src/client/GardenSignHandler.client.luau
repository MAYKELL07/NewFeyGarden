-- GardenSignHandler.client.luau
-- Handles garden sign UI with player avatar, name, level, likes
-- Feature 1: Garden signs show avatar (right), player name, garden level, likes count
-- Only other players can like (not the owner)
-- Uses the EXISTING SurfaceGui on the PlayerSign

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not sharedFolder then
	warn("[GardenSignHandler] Shared folder not found")
	return
end

local Config = require(sharedFolder:WaitForChild("Config"))

local player = Players.LocalPlayer

local GardenSignHandler = {}

-- Theme colors (matching UIHandler)
local THEME = {
	ForestDark = Color3.fromRGB(18, 10, 28),
	ForestDeep = Color3.fromRGB(28, 16, 40),
	TealGem = Color3.fromRGB(86, 108, 186),
	GoldLeaf = Color3.fromRGB(210, 168, 120),
	TextLight = Color3.fromRGB(228, 218, 240),
	TextGold = Color3.fromRGB(210, 190, 230),
	HeartRed = Color3.fromRGB(255, 100, 120),
}


-- Setup the existing SurfaceGui on a garden sign
local function setupSignSurfaceGui(garden, ownerUserId, ownerName, gardenLevel, likeCount)
	local signModel = garden:FindFirstChild(Config.World.PlayerSignName)
	if not signModel then return nil end
	
	local signPart = signModel:FindFirstChild(Config.World.PlayerSignPartName)
	if not signPart or not signPart:IsA("BasePart") then
		-- Try to find any BasePart in the sign model
		signPart = signModel:FindFirstChildWhichIsA("BasePart")
	end
	if not signPart then return nil end
	
	-- Find the existing SurfaceGui
	local surfaceGui = signPart:FindFirstChildOfClass("SurfaceGui")
	if not surfaceGui then
		-- Create one if missing
		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "SignSurfaceGui"
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surfaceGui.PixelsPerStud = 50
		surfaceGui.Parent = signPart
	end
	
	-- Clear existing content
	for _, child in ipairs(surfaceGui:GetChildren()) do
		if child.Name == "GardenSignContent" then
			child:Destroy()
		end
	end
	
	-- Create main content frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "GardenSignContent"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = THEME.ForestDark
	mainFrame.BackgroundTransparency = 0.7
	mainFrame.Parent = surfaceGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.TealGem
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = mainFrame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = mainFrame
	
	-- Left side: Name, level, and likes
	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "InfoFrame"
	infoFrame.Size = UDim2.new(0.6, 0, 1, 0)
	infoFrame.Position = UDim2.new(0, 0, 0, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Parent = mainFrame
	
	local infoLayout = Instance.new("UIListLayout")
	infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.Padding = UDim.new(0, 4)
	infoLayout.Parent = infoFrame
	
	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.LayoutOrder = 1
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ownerName
	nameLabel.TextColor3 = THEME.TextLight
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 20
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = infoFrame
	
	-- Garden level
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 0, 18)
	levelLabel.LayoutOrder = 2
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "🌿 Level " .. tostring(gardenLevel)
	levelLabel.TextColor3 = THEME.TextGold
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextSize = 16
	levelLabel.TextScaled = true
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = infoFrame
	
	-- Likes row
	local likesFrame = Instance.new("Frame")
	likesFrame.Name = "LikesFrame"
	likesFrame.Size = UDim2.new(1, 0, 0, 22)
	likesFrame.LayoutOrder = 3
	likesFrame.BackgroundTransparency = 1
	likesFrame.Parent = infoFrame
	
	local likesLayout = Instance.new("UIListLayout")
	likesLayout.FillDirection = Enum.FillDirection.Horizontal
	likesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	likesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	likesLayout.Padding = UDim.new(0, 6)
	likesLayout.Parent = likesFrame
	
	-- Heart icon
	local heartLabel = Instance.new("TextLabel")
	heartLabel.Name = "HeartIcon"
	heartLabel.Size = UDim2.new(0, 22, 0, 22)
	heartLabel.LayoutOrder = 1
	heartLabel.BackgroundColor3 = THEME.ForestDeep
	heartLabel.BackgroundTransparency = 0.5
	heartLabel.Text = "❤️"
	heartLabel.TextSize = 14
	heartLabel.Font = Enum.Font.GothamBold
	heartLabel.Parent = likesFrame
	
	local heartCorner = Instance.new("UICorner")
	heartCorner.CornerRadius = UDim.new(0.5, 0)
	heartCorner.Parent = heartLabel
	
	-- Like count
	local likeCountLabel = Instance.new("TextLabel")
	likeCountLabel.Name = "LikeCount"
	likeCountLabel.Size = UDim2.new(0, 40, 0, 22)
	likeCountLabel.LayoutOrder = 2
	likeCountLabel.BackgroundTransparency = 1
	likeCountLabel.Text = tostring(likeCount or 0)
	likeCountLabel.TextColor3 = THEME.HeartRed
	likeCountLabel.Font = Enum.Font.GothamBold
	likeCountLabel.TextSize = 16
	likeCountLabel.TextScaled = true
	likeCountLabel.TextXAlignment = Enum.TextXAlignment.Left
	likeCountLabel.Parent = likesFrame
	
	-- Right side: Avatar
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.new(0.35, 0, 0.9, 0)
	avatarFrame.Position = UDim2.new(0.62, 0, 0.05, 0)
	avatarFrame.BackgroundColor3 = THEME.ForestDeep
	avatarFrame.Parent = mainFrame
	
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0.5, 0)
	avatarCorner.Parent = avatarFrame
	
	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = THEME.GoldLeaf
	avatarStroke.Thickness = 2
	avatarStroke.Parent = avatarFrame
	
	local avatarAspect = Instance.new("UIAspectRatioConstraint")
	avatarAspect.AspectRatio = 1
	avatarAspect.Parent = avatarFrame
	
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
	
	return surfaceGui
end

-- Scan all gardens and setup sign surface GUIs
local function setupAllGardenSigns()
	local gardensFolder = workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then
		warn("[GardenSignHandler] Gardens folder not found:", Config.World.GardensFolder)
		return
	end
	
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local ownerUserId = garden:GetAttribute("OwnerUserId")
			if ownerUserId and ownerUserId > 0 then
				-- Get owner info
				local ownerName = "Unknown"
				local success, playerInfo = pcall(function()
					return Players:GetNameFromUserIdAsync(ownerUserId)
				end)
				if success then
					ownerName = playerInfo
				end
				
				-- Get garden level (from attribute or default to 1)
				local gardenLevel = garden:GetAttribute("GardenLevel") or 1
				
				-- Get like count (from attribute or default to 0)
				local likeCount = garden:GetAttribute("Likes") or 0
				
				setupSignSurfaceGui(garden, ownerUserId, ownerName, gardenLevel, likeCount)
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
				if ownerUserId and ownerUserId > 0 then
					task.wait(0.2) -- Wait for other attributes to update
					
					local ownerName = "Unknown"
					pcall(function()
						ownerName = Players:GetNameFromUserIdAsync(ownerUserId)
					end)
					
					local gardenLevel = garden:GetAttribute("GardenLevel") or 1
					local likeCount = garden:GetAttribute("Likes") or 0
					
					setupSignSurfaceGui(garden, ownerUserId, ownerName, gardenLevel, likeCount)
				else
					-- Clear sign content if garden is unowned
					local signModel = garden:FindFirstChild(Config.World.PlayerSignName)
					if signModel then
						local signPart = signModel:FindFirstChild(Config.World.PlayerSignPartName) or signModel:FindFirstChildWhichIsA("BasePart")
						if signPart then
							local surfaceGui = signPart:FindFirstChildOfClass("SurfaceGui")
							if surfaceGui then
								local content = surfaceGui:FindFirstChild("GardenSignContent")
								if content then
									content:Destroy()
								end
							end
						end
					end
				end
			end)
			
			-- Watch for like count changes
			garden:GetAttributeChangedSignal("Likes"):Connect(function()
				local signModel = garden:FindFirstChild(Config.World.PlayerSignName)
				if signModel then
					local signPart = signModel:FindFirstChild(Config.World.PlayerSignPartName) or signModel:FindFirstChildWhichIsA("BasePart")
					if signPart then
						local surfaceGui = signPart:FindFirstChildOfClass("SurfaceGui")
						if surfaceGui then
							local content = surfaceGui:FindFirstChild("GardenSignContent")
							if content then
								local infoFrame = content:FindFirstChild("InfoFrame")
								if infoFrame then
									local likesFrame = infoFrame:FindFirstChild("LikesFrame")
									if likesFrame then
										local likeCountLabel = likesFrame:FindFirstChild("LikeCount")
										if likeCountLabel then
											likeCountLabel.Text = tostring(garden:GetAttribute("Likes") or 0)
										end
									end
								end
							end
						end
					end
				end
			end)
		end
	end
end

-- Initialize
task.spawn(function()
	-- Wait for character and gardens to be set up
	player.CharacterAdded:Wait()
	task.wait(1)
	
	setupAllGardenSigns()
	watchGardenChanges()
	
	-- Refresh signs periodically to catch late-joining players
	while true do
		task.wait(10)
		setupAllGardenSigns()
	end
end)

return GardenSignHandler
