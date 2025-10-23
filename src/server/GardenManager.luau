-- GardenManager.luau
-- Manages player garden plots and plant placement

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local PlantModule = require(ReplicatedStorage.Shared.PlantModule)
local EconomyService = require(ServerScriptService.Server.EconomyService)

local GardenManager = {}
GardenManager.PlayerPlots = {}
GardenManager.ActivePlants = {}

-- Create RemoteEvents
local plantSeedEvent = Instance.new("RemoteEvent")
plantSeedEvent.Name = Constants.EVENTS.PLANT_SEED
plantSeedEvent.Parent = ReplicatedStorage

local harvestPlantEvent = Instance.new("RemoteEvent")
harvestPlantEvent.Name = Constants.EVENTS.HARVEST_PLANT
harvestPlantEvent.Parent = ReplicatedStorage

-- Create a garden plot for a player
function GardenManager.CreatePlot(player)
	local plotsFolder = Workspace:FindFirstChild("GardenPlots")
	if not plotsFolder then
		plotsFolder = Instance.new("Folder")
		plotsFolder.Name = "GardenPlots"
		plotsFolder.Parent = Workspace
	end
	
	-- Calculate plot position based on player count
	local plotCount = #plotsFolder:GetChildren()
	local plotX = (plotCount % 5) * Constants.PLOT_SPACING
	local plotZ = math.floor(plotCount / 5) * Constants.PLOT_SPACING
	local plotPosition = Vector3.new(plotX, 0, plotZ)
	
	-- Create plot model
	local plotModel = Instance.new("Model")
	plotModel.Name = player.Name .. "_Plot"
	
	-- Create plot floor
	local plotFloor = Instance.new("Part")
	plotFloor.Name = "Floor"
	plotFloor.Size = Constants.PLOT_SIZE
	plotFloor.Position = plotPosition
	plotFloor.Anchored = true
	plotFloor.Color = Color3.fromRGB(101, 67, 33)
	plotFloor.Material = Enum.Material.Ground
	plotFloor.Parent = plotModel
	
	-- Create border
	for i = 1, 4 do
		local border = Instance.new("Part")
		border.Name = "Border" .. i
		border.Size = Vector3.new(1, 2, Constants.PLOT_SIZE.Z + 2)
		border.Anchored = true
		border.Color = Color3.fromRGB(139, 90, 43)
		border.Material = Enum.Material.Wood
		border.Parent = plotModel
		
		if i == 1 then -- Left
			border.Position = plotPosition + Vector3.new(-Constants.PLOT_SIZE.X/2 - 0.5, 1, 0)
		elseif i == 2 then -- Right
			border.Position = plotPosition + Vector3.new(Constants.PLOT_SIZE.X/2 + 0.5, 1, 0)
		elseif i == 3 then -- Front
			border.Size = Vector3.new(Constants.PLOT_SIZE.X + 2, 2, 1)
			border.Position = plotPosition + Vector3.new(0, 1, -Constants.PLOT_SIZE.Z/2 - 0.5)
		else -- Back
			border.Size = Vector3.new(Constants.PLOT_SIZE.X + 2, 2, 1)
			border.Position = plotPosition + Vector3.new(0, 1, Constants.PLOT_SIZE.Z/2 + 0.5)
		end
	end
	
	-- Create sign
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(4, 3, 0.5)
	sign.Position = plotPosition + Vector3.new(0, 2, -Constants.PLOT_SIZE.Z/2 - 2)
	sign.Anchored = true
	sign.Color = Color3.fromRGB(139, 90, 43)
	sign.Material = Enum.Material.Wood
	sign.Parent = plotModel
	
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.new(1, 0, 1, 0)
	signLabel.BackgroundTransparency = 1
	signLabel.Text = player.Name .. "'s Garden"
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	signLabel.Font = Enum.Font.SourceSansBold
	signLabel.Parent = signGui
	
	plotModel.PrimaryPart = plotFloor
	plotModel:SetAttribute("Owner", player.UserId)
	plotModel:SetAttribute("PlantCount", 0)
	plotModel.Parent = plotsFolder
	
	GardenManager.PlayerPlots[player.UserId] = plotModel
	
	print("Created garden plot for", player.Name)
	return plotModel
end

-- Get plant position on plot
function GardenManager.GetPlantPosition(plotModel, index)
	local plotFloor = plotModel:FindFirstChild("Floor")
	if not plotFloor then return nil end
	
	local gridSize = 3 -- 3x3 grid
	local row = math.floor((index - 1) / gridSize)
	local col = (index - 1) % gridSize
	
	local spacing = Constants.PLOT_SIZE.X / (gridSize + 1)
	local offsetX = (col - 1) * spacing
	local offsetZ = (row - 1) * spacing
	
	return plotFloor.Position + Vector3.new(offsetX, 1, offsetZ)
end

-- Plant a seed
function GardenManager.PlantSeed(player, plantType, slotIndex)
	local plotModel = GardenManager.PlayerPlots[player.UserId]
	if not plotModel then
		warn("No plot found for player:", player.Name)
		return false
	end
	
	-- Check if player has the seed
	if not EconomyService.RemoveSeed(player, plantType) then
		warn(player.Name .. " doesn't have a " .. plantType .. " seed")
		return false
	end
	
	local plantCount = plotModel:GetAttribute("PlantCount") or 0
	if plantCount >= Constants.MAX_PLANTS_PER_PLOT then
		warn("Plot is full!")
		-- Refund the seed
		EconomyService.AddSeed(player, plantType, 1)
		return false
	end
	
	-- Check if slot is already occupied
	for _, child in ipairs(plotModel:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("SlotIndex") == slotIndex then
			warn("Slot", slotIndex, "is already occupied!")
			-- Refund the seed
			EconomyService.AddSeed(player, plantType, 1)
			return false
		end
	end
	
	-- Get position for plant
	local position = GardenManager.GetPlantPosition(plotModel, slotIndex)
	if not position then
		warn("Invalid plant position")
		-- Refund the seed
		EconomyService.AddSeed(player, plantType, 1)
		return false
	end
	
	-- Create plant
	local plantModel = PlantModule.CreatePlantModel(plantType, position)
	if not plantModel then
		-- Refund the seed
		EconomyService.AddSeed(player, plantType, 1)
		return false
	end
	
	plantModel:SetAttribute("Owner", player.UserId)
	plantModel:SetAttribute("SlotIndex", slotIndex)
	plantModel.Parent = plotModel
	
	-- Start growth (BuffsModule now handles all multipliers dynamically)
	PlantModule.GrowPlant(plantModel)
	
	-- Update plant count
	plotModel:SetAttribute("PlantCount", plantCount + 1)
	
	-- Track active plant
	if not GardenManager.ActivePlants[player.UserId] then
		GardenManager.ActivePlants[player.UserId] = {}
	end
	table.insert(GardenManager.ActivePlants[player.UserId], plantModel)
	
	print(player.Name .. " planted " .. plantType)
	return true
end

-- Harvest a plant
function GardenManager.HarvestPlant(player, plantModel)
	if plantModel:GetAttribute("Owner") ~= player.UserId then
		warn("Player doesn't own this plant")
		return 0
	end
	
	if not PlantModule.CanHarvest(plantModel) then
		warn("Plant is not ready to harvest")
		return 0
	end
	
	local value = PlantModule.GetHarvestValue(plantModel)
	
	-- Update plot plant count
	local plotModel = GardenManager.PlayerPlots[player.UserId]
	if plotModel then
		local plantCount = plotModel:GetAttribute("PlantCount") or 0
		plotModel:SetAttribute("PlantCount", math.max(0, plantCount - 1))
	end
	
	-- Remove from active plants
	if GardenManager.ActivePlants[player.UserId] then
		for i, plant in ipairs(GardenManager.ActivePlants[player.UserId]) do
			if plant == plantModel then
				table.remove(GardenManager.ActivePlants[player.UserId], i)
				break
			end
		end
	end
	
	-- Destroy plant
	plantModel:Destroy()
	
	print(player.Name .. " harvested plant for " .. value .. " coins")
	return value
end

-- Initialize Garden Manager
function GardenManager.Initialize()
	print("GardenManager initialized")
	
	-- Handle plant seed requests
	plantSeedEvent.OnServerEvent:Connect(function(player, plantType, slotIndex)
		GardenManager.PlantSeed(player, plantType, slotIndex)
	end)
	
	-- Handle harvest requests
	harvestPlantEvent.OnServerEvent:Connect(function(player, plantModel)
		local value = GardenManager.HarvestPlant(player, plantModel)
		
		-- Update player currency (will be handled by EconomyService)
		local updateCurrencyEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.UPDATE_CURRENCY)
		if updateCurrencyEvent then
			updateCurrencyEvent:FireClient(player, value)
		end
	end)
	
	-- Create plots for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		GardenManager.CreatePlot(player)
	end
	
	-- Create plots for new players
	Players.PlayerAdded:Connect(function(player)
		GardenManager.CreatePlot(player)
	end)
	
	-- Cleanup when player leaves
	Players.PlayerRemoving:Connect(function(player)
		GardenManager.PlayerPlots[player.UserId] = nil
		GardenManager.ActivePlants[player.UserId] = nil
	end)
end

return GardenManager
