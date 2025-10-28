-- PlantingHandler.luau
-- Handles clicking on PlantAnchors to plant seeds

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIHandler = require(script.Parent.UIHandler)

local PlantingHandler = {}
local player = Players.LocalPlayer
local connections = {}

local function getSlotIndexFromAnchor(anchor)
	local anchorName = anchor.Name
	local prefix = Config.Garden.PlantAnchorPrefix
	local slotIndex = tonumber(anchorName:match(prefix .. "(%d+)"))
	return slotIndex
end

local function setupAnchorClick(anchor)
	local clickDetector = anchor:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then
		return
	end
	
	-- Disconnect if already connected
	if connections[anchor] then
		connections[anchor]:Disconnect()
	end
	
	-- Connect to click event
	connections[anchor] = clickDetector.MouseClick:Connect(function()
		-- Check if anchor already has a plant
		local hasPlant = false
		for _, child in ipairs(anchor:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("PlantType") then
				hasPlant = true
				break
			end
		end
		
		if hasPlant then
			-- Don't plant if there's already a plant here
			return
		end
		
		-- Get selected plant type from UIHandler
		local selectedPlantType = UIHandler.GetSelectedPlantType()
		if not selectedPlantType then
			-- No seed selected
			warn("[PlantingHandler] No seed selected! Select a seed from your inventory first.")
			return
		end
		
		-- Get slot index from anchor name
		local slotIndex = getSlotIndexFromAnchor(anchor)
		if not slotIndex then
			warn("[PlantingHandler] Could not determine slot index from anchor:", anchor.Name)
			return
		end
		
		-- Fire plant seed event to server
		local plantSeedEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.PLANT_SEED)
		if plantSeedEvent then
			print(string.format("[PlantingHandler] Planting %s at slot %d", selectedPlantType, slotIndex))
			plantSeedEvent:FireServer(slotIndex, selectedPlantType)
		else
			warn("[PlantingHandler] PLANT_SEED event not found!")
		end
	end)
end

function PlantingHandler.Initialize()
	print("[PlantingHandler] Initializing...")
	
	-- Wait for player's garden
	task.wait(2) -- Give time for garden assignment
	
	-- Find player's garden
	local gardensFolder = workspace:WaitForChild(Config.World.GardensFolder, 10)
	if not gardensFolder then
		warn("[PlantingHandler] Gardens folder not found!")
		return
	end
	
	-- Find the garden with our UserId
	local playerGarden = nil
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") and garden:GetAttribute("OwnerUserId") == player.UserId then
			playerGarden = garden
			break
		end
	end
	
	if not playerGarden then
		warn("[PlantingHandler] Player garden not found!")
		return
	end
	
	print("[PlantingHandler] Found player garden:", playerGarden.Name)
	
	-- Setup click detectors for all plant anchors
	local plotsFolder = playerGarden:FindFirstChild(Config.World.PlotsFolder)
	if not plotsFolder then
		warn("[PlantingHandler] Plots folder not found in garden!")
		return
	end
	
	local anchorCount = 0
	for _, child in ipairs(plotsFolder:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match(Config.Garden.PlantAnchorPrefix) then
			setupAnchorClick(child)
			anchorCount = anchorCount + 1
		end
	end
	
	print(string.format("[PlantingHandler] ✅ Setup complete - %d anchors ready", anchorCount))
end

return PlantingHandler
