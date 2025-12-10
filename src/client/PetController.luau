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
PetController.EquippedPets = {} -- Array of pets following player (max 2)
PetController.GardenPets = {} -- Array of pets roaming in garden (max 5)
local player = Players.LocalPlayer
local PET_BOOST_RADIUS = 12
local GARDEN_ROAM_RADIUS = 20 -- How far pets can roam from garden center
local MAX_EQUIPPED_PETS = 2
local MAX_GARDEN_PETS = 5

-- Create pet model
local function createPetModel(petType, petName)
	local config = Constants.PET_CONFIG[petType]
	if not config then return nil end
	
	-- Get pet models from ReplicatedStorage
	local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
	if not petsFolder then
		warn("[PetController] Pets folder not found in ReplicatedStorage")
		return nil
	end
	
	local petMesh = petsFolder:FindFirstChild(petType)
	if not petMesh then
		warn("[PetController] Pet mesh not found for:", petType)
		return nil
	end
	
	-- Clone the pet mesh
	local clonedPet = petMesh:Clone()
	
	-- Always create a Model container for the pet
	local petModel = Instance.new("Model")
	petModel.Name = petName or (player.Name .. "_Pet")
	
	-- Find or use the main part (should be a MeshPart)
	local body
	if clonedPet:IsA("MeshPart") then
		body = clonedPet
		body.Parent = petModel
	else
		-- If it's already a model, find the MeshPart inside
		body = clonedPet:FindFirstChildWhichIsA("MeshPart")
		if body then
			clonedPet:Destroy()
			body = body:Clone()
			body.Parent = petModel
		else
			warn("[PetController] No MeshPart found in pet:", petType)
			return nil
		end
	end
	
	-- Setup physics
	if body then
		body.Name = "Body"
		body.CanCollide = false
		body.Anchored = false
		body.Size = Vector3.new(2, 2, 2) -- Ensure it has a size
		body.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1) -- Light and bouncy
		
		-- Add glow effect
		local light = Instance.new("PointLight")
		light.Brightness = 1
		light.Range = 8
		light.Color = config.Color
		light.Parent = body
		
		-- Add floating effect with BodyPosition
		local bodyPosition = Instance.new("BodyPosition")
		bodyPosition.MaxForce = Vector3.new(10000, 10000, 10000) -- Stronger force
		bodyPosition.P = 5000
		bodyPosition.D = 1000
		-- Position will be set in updatePetFollow or updateGardenPets
		bodyPosition.Parent = body
		
		-- Add slight rotation
		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
		bodyGyro.P = 3000
		bodyGyro.D = 500
		bodyGyro.Parent = body
		
		petModel.PrimaryPart = body
	end
	
	petModel:SetAttribute("PetType", petType)
	
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
			local petBody = petModel:FindFirstChild("Body")
			if petBody then
				local bodyPosition = petBody:FindFirstChild("BodyPosition")
				if bodyPosition then
					local petType = petModel:GetAttribute("PetType")
					local config = Constants.PET_CONFIG[petType]
					
					if config then
						-- Calculate follow position (spread pets around player)
						local angle = (index - 1) * (math.pi * 2 / MAX_EQUIPPED_PETS)
						local offsetX = math.cos(angle) * config.FollowDistance
						local offsetZ = math.sin(angle) * config.FollowDistance
						local offset = Vector3.new(offsetX, 2, offsetZ)
						local targetPosition = hrp.Position + offset
						
						-- Add bobbing motion
						local bobOffset = math.sin(time * 2 + index) * 0.5
						
						-- Smooth follow with BodyPosition
						bodyPosition.Position = targetPosition + Vector3.new(0, bobOffset, 0)
						
						-- Update BodyGyro for smooth rotation
						local bodyGyro = petBody:FindFirstChild("BodyGyro")
						if bodyGyro then
							local rotationSpeed = time * 0.5
							bodyGyro.CFrame = CFrame.Angles(0, rotationSpeed, 0)
						end
					end
				end
			end
		end
	end
end

-- Get player's garden center position
local function getPlayerGardenCenter()
	local gardensFolder = Workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then return nil end
	
	-- Find player's assigned garden
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
							-- Found player's garden, return floor center
							local floor = garden:FindFirstChild(Config.World.FloorName)
							if floor then
								return floor.Position
							end
						end
					end
				end
			end
		end
	end
	
	return nil
end

-- Update garden pets roaming behavior
local function updateGardenPets()
	if #PetController.GardenPets == 0 then return end
	
	local gardenCenter = getPlayerGardenCenter()
	if not gardenCenter then return end
	
	local time = tick()
	
	for index, petData in ipairs(PetController.GardenPets) do
		local petModel = petData.model
		if petModel and petModel.Parent then
			local petBody = petModel:FindFirstChild("Body")
			if petBody then
				local bodyPosition = petBody:FindFirstChild("BodyPosition")
				if bodyPosition then
					local petType = petModel:GetAttribute("PetType")
					local config = Constants.PET_CONFIG[petType]
					
					if config then
						-- Initialize roam target if not set
						if not petData.roamTarget or not petData.roamTime or time > petData.roamTime then
							-- Pick a random point within garden bounds
							local randomAngle = math.random() * math.pi * 2
							local randomDistance = math.random() * GARDEN_ROAM_RADIUS * 0.8
							local randomX = math.cos(randomAngle) * randomDistance
							local randomZ = math.sin(randomAngle) * randomDistance
							
							petData.roamTarget = gardenCenter + Vector3.new(randomX, 2, randomZ)
							petData.roamTime = time + math.random(5, 10) -- New target every 5-10 seconds
						end
						
						-- Check if pet is outside garden bounds
						local currentPos = petBody.Position
						local distanceFromCenter = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(gardenCenter.X, 0, gardenCenter.Z)).Magnitude
						
						if distanceFromCenter > GARDEN_ROAM_RADIUS then
							-- Force pet back to garden center
							petData.roamTarget = gardenCenter + Vector3.new(0, 2, 0)
							petData.roamTime = time + 0.5
						end
						
						-- Add bobbing motion
						local bobOffset = math.sin(time * 2 + index) * 0.5
						
						-- Smooth move to roam target
						bodyPosition.Position = petData.roamTarget + Vector3.new(0, bobOffset, 0)
						
						-- Update BodyGyro for smooth rotation
						local bodyGyro = petBody:FindFirstChild("BodyGyro")
						if bodyGyro then
							local rotationSpeed = time * 0.3
							bodyGyro.CFrame = CFrame.Angles(0, rotationSpeed, 0)
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
									local petBody = petModel:FindFirstChild("Body")
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
function PetController.SpawnEquippedPets(equippedPets)
	-- Remove all existing equipped pets
	for _, petModel in ipairs(PetController.EquippedPets) do
		if petModel and petModel.Parent then
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
		local petType = equippedPets[i]
		if petType then
			local petModel = createPetModel(petType, player.Name .. "_Equipped_" .. i)
			if petModel then
				petModel.Parent = Workspace
				
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
function PetController.SpawnGardenPets(gardenPets)
	-- Remove all existing garden pets
	for _, petData in ipairs(PetController.GardenPets) do
		if petData.model and petData.model.Parent then
			petData.model:Destroy()
		end
	end
	PetController.GardenPets = {}
	
	-- Validate garden pets array
	if not gardenPets or type(gardenPets) ~= "table" then
		return
	end
	
	-- Get garden center
	local gardenCenter = getPlayerGardenCenter()
	if not gardenCenter then
		warn("[PetController] Cannot spawn garden pets - player garden not found")
		return
	end
	
	-- Limit to MAX_GARDEN_PETS
	local petsToSpawn = math.min(#gardenPets, MAX_GARDEN_PETS)
	
	for i = 1, petsToSpawn do
		local petType = gardenPets[i]
		if petType then
			local petModel = createPetModel(petType, player.Name .. "_Garden_" .. i)
			if petModel then
				petModel.Parent = Workspace
				
				-- Position pet in garden
				local angle = (i - 1) * (math.pi * 2 / petsToSpawn)
				local distance = GARDEN_ROAM_RADIUS * 0.5
				local offsetX = math.cos(angle) * distance
				local offsetZ = math.sin(angle) * distance
				local spawnPosition = gardenCenter + Vector3.new(offsetX, 2, offsetZ)
				
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
					roamTarget = spawnPosition,
					roamTime = tick() + math.random(3, 8)
				})
			end
		end
	end
end

-- Remove a specific equipped pet
function PetController.RemoveEquippedPet(index)
	if PetController.EquippedPets[index] then
		if PetController.EquippedPets[index].Parent then
			PetController.EquippedPets[index]:Destroy()
		end
		table.remove(PetController.EquippedPets, index)
	end
end

-- Remove a specific garden pet
function PetController.RemoveGardenPet(index)
	if PetController.GardenPets[index] then
		if PetController.GardenPets[index].model and PetController.GardenPets[index].model.Parent then
			PetController.GardenPets[index].model:Destroy()
		end
		table.remove(PetController.GardenPets, index)
	end
end

-- Initialize pet controller
function PetController.Initialize()
	-- print("PetController initialized")
	
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
			PetController.SpawnGardenPets(inventory.GardenPets)
		else
			-- Remove all garden pets if none
			for _, petData in ipairs(PetController.GardenPets) do
				if petData.model and petData.model.Parent then
					petData.model:Destroy()
				end
			end
			PetController.GardenPets = {}
		end
	end)
	
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
