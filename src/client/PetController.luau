-- PetController.luau
-- Handles pet spawning and following behavior on client

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[PetController] Shared folder missing; pet controller disabled")
	return {}
end

local function safeRequire(name)
	local ok, mod = pcall(function()
		return require(sharedFolder:WaitForChild(name, 5))
	end)
	if not ok then
		warn(string.format("[PetController] Failed to load %s: %s", name, tostring(mod)))
		return nil
	end
	return mod
end

local Constants = safeRequire("Constants")
local Config = safeRequire("Config")
local BuffsModule = safeRequire("BuffsModule")
local VFXModule = safeRequire("VFXModule")
if not (Constants and Config and BuffsModule and VFXModule) then
	return {}
end

local PetController = {}
PetController.EquippedPets = {} -- Array of pets following player (max 3)
PetController.GardenPets = {} -- Array of pets roaming in garden (max 7)
local player = Players.LocalPlayer
local PET_BOOST_RADIUS = 30
local PET_FOLLOW_DISTANCE_MULTIPLIER = 2.5 -- Multiply config.FollowDistance by this (makes pets orbit further from player)
local MAX_EQUIPPED_PETS = Constants.MAX_EQUIPPED_PETS or 3
local MAX_GARDEN_PETS = Constants.MAX_GARDEN_PETS or 7

-- Weight to scale mapping
-- Weight 1 = scale 1.0, Weight increases/decreases scale proportionally
local MIN_WEIGHT_SCALE = 0.7  -- Minimum scale at very low weight (increased from 0.6 for stability)
local MAX_WEIGHT_SCALE = 1.6  -- Maximum scale at very high weight (reduced from 1.8 to prevent extremes)
local WEIGHT_SCALE_FACTOR = 0.12  -- How much each weight point affects scale (reduced from 0.15)

-- Scale categories - parts that should scale differently to maintain proportions
local SCALE_EXEMPT_NAMES = {
	"Handle", "Handle1", "Handle2", -- Tool handles that might be parented to pets
	"Attachment", "WeldConstraint", "Motor6D" -- Constraints that shouldn't be scaled
}

-- Animation IDs keyed by pet type string (matches Constants.PET_TYPES values)
local PET_ANIMATION_IDS = {
	CrystalOwl = "rbxassetid://123529384488047",
	EmberCat = "rbxassetid://78828702711075",
	EverflameGriffin = "rbxassetid://134717447296684",
	GlowBug = "rbxassetid://103068963428519",
	Leafling = "rbxassetid://92889904712907",
	MoonDragon = "rbxassetid://121557478752388",
	MossySlime = "rbxassetid://113805401501210",
	PebblePup = "rbxassetid://135071793175470",
	SparkFox = "rbxassetid://123453968074742",
	SproutTail = "rbxassetid://88562824413900",
	StarlightPhoenix = "rbxassetid://109320769613379",
	Thornbeak = "rbxassetid://90563216315905",
	WispRabbit = "rbxassetid://94499105982343"
}

-- Track animation per pet without leaking
local animationTracks = setmetatable({}, { __mode = "k" })

local function getAnimator(model)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	local controller = model:FindFirstChildWhichIsA("AnimationController")
	if not controller then
		controller = Instance.new("AnimationController")
		controller.Name = "PetAnimationController"
		controller.Parent = model
	end

	local animator = controller:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end

	return animator
end

local function stopMoveAnimation(model)
	local track = animationTracks[model]
	if track then
		track:Stop()
		animationTracks[model] = nil
	end
end

-- Calculate scale based on weight
local function calculateWeightScale(weight)
	local baseWeight = 1
	local weightDiff = (weight or 1) - baseWeight
	local scale = 1 + (weightDiff * WEIGHT_SCALE_FACTOR)
	return math.clamp(scale, MIN_WEIGHT_SCALE, MAX_WEIGHT_SCALE)
end

-- Apply scale to pet model based on weight
local function applyWeightScale(petModel, weight)
	if not petModel or not petModel.Parent then return end
	
	local scale = calculateWeightScale(weight)
	local currentScale = petModel:GetAttribute("AppliedScale") or 1
	
	-- Skip if scale hasn't changed significantly
	if math.abs(scale - currentScale) < 0.01 then return end
	
	-- Calculate relative scale change
	local relativeScale = scale / currentScale
	
	-- Validate scale change isn't too extreme (safety check)
	if relativeScale < 0.5 or relativeScale > 2.0 then
		warn("[PetController] Extreme scale change detected, skipping:", relativeScale)
		return
	end
	
	-- Scale BaseParts in the model, but be selective about what we scale
	for _, part in ipairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Check if this part should be exempt from scaling
			local shouldScale = true
			for _, exemptName in ipairs(SCALE_EXEMPT_NAMES) do
				if string.find(part.Name, exemptName) then
					shouldScale = false
					break
				end
			end
			
			-- Also exempt very small parts that might be details/accessories
			local partVolume = part.Size.X * part.Size.Y * part.Size.Z
			if partVolume < 0.1 then -- Very small parts (likely details)
				shouldScale = false
			end
			
			if shouldScale then
				-- Store original size if not already stored
				if not part:GetAttribute("OriginalSize") then
					part:SetAttribute("OriginalSize", tostring(part.Size))
				end
				
				part.Size = part.Size * relativeScale
			end
		end
	end
	
	-- Update light range if present (scale with pet size)
	local body = petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart")
	if body then
		local light = body:FindFirstChild("PetLight")
		if light and light:IsA("PointLight") then
			-- Scale light range more conservatively than the pet itself
			local lightScale = 1 + ((scale - 1) * 0.7) -- 70% of the size scaling
			light.Range = 8 * lightScale
		end
	end
	
	-- Store the applied scale for future reference
	petModel:SetAttribute("AppliedScale", scale)
end

-- Setup weight attribute listener for a pet model
local function setupWeightListener(petModel)
	if not petModel then return end
	
	-- Listen for weight changes
	petModel:GetAttributeChangedSignal("Weight"):Connect(function()
		local newWeight = petModel:GetAttribute("Weight") or 1
		applyWeightScale(petModel, newWeight)
	end)
end

local function getMoveAnimation(model)
	local existing = model:FindFirstChildWhichIsA("Animation", true)
	if existing and existing.AnimationId ~= "" then
		return existing
	end

	local petType = model:GetAttribute("PetType")
	local mappedId = petType and PET_ANIMATION_IDS[petType]
	if mappedId then
		local animation = Instance.new("Animation")
		animation.Name = "PetMove"
		animation.AnimationId = mappedId
		animation.Parent = model
		return animation
	end

	return nil
end

local function ensureMoveAnimation(model)
	if animationTracks[model] then return end

	local anim = getMoveAnimation(model)
	if not anim then return end

	local animator = getAnimator(model)
	if not animator then return end

	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)

	if ok and track then
		track.Looped = true
		track:Play()
		animationTracks[model] = track
	end
end

local function faceTarget(petBody, targetPosition, movementType)
	local bodyGyro = petBody and petBody:FindFirstChild("BodyGyro")
	if not bodyGyro then return end

	local currentPosition = petBody.Position
	local direction = targetPosition - currentPosition
	
	-- Always flatten to horizontal (no pitch rotation for any pet type)
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.1 then return end -- Don't rotate if barely moving

	-- Calculate target rotation
	local lookTarget = currentPosition + direction.Unit
	local targetCFrame = CFrame.lookAt(currentPosition, lookTarget, Vector3.yAxis)
	
	-- Get current rotation for smooth interpolation
	local currentCFrame = bodyGyro.CFrame
	
	-- Smooth rotation interpolation (prevents snappy turning)
	local rotationSpeed = 0.15 -- Lower = smoother rotation (0.1-0.3 range)
	
	-- Different rotation speeds based on movement type
	if movementType == "Walk" then
		rotationSpeed = 0.08 -- Walking pets turn more gradually
	else
		rotationSpeed = 0.12 -- Flying pets can turn a bit faster
	end
	
	-- Interpolate between current and target rotation
	local smoothedCFrame = currentCFrame:Lerp(targetCFrame, rotationSpeed)
	bodyGyro.CFrame = smoothedCFrame
	
	-- Adjust gyro properties for smoother turning
	if movementType == "Walk" then
		-- Walking pets need more stable ground orientation
		bodyGyro.MaxTorque = Vector3.new(8000, 4000, 8000) -- Stronger X/Z, moderate Y
		bodyGyro.P = 4000
		bodyGyro.D = 600
	else
		-- Flying pets can be more free in rotation
		bodyGyro.MaxTorque = Vector3.new(3000, 3000, 3000)
		bodyGyro.P = 2500
		bodyGyro.D = 400
	end
end

-- Control animation playback based on movement state
local function setAnimationPlaying(model, shouldPlay)
	local track = animationTracks[model]
	if not track then return end
	
	if shouldPlay then
		if not track.IsPlaying then
			track:Play()
		end
	else
		if track.IsPlaying then
			track:Stop()
		end
	end
end

-- Create pet model with size scaling
local function createPetModel(petInstance, petName)
	-- petInstance is now {Id, PetType, Size, Weight}
	local petType = petInstance.PetType or petInstance -- Support legacy string format
	local petSize = petInstance.Size or 1
	local petWeight = petInstance.Weight or 1
	local petId = petInstance.Id
	
	local config = Constants.PET_CONFIG[petType]
	if not config then return nil end
	
	-- Get pet models from ReplicatedStorage
	local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
	if not petsFolder then
		warn("[PetController] Pets folder not found in ReplicatedStorage")
		return nil
	end
	
	local petTemplate = petsFolder:FindFirstChild(petType)
	if not petTemplate then
		warn("[PetController] Pet template not found for:", petType)
		return nil
	end
	
	-- Clone the pet template
	local petModel
	local body
	
	if petTemplate:IsA("Model") then
		-- Clone the entire model
		petModel = petTemplate:Clone()
		petModel.Name = petName or (player.Name .. "_Pet")
		
		-- Find the primary part or first MeshPart as the body
		body = petModel.PrimaryPart
		if not body then
			body = petModel:FindFirstChildWhichIsA("MeshPart", true)
		end
		if not body then
			body = petModel:FindFirstChildWhichIsA("BasePart", true)
		end
		
		if body then
			petModel.PrimaryPart = body
		else
			warn("[PetController] No BasePart found in pet model:", petType)
			petModel:Destroy()
			return nil
		end
	elseif petTemplate:IsA("BasePart") then
		-- Single part, wrap in a model
		petModel = Instance.new("Model")
		petModel.Name = petName or (player.Name .. "_Pet")
		body = petTemplate:Clone()
		body.Name = "Body"
		body.Parent = petModel
		petModel.PrimaryPart = body
	else
		warn("[PetController] Pet template is not a Model or BasePart:", petType, petTemplate.ClassName)
		return nil
	end
	
	-- Get movement type (Fly or Walk)
	local movementType = config.MovementType or "Fly"
	
	-- Setup physics for all parts in the model
	for _, part in ipairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = false
			
			-- Apply size scaling (scale relative to original size)
			if petSize ~= 1 then
				part.Size = part.Size * petSize
			end
		end
	end
	
	-- Setup the body (primary part) with movement physics
	if body then
		-- Weight affects physical properties (heavier = slower, more stable)
		local density = 0.7 * petWeight
		body.CustomPhysicalProperties = PhysicalProperties.new(density, 0.3, 0.5, 1, 1)
		
		-- Add glow effect
		if not body:FindFirstChild("PetLight") then
			local light = Instance.new("PointLight")
			light.Name = "PetLight"
			light.Brightness = 1
			light.Range = 8 * petSize -- Scale light with size
			light.Color = config.Color
			light.Parent = body
		end
		
		-- Add movement physics based on movement type
		if movementType == "Fly" then
			-- Flying pets use BodyPosition for floating
			local bodyPosition = Instance.new("BodyPosition")
			bodyPosition.Name = "BodyPosition"
			bodyPosition.MaxForce = Vector3.new(10000, 10000, 10000)
			bodyPosition.P = 5000 / petWeight -- Heavier = slower movement
			bodyPosition.D = 1000
			bodyPosition.Parent = body
			
			-- Add slight rotation for flying pets
			local bodyGyro = Instance.new("BodyGyro")
			bodyGyro.Name = "BodyGyro"
			bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
			bodyGyro.P = 3000
			bodyGyro.D = 500
			bodyGyro.Parent = body
		else
			-- Walking pets use BodyPosition with ground-level constraint
			local bodyPosition = Instance.new("BodyPosition")
			bodyPosition.Name = "BodyPosition"
			bodyPosition.MaxForce = Vector3.new(10000, 10000, 10000)
			bodyPosition.P = 8000 / petWeight -- Walking pets are more responsive
			bodyPosition.D = 1500
			bodyPosition.Parent = body
			
			-- Walking pets need gyro to stay upright
			local bodyGyro = Instance.new("BodyGyro")
			bodyGyro.Name = "BodyGyro"
			bodyGyro.MaxTorque = Vector3.new(10000, 0, 10000) -- Allow Y rotation (turning)
			bodyGyro.P = 5000
			bodyGyro.D = 800
			bodyGyro.Parent = body
		end
	end
	
	-- Collect parts that are connected via Motor6D (animated joints) - don't weld these
	local motorConnectedParts = {}
	for _, motor in ipairs(petModel:GetDescendants()) do
		if motor:IsA("Motor6D") then
			if motor.Part0 then motorConnectedParts[motor.Part0] = true end
			if motor.Part1 then motorConnectedParts[motor.Part1] = true end
		end
	end
	
	-- Weld only parts that are NOT connected via Motor6D (so animations still work)
	if petModel:IsA("Model") and body then
		for _, part in ipairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") and part ~= body and not motorConnectedParts[part] then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = body
				weld.Part1 = part
				weld.Parent = body
			end
		end
	end
	
	petModel:SetAttribute("PetType", petType)
	petModel:SetAttribute("PetId", petId)
	petModel:SetAttribute("Size", petSize)
	petModel:SetAttribute("Weight", petWeight)
	petModel:SetAttribute("MovementType", movementType)
	
	-- Apply weight-based scaling and setup listener for future changes
	local weightScale = calculateWeightScale(petWeight)
	petModel:SetAttribute("AppliedScale", petSize * weightScale)  -- Combined initial scale
	
	-- Apply additional weight scale on top of size
	if petWeight ~= 1 then
		local relativeScale = weightScale  -- Weight scale relative to base (size already applied)
		for _, part in ipairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Size = part.Size * relativeScale
			end
		end
		
		-- Update light range
		if body then
			local light = body:FindFirstChild("PetLight")
			if light and light:IsA("PointLight") then
				light.Range = 8 * petSize * weightScale
			end
		end
	end
	
	-- Setup listener for weight attribute changes
	setupWeightListener(petModel)
	
	return petModel
end

-- Update pet follow behavior for equipped pets
local function updateEquippedPets()
	if #PetController.EquippedPets == 0 then return end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	
	local hrp = player.Character.HumanoidRootPart
	local time = tick()
	
	for index, petModel in ipairs(PetController.EquippedPets) do
		if petModel and petModel.Parent then
			local petBody = petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart")
			if petBody then
				local bodyPosition = petBody:FindFirstChild("BodyPosition")
				if bodyPosition then
					local petType = petModel:GetAttribute("PetType")
					local movementType = petModel:GetAttribute("MovementType") or "Fly"
					local config = Constants.PET_CONFIG[petType]
					
					if config then
						-- Calculate follow position with more natural variation
						local angle = (index - 1) * (math.pi * 2 / MAX_EQUIPPED_PETS)
						
						-- Add some dynamic variation to the follow distance and angle
						local distanceVariation = math.sin(time * 0.8 + index) * 0.3 -- Small distance wobble
						local angleVariation = math.sin(time * 0.5 + index * 2) * 0.2 -- Slight angle drift
						
						local followDist = config.FollowDistance * PET_FOLLOW_DISTANCE_MULTIPLIER * (1 + distanceVariation)
						local adjustedAngle = angle + angleVariation
						
						local offsetX = math.cos(adjustedAngle) * followDist
						local offsetZ = math.sin(adjustedAngle) * followDist
						
						-- Store previous position for lag calculation
						if not petModel:GetAttribute("LastTargetPos") then
							petModel:SetAttribute("LastTargetPos", tostring(hrp.Position))
						end
						
						local targetPosition
						if movementType == "Fly" then
							-- Flying pets hover above/around the player with natural drift
							local baseHeight = 2 + math.sin(time * 1.2 + index) * 0.8 -- Varying heights
							local offset = Vector3.new(offsetX, baseHeight, offsetZ)
							targetPosition = hrp.Position + offset
							
							-- Add gentle bobbing motion for flying pets (weight affects frequency)
							local petWeight = petModel:GetAttribute("Weight") or 1
							local bobFreq = 1.8 / petWeight -- Heavier pets bob slower
							local bobOffset = math.sin(time * bobFreq + index) * 0.4
							targetPosition = targetPosition + Vector3.new(0, bobOffset, 0)
						else
							-- Walking pets follow on ground with natural lag
							local offset = Vector3.new(offsetX, 0, offsetZ)
							targetPosition = hrp.Position + offset
							
							-- Add slight lag behind player movement for more natural following
							local prevTargetStr = petModel:GetAttribute("LastTargetPos") or tostring(hrp.Position)
							local prevTarget = Vector3.new(tonumber(string.split(prevTargetStr, ",")[1]) or 0, 
														  tonumber(string.split(prevTargetStr, ",")[2]) or 0, 
														  tonumber(string.split(prevTargetStr, ",")[3]) or 0)
							local laggedTarget = prevTarget:Lerp(targetPosition, 0.85) -- Slight lag
							
							-- Raycast to find ground level
							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {player.Character, petModel}
							
							local rayOrigin = laggedTarget + Vector3.new(0, 5, 0)
							local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -15, 0), rayParams)
							
							if rayResult then
								-- Place pet on the ground with a small offset for pet height
								local petHeight = petBody.Size.Y / 2
								targetPosition = rayResult.Position + Vector3.new(0, petHeight + 0.1, 0)
							else
								-- Fallback: use player's Y position
								targetPosition = Vector3.new(laggedTarget.X, hrp.Position.Y - 2, laggedTarget.Z)
							end
							
							-- Add slight hop/bounce motion for walking pets (varies by weight)
							local petWeight = petModel:GetAttribute("Weight") or 1
							local hopFreq = 3.5 / petWeight -- Heavier pets hop less frequently
							local hopOffset = math.abs(math.sin(time * hopFreq + index)) * (0.2 / petWeight)
							targetPosition = targetPosition + Vector3.new(0, hopOffset, 0)
						end
						
						-- Store current target for next frame's lag calculation
						petModel:SetAttribute("LastTargetPos", tostring(targetPosition))
						
						-- Smooth follow with BodyPosition (less snappy than before)
						local currentPos = petBody.Position
						local smoothingFactor = 0.12 -- Reduced from implicit 1.0 for smoother following
						local smoothedTarget = currentPos:Lerp(targetPosition, smoothingFactor)
						bodyPosition.Position = smoothedTarget

						-- Check if pet is actually moving (distance to target)
						local distanceToTarget = (currentPos - targetPosition).Magnitude
						local isMoving = distanceToTarget > 0.8 -- Slightly higher threshold
						
						-- Face movement direction more naturally
						if isMoving then
							-- Look ahead in movement direction rather than directly at target
							local movementDirection = (smoothedTarget - currentPos)
							if movementDirection.Magnitude > 0.1 then
								local lookAheadPos = currentPos + movementDirection.Unit * 3
								faceTarget(petBody, lookAheadPos, movementType)
							end
						end
						
						-- Control animation based on movement type
						if movementType == "Walk" then
							-- Walking pets only animate when moving
							setAnimationPlaying(petModel, isMoving)
						else
							-- Flying pets always animate (hovering)
							setAnimationPlaying(petModel, true)
						end
					end
				end
			end
		end
	end
end

-- Get player's garden center position and bounds
local function getPlayerGardenInfo()
	local gardensFolder = Workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then 
		-- warn("[PetController] Gardens folder not found:", Config.World.GardensFolder)
		return nil 
	end
	
	-- Helper to build roam config from garden
	local function buildRoamConfig(centerPos)
		local roamConfig = Config.GardenPetRoaming or {}
		return {
			center = centerPos,
			halfWidth = roamConfig.BoundsHalfWidth or 28,
			halfLength = roamConfig.BoundsHalfLength or 28,
			minHeight = roamConfig.MinHeight or 1,
			maxHeight = roamConfig.MaxHeight or 4,
			idleChance = roamConfig.IdleChance or 0.6,
			minIdleTime = roamConfig.MinIdleTime or 3,
			maxIdleTime = roamConfig.MaxIdleTime or 8,
			minMoveTime = roamConfig.MinMoveTime or 2,
			maxMoveTime = roamConfig.MaxMoveTime or 5,
			moveSpeed = roamConfig.MoveSpeed or 0.3,
			bobAmplitude = roamConfig.BobAmplitude or 0.3,
			bobSpeed = roamConfig.BobSpeed or 1.5
		}
	end
	
	-- Helper to find a valid center in a garden
	local function findGardenCenter(garden)
		-- Prefer explicit Center marker for consistent roaming origin
		local explicitCenter = garden:FindFirstChild("Center")
		if explicitCenter and explicitCenter:IsA("BasePart") then
			return explicitCenter.Position
		end

		-- Try Floor first
		local floor = garden:FindFirstChild(Config.World.FloorName)
		if floor and floor:IsA("BasePart") then
			return floor.Position
		end
		
		-- Try TpPart 
		local tpPart = garden:FindFirstChild(Config.World.TeleportPartName)
		if tpPart and tpPart:IsA("BasePart") then
			return tpPart.Position
		end
		
		-- Try Plots folder and PlantAnchors
		local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder or "Plots")
		if plotsFolder then
			local anchor = plotsFolder:FindFirstChild("PlantAnchor1")
			if anchor and anchor:IsA("BasePart") then
				return anchor.Position + Vector3.new(0, 2, 0)
			end
			-- Try any part in Plots
			for _, child in ipairs(plotsFolder:GetChildren()) do
				if child:IsA("BasePart") then
					return child.Position + Vector3.new(0, 2, 0)
				end
			end
		end
		
		-- Try finding any BasePart in the garden
		for _, child in ipairs(garden:GetDescendants()) do
			if child:IsA("BasePart") and child.Name ~= "Sign" then
				return child.Position + Vector3.new(0, 2, 0)
			end
		end
		
		return nil
	end
	
	-- Find player's assigned garden using OwnerUserId attribute (primary method)
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local ownerUserId = garden:GetAttribute("OwnerUserId")
			if ownerUserId == player.UserId then
				local center = findGardenCenter(garden)
				if center then
					return buildRoamConfig(center)
				end
			end
		end
	end
	
	-- Fallback: Check player sign text (legacy method)
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local playerSign = garden:FindFirstChild(Config.World.PlayerSignName)
			if playerSign then
				local signPart = playerSign:FindFirstChild(Config.World.PlayerSignPartName)
				if signPart then
					local surfaceGui = signPart:FindFirstChild("SurfaceGui")
					if surfaceGui then
						local textLabel = surfaceGui:FindFirstChild("TextLabel")
						if textLabel and textLabel.Text == player.Name then
							local center = findGardenCenter(garden)
							if center then
								return buildRoamConfig(center)
							end
						end
					end
				end
			end
		end
	end
	
	return nil
end

-- Legacy function for compatibility
local function getPlayerGardenCenter()
	local info = getPlayerGardenInfo()
	return info and info.center or nil
end

-- Update garden pets roaming behavior with box bounds and idle
local function updateGardenPets(deltaTime)
	if #PetController.GardenPets == 0 then return end
	
	local gardenInfo = getPlayerGardenInfo()
	if not gardenInfo then return end

	-- Clamp smoothing factor so pets glide instead of snapping to new targets
	local baseMoveAlpha = math.clamp(gardenInfo.moveSpeed or 0.3, 0.05, 0.8)
	local moveAlpha
	if deltaTime then
		local frameScale = math.clamp(deltaTime * 60, 0.5, 2)
		moveAlpha = math.clamp(baseMoveAlpha * frameScale, 0.05, 0.8)
	else
		moveAlpha = baseMoveAlpha
	end
	
	local time = tick()
	
	for index, petData in ipairs(PetController.GardenPets) do
		local petModel = petData.model
		if petModel and petModel.Parent then
			local petBody = petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart")
			if petBody then
				local bodyPosition = petBody:FindFirstChild("BodyPosition")
				if bodyPosition then
					local petType = petModel:GetAttribute("PetType")
					local petWeight = petModel:GetAttribute("Weight") or 1
					local movementType = petModel:GetAttribute("MovementType") or "Fly"
					local config = Constants.PET_CONFIG[petType]
					
					if config then
						-- Initialize state if not set
						if not petData.state then
							petData.state = "idle"
							petData.stateEndTime = time + math.random(gardenInfo.minIdleTime, gardenInfo.maxIdleTime)
							petData.targetPos = petBody.Position
							petData.lastMoveTime = time
							petData.moveStartPos = petBody.Position -- Track where movement started for curves
						end
						
						-- Check if state should change
						if time > petData.stateEndTime then
							-- Decide next state with some personality variations
							local idleChance = gardenInfo.idleChance
							
							-- Heavier pets are lazier (more likely to idle)
							idleChance = idleChance + (petWeight - 1) * 0.15
							idleChance = math.clamp(idleChance, 0.2, 0.9)
							
							if math.random() < idleChance then
								petData.state = "idle"
								-- Vary idle times more naturally
								local baseIdleTime = math.random(gardenInfo.minIdleTime, gardenInfo.maxIdleTime)
								local weightFactor = 1 + (petWeight - 1) * 0.3 -- Heavier pets idle longer
								petData.stateEndTime = time + (baseIdleTime * weightFactor)
							else
								petData.state = "moving"
								petData.lastMoveTime = time
								petData.moveStartPos = petBody.Position
								
								-- More realistic movement duration (distance-based)
								local baseMoveTime = math.random(gardenInfo.minMoveTime, gardenInfo.maxMoveTime)
								petData.stateEndTime = time + baseMoveTime
								
								-- Generate more natural target positions (avoid moving to exact center too often)
								local currentPos = petBody.Position
								local distanceFromCenter = (currentPos - gardenInfo.center).Magnitude
								
								-- If far from center, bias toward center; if close, allow more wandering
								local centerBias = math.clamp(distanceFromCenter / (gardenInfo.halfWidth * 0.5), 0, 1)
								
								local offsetX, offsetZ
								if math.random() < centerBias * 0.4 then
									-- Move toward center occasionally
									local dirToCenter = (gardenInfo.center - currentPos).Unit
									local moveDistance = math.random(gardenInfo.halfWidth * 0.3, gardenInfo.halfWidth * 0.7)
									offsetX = dirToCenter.X * moveDistance
									offsetZ = dirToCenter.Z * moveDistance
								else
									-- Random wandering with some direction preference
									-- Add slight bias to continue in a similar direction (more natural)
									local prevDirection = petData.lastDirection or Vector3.new(math.random(-1,1), 0, math.random(-1,1))
									local newDirection = Vector3.new(
										math.random(-1, 1) * 0.7 + prevDirection.X * 0.3,
										0,
										math.random(-1, 1) * 0.7 + prevDirection.Z * 0.3
									).Unit
									
									local moveDistance = math.random(gardenInfo.halfWidth * 0.4, gardenInfo.halfWidth * 0.8)
									offsetX = newDirection.X * moveDistance
									offsetZ = newDirection.Z * moveDistance
									petData.lastDirection = newDirection
								end
								
								-- Clamp to bounds with some padding
								offsetX = math.clamp(offsetX, -gardenInfo.halfWidth * 0.85, gardenInfo.halfWidth * 0.85)
								offsetZ = math.clamp(offsetZ, -gardenInfo.halfLength * 0.85, gardenInfo.halfLength * 0.85)
								
								if movementType == "Fly" then
									-- Flying pets: vary height based on distance traveled
									local horizontalDist = math.sqrt(offsetX*offsetX + offsetZ*offsetZ)
									local heightRange = gardenInfo.maxHeight - gardenInfo.minHeight
									local heightVariation = (horizontalDist / gardenInfo.halfWidth) * heightRange * 0.5
									local baseHeight = gardenInfo.minHeight + math.random() * (heightRange - heightVariation)
									local height = math.clamp(baseHeight + heightVariation, gardenInfo.minHeight, gardenInfo.maxHeight)
									
									petData.targetPos = gardenInfo.center + Vector3.new(offsetX, height, offsetZ)
								else
									-- Walking pets stay on the ground
									petData.targetPos = gardenInfo.center + Vector3.new(offsetX, 0, offsetZ)
								end
							end
						end
						
						-- Check if pet is outside box bounds
						local currentPos = petBody.Position
						local relativeX = currentPos.X - gardenInfo.center.X
						local relativeZ = currentPos.Z - gardenInfo.center.Z
						
						if math.abs(relativeX) > gardenInfo.halfWidth or math.abs(relativeZ) > gardenInfo.halfLength then
							-- Force pet back to center
							if movementType == "Fly" then
								petData.targetPos = gardenInfo.center + Vector3.new(0, gardenInfo.minHeight + 1, 0)
							else
								petData.targetPos = gardenInfo.center + Vector3.new(0, 0, 0)
							end
							petData.state = "moving"
							petData.stateEndTime = time + 1
						end
						
						local finalTargetPos = petData.targetPos
						
						if movementType == "Fly" then
							-- Add bobbing motion for flying pets (slower for heavier pets)
							local bobOffset = math.sin(time * gardenInfo.bobSpeed / petWeight + index) * gardenInfo.bobAmplitude
							finalTargetPos = finalTargetPos + Vector3.new(0, bobOffset, 0)
						else
							-- Walking pets: raycast to find ground level
							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {petModel, player.Character}
							
							local rayOrigin = petData.targetPos + Vector3.new(0, 10, 0)
							local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -20, 0), rayParams)
							
							if rayResult then
								local petHeight = petBody.Size.Y / 2
								finalTargetPos = rayResult.Position + Vector3.new(0, petHeight + 0.1, 0)
							else
								-- Fallback to garden center height
								finalTargetPos = Vector3.new(petData.targetPos.X, gardenInfo.center.Y + 1, petData.targetPos.Z)
							end
							
							-- Add slight hop/bounce motion for walking pets when moving
							if petData.state == "moving" then
								local hopOffset = math.abs(math.sin(time * 3 + index)) * 0.2
								finalTargetPos = finalTargetPos + Vector3.new(0, hopOffset, 0)
							end
						end
						
						-- Smooth move to target with improved realism
						if petData.state == "moving" then
							-- Create curved path for more natural movement
							local moveProgress = 0
							if petData.lastMoveTime and petData.stateEndTime > petData.lastMoveTime then
								moveProgress = math.clamp((time - petData.lastMoveTime) / (petData.stateEndTime - petData.lastMoveTime), 0, 1)
							end
							
							-- Add slight curve to the movement path (more natural than straight lines)
							local startPos = petData.moveStartPos or currentPos
							local endPos = finalTargetPos
							local midPoint = (startPos + endPos) * 0.5
							
							-- Add perpendicular offset for curve (flying pets curve more)
							local pathDirection = (endPos - startPos)
							if pathDirection.Magnitude > 0.5 then
								local perpendicular = Vector3.new(-pathDirection.Z, 0, pathDirection.X).Unit
								local curveIntensity = movementType == "Fly" and 2.0 or 0.8
								local curveOffset = perpendicular * math.sin(moveProgress * math.pi) * curveIntensity * petWeight
								midPoint = midPoint + curveOffset
							end
							
							-- Bezier curve interpolation for smooth curved movement
							local curvedPos
							if moveProgress < 0.5 then
								-- First half: start to midpoint
								local t = moveProgress * 2
								curvedPos = startPos:Lerp(midPoint, t)
							else
								-- Second half: midpoint to end
								local t = (moveProgress - 0.5) * 2
								curvedPos = midPoint:Lerp(endPos, t)
							end
							
							-- Apply movement with weight-based speed variation
							local weightSpeedFactor = 1 / math.sqrt(petWeight) -- Heavier pets move slower
							local adjustedMoveAlpha = moveAlpha * weightSpeedFactor
							
							local smoothed = currentPos:Lerp(curvedPos, adjustedMoveAlpha)
							bodyPosition.Position = smoothed
							
							-- Face the direction of movement (not just target)
							local movementDirection = smoothed - currentPos
							if movementDirection.Magnitude > 0.1 then
								local lookAheadPos = smoothed + movementDirection.Unit * 2
								faceTarget(petBody, lookAheadPos, movementType)
							end
						else
							-- When idle, gently settle toward the current vertical plane
							local idlePos = Vector3.new(currentPos.X, finalTargetPos.Y, currentPos.Z)
							local smoothedIdle = currentPos:Lerp(idlePos, moveAlpha * 0.5)
							bodyPosition.Position = smoothedIdle
						end
						
						-- Control animation based on movement type
						if movementType == "Walk" then
							-- Walking pets only animate when moving
							setAnimationPlaying(petModel, petData.state == "moving")
						else
							-- Flying pets always animate (hovering)
							setAnimationPlaying(petModel, true)
						end
					end
				end
			end
		end
	end
end

-- Apply pet boost to nearby plants (for both equipped and garden pets)
local function applyPetBoosts()
	local Config = require(ReplicatedStorage.Shared.Config)
	local gardensFolder = Workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then return end
	
	-- Collect all active pets
	local allPets = {}
	for _, pet in ipairs(PetController.EquippedPets) do
		if pet and pet.Parent then
			table.insert(allPets, pet)
		end
	end
	for _, petData in ipairs(PetController.GardenPets) do
		if petData.model and petData.model.Parent then
			table.insert(allPets, petData.model)
		end
	end
	
	-- Scan all gardens for plants
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
			if plotsFolder and plotsFolder:IsA("Folder") then
				-- Check all children of plots folder for plant models
				for _, child in ipairs(plotsFolder:GetChildren()) do
					if child:IsA("Model") and child:GetAttribute("PlantType") then
						local plantPos = child:GetBoundingBox().Position
						local boosted = false
						
						-- Check if any pet is close enough
						for _, petModel in ipairs(allPets) do
							local petBody = petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart")
							if petBody then
								local distance = (plantPos - petBody.Position).Magnitude
								if distance <= PET_BOOST_RADIUS then
									boosted = true
									break
								end
							end
						end
						
						-- Apply or remove boost
						if boosted then
							if not child:GetAttribute("PetBoost") then
								child:SetAttribute("PetBoost", true)
							end
						else
							if child:GetAttribute("PetBoost") then
								child:SetAttribute("PetBoost", false)
							end
						end
					end
				end
			end
		end
	end
end

-- Helper to compare pet arrays and check if respawn is needed
local function arePetArraysEqual(currentPets, newPets, isEquipped)
	-- Handle nil/empty cases
	local currentCount = currentPets and #currentPets or 0
	local newCount = newPets and #newPets or 0
	
	if currentCount == 0 and newCount == 0 then return true end
	if currentCount ~= newCount then return false end
	if not newPets then return currentCount == 0 end
	
	-- Build a set of current pet IDs for fast lookup
	local currentPetIds = {}
	for _, entry in ipairs(currentPets) do
		local model = isEquipped and entry or (entry and entry.model)
		if model and model.Parent then
			local petId = model:GetAttribute("PetId")
			if petId then
				currentPetIds[petId] = true
			end
		end
	end
	
	-- Check if all new pets exist in current pets
	local matchedCount = 0
	for _, newPet in ipairs(newPets) do
		local newPetId = newPet.Id
		if newPetId and currentPetIds[newPetId] then
			matchedCount = matchedCount + 1
		else
			-- Pet not found by ID, they're different
			return false
		end
	end
	
	-- Ensure we matched all current pets
	return matchedCount == currentCount
end

-- Spawn equipped pets (follow player)
-- equippedPets is now an array of pet instances: [{Id, PetType, Size, Weight}]
function PetController.SpawnEquippedPets(equippedPets)
	-- Check if pets are the same - skip respawn if unchanged
	if arePetArraysEqual(PetController.EquippedPets, equippedPets, true) then
		return -- No change, skip respawn
	end
	
	-- Remove all existing equipped pets
	for _, petModel in ipairs(PetController.EquippedPets) do
		if petModel and petModel.Parent then
			stopMoveAnimation(petModel)
			petModel:Destroy()
		end
	end
	PetController.EquippedPets = {}
	
	-- Validate equipped pets array
	if not equippedPets or type(equippedPets) ~= "table" then
		return
	end
	
	-- Limit to MAX_EQUIPPED_PETS
	local petsToSpawn = math.min(#equippedPets, MAX_EQUIPPED_PETS)
	
	for i = 1, petsToSpawn do
		local petInstance = equippedPets[i]
		if petInstance then
			local petModel = createPetModel(petInstance, player.Name .. "_Equipped_" .. i)
			if petModel then
				petModel.Parent = Workspace
				ensureMoveAnimation(petModel)
				
				-- Position pet near player
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = player.Character.HumanoidRootPart
					local angle = (i - 1) * (math.pi * 2 / petsToSpawn)
					local offsetX = math.cos(angle) * 3
					local offsetZ = math.sin(angle) * 3
					local spawnPosition = hrp.Position + Vector3.new(offsetX, 2, offsetZ)
					
					if petModel.PrimaryPart then
						petModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
						local bodyPosition = petModel.PrimaryPart:FindFirstChild("BodyPosition")
						if bodyPosition then
							bodyPosition.Position = spawnPosition
						end
					end
				end
				
				table.insert(PetController.EquippedPets, petModel)
			end
		end
	end
end

-- Spawn garden pets (roam in garden)
-- gardenPets is now an array of pet instances: [{Id, PetType, Size, Weight}]
function PetController.SpawnGardenPets(gardenPets)
	-- Check if pets are the same - skip respawn if unchanged
	if arePetArraysEqual(PetController.GardenPets, gardenPets, false) then
		return -- No change, skip respawn
	end
	
	-- Remove all existing garden pets
	for _, petData in ipairs(PetController.GardenPets) do
		if petData.model and petData.model.Parent then
			stopMoveAnimation(petData.model)
			petData.model:Destroy()
		end
	end
	PetController.GardenPets = {}
	
	-- Validate garden pets array
	if not gardenPets or type(gardenPets) ~= "table" or #gardenPets == 0 then
		return
	end
	
	-- Get garden info with retry (garden may not be assigned yet)
	local gardenInfo = nil
	local maxRetries = 10
	for attempt = 1, maxRetries do
		gardenInfo = getPlayerGardenInfo()
		if gardenInfo then
			break
		end
		-- Wait a bit and retry
		task.wait(0.5)
	end
	
	if not gardenInfo then
		warn("[PetController] Cannot spawn garden pets - player garden not found after", maxRetries, "attempts")
		return
	end
	
	-- Limit to MAX_GARDEN_PETS
	local petsToSpawn = math.min(#gardenPets, MAX_GARDEN_PETS)
	
	for i = 1, petsToSpawn do
		local petInstance = gardenPets[i]
		if petInstance then
			local petModel = createPetModel(petInstance, player.Name .. "_Garden_" .. i)
			if petModel then
				petModel.Parent = Workspace
				ensureMoveAnimation(petModel)
				
				-- Position pet in garden (random within bounds)
				local offsetX = (math.random() * 2 - 1) * gardenInfo.halfWidth * 0.6
				local offsetZ = (math.random() * 2 - 1) * gardenInfo.halfLength * 0.6
				
				local movementType = petModel:GetAttribute("MovementType") or "Fly"
				local spawnPosition
				
				if movementType == "Fly" then
					-- Flying pets spawn at random heights
					local height = gardenInfo.minHeight + math.random() * (gardenInfo.maxHeight - gardenInfo.minHeight)
					spawnPosition = gardenInfo.center + Vector3.new(offsetX, height, offsetZ)
				else
					-- Walking pets spawn at ground level (raycast to find ground)
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = {petModel, player.Character}
					
					local rayOrigin = gardenInfo.center + Vector3.new(offsetX, 10, offsetZ)
					local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -20, 0), rayParams)
					
					if rayResult then
						local petHeight = petModel.PrimaryPart and (petModel.PrimaryPart.Size.Y / 2) or 1
						spawnPosition = rayResult.Position + Vector3.new(0, petHeight + 0.1, 0)
					else
						-- Fallback to garden center height
						spawnPosition = gardenInfo.center + Vector3.new(offsetX, 1, offsetZ)
					end
				end
				
				if petModel.PrimaryPart then
					petModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
					local bodyPosition = petModel.PrimaryPart:FindFirstChild("BodyPosition")
					if bodyPosition then
						bodyPosition.Position = spawnPosition
					end
				end
				
				-- Add to garden pets with roaming data
				table.insert(PetController.GardenPets, {
					model = petModel,
					targetPos = spawnPosition,
					state = "idle",
					stateEndTime = tick() + math.random(gardenInfo.minIdleTime or 3, gardenInfo.maxIdleTime or 8)
				})
			end
		end
	end
end

-- Remove a specific equipped pet
function PetController.RemoveEquippedPet(index)
	if PetController.EquippedPets[index] then
		local petModel = PetController.EquippedPets[index]
		stopMoveAnimation(petModel)
		if petModel.Parent then
			petModel:Destroy()
		end
		table.remove(PetController.EquippedPets, index)
	end
end

-- Remove a specific garden pet
function PetController.RemoveGardenPet(index)
	if PetController.GardenPets[index] then
		local petModel = PetController.GardenPets[index].model
		stopMoveAnimation(petModel)
		if petModel and petModel.Parent then
			petModel:Destroy()
		end
		table.remove(PetController.GardenPets, index)
	end
end

-- Initialize pet controller
-- Track pending garden pets to spawn (for when garden isn't assigned yet)
local pendingGardenPets = nil
local gardenAssignedListenerConnected = false

function PetController.Initialize()
	-- print("PetController initialized")
	
	-- Helper to spawn pending garden pets once garden is available
	local function trySpawnPendingGardenPets()
		if pendingGardenPets and #pendingGardenPets > 0 then
			local gardenInfo = getPlayerGardenInfo()
			if gardenInfo then
				PetController.SpawnGardenPets(pendingGardenPets)
				pendingGardenPets = nil
			end
		end
	end
	
	-- Set up listener for when gardens get assigned (OwnerUserId attribute changes)
	local function setupGardenListener()
		if gardenAssignedListenerConnected then return end
		
		local gardensFolder = Workspace:FindFirstChild(Config.World.GardensFolder)
		if not gardensFolder then return end
		
		for _, garden in ipairs(gardensFolder:GetChildren()) do
			if garden:IsA("Folder") then
				garden:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
					local ownerUserId = garden:GetAttribute("OwnerUserId")
					if ownerUserId == player.UserId then
						-- Garden was just assigned to us, try spawning pending pets
						task.wait(0.1) -- Small delay to let garden setup complete
						trySpawnPendingGardenPets()
					end
				end)
			end
		end
		
		gardenAssignedListenerConnected = true
	end
	
	-- Listen for inventory updates to spawn pets
	local updateInventoryEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_INVENTORY)
	updateInventoryEvent.OnClientEvent:Connect(function(inventory)
		-- Spawn equipped pets (follow player)
		-- Only update if EquippedPets key is present in inventory
		if inventory.EquippedPets ~= nil then
			if type(inventory.EquippedPets) == "table" and #inventory.EquippedPets > 0 then
				PetController.SpawnEquippedPets(inventory.EquippedPets)
			elseif type(inventory.EquippedPets) == "table" and #inventory.EquippedPets == 0 then
				-- Only clear pets if server explicitly sends empty array
				if #PetController.EquippedPets > 0 then
					for _, petModel in ipairs(PetController.EquippedPets) do
						if petModel and petModel.Parent then
							stopMoveAnimation(petModel)
							petModel:Destroy()
						end
					end
					PetController.EquippedPets = {}
				end
			end
		end
		-- If EquippedPets key is nil/missing, keep existing pets (no change)
		
		-- Spawn garden pets (roam in garden)
		-- Only update if GardenPets key is present in inventory
		if inventory.GardenPets ~= nil then
			if type(inventory.GardenPets) == "table" and #inventory.GardenPets > 0 then
				-- Store pending pets in case garden isn't assigned yet
				pendingGardenPets = inventory.GardenPets
				PetController.SpawnGardenPets(inventory.GardenPets)
			elseif type(inventory.GardenPets) == "table" and #inventory.GardenPets == 0 then
				pendingGardenPets = nil
				-- Only clear pets if server explicitly sends empty array
				if #PetController.GardenPets > 0 then
					for _, petData in ipairs(PetController.GardenPets) do
						if petData.model and petData.model.Parent then
							stopMoveAnimation(petData.model)
							petData.model:Destroy()
						end
					end
					PetController.GardenPets = {}
				end
			end
		end
		-- If GardenPets key is nil/missing, keep existing pets (no change)
	end)
	
	-- Set up garden assignment listener
	setupGardenListener()
	
	-- Update pets on every frame
	RunService.RenderStepped:Connect(function(dt)
		updateEquippedPets(dt)
		updateGardenPets(dt)
		applyPetBoosts()
	end)
	
	-- Respawn pets when character respawns
	player.CharacterAdded:Connect(function(character)
		task.wait(1) -- Wait for character to load
		
		-- Respawn equipped pets
		local currentEquipped = {}
		for _, petModel in ipairs(PetController.EquippedPets) do
			if petModel then
				local petType = petModel:GetAttribute("PetType")
				if petType then
					table.insert(currentEquipped, petType)
				end
			end
		end
		if #currentEquipped > 0 then
			PetController.SpawnEquippedPets(currentEquipped)
		end
	end)
end

return PetController
