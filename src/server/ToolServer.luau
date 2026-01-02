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
	
	-- Find the root plantModel (which has Stage attribute)
	-- Check ancestors for a Model with PlantType AND Stage
	local model = target
	if target:IsA("BasePart") then
		model = target:FindFirstAncestorOfClass("Model")
	end
	
	while model do
		if model:GetAttribute("PlantType") and model:GetAttribute("Stage") then
			return model
		end
		-- Check parent model
		local parentModel = model.Parent
		if parentModel and parentModel:IsA("Model") and parentModel:GetAttribute("PlantType") then
			return parentModel
		end
		-- Keep searching up
		if model.Parent then
			model = model.Parent:FindFirstAncestorOfClass("Model")
		else
			break
		end
	end
	
	-- Fallback: simple ancestor check
	model = target:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("PlantType") then
		-- Check if this model's parent also has PlantType (meaning this is the Plant child)
		local parentModel = model.Parent
		if parentModel and parentModel:IsA("Model") and parentModel:GetAttribute("PlantType") then
			return parentModel
		end
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
		
		-- Ensure we destroy the entire plant model including all children
		-- First, destroy all descendants explicitly to handle any edge cases
		for _, descendant in ipairs(plant:GetDescendants()) do
			if descendant:IsA("BasePart") or descendant:IsA("Model") then
				descendant:Destroy()
			end
		end
		
		-- Then destroy the plant model itself
		plant:Destroy()
		
		-- Show VFX
		if VFXModule then
			VFXModule.ShowGrowthEffect(plantPosition)
		end
	end
end

-- Helper: Find player's garden and all plants in it
local function getPlayerGardenPlants(player)
	local gardensFolder = workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then return {} end
	
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		local ownerId = garden:GetAttribute("OwnerUserId")
		if ownerId == player.UserId then
			local plants = {}
			-- Get all plants from PlotAnchors
			local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
			if plotsFolder then
				for _, anchor in ipairs(plotsFolder:GetChildren()) do
					for _, child in ipairs(anchor:GetChildren()) do
						if child:IsA("Model") and child:GetAttribute("PlantType") then
							table.insert(plants, child)
						end
					end
				end
			end
			-- Also check direct children for free-placed plants
			for _, child in ipairs(garden:GetDescendants()) do
				if child:IsA("Model") and child:GetAttribute("PlantType") then
					local found = false
					for _, p in ipairs(plants) do
						if p == child then found = true break end
					end
					if not found then
						table.insert(plants, child)
					end
				end
			end
			return plants
		end
	end
	
	return {}
end

-- Watering Can tool handler
-- Waters up to MAX_PLANTS nearby plants (closest first)
local function handleWateringCan(player, target, position)
	-- Check ownership
	if not playerOwnsGarden(player, target) then
		return
	end
	
	-- Get max plants from Constants GEAR_CONFIG or fallback to 5
	local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))
	local maxPlants = 5
	local waterSeconds = Config.Tools.WateringCan.WaterSeconds
	
	if Constants.GEAR_CONFIG and Constants.GEAR_CONFIG[Constants.GEAR_TYPES.WATERING_CAN] then
		local gearConfig = Constants.GEAR_CONFIG[Constants.GEAR_TYPES.WATERING_CAN]
		maxPlants = gearConfig.MaxPlantsPerUse or 5
		waterSeconds = gearConfig.WaterDuration or waterSeconds
	end
	
	-- Find clicked plant first
	local clickedPlant = getPlantFromTarget(target)
	
	-- Get all plants in player's garden
	local allPlants = getPlayerGardenPlants(player)
	
	-- Sort plants by distance to click position
	table.sort(allPlants, function(a, b)
		local posA = a:GetBoundingBox().Position
		local posB = b:GetBoundingBox().Position
		return (posA - position).Magnitude < (posB - position).Magnitude
	end)
	
	-- Water up to maxPlants closest plants
	local wateredCount = 0
	for _, plant in ipairs(allPlants) do
		if wateredCount >= maxPlants then break end
		
		local plantPosition = plant:GetBoundingBox().Position
		
		-- Only water plants within 15 studs of click
		if (plantPosition - position).Magnitude <= 15 then
			if BuffsModule and Config then
				BuffsModule.WaterPlant(plant, waterSeconds)
			end
			
			if VFXModule then
				VFXModule.TryEmitWater(plant)
				VFXModule.ShowWateringEffect(plantPosition)
			end
			
			wateredCount = wateredCount + 1
		end
	end
	
	-- If no plants in range, still show effect at position (feedback to player)
	if wateredCount == 0 and VFXModule then
		VFXModule.ShowWateringEffect(position)
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
