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

-- Helper: Find plant in plot
local function getPlantInPlot(plot)
	for _, child in ipairs(plot:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("PlantType") then
			return child
		end
	end
	return nil
end

-- Shovel tool handler
local function handleShovel(player, hitPart, position)
	local plot = getPlayerPlot(hitPart, player)
	if not plot then
		warn(player.Name, "tried to use shovel on non-owned plot")
		return
	end
	
	-- Find and remove plant
	local plant = getPlantInPlot(plot)
	if plant then
		plant:Destroy()
		plot:SetAttribute("PlantCount", math.max(0, (plot:GetAttribute("PlantCount") or 1) - 1))
		
		-- Show VFX
		VFXModule.ShowGrowthEffect(position)
		
		print(player.Name, "cleared plant from plot with shovel")
	else
		warn("No plant found to clear")
	end
end

-- Watering Can tool handler
local function handleWateringCan(player, hitPart, position)
	local plot = getPlayerPlot(hitPart, player)
	if not plot then
		warn(player.Name, "tried to water non-owned plot")
		return
	end
	
	-- Find plant
	local plant = getPlantInPlot(plot)
	if not plant then
		warn("No plant found to water")
		return
	end
	
	-- Water the plant
	BuffsModule.WaterPlant(plant, Config.Tools.WateringCan.WaterSeconds)
	
	-- Show VFX
	VFXModule.TryEmitWater(plant)
	VFXModule.ShowWateringEffect(position)
	
	print(player.Name, "watered plant for", Config.Tools.WateringCan.WaterSeconds, "seconds")
end

-- Main tool action handler
toolActionEvent.OnServerEvent:Connect(function(player, toolName, hitPart, position)
	-- Validate inputs
	if not toolName or not hitPart then return end
	
	-- Check cooldown
	if isOnCooldown(player, toolName) then
		return
	end
	
	-- Handle tool actions
	if toolName == Config.Tools.Shovel.Name then
		handleShovel(player, hitPart, position)
		
	elseif toolName == Config.Tools.WateringCan.Name then
		handleWateringCan(player, hitPart, position)
		
	else
		warn("Unknown tool:", toolName)
	end
end)

print("🔧 Tool Server Handler Loaded")

return {}
