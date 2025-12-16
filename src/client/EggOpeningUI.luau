-- EggOpeningUI.luau
-- Handles the egg opening animation and reveal sequence

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[EggOpeningUI] Shared folder missing; egg opening disabled")
	return {}
end

local function safeRequire(name)
	local ok, mod = pcall(function()
		return require(sharedFolder:WaitForChild(name, 5))
	end)
	if not ok then
		warn(string.format("[EggOpeningUI] Failed to load %s: %s", name, tostring(mod)))
		return nil
	end
	return mod
end

local Constants = safeRequire("Constants")
local Config = safeRequire("Config")
if not (Constants and Config) then
	return {}
end

local EggOpeningUI = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- State
local isAnimating = false
local currentUI = nil

-- Create the egg opening UI
local function createEggOpeningUI()
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EggOpeningUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100 -- Above other UIs
	
	-- Dark background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1 -- Start invisible
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = screenGui
	
	-- Container for egg and effects
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Position = UDim2.new(0, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.ZIndex = 2
	container.Parent = screenGui
	
	-- Egg image
	local eggImage = Instance.new("ImageLabel")
	eggImage.Name = "EggImage"
	eggImage.Size = UDim2.new(0, 200, 0, 240)
	eggImage.Position = UDim2.new(0.5, -100, 0.5, -120)
	eggImage.BackgroundTransparency = 1
	eggImage.ScaleType = Enum.ScaleType.Fit
	eggImage.ZIndex = 10
	eggImage.Parent = container
	
	-- Glow effect behind egg (for epic/legendary)
	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.Size = UDim2.new(0, 400, 0, 400)
	glow.Position = UDim2.new(0.5, -200, 0.5, -200)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://1316045217" -- Radial gradient
	glow.ImageTransparency = 1 -- Start invisible
	glow.ZIndex = 5
	glow.Parent = container
	
	-- Light rays effect (for legendary)
	local rays = Instance.new("ImageLabel")
	rays.Name = "Rays"
	rays.Size = UDim2.new(0, 600, 0, 600)
	rays.Position = UDim2.new(0.5, -300, 0.5, -300)
	rays.BackgroundTransparency = 1
	rays.Image = "rbxassetid://2610133241" -- Light rays
	rays.ImageTransparency = 1
	rays.ZIndex = 4
	rays.Rotation = 0
	rays.Parent = container
	
	-- Pet reveal container
	local petReveal = Instance.new("Frame")
	petReveal.Name = "PetReveal"
	petReveal.Size = UDim2.new(0, 300, 0, 350)
	petReveal.Position = UDim2.new(0.5, -150, 0.5, -175)
	petReveal.BackgroundTransparency = 1
	petReveal.Visible = false
	petReveal.ZIndex = 15
	petReveal.Parent = container
	
	-- Pet viewport for 3D model
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "PetViewport"
	viewport.Size = UDim2.new(1, 0, 0.7, 0)
	viewport.Position = UDim2.new(0, 0, 0, 0)
	viewport.BackgroundTransparency = 1
	viewport.ZIndex = 16
	viewport.Parent = petReveal
	
	-- Pet name label
	local petNameLabel = Instance.new("TextLabel")
	petNameLabel.Name = "PetName"
	petNameLabel.Size = UDim2.new(1, 0, 0, 40)
	petNameLabel.Position = UDim2.new(0, 0, 0.7, 10)
	petNameLabel.BackgroundTransparency = 1
	petNameLabel.Font = Enum.Font.GothamBold
	petNameLabel.TextSize = 28
	petNameLabel.TextColor3 = Color3.new(1, 1, 1)
	petNameLabel.TextStrokeTransparency = 0.5
	petNameLabel.ZIndex = 16
	petNameLabel.Parent = petReveal
	
	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Size = UDim2.new(1, 0, 0, 30)
	rarityLabel.Position = UDim2.new(0, 0, 0.7, 55)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.GothamMedium
	rarityLabel.TextSize = 22
	rarityLabel.TextColor3 = Color3.new(1, 1, 1)
	rarityLabel.TextStrokeTransparency = 0.5
	rarityLabel.ZIndex = 16
	rarityLabel.Parent = petReveal
	
	-- Size/Weight info
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "Stats"
	statsLabel.Size = UDim2.new(1, 0, 0, 25)
	statsLabel.Position = UDim2.new(0, 0, 0.7, 85)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextSize = 16
	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsLabel.TextStrokeTransparency = 0.7
	statsLabel.ZIndex = 16
	statsLabel.Parent = petReveal
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 150, 0, 45)
	closeButton.Position = UDim2.new(0.5, -75, 1, -60)
	closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 18
	closeButton.Text = "Continue"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Visible = false
	closeButton.ZIndex = 20
	closeButton.Parent = container
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = closeButton
	
	return screenGui
end

-- Shake animation for the egg
local function animateEggShake(eggImage, duration, intensity)
	local startTime = tick()
	local originalPosition = eggImage.Position
	local shakeConnection
	
	shakeConnection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration then
			shakeConnection:Disconnect()
			eggImage.Position = originalPosition
			return
		end
		
		-- Increase shake intensity over time
		local progress = elapsed / duration
		local currentIntensity = intensity * (0.5 + progress * 0.5)
		
		-- Add shake frequency increase
		local frequency = 20 + progress * 30
		local offsetX = math.sin(elapsed * frequency) * currentIntensity * (1 - progress * 0.3)
		local offsetRotation = math.sin(elapsed * frequency * 0.7) * 5 * progress
		
		eggImage.Position = UDim2.new(
			originalPosition.X.Scale,
			originalPosition.X.Offset + offsetX,
			originalPosition.Y.Scale,
			originalPosition.Y.Offset
		)
		eggImage.Rotation = offsetRotation
	end)
	
	return shakeConnection
end

-- Create particles for the reveal
local function createParticles(container, color, count)
	local particles = {}
	
	for i = 1, count do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(5, 15), 0, math.random(5, 15))
		particle.Position = UDim2.new(0.5, 0, 0.5, 0)
		particle.BackgroundColor3 = color
		particle.BorderSizePixel = 0
		particle.ZIndex = 12
		particle.Rotation = math.random(0, 360)
		particle.Parent = container
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = particle
		
		-- Animate particle outward
		local angle = math.random() * math.pi * 2
		local distance = math.random(150, 300)
		local targetX = math.cos(angle) * distance
		local targetY = math.sin(angle) * distance
		
		local tween = TweenService:Create(particle, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, targetX, 0.5, targetY),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 3, 0, 3)
		})
		tween:Play()
		
		table.insert(particles, particle)
	end
	
	-- Cleanup after animation
	task.delay(1.5, function()
		for _, p in ipairs(particles) do
			if p and p.Parent then
				p:Destroy()
			end
		end
	end)
end

-- Play the egg opening animation
function EggOpeningUI.PlayOpeningAnimation(eggType, resultData)
	if isAnimating then return end
	isAnimating = true
	
	-- Get configs
	local eggConfig = Constants.EGG_CONFIG[eggType]
	local openingConfig = Config.EggOpening or {}
	
	if not eggConfig then
		warn("[EggOpeningUI] Invalid egg type:", eggType)
		isAnimating = false
		return
	end
	
	-- Create UI if needed
	if currentUI and currentUI.Parent then
		currentUI:Destroy()
	end
	currentUI = createEggOpeningUI()
	currentUI.Parent = playerGui
	
	-- Get UI elements
	local overlay = currentUI.Overlay
	local container = currentUI.Container
	local eggImage = container.EggImage
	local glow = container.Glow
	local rays = container.Rays
	local petReveal = container.PetReveal
	local closeButton = container.CloseButton
	
	-- Set egg image
	eggImage.Image = eggConfig.ImageId
	
	-- Get rarity info
	local rarity = resultData.Rarity
	local rarityColor = Constants.RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
	local isEpic = rarity == Constants.RARITIES.EPIC
	local isLegendary = rarity == Constants.RARITIES.LEGENDARY
	
	-- Timings
	local shakeDuration = openingConfig.ShakeDuration or 2.0
	local crackDuration = openingConfig.CrackDuration or 0.5
	local revealDuration = openingConfig.RevealDuration or 1.5
	local shakeIntensity = openingConfig.ShakeIntensity or 10
	local darknessAlpha = openingConfig.BackgroundDarknessAlpha or 0.85
	
	-- Phase 1: Fade in overlay
	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 1 - darknessAlpha
	})
	overlayTween:Play()
	
	-- Phase 2: Egg appears and shakes
	eggImage.ImageTransparency = 0
	task.wait(0.3)
	
	-- Start shake animation
	local shakeConnection = animateEggShake(eggImage, shakeDuration, shakeIntensity)
	
	-- For epic/legendary, show glow during shake
	if isEpic or isLegendary then
		local effectConfig = isLegendary and (openingConfig.LegendaryEffects or {}) or (openingConfig.EpicEffects or {})
		local glowColor = effectConfig.GlowColor or rarityColor
		
		glow.ImageColor3 = glowColor
		local glowTween = TweenService:Create(glow, TweenInfo.new(shakeDuration * 0.7), {
			ImageTransparency = 0.3
		})
		glowTween:Play()
		
		-- Legendary rays effect
		if isLegendary and effectConfig.EnableRays then
			rays.ImageColor3 = glowColor
			local raysTween = TweenService:Create(rays, TweenInfo.new(shakeDuration * 0.5), {
				ImageTransparency = 0.5
			})
			raysTween:Play()
			
			-- Rotate rays
			task.spawn(function()
				while currentUI and currentUI.Parent do
					rays.Rotation = rays.Rotation + 0.5
					task.wait()
				end
			end)
		end
	end
	
	task.wait(shakeDuration)
	
	-- Phase 3: Egg cracks/explodes
	local crackTween = TweenService:Create(eggImage, TweenInfo.new(crackDuration, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 250, 0, 300),
		ImageTransparency = 1
	})
	crackTween:Play()
	
	-- Flash effect
	if isLegendary then
		overlay.BackgroundColor3 = Color3.new(1, 1, 1)
		local flashTween = TweenService:Create(overlay, TweenInfo.new(0.2), {
			BackgroundTransparency = 0
		})
		flashTween:Play()
		task.wait(0.1)
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		local unflashTween = TweenService:Create(overlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 1 - darknessAlpha
		})
		unflashTween:Play()
	end
	
	-- Create particles
	local particleCount = isLegendary and 40 or (isEpic and 20 or 10)
	createParticles(container, rarityColor, particleCount)
	
	task.wait(crackDuration)
	
	-- Phase 4: Reveal pet
	petReveal.Visible = true
	
	-- Setup viewport with pet model
	local viewport = petReveal.PetViewport
	local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
	if petsFolder then
		local petMesh = petsFolder:FindFirstChild(resultData.PetType)
		if petMesh then
			-- Clear existing
			for _, child in ipairs(viewport:GetChildren()) do
				child:Destroy()
			end
			
			-- Clone and add pet
			local petClone = petMesh:Clone()
			if petClone:IsA("MeshPart") then
				local model = Instance.new("Model")
				petClone.Parent = model
				model.PrimaryPart = petClone
				model.Parent = viewport
				
				-- Scale by pet size
				local petSize = resultData.Size or 1
				petClone.Size = petClone.Size * petSize
			else
				petClone.Parent = viewport
			end
			
			-- Add camera
			local camera = Instance.new("Camera")
			camera.CFrame = CFrame.new(Vector3.new(0, 2, 5), Vector3.new(0, 1, 0))
			camera.Parent = viewport
			viewport.CurrentCamera = camera
		end
	end
	
	-- Set labels
	local petNameLabel = petReveal.PetName
	local rarityLabel = petReveal.Rarity
	local statsLabel = petReveal.Stats
	
	petNameLabel.Text = resultData.DisplayName or resultData.PetType
	petNameLabel.TextColor3 = rarityColor
	
	rarityLabel.Text = rarity
	rarityLabel.TextColor3 = rarityColor
	
	statsLabel.Text = string.format("Size: %.2f | Weight: %.2f", resultData.Size or 1, resultData.Weight or 1)
	
	-- Animate reveal
	petReveal.Size = UDim2.new(0, 0, 0, 0)
	petReveal.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	local revealTween = TweenService:Create(petReveal, TweenInfo.new(revealDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 300, 0, 350),
		Position = UDim2.new(0.5, -150, 0.5, -175)
	})
	revealTween:Play()
	
	task.wait(revealDuration)
	
	-- Show close button
	closeButton.Visible = true
	closeButton.MouseButton1Click:Connect(function()
		EggOpeningUI.Close()
	end)
	
	isAnimating = false
end

-- Close the UI
function EggOpeningUI.Close()
	if currentUI and currentUI.Parent then
		local overlay = currentUI:FindFirstChild("Overlay")
		if overlay then
			local fadeOut = TweenService:Create(overlay, TweenInfo.new(0.3), {
				BackgroundTransparency = 1
			})
			fadeOut:Play()
		end
		
		task.delay(0.3, function()
			if currentUI and currentUI.Parent then
				currentUI:Destroy()
				currentUI = nil
			end
		end)
	end
end

-- Initialize - listen for egg opened events
function EggOpeningUI.Initialize()
	local eggOpenedEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.EGG_OPENED, 10)
	if not eggOpenedEvent then
		warn("[EggOpeningUI] EggOpened event not found")
		return
	end
	
	eggOpenedEvent.OnClientEvent:Connect(function(success, resultData, errorMessage)
		if success and resultData then
			EggOpeningUI.PlayOpeningAnimation(resultData.EggType, resultData)
		elseif errorMessage then
			warn("[EggOpeningUI] Egg opening failed:", errorMessage)
		end
	end)
	
	print("🥚 EggOpeningUI initialized")
end

return EggOpeningUI
