-- PetController.luau
-- Handles pet spawning and following behavior on client

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)

local PetController = {}
PetController.CurrentPet = nil
local player = Players.LocalPlayer

-- Create pet model
local function createPetModel(petType)
	local config = Constants.PET_CONFIG[petType]
	if not config then return nil end
	
	-- Create pet model
	local petModel = Instance.new("Model")
	petModel.Name = player.Name .. "_Pet"
	
	-- Create main body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 2, 2)
	body.Shape = Enum.PartType.Ball
	body.Color = config.Color
	body.Material = Enum.Material.Neon
	body.CanCollide = false
	body.Anchored = false
	body.Parent = petModel
	
	-- Add glow effect
	local light = Instance.new("PointLight")
	light.Brightness = 1
	light.Range = 8
	light.Color = config.Color
	light.Parent = body
	
	-- Add floating effect with BodyPosition
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyPosition.P = 10000
	bodyPosition.D = 500
	bodyPosition.Parent = body
	
	-- Add slight rotation
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(400, 400, 400)
	bodyGyro.P = 3000
	bodyGyro.Parent = body
	
	petModel.PrimaryPart = body
	petModel:SetAttribute("PetType", petType)
	
	return petModel
end

-- Update pet follow behavior
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
	
	-- Smooth follow with BodyPosition
	bodyPosition.Position = targetPosition
	
	-- Add bobbing motion
	local time = tick()
	local bobOffset = math.sin(time * 2) * 0.5
	bodyPosition.Position = targetPosition + Vector3.new(0, bobOffset, 0)
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
	
	-- Position pet near player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		petModel:MoveTo(hrp.Position + Vector3.new(3, 2, 3))
	end
	
	petModel.Parent = Workspace
	PetController.CurrentPet = petModel
	
	print("Spawned pet:", petType)
end

-- Initialize pet controller
function PetController.Initialize()
	print("PetController initialized")
	
	-- Listen for inventory updates to spawn pets
	local updateInventoryEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.UPDATE_INVENTORY)
	updateInventoryEvent.OnClientEvent:Connect(function(inventory)
		-- Check if player has any pets
		if inventory.Pets then
			for petType, owned in pairs(inventory.Pets) do
				if owned and not PetController.CurrentPet then
					PetController.SpawnPet(petType)
					break
				end
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
