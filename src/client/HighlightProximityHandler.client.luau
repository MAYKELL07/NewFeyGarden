-- HighlightProximityHandler.client.luau
-- Feature 3: NPCs and fruits get highlighted when player is near
-- Only shows 1 proximity prompt at a time (closest)
-- Uses default ProximityPrompt style from NPC models

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not sharedFolder then
	warn("[HighlightProximityHandler] Shared folder not found")
	return
end

local Config = require(sharedFolder:WaitForChild("Config"))

local player = Players.LocalPlayer

-- NPCDialogueHandler reference (loaded lazily)
local NPCDialogueHandler = nil
local function getNPCDialogueHandler()
	if not NPCDialogueHandler then
		pcall(function()
			NPCDialogueHandler = require(script.Parent:WaitForChild("NPCDialogueHandler"))
		end)
	end
	return NPCDialogueHandler
end

local HighlightProximityHandler = {}

-- Configuration
local DEFAULT_HIGHLIGHT_DISTANCE = 15 -- studs - fallback distance to start highlighting
local DEFAULT_PROMPT_DISTANCE = 8 -- studs - fallback distance for prompt to be interactable
local SHOP_DISTANCE_MULTIPLIER = (Config.ProximityPrompts and Config.ProximityPrompts.ShopDistanceMultiplier) or 1
local NPC_FOLDER_NAME = "NPCs"

-- Theme colors
local NPC_HIGHLIGHT_COLOR = Color3.fromRGB(200, 180, 255) -- Purple for NPCs
local FRUIT_HIGHLIGHT_COLOR = Color3.fromRGB(255, 200, 150) -- Orange for fruits

-- Store all interactable objects
local interactables = {} -- {instance = {type = "NPC"/"Fruit", highlight = Highlight?, prompt = ProximityPrompt?}}

-- Get player position
local function getPlayerPosition()
	local character = player.Character
	if not character then return nil end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position
end

-- Create a highlight for an object
local function createHighlight(instance, highlightColor)
	-- Find parent model or use instance directly
	local targetModel = instance
	if instance:IsA("BasePart") then
		targetModel = instance:FindFirstAncestorWhichIsA("Model") or instance
	end
	
	-- Check if highlight already exists
	local existingHighlight = targetModel:FindFirstChildOfClass("Highlight")
	if existingHighlight then
		return existingHighlight
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "ProximityHighlight"
	highlight.Adornee = targetModel
	highlight.FillColor = highlightColor
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = highlightColor
	highlight.OutlineTransparency = 0.3
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = targetModel
	
	return highlight
end

-- Remove highlight from an object
local function removeHighlight(instance)
	local targetModel = instance
	if instance:IsA("BasePart") then
		targetModel = instance:FindFirstAncestorWhichIsA("Model") or instance
	end
	
	local highlight = targetModel:FindFirstChild("ProximityHighlight")
	if highlight then
		highlight:Destroy()
	end
end

-- Register an interactable
local function applyShopPromptDistance(prompt)
	if not prompt then return end
	if prompt:GetAttribute("ShopDistanceScaled") then return end

	if SHOP_DISTANCE_MULTIPLIER and SHOP_DISTANCE_MULTIPLIER ~= 1 then
		local baseDistance = prompt.MaxActivationDistance
		if not baseDistance or baseDistance <= 0 then
			baseDistance = 10
		end
		prompt.MaxActivationDistance = baseDistance * SHOP_DISTANCE_MULTIPLIER
	end

	prompt:SetAttribute("ShopDistanceScaled", true)
end

local function registerInteractable(instance, interactType)
	if interactables[instance] then return end
	
	local highlightColor = interactType == "NPC" and NPC_HIGHLIGHT_COLOR or FRUIT_HIGHLIGHT_COLOR
	
	interactables[instance] = {
		type = interactType,
		highlightColor = highlightColor,
		highlighted = false
	}
	
	-- For NPCs, ensure they have a ProximityPrompt and set up dialogue trigger
	if interactType == "NPC" then
		-- Prefer existing prompt inside NPC model
		local prompt = instance:FindFirstChildOfClass("ProximityPrompt", true)
		
		if not prompt then
			local targetPart = nil
			if instance:IsA("Model") then
				targetPart = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
			elseif instance:IsA("BasePart") then
				targetPart = instance
			end
			
			if targetPart then
				prompt = Instance.new("ProximityPrompt")
				prompt.ObjectText = instance.Name
				prompt.ActionText = "Talk"
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false
				prompt.Parent = targetPart
			end
		end
		
		if not prompt then
			return
		end

		applyShopPromptDistance(prompt)
		
		-- Determine NPC type from name or attribute
		local npcType = instance:GetAttribute("NPCType") or instance.Name
		local lowerType = npcType:lower()
		-- Normalize NPC type - check for keywords
		npcType = "SeedShop"
		if lowerType:find("gear") or lowerType:find("tool") then
			npcType = "GearShop"
		elseif lowerType:find("pet") or lowerType:find("egg") then
			npcType = "PetStore"
		elseif lowerType:find("fruit") or lowerType:find("sell") or lowerType:find("market") then
			npcType = "FruitSeller"
		end
		
		-- Connect prompt triggered to dialogue handler
		prompt.Triggered:Connect(function(triggeringPlayer)
			if triggeringPlayer ~= player then return end
			local dialogueHandler = getNPCDialogueHandler()
			if dialogueHandler and dialogueHandler.OpenDialogue then
				dialogueHandler.OpenDialogue(npcType, instance)
			end
		end)
		
		interactables[instance].prompt = prompt
		interactables[instance].npcType = npcType
	end
end

-- Scan for NPCs
local function findAllNPCs()
	local npcsFolder = workspace:FindFirstChild(NPC_FOLDER_NAME)
	if npcsFolder then
		for _, npc in ipairs(npcsFolder:GetChildren()) do
			if npc:IsA("Model") then
				registerInteractable(npc, "NPC")
			end
		end
	end
	
	-- Check for specific NPC names
	local npcNames = {
		"SeedShop",
		"FruitSeller",
		"PetStore",
		"GearShop",
		"PetShop",
		"SeedShopNPC",
		"FruitSellerNPC",
		"PetStoreNPC",
		"GearShopNPC",
		"PetShopNPC",
	}
	for _, npcName in ipairs(npcNames) do
		local npc = workspace:FindFirstChild(npcName, true)
		if npc and npc:IsA("Model") then
			registerInteractable(npc, "NPC")
		end
	end

	-- Broad scan for NPC models by attribute or Humanoid
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("Model") and not interactables[descendant] then
			if Players:GetPlayerFromCharacter(descendant) then
				continue
			end
			local npcType = descendant:GetAttribute("NPCType")
			local lowerName = descendant.Name:lower()
			local hasPrompt = descendant:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
			local nameLooksLikeNPC = lowerName:find("shop") or lowerName:find("seller") or lowerName:find("merchant")
				or lowerName:find("pet") or lowerName:find("egg") or lowerName:find("gear") or lowerName:find("seed")
			if npcType or hasPrompt or nameLooksLikeNPC then
				registerInteractable(descendant, "NPC")
			end
		end
	end
end

-- Scan for fruits
local function findAllFruits()
	-- Fruits are typically in garden plots or under plant models
	local gardensFolder = workspace:FindFirstChild(Config.World.GardensFolder)
	if not gardensFolder then return end
	
	for _, garden in ipairs(gardensFolder:GetChildren()) do
		if garden:IsA("Folder") or garden:IsA("Model") then
			-- Find Fruits folders inside plants
			for _, descendant in ipairs(garden:GetDescendants()) do
				-- Check for FruitType attribute and ensure fruit is revealed
				if descendant:GetAttribute("FruitType") and descendant:GetAttribute("Revealed") then
					registerInteractable(descendant, "Fruit")
				end
			end
		end
	end
end

-- Get instance position
local function getInstancePosition(instance)
	if instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart.Position
		end
		local part = instance:FindFirstChildWhichIsA("BasePart")
		return part and part.Position
	elseif instance:IsA("BasePart") then
		return instance.Position
	end
	return nil
end

-- Update highlights and find closest prompt
local function update()
	local playerPos = getPlayerPosition()
	if not playerPos then return end
	
	local closestPromptInstance = nil
	local closestPromptDistance = math.huge
	
	-- Scan for new fruits (they spawn dynamically)
	findAllFruits()
	
	for instance, data in pairs(interactables) do
		-- Check if instance still exists
		if not instance or not instance.Parent then
			interactables[instance] = nil
			continue
		end
		
		local instancePos = getInstancePosition(instance)
		if not instancePos then continue end
		
		local distance = (playerPos - instancePos).Magnitude
		
		-- Resolve prompt (if any) for distance tuning
		local prompt = data.prompt
		if not prompt then
			if instance:IsA("Model") then
				prompt = instance:FindFirstChildOfClass("ProximityPrompt", true)
			elseif instance:IsA("BasePart") then
				prompt = instance:FindFirstChildOfClass("ProximityPrompt")
			end
			data.prompt = prompt
		end

		local highlightDistance = (prompt and prompt.MaxActivationDistance) or DEFAULT_HIGHLIGHT_DISTANCE
		local promptDistance = (prompt and prompt.MaxActivationDistance) or DEFAULT_PROMPT_DISTANCE

		-- Handle highlighting
		if distance <= highlightDistance then
			if not data.highlighted then
				createHighlight(instance, data.highlightColor)
				data.highlighted = true
			end
		else
			if data.highlighted then
				removeHighlight(instance)
				data.highlighted = false
			end
		end
		
		-- Find closest prompt
		if distance <= promptDistance then
			if prompt and distance < closestPromptDistance then
				closestPromptInstance = instance
				closestPromptDistance = distance
			end
		end
	end
	
	-- Handle single prompt visibility (only show closest prompt)
	for instance in pairs(interactables) do
		if not instance or not instance.Parent then continue end
		
		local prompts = {}
		if instance:IsA("Model") then
			for _, desc in ipairs(instance:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					table.insert(prompts, desc)
				end
			end
		elseif instance:IsA("BasePart") then
			local p = instance:FindFirstChildOfClass("ProximityPrompt")
			if p then
				table.insert(prompts, p)
			end
		end
		
		for _, prompt in ipairs(prompts) do
			if instance == closestPromptInstance then
				prompt.Enabled = true
			else
				prompt.Enabled = false
			end
		end
	end
end

-- Initialize
task.spawn(function()
	player.CharacterAdded:Wait()
	task.wait(0.5)
	
	-- Find all interactables
	findAllNPCs()
	findAllFruits()
	
	-- Watch for new NPCs/Fruits
	local npcsFolder = workspace:FindFirstChild(NPC_FOLDER_NAME)
	if npcsFolder then
		npcsFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				registerInteractable(child, "NPC")
			end
		end)
	end
	
	-- Watch for new fruits in gardens
	local gardensFolder = workspace:FindFirstChild(Config.World.GardensFolder)
	if gardensFolder then
		gardensFolder.DescendantAdded:Connect(function(descendant)
			if descendant:GetAttribute("FruitType") then
				-- Wait for reveal attribute to be set
				if descendant:GetAttribute("Revealed") then
					registerInteractable(descendant, "Fruit")
				else
					-- Listen for reveal
					local conn
					conn = descendant:GetAttributeChangedSignal("Revealed"):Connect(function()
						if descendant:GetAttribute("Revealed") then
							registerInteractable(descendant, "Fruit")
							conn:Disconnect()
						end
					end)
				end
			end
		end)
		
		gardensFolder.DescendantRemoving:Connect(function(descendant)
			if interactables[descendant] then
				removeHighlight(descendant)
				interactables[descendant] = nil
			end
		end)
	end
	
	-- Start update loop
	RunService.Heartbeat:Connect(update)
end)

return HighlightProximityHandler
