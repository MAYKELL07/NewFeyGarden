-- NPCUIHandler.client.luau
-- Handles NPC display with preset camera positions and dialog UI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local NPCModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NPCModule"))

local NPCUIHandler = {}

-- State
local currentNPC = nil
local currentDialogIndex = 1
local currentDialogSequence = {}
local isNPCActive = false
local originalCameraCFrame = nil
local originalCameraType = nil

-- UI References
local npcContainer = nil
local dialogBox = nil
local npcNameLabel = nil
local npcTitleLabel = nil
local dialogText = nil
local continueButton = nil
local closeButton = nil

-- Create NPC UI
function NPCUIHandler.Initialize()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NPCInterface"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Main Container (bottom section - like the reference image)
	npcContainer = Instance.new("Frame")
	npcContainer.Name = "NPCContainer"
	npcContainer.Size = UDim2.new(0.6, 0, 0.35, 0)
	npcContainer.Position = UDim2.new(0.2, 0, 1, 0) -- Start off-screen (bottom)
	npcContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	npcContainer.BackgroundTransparency = 0.15
	npcContainer.BorderSizePixel = 0
	npcContainer.Parent = screenGui
	
	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 20)
	containerCorner.Parent = npcContainer
	
	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
	})
	gradient.Rotation = 90
	gradient.Parent = npcContainer
	
	-- NPC Header
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "HeaderFrame"
	headerFrame.Size = UDim2.new(1, 0, 0.25, 0)
	headerFrame.Position = UDim2.new(0, 0, 0, 0)
	headerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	headerFrame.BackgroundTransparency = 0.3
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = npcContainer
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 20)
	headerCorner.Parent = headerFrame
	
	-- NPC Name
	npcNameLabel = Instance.new("TextLabel")
	npcNameLabel.Name = "NPCName"
	npcNameLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
	npcNameLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
	npcNameLabel.BackgroundTransparency = 1
	npcNameLabel.Font = Enum.Font.GothamBold
	npcNameLabel.TextSize = 24
	npcNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	npcNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	npcNameLabel.Text = "NPC Name"
	npcNameLabel.Parent = headerFrame
	
	-- NPC Title
	npcTitleLabel = Instance.new("TextLabel")
	npcTitleLabel.Name = "NPCTitle"
	npcTitleLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
	npcTitleLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
	npcTitleLabel.BackgroundTransparency = 1
	npcTitleLabel.Font = Enum.Font.Gotham
	npcTitleLabel.TextSize = 14
	npcTitleLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
	npcTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	npcTitleLabel.Text = "Shopkeeper"
	npcTitleLabel.Parent = headerFrame
	
	-- Close Button (X in top right)
	closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -60, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 24
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Text = "✕"
	closeButton.Parent = headerFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 12)
	closeCorner.Parent = closeButton
	
	-- Dialog Box
	dialogBox = Instance.new("Frame")
	dialogBox.Name = "DialogBox"
	dialogBox.Size = UDim2.new(0.9, 0, 0.6, 0)
	dialogBox.Position = UDim2.new(0.05, 0, 0.3, 0)
	dialogBox.BackgroundTransparency = 1
	dialogBox.BorderSizePixel = 0
	dialogBox.Parent = npcContainer
	
	-- Dialog Text
	dialogText = Instance.new("TextLabel")
	dialogText.Name = "DialogText"
	dialogText.Size = UDim2.new(1, 0, 0.7, 0)
	dialogText.Position = UDim2.new(0, 0, 0, 0)
	dialogText.BackgroundTransparency = 1
	dialogText.Font = Enum.Font.Gotham
	dialogText.TextSize = 20
	dialogText.TextColor3 = Color3.fromRGB(255, 255, 255)
	dialogText.TextWrapped = true
	dialogText.TextYAlignment = Enum.TextYAlignment.Top
	dialogText.TextXAlignment = Enum.TextXAlignment.Left
	dialogText.Text = "Dialog text goes here..."
	dialogText.Parent = dialogBox
	
	-- Continue Button
	continueButton = Instance.new("TextButton")
	continueButton.Name = "ContinueButton"
	continueButton.Size = UDim2.new(0.3, 0, 0.2, 0)
	continueButton.Position = UDim2.new(0.35, 0, 0.78, 0)
	continueButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	continueButton.BorderSizePixel = 0
	continueButton.Font = Enum.Font.GothamBold
	continueButton.TextSize = 18
	continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	continueButton.Text = "Continue ▶"
	continueButton.Parent = dialogBox
	
	local continueCorner = Instance.new("UICorner")
	continueCorner.CornerRadius = UDim.new(0, 10)
	continueCorner.Parent = continueButton
	
	-- Button hover effects
	NPCUIHandler.AddButtonHover(continueButton)
	NPCUIHandler.AddButtonHover(closeButton)
	
	-- Button connections
	continueButton.MouseButton1Click:Connect(function()
		NPCUIHandler.NextDialog()
	end)
	
	closeButton.MouseButton1Click:Connect(function()
		NPCUIHandler.CloseNPC()
	end)
	
	print("[NPCUIHandler] Interface initialized")
end

-- Add button hover effect
function NPCUIHandler.AddButtonHover(button)
	local originalColor = button.BackgroundColor3
	
	button.MouseEnter:Connect(function()
		local tween = TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(
				math.min(255, originalColor.R * 255 + 30),
				math.min(255, originalColor.G * 255 + 30),
				math.min(255, originalColor.B * 255 + 30)
			)
		})
		tween:Play()
	end)
	
	button.MouseLeave:Connect(function()
		local tween = TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = originalColor
		})
		tween:Play()
	end)
end

-- Move camera to preset position
function NPCUIHandler.MoveCameraToNPC(cameraPartName)
	local cameraPart = workspace:FindFirstChild(cameraPartName)
	if not cameraPart then
		warn("[NPCUIHandler] Camera part not found:", cameraPartName)
		return
	end
	
	-- Store original camera settings
	originalCameraCFrame = camera.CFrame
	originalCameraType = camera.CameraType
	
	-- Set camera to scripted mode
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Tween camera to preset position
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(camera, tweenInfo, {
		CFrame = cameraPart.CFrame
	})
	tween:Play()
	
	print("[NPCUIHandler] Camera moved to:", cameraPartName)
end

-- Restore camera to original position
function NPCUIHandler.RestoreCamera()
	if not originalCameraCFrame then return end
	
	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(camera, tweenInfo, {
		CFrame = originalCameraCFrame
	})
	tween:Play()
	
	tween.Completed:Connect(function()
		-- Restore camera type
		if originalCameraType then
			camera.CameraType = originalCameraType
			originalCameraType = nil
		end
		originalCameraCFrame = nil
	end)
	
	print("[NPCUIHandler] Camera restored")
end

-- Show NPC with dialog
function NPCUIHandler.ShowNPC(npcType, dialogCategory)
	if isNPCActive then
		NPCUIHandler.CloseNPC()
		wait(0.5)
	end
	
	local npcInfo = NPCModule.GetNPCInfo(npcType)
	if not npcInfo then
		warn("[NPCUIHandler] Invalid NPC type:", npcType)
		return
	end
	
	currentNPC = npcType
	currentDialogSequence = NPCModule.GetDialogSequence(npcType, dialogCategory)
	currentDialogIndex = 1
	isNPCActive = true
	
	-- Update NPC info
	npcNameLabel.Text = npcInfo.Icon .. " " .. npcInfo.Name
	npcTitleLabel.Text = npcInfo.Shopkeeper
	npcNameLabel.TextColor3 = npcInfo.Color
	
	-- Show first dialog
	if #currentDialogSequence > 0 then
		NPCUIHandler.ShowDialog(currentDialogSequence[currentDialogIndex])
	else
		dialogText.Text = "..."
	end
	
	-- Slide up animation
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(npcContainer, tweenInfo, {
		Position = UDim2.new(0.2, 0, 0.63, 0)
	})
	tween:Play()
	
	-- Move camera to NPC
	NPCUIHandler.MoveCameraToNPC(npcInfo.CameraPartName)
	
	print("[NPCUIHandler] Showing NPC:", npcInfo.Name)
end

-- Show dialog text with typewriter effect
function NPCUIHandler.ShowDialog(text)
	dialogText.Text = ""
	
	-- Typewriter effect
	for i = 1, #text do
		dialogText.Text = string.sub(text, 1, i)
		wait(0.03)
	end
	
	-- Update button text
	if currentDialogIndex >= #currentDialogSequence then
		continueButton.Text = "Finish ✓"
	else
		continueButton.Text = "Continue ▶"
	end
end

-- Next dialog in sequence
function NPCUIHandler.NextDialog()
	if currentDialogIndex >= #currentDialogSequence then
		NPCUIHandler.CloseNPC()
		return
	end
	
	currentDialogIndex = currentDialogIndex + 1
	NPCUIHandler.ShowDialog(currentDialogSequence[currentDialogIndex])
end

-- Close NPC interface
function NPCUIHandler.CloseNPC()
	if not isNPCActive then return end
	
	isNPCActive = false
	currentNPC = nil
	currentDialogSequence = {}
	currentDialogIndex = 1
	
	-- Slide down animation
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	local tween = TweenService:Create(npcContainer, tweenInfo, {
		Position = UDim2.new(0.2, 0, 1, 0)
	})
	tween:Play()
	
	-- Restore camera
	NPCUIHandler.RestoreCamera()
	
	print("[NPCUIHandler] Closed NPC")
end

-- Public functions for triggering NPCs
function NPCUIHandler.ShowSeedShop()
	NPCUIHandler.ShowNPC(NPCModule.NPC_TYPES.SEED_SHOP, "Welcome")
end

function NPCUIHandler.ShowFruitSeller()
	NPCUIHandler.ShowNPC(NPCModule.NPC_TYPES.FRUIT_SELLER, "Welcome")
end

function NPCUIHandler.ShowPetStore()
	NPCUIHandler.ShowNPC(NPCModule.NPC_TYPES.PET_STORE, "Welcome")
end

return NPCUIHandler
