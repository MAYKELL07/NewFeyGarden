-- PetController.luau
-- Handles pet spawning and following behavior on client

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Config = require(ReplicatedStorage.Shared.Config)
local BuffsModule = require(ReplicatedStorage.Shared.BuffsModule)
local VFXModule = require(ReplicatedStorage.Shared.VFXModule)

local PetController = {}
PetController.CurrentPet = nil
local player = Players.LocalPlayer
local PET_BOOST_RADIUS = 12

-- Create pet model
local function createPetModel(petType)
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
	petModel.Name = player.Name .. "_Pet"
	
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
		-- Position will be set in updatePetFollow
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

-- Update pet follow behavior and apply proximity buffs
local function updatePetFollow()
	if not PetController.CurrentPet then return end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	
	local petBody = PetController.CurrentPet:FindFirstChild("Body")
	if not petBody then return end
	
	local bodyPosition = petBody:FindFirstChild("BodyPosition")
	if not bodyPosition then return end
	
	local hrp = player.Character.HumanoidRootPart
	local petType = PetController.CurrentPet:GetAttribute("PetType")
	local config = Constants.PET_CONFIG[petType]
	
	if not config then return end
	
	-- Calculate follow position (behind and to the right of player)
	local offset = Vector3.new(config.FollowDistance, 2, config.FollowDistance)
	local targetPosition = hrp.Position + offset
	
	-- Add bobbing motion
	local time = tick()
	local bobOffset = math.sin(time * 2) * 0.5
	
	-- Smooth follow with BodyPosition
	bodyPosition.Position = targetPosition + Vector3.new(0, bobOffset, 0)
	
	-- Update BodyGyro for smooth rotation
	local bodyGyro = petBody:FindFirstChild("BodyGyro")
	if bodyGyro then
		-- Slow rotation around Y axis
		local rotationSpeed = time * 0.5
		bodyGyro.CFrame = CFrame.Angles(0, rotationSpeed, 0)
	end
	
	-- Apply pet boost to nearby plants
	local Config = require(ReplicatedStorage.Shared.Config)
	local gardensFolder = Workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then return end
	
	local petPosition = petBody.Position
	
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
								local distance = (plantPos - petPosition).Magnitude
								
								-- Apply boost if close enough
								if distance <= PET_BOOST_RADIUS then
									if not child:GetAttribute("PetBoost") then
										child:SetAttribute("PetBoost", true)
										-- print(string.format("[PetController] Pet boosting plant at distance %.1f", distance))
									end
								else
									-- Remove boost if too far
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

-- Spawn a pet
function PetController.SpawnPet(petType)
	-- Remove existing pet
	if PetController.CurrentPet then
		PetController.CurrentPet:Destroy()
		PetController.CurrentPet = nil
	end
	
	-- Create new pet
	local petModel = createPetModel(petType)
	if not petModel then
		warn("Failed to create pet:", petType)
		return
	end
	
	-- Parent to workspace first
	petModel.Parent = Workspace
	
	-- Position pet near player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local spawnPosition = hrp.Position + Vector3.new(3, 2, 3)
		
		-- Set the model position
		if petModel.PrimaryPart then
			petModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
			
			-- Initialize BodyPosition to current position
			local bodyPosition = petModel.PrimaryPart:FindFirstChild("BodyPosition")
			if bodyPosition then
				bodyPosition.Position = spawnPosition
			end
		end
	end
	
	PetController.CurrentPet = petModel
	
	-- print("Spawned pet:", petType)
end

-- Initialize pet controller
function PetController.Initialize()
	-- print("PetController initialized")
	
	-- Listen for inventory updates to spawn equipped pet
	local updateInventoryEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_INVENTORY)
	updateInventoryEvent.OnClientEvent:Connect(function(inventory)
		-- Check if player has an equipped pet
		if inventory.EquippedPet then
			-- Only spawn if it's different from current pet
			local currentPetType = PetController.CurrentPet and PetController.CurrentPet:GetAttribute("PetType")
			if currentPetType ~= inventory.EquippedPet then
				PetController.SpawnPet(inventory.EquippedPet)
			end
		else
			-- No equipped pet, remove current pet
			if PetController.CurrentPet then
				PetController.CurrentPet:Destroy()
				PetController.CurrentPet = nil
			end
		end
	end)
	
	-- Update pet follow on every frame
	RunService.RenderStepped:Connect(updatePetFollow)
	
	-- Respawn pet when character respawns
	player.CharacterAdded:Connect(function(character)
		if PetController.CurrentPet then
			local petType = PetController.CurrentPet:GetAttribute("PetType")
			task.wait(1) -- Wait for character to load
			PetController.SpawnPet(petType)
		end
	end)
end

return PetController
