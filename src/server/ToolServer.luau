-- ToolServer.luau
-- Server-side tool action processing
-- Tools are now inventory items that weld to player hands client-side

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)

local Config, BuffsModule, VFXModule
if sharedFolder then
	local function safeRequire(name)
		local ok, mod = pcall(function()
			return require(sharedFolder:WaitForChild(name, 5))
		end)
		if not ok then
			warn(string.format("[ToolServer] Failed to load %s: %s", name, tostring(mod)))
			return nil
		end
		return mod
	end

	Config = safeRequire("Config")
	BuffsModule = safeRequire("BuffsModule")
	VFXModule = safeRequire("VFXModule")
else
	warn("[ToolServer] Shared folder missing; tool handling limited")
end

-- Create ToolAction RemoteEvent
local toolActionEvent = Instance.new("RemoteEvent")
toolActionEvent.Name = "ToolAction"
toolActionEvent.Parent = ReplicatedStorage

if not Config or not BuffsModule or not VFXModule then
	warn("[ToolServer] Missing shared modules; tool actions will be ignored")
end

-- Cooldown tracking
local playerCooldowns = {}

-- Helper: Check cooldown
local function isOnCooldown(player, toolName)
	local key = player.UserId .. ":" .. toolName
	local now = os.clock()
	
	if playerCooldowns[key] and now - playerCooldowns[key] < 0.5 then -- 0.5s cooldown
		return true
	end
	
	playerCooldowns[key] = now
	return false
end

-- Helper: Find plant from target part
local function getPlantFromTarget(target)
	if not target then return nil end
	
	-- Check if target itself is a plant model
	if target:IsA("Model") and target:GetAttribute("PlantType") then
		return target
	end
	
	-- Check if target is part of a plant model
	local model = target:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("PlantType") then
		return model
	end
	
	-- Check if target is a PlantAnchor with a plant child
	if target:IsA("BasePart") and target.Name:match("PlantAnchor") then
		for _, child in ipairs(target:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("PlantType") then
				return child
			end
		end
	end
	
	-- Check parent if it's a PlantAnchor
	if target.Parent and target.Parent:IsA("BasePart") and target.Parent.Name:match("PlantAnchor") then
		for _, child in ipairs(target.Parent:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("PlantType") then
				return child
			end
		end
	end
	
	return nil
end

-- Helper: Check if player owns the garden this target is in
local function playerOwnsGarden(player, target)
	if not target then return false end
	
	-- Traverse up to find the garden
	local current = target
	while current and current ~= workspace do
		-- Check if current is a garden folder
		if current.Parent and current.Parent.Name == Config.World.GardensFolder then
			local ownerId = current:GetAttribute("OwnerUserId")
			return ownerId == player.UserId
		end
		current = current.Parent
	end
	
	return false
end

-- Shovel tool handler
local function handleShovel(player, target, position)
	-- Check ownership
	if not playerOwnsGarden(player, target) then
		return
	end
	
	-- Find plant from target
	local plant = getPlantFromTarget(target)
	
	if plant then
		local plantPosition = plant:GetBoundingBox().Position
		
		-- Destroy the plant
		plant:Destroy()
		
		-- Show VFX
		if VFXModule then
			VFXModule.ShowGrowthEffect(plantPosition)
		end
	end
end

-- Watering Can tool handler
local function handleWateringCan(player, target, position)
	-- Check ownership8
	if not playerOwnsGarden(player, target) then
		return
	end
	
	-- Find plant from target
	local plant = getPlantFromTarget(target)
	
	if plant then
		local plantPosition = plant:GetBoundingBox().Position
		
		if BuffsModule and Config then
			BuffsModule.WaterPlant(plant, Config.Tools.WateringCan.WaterSeconds)
		end
	
		if VFXModule then
			VFXModule.TryEmitWater(plant)
			VFXModule.ShowWateringEffect(plantPosition)
		end
	end
end

-- Handle tool action requests from client
toolActionEvent.OnServerEvent:Connect(function(player, toolName, target, position)
	-- Validate inputs
	if not toolName or not target then 
		return 
	end
	
	-- Check cooldown
	if isOnCooldown(player, toolName) then
		return
	end
	
	if not Config then return end
	-- Handle tool actions
	if toolName == Config.Tools.Shovel.Name then
		handleShovel(player, target, position)
		
	elseif toolName == Config.Tools.WateringCan.Name then
		handleWateringCan(player, target, position)
		
	else
		warn(string.format("[ToolServer] Unknown tool: %s", toolName))
	end
end)

return {}
