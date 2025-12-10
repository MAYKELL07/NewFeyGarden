-- LoadingScreen.client.luau
-- Handles the loading screen with progress bar

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

local loadingScreen = screenGui:WaitForChild("LoadingScreen", 5)
if not loadingScreen then
	warn("[LoadingScreen] LoadingScreen not found!")
	return
end

local progressBarFill = loadingScreen:WaitForChild("ProgressBarBg"):WaitForChild("ProgressBarFill")
local percentLabel = loadingScreen:WaitForChild("ProgressBarBg"):WaitForChild("PercentLabel")
local loadingLabel = loadingScreen:WaitForChild("LoadingLabel")

-- Loading tips to rotate
local tips = {
	"💡 Tip: Water your plants during rainy weather for bonus growth!",
	"💡 Tip: Different weather types boost different plants!",
	"💡 Tip: Pets can speed up your plant growth!",
	"💡 Tip: Harvest fruits to sell for coins!",
	"💡 Tip: Press B to open your inventory!",
	"💡 Tip: Use number keys 1-6 to select hotbar slots!",
	"💡 Tip: Storm weather gives the biggest growth boost!",
	"💡 Tip: Glowbuds emit magical light at night!"
}

local tipLabel = loadingScreen:FindFirstChild("TipLabel")
if tipLabel then
	tipLabel.Text = tips[math.random(1, #tips)]
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

-- Loading sequence
local function loadGame()
	-- Step 1: Wait for character
	updateProgress(0.1, "Loading character...")
	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(0.5)
	
	-- Step 2: Load shared modules
	updateProgress(0.25, "Loading game modules...")
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
	if sharedFolder then
		for _, module in ipairs(sharedFolder:GetChildren()) do
			if module:IsA("ModuleScript") then
				pcall(function()
					require(module)
				end)
			end
		end
	end
	task.wait(0.5)
	
	-- Step 3: Wait for player data
	updateProgress(0.6, "Loading player data...")
	task.wait(1) -- Give time for server to send data
	
	-- Step 4: Finalizing
	updateProgress(0.85, "Preparing garden...")
	task.wait(0.5)
	
	-- Step 5: Complete
	updateProgress(1, "Ready!")
	task.wait(0.5)
	
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
	
	fadeOut:Play()
	fadeOut.Completed:Wait()
	
	loadingScreen.Visible = false
	loadingScreen:Destroy()
end

-- Start loading
task.spawn(loadGame)
