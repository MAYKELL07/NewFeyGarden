-- LoadingScreen.client.luau
-- Handles the loading screen with progress bar
-- Feature 8: Blurred background with preplaced camera (e.g., LobbyCameraPart)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Configuration
local LOBBY_CAMERA_PART_NAME = "LobbyCameraPart" -- The preplaced camera part in workspace
local BLUR_SIZE = 24 -- Blur amount during loading

-- Loading state tracking
local loadingStates = {
	character = false,
	sharedModules = false,
	uiHandler = false,
	remoteEvents = false,
	playerData = false,
	gardenAssigned = false,
}

-- Store original camera settings
local originalCameraType = nil
local originalCameraCFrame = nil
local blurEffect = nil

-- Wait for UI
local screenGui = playerGui:WaitForChild("FeyGardenUI", 10)
if not screenGui then
	-- Attempt to build UI on the fly if it wasn't created
	local setupModule = game:GetService("ReplicatedStorage"):FindFirstChild("Setup")
	if setupModule and setupModule:FindFirstChild("UISetup") then
		pcall(function()
			require(setupModule.UISetup).CreateUI()
		end)
		screenGui = playerGui:WaitForChild("FeyGardenUI", 5)
	end
	if not screenGui then
		warn("[LoadingScreen] FeyGardenUI not found!")
		return
	end
end

local loadingScreen = screenGui:FindFirstChild("LoadingScreen", true)
if not loadingScreen then
	local uiRoot = screenGui:FindFirstChild("UIRoot")
	if uiRoot then
		local overlayGroup = uiRoot:FindFirstChild("OverlayGroup")
		if overlayGroup then
			loadingScreen = overlayGroup:FindFirstChild("LoadingScreen")
			if not loadingScreen then
				loadingScreen = overlayGroup:WaitForChild("LoadingScreen", 5)
			end
		end
	end
	if not loadingScreen then
		warn("[LoadingScreen] LoadingScreen not found!")
		return
	end
end

local progressBarFill = loadingScreen:WaitForChild("ProgressBarBg"):WaitForChild("ProgressBarFill")
local percentLabel = loadingScreen:WaitForChild("ProgressBarBg"):WaitForChild("PercentLabel")
local loadingLabel = loadingScreen:WaitForChild("LoadingLabel")
local uiRoot = screenGui:FindFirstChild("UIRoot")
local hudGroup = uiRoot and uiRoot:FindFirstChild("HUDGroup")

-- Loading tips to rotate
local tips = {
	"💡 Tip: Water your plants during rainy weather for bonus growth!",
	"💡 Tip: Different weather types boost different plants!",
	"💡 Tip: Pets can speed up your plant growth!",
	"💡 Tip: Harvest fruits to sell for coins!",
	"💡 Tip: Press B to open your inventory!",
	"💡 Tip: Use number keys 1-6 to select hotbar slots!",
	"💡 Tip: Storm weather gives the biggest growth boost!",
	"💡 Tip: Glowbuds emit magical light at night!",
	"💡 Tip: Place pets in your garden to boost nearby plants!",
	"💡 Tip: Visit the Pet Shop to buy eggs with rare pets!",
	"💡 Tip: Trade with friends using the trade button!",
	"💡 Tip: Rarer seeds grow more valuable fruits!",
	"💡 Tip: Check the shop for rotating seed stock!",
}

local tipLabel = loadingScreen:FindFirstChild("TipLabel")
local currentTipIndex = math.random(1, #tips)
if tipLabel then
	tipLabel.Text = tips[currentTipIndex]
end

-- Rotate tips every few seconds during loading
local tipRotationConnection = nil
local function startTipRotation()
	if not tipLabel then return end
	tipRotationConnection = task.spawn(function()
		while tipLabel and tipLabel.Parent do
			task.wait(4) -- Change tip every 4 seconds
			currentTipIndex = (currentTipIndex % #tips) + 1
			-- Fade out, change, fade in
			TweenService:Create(tipLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
			task.wait(0.3)
			if tipLabel and tipLabel.Parent then
				tipLabel.Text = tips[currentTipIndex]
				TweenService:Create(tipLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			end
		end
	end)
end

-- Setup lobby camera
local function setupLobbyCamera()
	-- Wait a moment for workspace to fully load
	task.wait(0.1)
	
	-- Find the preplaced camera part - check multiple locations
	local lobbyCameraPart = nil
	
	-- First try direct child of workspace
	lobbyCameraPart = workspace:FindFirstChild(LOBBY_CAMERA_PART_NAME)
	
	-- Try recursive search
	if not lobbyCameraPart then
		lobbyCameraPart = workspace:FindFirstChild(LOBBY_CAMERA_PART_NAME, true)
	end
	
	-- Try WaitForChild with timeout
	if not lobbyCameraPart then
		lobbyCameraPart = workspace:WaitForChild(LOBBY_CAMERA_PART_NAME, 3)
	end
	
	-- Search through all descendants as last resort
	if not lobbyCameraPart then
		for _, descendant in ipairs(workspace:GetDescendants()) do
			if descendant.Name == LOBBY_CAMERA_PART_NAME and descendant:IsA("BasePart") then
				lobbyCameraPart = descendant
				break
			end
		end
	end
	
	if lobbyCameraPart and lobbyCameraPart:IsA("BasePart") then
		-- Store original camera settings
		originalCameraType = camera.CameraType
		originalCameraCFrame = camera.CFrame
		
		-- Set camera to scriptable and move to lobby camera
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = lobbyCameraPart.CFrame
		
		return true
	else
		warn("[LoadingScreen] Lobby camera part not found:", LOBBY_CAMERA_PART_NAME, "- Skipping lobby camera")
		return false
	end
end

-- Add blur effect
local function addBlurEffect()
	-- Check if blur already exists
	blurEffect = Lighting:FindFirstChild("LoadingBlur")
	
	if not blurEffect then
		blurEffect = Instance.new("BlurEffect")
		blurEffect.Name = "LoadingBlur"
		blurEffect.Size = 0
		blurEffect.Parent = Lighting
	end
	
	-- Animate blur in
	TweenService:Create(blurEffect, TweenInfo.new(0.5), {
		Size = BLUR_SIZE
	}):Play()
end

-- Remove blur effect
local function removeBlurEffect()
	if blurEffect then
		-- Animate blur out
		local tweenOut = TweenService:Create(blurEffect, TweenInfo.new(0.5), {
			Size = 0
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		
		blurEffect:Destroy()
		blurEffect = nil
	end
end

-- Restore camera to player
local function restoreCamera()
	if originalCameraType then
		camera.CameraType = originalCameraType
		originalCameraType = nil
	end
	
	if originalCameraCFrame then
		-- Don't restore CFrame, let the player camera system handle it
		originalCameraCFrame = nil
	end
	
	-- Set to custom to allow player control
	camera.CameraType = Enum.CameraType.Custom
end

-- Calculate progress based on loading states
local function calculateProgress(): number
	local completed = 0
	local total = 0
	
	-- Weight each step (total = 1.0)
	local weights = {
		character = 0.10,
		sharedModules = 0.15,
		remoteEvents = 0.15,
		uiHandler = 0.25,
		playerData = 0.20,
		gardenAssigned = 0.15,
	}
	
	for state, weight in pairs(weights) do
		total = total + weight
		if loadingStates[state] then
			completed = completed + weight
		end
	end
	
	return completed / total
end

-- Hide all HUD elements during loading
local function hideAllHUD()
	if not screenGui then return end

	if hudGroup and hudGroup:IsA("GuiObject") then
		hudGroup.Visible = false
	end

	local elementsToHide = {
		"CurrencyFrame",
		"WeatherFrame",
		"HotbarFrame",
		"PetsButton",
		"NavigationFrame",
		"NotificationContainer",
		"SidePanel",
	}

	local containers = {hudGroup, uiRoot, screenGui}
	for _, container in ipairs(containers) do
		if container then
			for _, elementName in ipairs(elementsToHide) do
				local element = container:FindFirstChild(elementName, true)
				if element and element:IsA("GuiObject") then
					element.Visible = false
				end
			end
		end
	end
end

-- Show all HUD elements after loading
local function showAllHUD()
	if not screenGui then return end

	if hudGroup and hudGroup:IsA("GuiObject") then
		hudGroup.Visible = true
	end

	local elementsToShow = {
		"CurrencyFrame",
		"WeatherFrame",
		"HotbarFrame",
		"PetsButton",
		"NavigationFrame",
		"NotificationContainer",
		"SidePanel",
	}

	local containers = {hudGroup, uiRoot, screenGui}
	for _, container in ipairs(containers) do
		if container then
			for _, elementName in ipairs(elementsToShow) do
				local element = container:FindFirstChild(elementName, true)
				if element and element:IsA("GuiObject") then
					element.Visible = true
				end
			end
		end
	end
end

-- Update progress bar
local function updateProgress(progress, message)
	progress = math.clamp(progress, 0, 1)
	local percent = math.floor(progress * 100)
	
	-- Smooth tween
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(progressBarFill, tweenInfo, {
		Size = UDim2.new(progress, 0, 1, 0)
	})
	tween:Play()
	
	percentLabel.Text = percent .. "%"
	
	if message then
		loadingLabel.Text = message
	end
end

-- Make loading screen background transparent (blur handles visuals)
local function setupLoadingScreenForBlur()
	-- Make loading screen semi-transparent to show blurred background
	loadingScreen.BackgroundTransparency = 0.3
	loadingScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	
	-- Add a subtle gradient overlay
	local gradient = loadingScreen:FindFirstChild("LoadingGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "LoadingGradient"
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 20, 50))
		})
		gradient.Rotation = 45
		gradient.Parent = loadingScreen
	end
end

-- Loading sequence
local function loadGame()
	-- Make loading screen visible immediately
	loadingScreen.Visible = true
	
	-- Setup camera and blur
	setupLoadingScreenForBlur()
	setupLobbyCamera()
	addBlurEffect()
	
	-- Hide all HUD elements during loading
	hideAllHUD()
	
	-- Start rotating tips
	startTipRotation()
	
	-- Get references to modules/events we need to wait for
	local clientFolder = script.Parent
	local UIHandler = nil
	local Constants = nil
	local Config = nil
	
	-- =========================================================================
	-- Step 1: Wait for character (REAL)
	-- =========================================================================
	updateProgress(calculateProgress(), "Loading character...")
	local character = player.Character or player.CharacterAdded:Wait()
	loadingStates.character = true
	updateProgress(calculateProgress(), "Character loaded!")
	
	-- =========================================================================
	-- Step 2: Load shared modules (REAL)
	-- =========================================================================
	updateProgress(calculateProgress(), "Loading game modules...")
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	if sharedFolder then
		-- Load critical modules
		local criticalModules = {"Constants", "Config", "PlantModule", "BuffsModule"}
		for _, moduleName in ipairs(criticalModules) do
			local module = sharedFolder:WaitForChild(moduleName, 5)
			if module then
				pcall(function()
					local loaded = require(module)
					if moduleName == "Constants" then
						Constants = loaded
					elseif moduleName == "Config" then
						Config = loaded
					end
				end)
			end
		end
	end
	loadingStates.sharedModules = true
	updateProgress(calculateProgress(), "Game modules loaded!")
	
	-- =========================================================================
	-- Step 3: Wait for remote events to exist (REAL)
	-- =========================================================================
	updateProgress(calculateProgress(), "Connecting to server...")
	
	-- Wait for critical remote events to be created by server
	local eventsToWait = {}
	if Constants and Constants.EVENTS then
		eventsToWait = {
			Constants.EVENTS.UPDATE_CURRENCY,
			Constants.EVENTS.UPDATE_INVENTORY,
		}
	else
		eventsToWait = {"UpdateCurrency", "UpdateInventory"}
	end
	
	for _, eventName in ipairs(eventsToWait) do
		ReplicatedStorage:WaitForChild(eventName, 10)
	end
	loadingStates.remoteEvents = true
	updateProgress(calculateProgress(), "Connected to server!")
	
	-- =========================================================================
	-- Step 4: Wait for UIHandler to be ready (REAL)
	-- =========================================================================
	updateProgress(calculateProgress(), "Initializing interface...")
	
	pcall(function()
		UIHandler = require(clientFolder:WaitForChild("UIHandler", 10))
	end)
	
	if UIHandler then
		-- Wait for UIHandler.IsReady with timeout
		local startTime = tick()
		local maxWaitTime = 20 -- seconds
		
		while not UIHandler.IsReady and (tick() - startTime) < maxWaitTime do
			updateProgress(calculateProgress(), "Initializing interface...")
			task.wait(0.1)
		end
		
		if UIHandler.IsReady then
			loadingStates.uiHandler = true
			updateProgress(calculateProgress(), "Interface ready!")
		end
	end
	
	-- =========================================================================
	-- Step 5: Wait for player data sync (REAL - listen for first inventory update)
	-- =========================================================================
	updateProgress(calculateProgress(), "Syncing player data...")
	
	local dataReceived = false
	local dataConnection = nil
	
	-- Listen for the first inventory update from server
	local updateInventoryEvent = ReplicatedStorage:FindFirstChild(
		Constants and Constants.EVENTS and Constants.EVENTS.UPDATE_INVENTORY or "UpdateInventory"
	)
	
	if updateInventoryEvent and updateInventoryEvent:IsA("RemoteEvent") then
		dataConnection = updateInventoryEvent.OnClientEvent:Once(function()
			dataReceived = true
		end)
	end
	
	-- Also check for currency update
	local updateCurrencyEvent = ReplicatedStorage:FindFirstChild(
		Constants and Constants.EVENTS and Constants.EVENTS.UPDATE_CURRENCY or "UpdateCurrency"
	)
	
	if updateCurrencyEvent and updateCurrencyEvent:IsA("RemoteEvent") then
		updateCurrencyEvent.OnClientEvent:Once(function()
			dataReceived = true
		end)
	end
	
	-- Wait for data with timeout
	local dataStartTime = tick()
	local dataMaxWait = 10 -- seconds
	
	while not dataReceived and (tick() - dataStartTime) < dataMaxWait do
		updateProgress(calculateProgress(), "Syncing player data...")
		task.wait(0.1)
	end
	
	loadingStates.playerData = true
	updateProgress(calculateProgress(), "Player data synced!")
	
	-- =========================================================================
	-- Step 6: Wait for garden assignment (REAL)
	-- =========================================================================
	updateProgress(calculateProgress(), "Preparing garden...")
	
	local gardensFolderName = Config and Config.World and Config.World.GardensFolder or "Gardens"
	local gardensFolder = workspace:WaitForChild(gardensFolderName, 10)
	
	if gardensFolder then
		-- Check if we already have a garden assigned
		local gardenAssigned = false
		
		local function checkForGarden()
			for _, garden in ipairs(gardensFolder:GetChildren()) do
				if garden:IsA("Folder") and garden:GetAttribute("OwnerUserId") == player.UserId then
					return true
				end
			end
			return false
		end
		
		-- Initial check
		gardenAssigned = checkForGarden()
		
		-- If not assigned, wait for attribute change
		if not gardenAssigned then
			local gardenStartTime = tick()
			local gardenMaxWait = 10 -- seconds
			
			while not gardenAssigned and (tick() - gardenStartTime) < gardenMaxWait do
				gardenAssigned = checkForGarden()
				if not gardenAssigned then
					updateProgress(calculateProgress(), "Preparing garden...")
					task.wait(0.2)
				end
			end
		end
		
		loadingStates.gardenAssigned = true
		updateProgress(calculateProgress(), "Garden ready!")
	else
		-- No gardens folder, skip this step
		loadingStates.gardenAssigned = true
	end
	
	-- =========================================================================
	-- Step 7: Complete
	-- =========================================================================
	updateProgress(1, "Welcome to FeyGarden!")
	task.wait(0.8)
	
	-- Fade out the entire loading screen
	for _, child in ipairs(loadingScreen:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(1), {
				TextTransparency = 1
			}):Play()
		end
	end
	
	local fadeOut = TweenService:Create(loadingScreen, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	})
	
	-- Start restoring camera and removing blur
	restoreCamera()
	removeBlurEffect()
	
	fadeOut:Play()
	fadeOut.Completed:Wait()
	
	-- Show all HUD elements now that loading is complete
	showAllHUD()
	
	loadingScreen.Visible = false
	loadingScreen:Destroy()
end

-- Start loading
task.spawn(loadGame)
