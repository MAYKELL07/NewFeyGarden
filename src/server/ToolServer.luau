-- ToolServer.luau
-- Server-side tool action processing

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BuffsModule = require(ReplicatedStorage.Shared.BuffsModule)
local VFXModule = require(ReplicatedStorage.Shared.VFXModule)

-- Create ToolAction RemoteEvent
local toolActionEvent = Instance.new("RemoteEvent")
toolActionEvent.Name = "ToolAction"
toolActionEvent.Parent = ReplicatedStorage

-- Cooldown tracking
local playerCooldowns = {}

-- Helper: Check cooldown
local function isOnCooldown(player, toolName)
	local key = player.UserId .. ":" .. toolName
	local now = os.clock()
	
	if playerCooldowns[key] and now - playerCooldowns[key] < 1 then
		return true
	end
	
	playerCooldowns[key] = now
	return false
end

-- Helper: Get player's plot from hit part
local function getPlayerPlot(hitPart, player)
	local plotsFolder = Config.functions.GetWorldFolder(Config.World.PlotsFolder)
	if not plotsFolder then
		warn("Plots folder not found!")
		return nil
	end
	
	-- Traverse up to find the plot model
	local plot = hitPart
	while plot and plot.Parent ~= plotsFolder do
		plot = plot.Parent
		if not plot or plot == workspace then
			return nil
		end
	end
	
	-- Verify ownership
	if plot and plot:IsA("Model") and plot:GetAttribute("Owner") == player.UserId then
		return plot
	end
	
	return nil
end

-- Helper: Find plant that was clicked
local function getPlantFromHit(hitPart)
	print("ToolServer: Looking for plant from hitPart:", hitPart:GetFullName())
	
	-- Check if hitPart is part of a plant model
	local model = hitPart:FindFirstAncestorOfClass("Model")
	if model then
		print("ToolServer: Found model:", model.Name, "PlantType attribute:", model:GetAttribute("PlantType"))
		if model:GetAttribute("PlantType") then
			return model
		end
	end
	
	print("ToolServer: No plant found from hitPart")
	return nil
end

-- Shovel tool handler
local function handleShovel(player, hitPart, position)
	-- First check if they clicked on a plant directly
	local plant = getPlantFromHit(hitPart)
	
	if plant then
		-- Verify it's in the player's plot
		local plot = plant.Parent
		if plot and plot:IsA("Model") and plot:GetAttribute("Owner") == player.UserId then
			plant:Destroy()
			plot:SetAttribute("PlantCount", math.max(0, (plot:GetAttribute("PlantCount") or 1) - 1))
			
			-- Show VFX
			VFXModule.ShowGrowthEffect(position)
			
			print(player.Name, "cleared plant from plot with shovel")
		else
			warn(player.Name, "tried to clear plant from non-owned plot")
		end
	else
		warn("No plant found to clear - click directly on a plant")
	end
end

-- Watering Can tool handler
local function handleWateringCan(player, hitPart, position)
	-- Find the plant that was clicked
	local plant = getPlantFromHit(hitPart)
	
	if plant then
		-- Verify it's in the player's plot
		local plot = plant.Parent
		if plot and plot:IsA("Model") and plot:GetAttribute("Owner") == player.UserId then
			-- Water the plant
			BuffsModule.WaterPlant(plant, Config.Tools.WateringCan.WaterSeconds)
			
			-- Show VFX
			VFXModule.TryEmitWater(plant)
			VFXModule.ShowWateringEffect(position)
			
			print(player.Name, "watered plant for", Config.Tools.WateringCan.WaterSeconds, "seconds")
		else
			warn(player.Name, "tried to water plant from non-owned plot")
		end
	else
		warn("No plant found to water - click directly on a plant")
	end
end

-- Main tool action handler
toolActionEvent.OnServerEvent:Connect(function(player, toolName, hitPart, position)
	-- Validate inputs
	if not toolName or not hitPart then 
		warn("ToolServer: Invalid inputs - toolName:", toolName, "hitPart:", hitPart)
		return 
	end
	
	print("ToolServer: Received action - Tool:", toolName, "Hit:", hitPart:GetFullName(), "Position:", position)
	
	-- Check cooldown
	if isOnCooldown(player, toolName) then
		print("ToolServer:", player.Name, "is on cooldown for", toolName)
		return
	end
	
	-- Handle tool actions
	if toolName == Config.Tools.Shovel.Name then
		print("ToolServer: Handling Shovel action")
		handleShovel(player, hitPart, position)
		
	elseif toolName == Config.Tools.WateringCan.Name then
		print("ToolServer: Handling WateringCan action")
		handleWateringCan(player, hitPart, position)
		
	else
		warn("Unknown tool:", toolName)
	end
end)

print("🔧 Tool Server Handler Loaded")

return {}
