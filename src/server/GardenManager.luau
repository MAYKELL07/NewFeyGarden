-- GardenManager.luau
-- Manages pre-built garden folders, plant slots, and persistence.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Constants = require(ReplicatedStorage.Shared.Constants)
local Config = require(ReplicatedStorage.Shared.Config)
local PlantModule = require(ReplicatedStorage.Shared.PlantModule)
local BuffsModule = require(ReplicatedStorage.Shared.BuffsModule)
local EconomyService = require(ServerScriptService.Server.EconomyService)
local DataService = require(ServerScriptService.Server.Persistence.DataService)

local GardenManager = {}
GardenManager.PlayerGardens = {}
GardenManager.GardenAssignments = {}
GardenManager.ActivePlants = {}

local stageOrder = {
	Constants.GROWTH_STAGES.SEED,
	Constants.GROWTH_STAGES.SPROUT,
	Constants.GROWTH_STAGES.BLOOM,
}

local function ensureRemoteEvent(eventName: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(eventName)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = eventName
	remote.Parent = ReplicatedStorage
	return remote
end

local plantSeedEvent = ensureRemoteEvent(Constants.EVENTS.PLANT_SEED)
local harvestPlantEvent = ensureRemoteEvent(Constants.EVENTS.HARVEST_PLANT)

local function getGardensFolder(): Folder?
	local folder = Config.functions.GetWorldFolder(Config.World.GardensFolder)
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function ensurePlayerCache(userId: number): {[number]: Model}
	local cache = GardenManager.ActivePlants[userId]
	if not cache then
		cache = {}
		GardenManager.ActivePlants[userId] = cache
	end
	return cache
end

local function isValidSlot(slotIndex: number): boolean
	return typeof(slotIndex) == "number" and slotIndex >= 1 and slotIndex <= (Config.Garden.SlotsPerGarden or 0)
end

function GardenManager.GetPlayerGarden(player: Player): Folder?
	return GardenManager.PlayerGardens[player.UserId]
end

function GardenManager.GetPlantAnchor(gardenFolder: Folder?, slotIndex: number): BasePart?
	if not gardenFolder or not isValidSlot(slotIndex) then
		print(string.format("[PlantAnchor] Invalid parameters - gardenFolder: %s, slotIndex: %s, isValid: %s", 
			tostring(gardenFolder), tostring(slotIndex), tostring(isValidSlot(slotIndex))))
		return nil
	end

	local plotsFolder = gardenFolder:FindFirstChild(Config.World.PlotsFolder)
	if not plotsFolder or not plotsFolder:IsA("Folder") then
		print(string.format("[PlantAnchor] Plots folder not found or invalid - Looking for: %s in %s", 
			Config.World.PlotsFolder, gardenFolder.Name))
		print(string.format("[PlantAnchor] Garden children: %s", table.concat(gardenFolder:GetChildren():GetFullName(), ", ")))
		return nil
	end

	local anchorName = Config.Garden.PlantAnchorPrefix .. tostring(slotIndex)
	local anchor = plotsFolder:FindFirstChild(anchorName)
	
	if not anchor then
		print(string.format("[PlantAnchor] Anchor not found - Looking for: %s in %s", anchorName, plotsFolder:GetFullName()))
		print(string.format("[PlantAnchor] Available anchors in Plots: %s", 
			table.concat(plotsFolder:GetChildren():GetFullName(), ", ")))
		return nil
	end
	
	if not anchor:IsA("BasePart") then
		print(string.format("[PlantAnchor] Found %s but it's not a BasePart, it's a %s", anchorName, anchor.ClassName))
		return nil
	end
	
	print(string.format("[PlantAnchor] ✓ Successfully found anchor: %s at position %s", anchorName, tostring(anchor.Position)))
	return anchor
end

local function findPlantModel(anchor: Instance): Model?
	for _, child in ipairs(anchor:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("PlantType") then
			return child
		end
	end
	return nil
end

local function clearAnchor(anchor: Instance)
	for _, child in ipairs(anchor:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("PlantType") then
			child:Destroy()
		end
	end
end

local function updateGardenSign(gardenFolder: Folder, playerName: string?)
	local signModel = gardenFolder:FindFirstChild(Config.World.PlayerSignName)
	if not signModel or not signModel:IsA("Model") then
		return
	end

	local signPart = signModel:FindFirstChild(Config.World.PlayerSignPartName)
	if not signPart or not signPart:IsA("BasePart") then
		return
	end

	local surfaceGui = signPart:FindFirstChildWhichIsA("SurfaceGui")
	if not surfaceGui then
		return
	end

	local label = surfaceGui:FindFirstChildWhichIsA("TextLabel")
	if not label then
		return
	end

	if playerName then
		label.Text = string.format("%s's Garden", playerName)
	else
		label.Text = Config.Garden.DefaultSignText or "Available"
	end

	if Config.Garden.SignTextColor then
		label.TextColor3 = Config.Garden.SignTextColor
	end

	if Config.Garden.SignBackgroundColor then
		label.BackgroundColor3 = Config.Garden.SignBackgroundColor
	end
end

local function serializePlant(model: Model)
	local plantType = model:GetAttribute("PlantType")
	if type(plantType) ~= "string" then
		return nil
	end

	return {
		Type = plantType,
		Stage = model:GetAttribute("Stage") or Constants.GROWTH_STAGES.SEED,
		WateredUntil = model:GetAttribute("WateredUntil") or 0,
		PetBoost = model:GetAttribute("PetBoost") or false,
	}
end

local function continueGrowthFromStage(plantModel: Model, savedStage: string?)
	local plantType = plantModel:GetAttribute("PlantType")
	local config = Constants.PLANT_CONFIG[plantType]
	if not config then
		return
	end

	local startIndex = 1
	if type(savedStage) == "string" then
		for index, stage in ipairs(stageOrder) do
			if stage == savedStage then
				startIndex = index
				break
			end
		end
	end

	local currentStage = stageOrder[startIndex]
	plantModel:SetAttribute("Stage", currentStage)
	plantModel:SetAttribute("Harvestable", currentStage == Constants.GROWTH_STAGES.BLOOM)
	PlantModule.UpdatePlantVisual(plantModel)

	if currentStage == Constants.GROWTH_STAGES.BLOOM then
		return
	end

	task.spawn(function()
		for index = startIndex + 1, #stageOrder do
			local nextStage = stageOrder[index]
			local multiplier = BuffsModule.GetGrowthMultiplier(plantModel)
			local waitTime = math.max(config.GrowthTime * multiplier, 0.1)
			task.wait(waitTime)

			if not plantModel.Parent then
				return
			end

			plantModel:SetAttribute("Stage", nextStage)
			plantModel:SetAttribute("Harvestable", nextStage == Constants.GROWTH_STAGES.BLOOM)
			PlantModule.UpdatePlantVisual(plantModel)
		end
	end)
end

local function savePlantSlots(userId: number, gardenFolder: Folder)
	if not Config.Economy.EnablePersistence then
		return
	end
	
	for slotIndex = 1, Config.Garden.SlotsPerGarden do
		local anchor = GardenManager.GetPlantAnchor(gardenFolder, slotIndex)
		local plantModel = anchor and findPlantModel(anchor) or nil
		if plantModel then
			local payload = serializePlant(plantModel)
			if payload then
				DataService.SetPlantSlot(userId, slotIndex, payload)
			else
				DataService.ClearPlantSlot(userId, slotIndex)
			end
		else
			DataService.ClearPlantSlot(userId, slotIndex)
		end
	end
end

local function restorePlantSlots(userId: number, gardenFolder: Folder)
	local cache = ensurePlayerCache(userId)

	for slotIndex = 1, Config.Garden.SlotsPerGarden do
		cache[slotIndex] = nil
		local anchor = GardenManager.GetPlantAnchor(gardenFolder, slotIndex)
		if anchor then
			clearAnchor(anchor)
		end
	end

	if not Config.Garden.RestorePlantsOnJoin then
		return
	end

	local savedSlots = DataService.GetAllPlantSlots(userId)
	for slotIndex, state in pairs(savedSlots) do
		local numericIndex = tonumber(slotIndex)
		if numericIndex and isValidSlot(numericIndex) then
			if type(state) == "table" and type(state.Type) == "string" then
				local anchor = GardenManager.GetPlantAnchor(gardenFolder, numericIndex)
				if anchor then
					local plantModel = PlantModule.CreatePlantModel(state.Type, anchor.Position)
					if plantModel then
						plantModel:SetAttribute("OwnerUserId", userId)
						plantModel:SetAttribute("Owner", userId)
						plantModel:SetAttribute("SlotIndex", numericIndex)
						plantModel:SetAttribute("WateredUntil", state.WateredUntil or 0)
						plantModel:SetAttribute("PetBoost", state.PetBoost or false)
						plantModel.Parent = anchor

						continueGrowthFromStage(plantModel, state.Stage)
						cache[numericIndex] = plantModel
					end
				end
			end
		end
	end
end

local function findGardenForPlayer(userId: number): Folder?
	local gardensFolder = getGardensFolder()
	if not gardensFolder then
		return nil
	end

	for gardenName, assignedUserId in pairs(GardenManager.GardenAssignments) do
		if assignedUserId == userId then
			local garden = gardensFolder:FindFirstChild(gardenName)
			if garden and garden:IsA("Folder") then
				return garden
			end
		end
	end

	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local ownerId = garden:GetAttribute("OwnerUserId")
			if ownerId == userId then
				return garden
			end
		end
	end

	if Config.Garden.GardenNames then
		for _, gardenName in ipairs(Config.Garden.GardenNames) do
			local garden = gardensFolder:FindFirstChild(gardenName)
			if garden and garden:IsA("Folder") then
				local assignedUserId = GardenManager.GardenAssignments[garden.Name]
				local ownerId = garden:GetAttribute("OwnerUserId")
				if not assignedUserId and (not ownerId or ownerId == 0) then
					return garden
				end
			end
		end
	end

	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			local assignedUserId = GardenManager.GardenAssignments[garden.Name]
			local ownerId = garden:GetAttribute("OwnerUserId")
			if not assignedUserId and (not ownerId or ownerId == 0) then
				return garden
			end
		end
	end

	return nil
end

local function setupClickDetectors(garden: Folder)
	print(string.format("[GardenManager] Setting up ClickDetectors for %s", garden.Name))
	local successCount = 0
	
	for slotIndex = 1, Config.Garden.SlotsPerGarden do
		local anchor = GardenManager.GetPlantAnchor(garden, slotIndex)
		if anchor then
			-- Remove existing ClickDetector if present
			local existingCD = anchor:FindFirstChildOfClass("ClickDetector")
			if existingCD then
				existingCD:Destroy()
				print(string.format("[ClickDetector] Removed old ClickDetector from %s", anchor.Name))
			end
			
			-- Create new ClickDetector
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 15
			clickDetector.Parent = anchor
			
			successCount = successCount + 1
			print(string.format("[ClickDetector] ✓ Added to %s (MaxDistance: 15)", anchor.Name))
		else
			warn(string.format("[ClickDetector] ❌ Failed to get anchor for slot %d in %s", slotIndex, garden.Name))
		end
	end
	
	print(string.format("[GardenManager] ✅ ClickDetector setup complete - %d/%d successful", successCount, Config.Garden.SlotsPerGarden))
end

local function bootstrapGardens()
	local gardensFolder = getGardensFolder()
	if not gardensFolder then
		warn("GardenManager: Missing gardens folder", Config.World.GardensFolder)
		return
	end

	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") then
			garden:SetAttribute("OwnerUserId", 0)
			GardenManager.GardenAssignments[garden.Name] = nil
			updateGardenSign(garden, nil)
			for slotIndex = 1, Config.Garden.SlotsPerGarden do
				local anchor = GardenManager.GetPlantAnchor(garden, slotIndex)
				if anchor then
					clearAnchor(anchor)
				end
			end
			-- Setup ClickDetectors for all anchors
			setupClickDetectors(garden)
		end
	end
end

function GardenManager.AssignGarden(player: Player): (boolean, string?)
	if GardenManager.PlayerGardens[player.UserId] then
		return true, nil
	end

	local garden = findGardenForPlayer(player.UserId)
	if not garden then
		return false, "No available gardens"
	end

	GardenManager.PlayerGardens[player.UserId] = garden
	GardenManager.GardenAssignments[garden.Name] = player.UserId
	garden:SetAttribute("OwnerUserId", player.UserId)
	updateGardenSign(garden, player.DisplayName)

	restorePlantSlots(player.UserId, garden)
	
	-- Ensure ClickDetectors are set up
	setupClickDetectors(garden)

	return true, nil
end

function GardenManager.ReleaseGarden(player: Player)
	local garden = GardenManager.PlayerGardens[player.UserId]
	if not garden then
		return
	end

	if Config.Garden.SavePlantsOnLeave then
		savePlantSlots(player.UserId, garden)
	else
		for slotIndex = 1, Config.Garden.SlotsPerGarden do
			DataService.ClearPlantSlot(player.UserId, slotIndex)
		end
	end

	for slotIndex = 1, Config.Garden.SlotsPerGarden do
		local anchor = GardenManager.GetPlantAnchor(garden, slotIndex)
		if anchor then
			clearAnchor(anchor)
		end
	end

	GardenManager.ActivePlants[player.UserId] = nil
	GardenManager.PlayerGardens[player.UserId] = nil

	if Config.Garden.FreeOnLeave then
		GardenManager.GardenAssignments[garden.Name] = nil
		garden:SetAttribute("OwnerUserId", 0)
		updateGardenSign(garden, nil)
	else
		GardenManager.GardenAssignments[garden.Name] = player.UserId
		garden:SetAttribute("OwnerUserId", player.UserId)
		updateGardenSign(garden, player.DisplayName)
	end
end

local function getPlantInSlot(player: Player, slotIndex: number): Model?
	local cache = GardenManager.ActivePlants[player.UserId]
	local cached = cache and cache[slotIndex]
	if cached and cached.Parent then
		return cached
	end

	local garden = GardenManager.PlayerGardens[player.UserId]
	if not garden then
		return nil
	end

	local anchor = GardenManager.GetPlantAnchor(garden, slotIndex)
	if not anchor then
		return nil
	end

	local model = findPlantModel(anchor)
	if model then
		ensurePlayerCache(player.UserId)[slotIndex] = model
	end
	return model
end

function GardenManager.PlantSeed(player: Player, slotIndex: number, plantType: string): (boolean, string?)
	print(string.format("[PlantSeed] %s attempting to plant %s in slot %d", player.Name, plantType, slotIndex))
	
	if not isValidSlot(slotIndex) then
		print(string.format("[PlantSeed] FAILED - Invalid slot index: %d (max: %d)", slotIndex, Config.Garden.SlotsPerGarden))
		return false, "Invalid slot index"
	end

	if type(plantType) ~= "string" then
		print(string.format("[PlantSeed] FAILED - Invalid plant type: %s", tostring(plantType)))
		return false, "Invalid plant type"
	end

	local garden = GardenManager.PlayerGardens[player.UserId]
	if not garden then
		print(string.format("[PlantSeed] FAILED - No garden assigned to %s", player.Name))
		return false, "No garden assigned"
	end
	
	print(string.format("[PlantSeed] Player has garden: %s", garden.Name))

	local anchor = GardenManager.GetPlantAnchor(garden, slotIndex)
	if not anchor then
		print(string.format("[PlantSeed] FAILED - Missing plant anchor for slot %d in %s", slotIndex, garden.Name))
		return false, "Missing plant anchor"
	end
	
	print(string.format("[PlantSeed] Found anchor at: %s", tostring(anchor.Position)))

	if getPlantInSlot(player, slotIndex) then
		print(string.format("[PlantSeed] FAILED - Slot %d already occupied", slotIndex))
		return false, "Slot already occupied"
	end

	if not EconomyService.RemoveSeed(player, plantType) then
		print(string.format("[PlantSeed] FAILED - %s doesn't have %s seed", player.Name, plantType))
		return false, "Seed unavailable"
	end

	local plantModel = PlantModule.CreatePlantModel(plantType, anchor.Position)
	if not plantModel then
		EconomyService.AddSeed(player, plantType, 1)
		print(string.format("[PlantSeed] FAILED - Could not create plant model for %s", plantType))
		return false, "Failed to create plant model"
	end

	plantModel:SetAttribute("OwnerUserId", player.UserId)
	plantModel:SetAttribute("Owner", player.UserId)
	plantModel:SetAttribute("SlotIndex", slotIndex)
	plantModel:SetAttribute("WateredUntil", 0)
	plantModel:SetAttribute("PetBoost", false)
	plantModel.Parent = anchor

	local cache = ensurePlayerCache(player.UserId)
	cache[slotIndex] = plantModel

	-- Only save to DataStore if persistence is enabled
	if Config.Economy.EnablePersistence then
		DataService.SetPlantSlot(player.UserId, slotIndex, {
			Type = plantType,
			Stage = plantModel:GetAttribute("Stage"),
			WateredUntil = 0,
			PetBoost = false,
		})
	end

	task.spawn(PlantModule.GrowPlant, plantModel)

	print(string.format("[PlantSeed] ✓ SUCCESS - %s planted %s in slot %d", player.Name, plantType, slotIndex))
	return true, nil
end

function GardenManager.HarvestPlant(player: Player, slotIndex: number): (boolean, string?)
	if not isValidSlot(slotIndex) then
		return false, "Invalid slot index"
	end

	local plantModel = getPlantInSlot(player, slotIndex)
	if not plantModel then
		return false, "No plant in slot"
	end

	local ownerId = plantModel:GetAttribute("OwnerUserId") or plantModel:GetAttribute("Owner")
	if ownerId ~= player.UserId then
		return false, "Plant belongs to another player"
	end

	if not PlantModule.CanHarvest(plantModel) then
		return false, "Plant is not ready"
	end

	local reward = PlantModule.GetHarvestValue(plantModel)
	if reward > 0 then
		EconomyService.AddCoins(player, reward)
	end

	-- Only clear from DataStore if persistence is enabled
	if Config.Economy.EnablePersistence then
		DataService.ClearPlantSlot(player.UserId, slotIndex)
	end

	local cache = ensurePlayerCache(player.UserId)
	cache[slotIndex] = nil

	plantModel:Destroy()

	return true, nil
end

function GardenManager.Initialize()
	bootstrapGardens()

	plantSeedEvent.OnServerEvent:Connect(function(player, slotIndex, plantType)
		local success, message = GardenManager.PlantSeed(player, slotIndex, plantType)
		if not success then
			warn(string.format("GardenManager: PlantSeed rejected for %s (%s)", player.Name, message or "unknown error"))
		end
	end)

	harvestPlantEvent.OnServerEvent:Connect(function(player, slotIndex)
		local success, message = GardenManager.HarvestPlant(player, slotIndex)
		if not success then
			warn(string.format("GardenManager: Harvest rejected for %s (%s)", player.Name, message or "unknown error"))
		end
	end)

	if Config.Garden.AssignOnJoin then
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				GardenManager.AssignGarden(player)
			end)
		end

		Players.PlayerAdded:Connect(function(player)
			task.defer(function()
				task.wait(0.3)
				GardenManager.AssignGarden(player)
			end)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		GardenManager.ReleaseGarden(player)
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			GardenManager.ReleaseGarden(player)
		end
	end)

	print("GardenManager initialized")
end

return GardenManager
