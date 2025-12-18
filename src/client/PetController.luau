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
local PET_BOOST_RADIUS = 12
local MAX_EQUIPPED_PETS = Constants.MAX_EQUIPPED_PETS or 3
local MAX_GARDEN_PETS = Constants.MAX_GARDEN_PETS or 7

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

local function ensureMoveAnimation(model)
	if animationTracks[model] then return end

	local anim = model:FindFirstChild("Automatic Save", true)
	if not (anim and anim:IsA("Animation")) then return end

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

	local direction = targetPosition - petBody.Position
	if movementType ~= "Fly" then
		direction = Vector3.new(direction.X, 0, direction.Z)
	end
	if direction.Magnitude < 0.1 then return end

	local lookTarget = petBody.Position + direction.Unit
	bodyGyro.CFrame = CFrame.lookAt(petBody.Position, lookTarget, Vector3.yAxis)
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
	
	-- Weld all parts to the primary part so the model moves as one unit
	if petModel:IsA("Model") and body then
		for _, part in ipairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") and part ~= body then
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
						-- Calculate follow position (spread pets around player)
						local angle = (index - 1) * (math.pi * 2 / MAX_EQUIPPED_PETS)
						local offsetX = math.cos(angle) * config.FollowDistance
						local offsetZ = math.sin(angle) * config.FollowDistance
						
						local targetPosition
						if movementType == "Fly" then
							-- Flying pets hover above/around the player
							local offset = Vector3.new(offsetX, 2, offsetZ)
							targetPosition = hrp.Position + offset
							
							-- Add bobbing motion for flying pets
							local bobOffset = math.sin(time * 2 + index) * 0.5
							targetPosition = targetPosition + Vector3.new(0, bobOffset, 0)
						else
							-- Walking pets stay on the ground near the player
							local offset = Vector3.new(offsetX, 0, offsetZ)
							targetPosition = hrp.Position + offset
							
							-- Raycast to find ground level
							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {player.Character, petModel}
							
							local rayOrigin = targetPosition + Vector3.new(0, 5, 0)
							local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -15, 0), rayParams)
							
							if rayResult then
								-- Place pet on the ground with a small offset for pet height
								local petHeight = petBody.Size.Y / 2
								targetPosition = rayResult.Position + Vector3.new(0, petHeight + 0.1, 0)
							else
								-- Fallback: use player's Y position
								targetPosition = Vector3.new(targetPosition.X, hrp.Position.Y - 2, targetPosition.Z)
							end
							
							-- Add slight hop/bounce motion for walking pets
							local hopOffset = math.abs(math.sin(time * 4 + index)) * 0.15
							targetPosition = targetPosition + Vector3.new(0, hopOffset, 0)
						end
						
						-- Smooth follow with BodyPosition
						bodyPosition.Position = targetPosition

						-- Make pet face its movement direction (fly and walk)
						faceTarget(petBody, targetPosition, movementType)
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
			halfWidth = roamConfig.BoundsHalfWidth or 18,
			halfLength = roamConfig.BoundsHalfLength or 18,
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
local function updateGardenPets()
	if #PetController.GardenPets == 0 then return end
	
	local gardenInfo = getPlayerGardenInfo()
	if not gardenInfo then return end
	
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
						end
						
						-- Check if state should change
						if time > petData.stateEndTime then
							-- Decide next state
							if math.random() < gardenInfo.idleChance then
								petData.state = "idle"
								petData.stateEndTime = time + math.random(gardenInfo.minIdleTime, gardenInfo.maxIdleTime)
							else
								petData.state = "moving"
								petData.stateEndTime = time + math.random(gardenInfo.minMoveTime, gardenInfo.maxMoveTime)
								
								-- Pick a random point within box bounds
								local offsetX = (math.random() * 2 - 1) * gardenInfo.halfWidth * 0.8
								local offsetZ = (math.random() * 2 - 1) * gardenInfo.halfLength * 0.8
								
								if movementType == "Fly" then
									-- Flying pets roam at various heights
									local height = gardenInfo.minHeight + math.random() * (gardenInfo.maxHeight - gardenInfo.minHeight)
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
						
						-- Smooth move to target
						if petData.state == "moving" then
							bodyPosition.Position = finalTargetPos
						else
							-- When idle, stay in place with subtle motion
							if movementType == "Fly" then
								local idlePos = Vector3.new(currentPos.X, finalTargetPos.Y, currentPos.Z)
								bodyPosition.Position = idlePos
							else
								-- Walking pets just sit still when idle
								bodyPosition.Position = Vector3.new(currentPos.X, finalTargetPos.Y, currentPos.Z)
							end
						end
						
						-- Face the direction of travel when moving
						if petData.state == "moving" then
							faceTarget(petBody, finalTargetPos, movementType)
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
				-- Check each PlantAnchor
				for _, anchor in ipairs(plotsFolder:GetChildren()) do
					if anchor:IsA("BasePart") then
						-- Find plant model in anchor
						for _, child in ipairs(anchor:GetChildren()) do
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
	end
end

-- Spawn equipped pets (follow player)
-- equippedPets is now an array of pet instances: [{Id, PetType, Size, Weight}]
function PetController.SpawnEquippedPets(equippedPets)
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
		if inventory.EquippedPets and type(inventory.EquippedPets) == "table" then
			PetController.SpawnEquippedPets(inventory.EquippedPets)
		else
			-- Remove all equipped pets if none
			for _, petModel in ipairs(PetController.EquippedPets) do
				if petModel and petModel.Parent then
					petModel:Destroy()
				end
			end
			PetController.EquippedPets = {}
		end
		
		-- Spawn garden pets (roam in garden)
		if inventory.GardenPets and type(inventory.GardenPets) == "table" then
			-- Store pending pets in case garden isn't assigned yet
			pendingGardenPets = inventory.GardenPets
			PetController.SpawnGardenPets(inventory.GardenPets)
		else
			pendingGardenPets = nil
			-- Remove all garden pets if none
			for _, petData in ipairs(PetController.GardenPets) do
				if petData.model and petData.model.Parent then
					petData.model:Destroy()
				end
			end
			PetController.GardenPets = {}
		end
	end)
	
	-- Set up garden assignment listener
	setupGardenListener()
	
	-- Update pets on every frame
	RunService.RenderStepped:Connect(function()
		updateEquippedPets()
		updateGardenPets()
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
