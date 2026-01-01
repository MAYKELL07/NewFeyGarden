--!strict
-- ItemHoldController.luau
-- Handles equipping and holding seeds/fruits in the player's hand
-- Items are welded to the player's right hand similar to tools

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[ItemHoldController] Shared folder missing; item hold disabled")
	return {}
end

local function safeRequire(name: string)
	local ok, mod = pcall(function()
		return require(sharedFolder:WaitForChild(name, 5))
	end)
	if not ok then
		warn(string.format("[ItemHoldController] Failed to load %s: %s", name, tostring(mod)))
		return nil
	end
	return mod
end

local Constants = safeRequire("Constants")
if not Constants then
	return {}
end

export type ItemType = "Seed" | "Fruit"

export type HeldItem = {
	itemType: ItemType,
	itemName: string,
	weight: number,
}

local ItemHoldController = {}

-- DEBUG: Set to true to see debug prints
local DEBUG = true

local function debugPrint(...)
	if DEBUG then
		print("[ItemHoldController DEBUG]", ...)
	end
end

local player = Players.LocalPlayer

-- State
local heldItemData: HeldItem? = nil -- Currently held item info
local heldItemModel: Model? = nil -- The welded model instance

-- Base scale for held items (items are scaled down when held)
local BASE_HELD_SCALE = 0.35

-- Scale range based on weight (weight 0.8-1.2 maps to scale multiplier)
local WEIGHT_SCALE_MIN = 0.8
local WEIGHT_SCALE_MAX = 1.3

-- Hand grip offset for items
local ITEM_GRIP_OFFSET = CFrame.new(0, -0.3, -0.2) * CFrame.Angles(math.rad(-30), 0, 0)

-- Get held item info
function ItemHoldController.GetHeldItem(): HeldItem?
	return heldItemData
end

-- Check if an item is held
function ItemHoldController.IsHoldingItem(): boolean
	return heldItemData ~= nil
end

-- Check if holding a specific item type
function ItemHoldController.IsHoldingType(itemType: ItemType): boolean
	return heldItemData ~= nil and heldItemData.itemType == itemType
end

-- Check if holding a specific item
function ItemHoldController.IsHolding(itemType: ItemType, itemName: string): boolean
	return heldItemData ~= nil and heldItemData.itemType == itemType and heldItemData.itemName == itemName
end

-- Find the right hand attachment point
local function getRightHandAttachment(): (BasePart?, CFrame)
	local character = player.Character
	if not character then 
		return nil, CFrame.new() 
	end
	
	-- Try to find RightHand (R15) or Right Arm (R6)
	local rightHand = character:FindFirstChild("RightHand")
	if rightHand and rightHand:IsA("BasePart") then
		-- R15 rig - use RightGripAttachment if available
		local attachment = rightHand:FindFirstChild("RightGripAttachment")
		if attachment then
			return rightHand, attachment.CFrame
		end
		return rightHand, CFrame.new(0, -0.5, 0)
	end
	
	-- R6 rig fallback
	local rightArm = character:FindFirstChild("Right Arm")
	if rightArm and rightArm:IsA("BasePart") then
		return rightArm, CFrame.new(0, -1, 0)
	end
	
	return nil, CFrame.new()
end

-- Calculate scale based on weight
local function calculateScale(weight: number): number
	-- Clamp weight to expected range
	local clampedWeight = math.clamp(weight, Constants.SIZE_WEIGHT_CONFIG.Plant.WeightMin, Constants.SIZE_WEIGHT_CONFIG.Plant.WeightMax)
	
	-- Map weight to scale multiplier (heavier = bigger visual)
	local weightRange = Constants.SIZE_WEIGHT_CONFIG.Plant.WeightMax - Constants.SIZE_WEIGHT_CONFIG.Plant.WeightMin
	local normalizedWeight = (clampedWeight - Constants.SIZE_WEIGHT_CONFIG.Plant.WeightMin) / weightRange
	
	local scaleMultiplier = WEIGHT_SCALE_MIN + (WEIGHT_SCALE_MAX - WEIGHT_SCALE_MIN) * normalizedWeight
	
	return BASE_HELD_SCALE * scaleMultiplier
end

-- Scale all parts in a model
local function scaleModel(model: Model, scale: number)
	-- Find primary part or first base part
	local primaryPart = model.PrimaryPart
	if not primaryPart then
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("BasePart") then
				primaryPart = child
				break
			end
		end
	end
	
	if not primaryPart then
		return
	end
	
	local primaryCFrame = primaryPart.CFrame
	
	-- Scale all parts relative to primary
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Scale the part size
			part.Size = part.Size * scale
			
			-- Adjust position relative to primary part
			if part ~= primaryPart then
				local offset = primaryCFrame:PointToObjectSpace(part.Position)
				part.CFrame = primaryCFrame * CFrame.new(offset * scale)
			end
		end
	end
end

-- Weld item model to player's hand
local function weldItemToHand(itemModel: Model, weight: number): boolean
	debugPrint("weldItemToHand called, model:", itemModel.Name, "weight:", weight)
	
	local handPart, gripOffset = getRightHandAttachment()
	if not handPart then
		warn("[ItemHoldController] Could not find hand part")
		debugPrint("Character exists:", player.Character ~= nil)
		if player.Character then
			debugPrint("Character children:")
			for _, c in ipairs(player.Character:GetChildren()) do
				debugPrint("  -", c.Name, c.ClassName)
			end
		end
		return false
	end
	debugPrint("Found hand part:", handPart.Name)
	
	-- Find the handle/primary part in the item model
	local handle = itemModel:FindFirstChild("Handle") or itemModel.PrimaryPart
	debugPrint("Initial handle search - Handle child:", itemModel:FindFirstChild("Handle") and "found" or "nil", "PrimaryPart:", itemModel.PrimaryPart and itemModel.PrimaryPart.Name or "nil")
	
	if not handle then
		-- If no Handle, use the first BasePart
		debugPrint("No Handle/PrimaryPart, searching descendants...")
		for _, child in ipairs(itemModel:GetDescendants()) do
			if child:IsA("BasePart") then
				handle = child
				debugPrint("Found BasePart as handle:", child.Name)
				break
			end
		end
	end
	
	if not handle or not handle:IsA("BasePart") then
		warn("[ItemHoldController] Item has no Handle or parts")
		debugPrint("Model descendants:")
		for _, c in ipairs(itemModel:GetDescendants()) do
			debugPrint("  -", c.Name, c.ClassName)
		end
		return false
	end
	debugPrint("Using handle:", handle.Name, "class:", handle.ClassName)
	
	-- Calculate scale based on weight
	local itemScale = calculateScale(weight)
	
	-- Scale the model
	scaleModel(itemModel, itemScale)
	
	-- Make all parts in the item non-collidable and unanchored
	for _, part in ipairs(itemModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = false
			part.Massless = true
			part.CastShadow = false
		end
	end
	
	-- Also handle the handle itself
	handle.CanCollide = false
	handle.Anchored = false
	handle.Massless = true
	
	-- Create weld
	local weld = Instance.new("Weld")
	weld.Name = "ItemWeld"
	weld.Part0 = handPart
	weld.Part1 = handle
	
	-- Apply grip offset with item-specific offset
	weld.C0 = gripOffset * ITEM_GRIP_OFFSET
	weld.C1 = CFrame.new(0, 0, 0)
	
	weld.Parent = handle
	
	-- Parent item to character
	itemModel.Parent = player.Character
	
	return true
end

-- Clone item model from ReplicatedStorage
local function cloneItemModel(itemType: ItemType, itemName: string): Model?
	debugPrint("cloneItemModel called with:", itemType, itemName)
	
	local plantsFolder = ReplicatedStorage:FindFirstChild("Plants")
	if not plantsFolder then
		warn("[ItemHoldController] Plants folder not found in ReplicatedStorage")
		debugPrint("ReplicatedStorage children:", table.concat({
			unpack((function()
				local names = {}
				for _, c in ipairs(ReplicatedStorage:GetChildren()) do
					table.insert(names, c.Name)
				end
				return names
			end)())
		}, ", "))
		return nil
	end
	debugPrint("Found Plants folder")
	
	-- Try exact match first
	local plantFolder = plantsFolder:FindFirstChild(itemName)
	
	-- If not found, try case-insensitive / partial match
	if not plantFolder then
		local itemNameLower = string.lower(itemName)
		debugPrint("Exact match not found, trying case-insensitive search for:", itemNameLower)
		
		for _, child in ipairs(plantsFolder:GetChildren()) do
			local childNameLower = string.lower(child.Name)
			-- Check if folder name starts with the item name (handles "chameleonberri" -> "ChameleonBerries")
			-- Or if item name starts with the folder name
			if string.find(childNameLower, itemNameLower, 1, true) or string.find(itemNameLower, childNameLower, 1, true) then
				plantFolder = child
				debugPrint("Found match:", child.Name, "for", itemName)
				break
			end
		end
	end
	
	if not plantFolder then
		warn("[ItemHoldController] Plant folder not found for:", itemName)
		debugPrint("Plants folder children:", table.concat({
			unpack((function()
				local names = {}
				for _, c in ipairs(plantsFolder:GetChildren()) do
					table.insert(names, c.Name)
				end
				return names
			end)())
		}, ", "))
		return nil
	end
	debugPrint("Found plant folder:", plantFolder.Name)
	
	-- List all children in plant folder for debugging
	debugPrint("Plant folder children:")
	for _, child in ipairs(plantFolder:GetChildren()) do
		debugPrint("  -", child.Name, "(", child.ClassName, ")")
	end
	
	-- Get the appropriate mesh based on item type
	local itemTemplate: Instance? = nil
	
	if itemType == "Seed" then
		-- Seeds are stored as "Seed" in the plant folder
		itemTemplate = plantFolder:FindFirstChild("Seed")
		debugPrint("Looking for Seed, found:", itemTemplate and itemTemplate.Name or "nil")
	else
		-- Fruits are stored as Fruit1, Fruit2, Fruit3, Fruit4 - pick a random one
		local fruitVariants = {}
		for i = 1, 4 do
			local fruit = plantFolder:FindFirstChild("Fruit" .. i)
			if fruit then
				debugPrint("Found fruit variant:", fruit.Name)
				table.insert(fruitVariants, fruit)
			end
		end
		
		debugPrint("Total fruit variants found:", #fruitVariants)
		
		if #fruitVariants > 0 then
			-- Pick a random fruit variant
			local idx = math.random(1, #fruitVariants)
			itemTemplate = fruitVariants[idx]
			debugPrint("Picked fruit variant index:", idx, "name:", itemTemplate and itemTemplate.Name or "nil")
		else
			-- Fallback: if no fruit models exist, use the Seed as fruit
			itemTemplate = plantFolder:FindFirstChild("Seed")
			debugPrint("No fruits found, falling back to Seed:", itemTemplate and itemTemplate.Name or "nil")
		end
	end
	
	if not itemTemplate then
		warn("[ItemHoldController] No model found for:", itemType, itemName)
		return nil
	end
	debugPrint("itemTemplate found:", itemTemplate.Name, "class:", itemTemplate.ClassName)
	
	-- If it's a Model, clone directly
	if itemTemplate:IsA("Model") then
		debugPrint("Cloning Model directly")
		local cloned = itemTemplate:Clone()
		debugPrint("Cloned model has", #cloned:GetDescendants(), "descendants")
		return cloned
	end
	
	-- If it's a BasePart, wrap in a model
	if itemTemplate:IsA("BasePart") then
		debugPrint("Wrapping BasePart in Model")
		local model = Instance.new("Model")
		model.Name = itemName .. "_Held"
		
		local partClone = itemTemplate:Clone()
		partClone.Name = "Handle"
		partClone.Parent = model
		
		model.PrimaryPart = partClone
		
		debugPrint("Created wrapper model with Handle:", partClone.Name, "size:", partClone.Size)
		return model
	end
	
	warn("[ItemHoldController] Unknown item template type for:", itemName)
	return nil
end

-- Unhold current item
function ItemHoldController.UnholdItem()
	if heldItemModel then
		-- Fade out animation
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, part in ipairs(heldItemModel:GetDescendants()) do
			if part:IsA("BasePart") then
				local tween = TweenService:Create(part, tweenInfo, {Transparency = 1})
				tween:Play()
			end
		end
		
		task.delay(0.15, function()
			if heldItemModel then
				heldItemModel:Destroy()
				heldItemModel = nil
			end
		end)
	else
		heldItemModel = nil
	end
	
	heldItemData = nil
end

-- Hold an item by type and name
-- @param itemType: "Seed" or "Fruit"
-- @param itemName: The plant type name (e.g., "lumut", "dreamfruit")
-- @param weight: Optional weight for scaling (default 1.0)
function ItemHoldController.HoldItem(itemType: ItemType, itemName: string, weight: number?): boolean
	debugPrint("============================================")
	debugPrint("HoldItem called:", itemType, itemName, "weight:", weight)
	
	-- Validate item type
	if itemType ~= "Seed" and itemType ~= "Fruit" then
		warn("[ItemHoldController] Invalid item type:", itemType)
		return false
	end
	
	-- Validate plant type exists
	local config = Constants.PLANT_CONFIG[itemName]
	if not config then
		warn("[ItemHoldController] Unknown plant type:", itemName)
		debugPrint("Available plant types in PLANT_CONFIG:")
		for k, _ in pairs(Constants.PLANT_CONFIG) do
			debugPrint("  -", k)
		end
		return false
	end
	debugPrint("Plant config found for:", itemName)
	
	-- Unhold current item first
	ItemHoldController.UnholdItem()
	
	-- Use provided weight or default to 1.0
	local itemWeight = weight or 1.0
	
	-- Clone the item model
	debugPrint("Cloning item model...")
	local itemModel = cloneItemModel(itemType, itemName)
	if not itemModel then
		debugPrint("cloneItemModel returned nil!")
		return false
	end
	debugPrint("Model cloned successfully:", itemModel.Name)
	
	itemModel.Name = itemName .. "_Held"
	
	-- Weld to hand
	debugPrint("Welding to hand...")
	local success = weldItemToHand(itemModel, itemWeight)
	if not success then
		debugPrint("weldItemToHand failed!")
		itemModel:Destroy()
		return false
	end
	debugPrint("Weld successful!")
	
	-- Fade in animation
	debugPrint("Starting fade in animation...")
	local partCount = 0
	for _, part in ipairs(itemModel:GetDescendants()) do
		if part:IsA("BasePart") then
			partCount = partCount + 1
			local originalTransparency = part.Transparency
			part.Transparency = 1
			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(part, tweenInfo, {Transparency = originalTransparency})
			tween:Play()
		end
	end
	debugPrint("Animating", partCount, "parts")
	
	heldItemData = {
		itemType = itemType,
		itemName = itemName,
		weight = itemWeight,
	}
	heldItemModel = itemModel
	
	debugPrint("HoldItem completed successfully! Model parent:", itemModel.Parent and itemModel.Parent.Name or "nil")
	debugPrint("============================================")
	
	return true
end

-- Toggle item hold
function ItemHoldController.ToggleItem(itemType: ItemType, itemName: string, weight: number?): boolean
	if ItemHoldController.IsHolding(itemType, itemName) then
		ItemHoldController.UnholdItem()
		return false
	else
		return ItemHoldController.HoldItem(itemType, itemName, weight)
	end
end

-- Handle character respawn
local function onCharacterAdded(character: Model)
	-- Re-hold item if one was held
	if heldItemData then
		local itemData = heldItemData
		heldItemModel = nil
		heldItemData = nil
		task.wait(0.5) -- Wait for character to fully load
		ItemHoldController.HoldItem(itemData.itemType, itemData.itemName, itemData.weight)
	end
end

-- Initialize
function ItemHoldController.Initialize()
	-- Handle respawn
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Auto-initialize
ItemHoldController.Initialize()

return ItemHoldController
