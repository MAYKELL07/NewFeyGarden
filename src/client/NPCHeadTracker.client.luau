--!strict
-- NPCHeadTracker.client.luau
-- NPC heads follow the player with a limited, smoothed yaw rotation.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not sharedFolder then
	warn("[NPCHeadTracker] Shared folder not found")
	return
end

local player = Players.LocalPlayer :: Player

type NPCData = {
	head: Model | BasePart,
	baseForward: Vector3,
	currentAngle: number,
}

local NPCHeadTracker = {}

-- Configuration
local MAX_TRACK_DISTANCE = 20 -- studs - NPC will only track if player is within this range
local MAX_PAN_ANGLE = math.rad(70) -- Maximum pan angle from forward (70 degrees each way)
local TURN_SPEED = 8 -- Higher means faster response; smoothing keeps motion natural
local NPC_FOLDER_NAME = "NPCs" -- Where NPCs are stored in workspace

-- Cache for NPC data
local trackedNPCs: { [Model]: NPCData } = {}

-- Get the player's head/torso position
local function getPlayerPosition()
	local character = player.Character
	if not character then return nil end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		return humanoidRootPart.Position
	end
	
	local head = character:FindFirstChild("Head")
	if head then
		return head.Position
	end
	
	return nil
end

-- Find the head of an NPC (no motors required; many NPCs are unrigged)
local function findNPCHead(npcModel)
	local head = npcModel:FindFirstChild("Head")
	if not head then
		return nil
	end

	if head:IsA("Model") or head:IsA("BasePart") then
		return head
	end

	return nil
end

local function getHeadPivotCFrame(head)
	if head:IsA("Model") then
		return head:GetPivot()
	end

	return head.CFrame
end

local function computeBaseForward(npcModel: Model, head: Model | BasePart)
	local pivotCF = if npcModel.PrimaryPart then npcModel.PrimaryPart.CFrame else npcModel:GetPivot()
	local forward = pivotCF.LookVector
	forward = Vector3.new(forward.X, 0, forward.Z)
	if forward.Magnitude < 0.001 then
		forward = Vector3.new(0, 0, -1)
	else
		forward = forward.Unit
	end

	-- Some NPC heads are modeled backwards. Use the head's current look to detect and flip.
	local headCF = if head:IsA("Model") then head:GetPivot() else head.CFrame
	local headForward = headCF.LookVector
	headForward = Vector3.new(headForward.X, 0, headForward.Z)
	if headForward.Magnitude > 0.001 and headForward.Unit:Dot(forward) < 0 then
		forward = -forward
	end

	return forward
end

-- Register an NPC for tracking
local function registerNPC(npcModel)
	if trackedNPCs[npcModel] then return end

	local head = findNPCHead(npcModel)
	if not head then return end

	-- Base forward comes from the model's facing; flipped if the head is modeled backwards
	local baseForward = computeBaseForward(npcModel, head)

	trackedNPCs[npcModel] = {
		head = head,
		baseForward = baseForward,
		currentAngle = 0,
	}
end

-- Unregister an NPC
local function unregisterNPC(npcModel)
	local data = trackedNPCs[npcModel]
	if data and data.head then
		-- Restore original facing direction
		local head = data.head
		local baseForward = data.baseForward or Vector3.new(0, 0, 1)
		local pivotCF = getHeadPivotCFrame(head)
		local targetCF = CFrame.lookAt(pivotCF.Position, pivotCF.Position + baseForward, Vector3.yAxis)

		if head:IsA("Model") then
			head:PivotTo(targetCF)
		else
			head.CFrame = targetCF
		end
	end
	trackedNPCs[npcModel] = nil
end

-- Scan for NPCs in the world
local function findAllNPCs()
	-- Check NPC folder in workspace
	local npcsFolder = workspace:FindFirstChild(NPC_FOLDER_NAME)
	if npcsFolder then
		for _, npc in ipairs(npcsFolder:GetChildren()) do
			if npc:IsA("Model") then
				-- Check if it has a Head part (all NPCs should have one)
				if npc:FindFirstChild("Head") then
					registerNPC(npc)
				end
			end
		end
	else
		warn("[NPCHeadTracker] NPC folder not found in workspace")
	end
end

-- Update head rotation for a single NPC
local function updateNPCHead(npcData, playerPos, deltaTime)
	local head = npcData.head
	if not head or not head.Parent then
		return false
	end

	local pivotCF = getHeadPivotCFrame(head)
	local headPos = pivotCF.Position
	local distance = (playerPos - headPos).Magnitude

	local targetAngle = 0
	local baseForward = npcData.baseForward or Vector3.new(0, 0, 1)

	if distance <= MAX_TRACK_DISTANCE then
		local directionToPlayer = playerPos - headPos
		directionToPlayer = Vector3.new(directionToPlayer.X, 0, directionToPlayer.Z)
		if directionToPlayer.Magnitude < 0.001 then
			directionToPlayer = baseForward
		else
			directionToPlayer = directionToPlayer.Unit
		end

		-- Angle between base forward and player direction
		local dotProduct = baseForward:Dot(directionToPlayer)
		local crossProduct = baseForward:Cross(directionToPlayer)
		targetAngle = math.atan2(crossProduct.Y, dotProduct)
		targetAngle = math.clamp(targetAngle, -MAX_PAN_ANGLE, MAX_PAN_ANGLE)
	end

	local currentAngle = npcData.currentAngle
	local angleDiff = targetAngle - currentAngle
	local alpha = 1 - math.exp(-TURN_SPEED * deltaTime) -- exponential smoothing for consistent motion
	local smoothedAngle = currentAngle + angleDiff * alpha
	npcData.currentAngle = smoothedAngle

	-- Apply rotation directly to head (works for unrigged NPCs)
	-- Invert the applied rotation so heads turn the opposite way.
	local appliedAngle = -smoothedAngle
	local cosA = math.cos(appliedAngle)
	local sinA = math.sin(appliedAngle)
	local rotatedDir = Vector3.new(
		baseForward.X * cosA - baseForward.Z * sinA,
		0,
		baseForward.X * sinA + baseForward.Z * cosA
	)

	if rotatedDir.Magnitude < 0.001 then
		rotatedDir = Vector3.new(0, 0, 1)
	else
		rotatedDir = rotatedDir.Unit
	end

	local targetCF = CFrame.lookAt(headPos, headPos + rotatedDir, Vector3.yAxis)

	if head:IsA("Model") then
		head:PivotTo(targetCF)
	else
		head.CFrame = targetCF
	end

	return true
end

-- Main update loop
local function update(deltaTime)
	local playerPos = getPlayerPosition()
	if not playerPos then return end
	
	-- Update all tracked NPCs
	for npcModel, npcData in pairs(trackedNPCs) do
		if npcModel and npcModel.Parent then
			local valid = updateNPCHead(npcData, playerPos, deltaTime)
			if not valid then
				trackedNPCs[npcModel] = nil
			end
		else
			-- NPC removed from workspace
			trackedNPCs[npcModel] = nil
		end
	end
end

-- Watch for new NPCs being added
local function watchForNewNPCs()
	local npcsFolder = workspace:FindFirstChild(NPC_FOLDER_NAME)
	if npcsFolder then
		npcsFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") and child:FindFirstChild("Head") then
				registerNPC(child)
			end
		end)
		
		npcsFolder.ChildRemoved:Connect(function(child)
			if trackedNPCs[child] then
				unregisterNPC(child)
			end
		end)
	end
end

-- Initialize
task.spawn(function()
	-- Wait for character
	player.CharacterAdded:Wait()
	task.wait(0.5)
	
	-- Find all NPCs
	findAllNPCs()
	
	-- Watch for new NPCs
	watchForNewNPCs()
	
	-- Start update loop
	RunService.Heartbeat:Connect(update)
end)

return NPCHeadTracker
