-- ToolController.luau
-- Handles tool equipping, welding to hand, and activation via input
-- Tools are inventory items that weld to the player's hand when selected

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[ToolController] Shared folder missing; tool controller disabled")
	return {}
end

local function safeRequire(name)
	local ok, mod = pcall(function()
		return require(sharedFolder:WaitForChild(name, 5))
	end)
	if not ok then
		warn(string.format("[ToolController] Failed to load %s: %s", name, tostring(mod)))
		return nil
	end
	return mod
end

local Constants = safeRequire("Constants")
local Config = safeRequire("Config")
if not (Constants and Config) then
	return {}
end

local ToolController = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- State
local equippedTool = nil -- Currently equipped tool name
local equippedToolModel = nil -- The welded model instance
local toolCooldowns = {} -- {[toolName] = lastUseTime}

-- Tool templates folder in ReplicatedStorage
local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")

-- RemoteEvent for tool actions
local toolActionEvent = ReplicatedStorage:WaitForChild("ToolAction", 20)

-- Tool definitions (matches Config.Tools)
local TOOL_TYPES = {
	Shovel = {
		Name = "Shovel",
		Icon = "🪓",
		Cooldown = Config.Tools.Shovel.Cooldown or 1.0,
		Description = Config.Tools.Shovel.Description or "Dig up plants"
	},
	WateringCan = {
		Name = "WateringCan",
		Icon = "💧",
		Cooldown = Config.Tools.WateringCan.Cooldown or 1.5,
		Description = Config.Tools.WateringCan.Description or "Water plants"
	}
}

-- Get tool config
function ToolController.GetToolConfig(toolName)
	return TOOL_TYPES[toolName]
end

-- Get all available tools
function ToolController.GetAllTools()
	return TOOL_TYPES
end

-- Check if a tool is equipped
function ToolController.IsToolEquipped(toolName)
	return equippedTool == toolName
end

-- Get currently equipped tool
function ToolController.GetEquippedTool()
	return equippedTool
end

-- Unequip current tool
function ToolController.UnequipTool()
	if equippedToolModel then
		equippedToolModel:Destroy()
		equippedToolModel = nil
	end
	equippedTool = nil
end

-- Find the right hand attachment point
local function getRightHandAttachment()
	local character = player.Character
	if not character then return nil end
	
	-- Try to find RightHand (R15) or Right Arm (R6)
	local rightHand = character:FindFirstChild("RightHand")
	if rightHand then
		-- R15 rig - use RightGripAttachment if available
		local attachment = rightHand:FindFirstChild("RightGripAttachment")
		if attachment then
			return rightHand, attachment.CFrame
		end
		return rightHand, CFrame.new(0, -0.5, 0)
	end
	
	-- R6 rig fallback
	local rightArm = character:FindFirstChild("Right Arm")
	if rightArm then
		return rightArm, CFrame.new(0, -1, 0)
	end
	
	return nil
end

-- Weld tool to player's hand
local function weldToolToHand(toolModel)
	local handPart, gripOffset = getRightHandAttachment()
	if not handPart then
		warn("[ToolController] Could not find hand part")
		return false
	end
	
	-- Find the handle in the tool model
	local handle = toolModel:FindFirstChild("Handle") or toolModel.PrimaryPart
	if not handle then
		-- If no Handle, use the first BasePart
		for _, child in ipairs(toolModel:GetDescendants()) do
			if child:IsA("BasePart") then
				handle = child
				break
			end
		end
	end
	
	if not handle then
		warn("[ToolController] Tool has no Handle or parts")
		return false
	end
	
	-- Make all parts in the tool non-collidable and unanchored
	for _, part in ipairs(toolModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = false
			part.Massless = true
		end
	end
	
	-- Also handle the handle itself
	handle.CanCollide = false
	handle.Anchored = false
	handle.Massless = true
	
	-- Create weld
	local weld = Instance.new("Weld")
	weld.Name = "ToolWeld"
	weld.Part0 = handPart
	weld.Part1 = handle
	
	-- Apply grip offset (adjust C1 for tool orientation)
	weld.C0 = gripOffset
	weld.C1 = CFrame.new(0, 0, 0) -- Adjust this per-tool if needed
	
	weld.Parent = handle
	
	-- Parent tool to character
	toolModel.Parent = player.Character
	
	return true
end

-- Equip a tool by name
function ToolController.EquipTool(toolName)
	-- Validate tool exists
	if not TOOL_TYPES[toolName] then
		warn("[ToolController] Unknown tool:", toolName)
		return false
	end
	
	-- Unequip current tool first
	ToolController.UnequipTool()
	
	-- Find tool template
	if not toolsFolder then
		toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	end
	
	if not toolsFolder then
		warn("[ToolController] Tools folder not found in ReplicatedStorage")
		return false
	end
	
	local toolTemplate = toolsFolder:FindFirstChild(toolName)
	if not toolTemplate then
		warn("[ToolController] Tool template not found:", toolName)
		return false
	end
	
	-- Clone the tool
	local toolClone = toolTemplate:Clone()
	toolClone.Name = toolName .. "_Equipped"
	
	-- Weld to hand
	local success = weldToolToHand(toolClone)
	if not success then
		toolClone:Destroy()
		return false
	end
	
	equippedTool = toolName
	equippedToolModel = toolClone
	
	return true
end

-- Toggle tool equip/unequip
function ToolController.ToggleTool(toolName)
	if equippedTool == toolName then
		ToolController.UnequipTool()
		return false
	else
		return ToolController.EquipTool(toolName)
	end
end

-- Check cooldown
local function isOnCooldown(toolName)
	local config = TOOL_TYPES[toolName]
	if not config then return false end
	
	local lastUse = toolCooldowns[toolName] or 0
	local now = os.clock()
	
	if now - lastUse < config.Cooldown then
		return true
	end
	
	return false
end

-- Use the equipped tool
function ToolController.UseTool()
	if not equippedTool then return end
	if not toolActionEvent then return end
	
	-- Check cooldown
	if isOnCooldown(equippedTool) then
		return
	end
	
	-- Set cooldown
	toolCooldowns[equippedTool] = os.clock()
	
	-- Get target from mouse
	local target = mouse.Target
	local position = mouse.Hit.Position
	
	-- Check distance
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local distance = (character.HumanoidRootPart.Position - position).Magnitude
		if distance > (Config.Tools.MaxUseDistance or 15) then
			-- Too far
			return
		end
	end
	
	-- Fire to server
	if target then
		toolActionEvent:FireServer(equippedTool, target, position)
	end
end

-- Input handling for tool activation (click to use)
local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	
	-- Left mouse button or touch
	if input.UserInputType == Enum.UserInputType.MouseButton1 or 
	   input.UserInputType == Enum.UserInputType.Touch then
		if equippedTool then
			ToolController.UseTool()
		end
	end
end

-- Handle character respawn
local function onCharacterAdded(character)
	-- Re-equip tool if one was equipped
	if equippedTool then
		local toolName = equippedTool
		equippedToolModel = nil
		equippedTool = nil
		task.wait(0.5) -- Wait for character to fully load
		ToolController.EquipTool(toolName)
	end
end

-- Initialize
function ToolController.Initialize()
	-- Connect input
	UserInputService.InputBegan:Connect(onInputBegan)
	
	-- Handle respawn
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Auto-initialize
ToolController.Initialize()

return ToolController
