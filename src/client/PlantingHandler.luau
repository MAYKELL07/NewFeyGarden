-- PlantingHandler.luau
-- Handles clicking on plots to plant seeds using raycast for free-form planting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PlantingHandler = {}
local selectedPlantProvider = nil

function PlantingHandler.SetSelectedPlantProvider(provider)
	selectedPlantProvider = provider
end
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local connections = {}
local playerGarden = nil
local plotParts = {} -- Plot1-Plot8 parts used for validation

-- Raycast from screen position to world
local function raycastFromMouse()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	-- Exclude the player's character
	local character = player.Character
	if character then
		raycastParams.FilterDescendantsInstances = {character}
	end
	
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
	return result
end

-- Check if a position is inside any of the Plot parts bounds (Plot1-Plot8)
local function isPositionInPlot(position)
	if #plotParts == 0 then
		return false
	end
	
	-- Check against each plot part
	for _, plotPart in ipairs(plotParts) do
		-- Convert position to local space to handle rotation
		local localPos = plotPart.CFrame:PointToObjectSpace(position)
		local halfSize = plotPart.Size / 2
		local margin = 1.0 -- Small margin to avoid edge-case rejections
		
		local inBounds = localPos.X >= -halfSize.X - margin
			and localPos.X <= halfSize.X + margin
			and localPos.Z >= -halfSize.Z - margin
			and localPos.Z <= halfSize.Z + margin
		
		if inBounds then
			return true
		end
	end
	
	return false
end

-- Check if hit part is part of the plot area (for planting)
local function isValidPlantingSurface(hitPart)
	if not hitPart then
		return false
	end
	
	-- Check if it's one of the plot parts
	for _, plotPart in ipairs(plotParts) do
		if hitPart == plotPart then
			return true
		end
	end
	
	-- Check if it's named Plot (including Plot1-Plot8), Floor, or Ground
	local name = hitPart.Name:lower()
	if name:match("^plot%d*$") or name == "floor" or name == "ground" then
		return true
	end
	
	-- Check if it's a descendant of the plots folder
	local plotsFolder = playerGarden and playerGarden:FindFirstChild(Config.World.PlotsFolder)
	if plotsFolder and hitPart:IsDescendantOf(plotsFolder) then
		return true
	end
	
	-- Check if it's a descendant of the player's garden
	if playerGarden and hitPart:IsDescendantOf(playerGarden) then
		-- Make sure it's not a plant or other object
		if not hitPart:FindFirstAncestorOfClass("Model") then
			return true
		end
		-- Allow if the ancestor model doesn't have PlantType (not a plant)
		local ancestorModel = hitPart:FindFirstAncestorOfClass("Model")
		if ancestorModel and not ancestorModel:GetAttribute("PlantType") then
			return true
		end
	end
	
	return false
end

-- Handle mouse click for free-form planting
local function onMouseClick()
	-- Get selected plant type
	local selectedPlantType = selectedPlantProvider and selectedPlantProvider()
	if not selectedPlantType then
		-- No seed selected, don't show warning on every click
		return
	end
	
	-- Raycast from mouse position
	local result = raycastFromMouse()
	if not result then
		return
	end
	
	-- Check if we hit a valid planting surface
	if not isValidPlantingSurface(result.Instance) then
		return
	end
	
	-- Check if position is within plot bounds
	local hitPosition = result.Position
	if not isPositionInPlot(hitPosition) then
		return
	end
	
	-- Fire to server with position
	local plantSeedAtPositionEvent = ReplicatedStorage:FindFirstChild(Constants.EVENTS.PLANT_SEED_AT_POSITION)
	if plantSeedAtPositionEvent then
		plantSeedAtPositionEvent:FireServer(hitPosition, selectedPlantType)
	else
		warn("[PlantingHandler] PLANT_SEED_AT_POSITION event not found!")
	end
end

-- Setup free-form planting with raycast
local function setupFreePlanting(garden)
	playerGarden = garden
	plotParts = {} -- Reset plot parts
	
	-- Find all Plot parts (Plot1-Plot8) for validation
	local plotsFolder = garden:FindFirstChild(Config.World.PlotsFolder)
	if plotsFolder then
		for i = 1, 8 do
			local plotPart = plotsFolder:FindFirstChild("Plot" .. i)
			if plotPart and plotPart:IsA("BasePart") then
				table.insert(plotParts, plotPart)
			end
		end
	end
	
	if #plotParts == 0 then
		warn("[PlantingHandler] No plot parts (Plot1-Plot8) found for bounds validation!")
	end
	
	-- Connect mouse click for planting
	if connections.mouseClick then
		connections.mouseClick:Disconnect()
	end
	
	connections.mouseClick = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Don't process if UI is handling it
		if gameProcessed then
			return
		end
		
		-- Only handle left mouse button
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			onMouseClick()
		end
	end)
end

function PlantingHandler.Initialize()
	-- Wait for player's garden
	task.wait(2) -- Give time for garden assignment
	
	-- Find player's garden
	local gardensFolder = workspace:WaitForChild(Config.World.GardensFolder, 10)
	if not gardensFolder then
		warn("[PlantingHandler] Gardens folder not found!")
		return
	end
	
	-- Find the garden with our UserId
	local foundGarden = nil
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") and garden:GetAttribute("OwnerUserId") == player.UserId then
			foundGarden = garden
			break
		end
	end
	
	if not foundGarden then
		warn("[PlantingHandler] Player garden not found!")
		return
	end
	
	playerGarden = foundGarden
	
	-- Free-form planting mode - raycast click anywhere on the plot
	setupFreePlanting(foundGarden)
end

return PlantingHandler
