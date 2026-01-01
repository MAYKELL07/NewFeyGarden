-- NPCDialogueHandler.client.luau
-- Feature 5: NPC dialogue system with numbered options (like the pet shop screenshot)
-- Seed shop has no dialogue, only opens the shop directly

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not sharedFolder then
	warn("[NPCDialogueHandler] Shared folder not found")
	return
end

local NPCModule = require(sharedFolder:WaitForChild("NPCModule"))
local Config = require(sharedFolder:WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Lazy load UIHandler to avoid circular dependency
local UIHandler = nil
local function getUIHandler()
	if not UIHandler then
		pcall(function()
			UIHandler = require(script.Parent:WaitForChild("UIHandler"))
		end)
	end
	return UIHandler
end

local NPCDialogueHandler = {}

-- Theme colors (matching UIHandler)
local THEME = {
	ForestDark = Color3.fromRGB(18, 10, 28),
	ForestDeep = Color3.fromRGB(28, 16, 40),
	WoodPanel = Color3.fromRGB(54, 24, 66),
	TealGem = Color3.fromRGB(86, 108, 186),
	GoldLeaf = Color3.fromRGB(210, 168, 120),
	TextLight = Color3.fromRGB(228, 218, 240),
	TextGold = Color3.fromRGB(210, 190, 230),
}

-- Dialogue definitions for each NPC type
local NPC_DIALOGUES = {
	-- Pet Store NPC dialogue (like the screenshot)
	PetStore = {
		greeting = "I am the pets salesman!",
		options = {
			{id = 1, text = "Show me the Egg Shop", action = "open_egg_shop"},
			{id = 2, text = "I want to sell my pet", action = "open_pet_sell"},
			{id = 3, text = "Show me pet info", action = "show_pet_info"},
			{id = 4, text = "Nevermind", action = "close"},
		}
	},
	
	-- Fruit Seller NPC dialogue
	FruitSeller = {
		greeting = "Welcome to the Fruit Market!",
		options = {
			{id = 1, text = "Sell my fruits", action = "open_sell_shop"},
			{id = 2, text = "Check fruit prices", action = "show_prices"},
			{id = 3, text = "Nevermind", action = "close"},
		}
	},
	
	-- Gear Shop NPC dialogue
	GearShop = {
		greeting = "Welcome to the Gear Emporium!",
		options = {
			{id = 1, text = "Show me your tools", action = "open_gear_shop"},
			{id = 2, text = "What gear do you have?", action = "open_gear_shop"},
			{id = 3, text = "Nevermind", action = "close"},
		}
	},
	
	-- Seed Shop has no dialogue - opens directly
	SeedShop = nil,
}

-- State
local currentSpeechUI = nil
local currentOptionsUI = nil
local currentNPCType = nil
local currentNPCModel = nil
local currentAdornee = nil
local isDialogueOpen = false
local activeTextTween = nil
local distanceCheckConnection = nil

local DIALOGUE_MAX_DISTANCE = 12 -- Close dialogue if player walks further than this

local function resolveNPCPart(npcModel)
	if not npcModel then
		return nil
	end

	if npcModel:IsA("BasePart") then
		return npcModel
	end

	if npcModel:IsA("Model") then
		-- Try to find Head that is a BasePart
		local head = npcModel:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			return head
		end
		
		-- Try PrimaryPart
		if npcModel.PrimaryPart and npcModel.PrimaryPart:IsA("BasePart") then
			return npcModel.PrimaryPart
		end
		
		-- Find any BasePart
		return npcModel:FindFirstChildWhichIsA("BasePart")
	end

	return nil
end

local function computeOffsets(targetPart)
	local heightOffset = 2.5
	if targetPart and targetPart:IsA("BasePart") then
		heightOffset = math.max(2.2, targetPart.Size.Y * 0.6)
	end

	local forwardOffset = Vector3.new()
	if targetPart and targetPart:IsA("BasePart") then
		forwardOffset = targetPart.CFrame.LookVector * 3
	end

	return Vector3.new(0, heightOffset, 0), forwardOffset + Vector3.new(0, heightOffset * 0.35, 0)
end

local function typeText(label, fullText)
	if not label then return end
	if activeTextTween then
		activeTextTween = nil
	end

	label.MaxVisibleGraphemes = 0
	label.Text = fullText

	local total = utf8.len(fullText) or #fullText
	local index = 0
	activeTextTween = true
	task.spawn(function()
		while activeTextTween and index < total do
			index += 1
			label.MaxVisibleGraphemes = index
			task.wait(0.02)
		end
		label.MaxVisibleGraphemes = total
		activeTextTween = nil
	end)
end

-- Create dialogue UI
local function createSpeechBillboard(targetPart)
	local speechOffset = Vector3.new()
	local _optionsOffset = Vector3.new()
	speechOffset, _optionsOffset = computeOffsets(targetPart)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NPCSpeech"
	billboard.Active = true
	billboard.AlwaysOnTop = true
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Size = UDim2.new(0, 400, 0, 60)
	billboard.StudsOffsetWorldSpace = speechOffset
	billboard.LightInfluence = 0
	billboard.MaxDistance = 90
	billboard.Adornee = targetPart
	billboard.Parent = playerGui

	-- No bubble background - just text with stroke/shadow
	local dialogueLabel = Instance.new("TextLabel")
	dialogueLabel.Name = "Dialogue"
	dialogueLabel.Size = UDim2.new(1, 0, 1, 0)
	dialogueLabel.BackgroundTransparency = 1
	dialogueLabel.Text = ""
	dialogueLabel.TextColor3 = THEME.TextLight
	dialogueLabel.Font = Enum.Font.GothamBlack
	dialogueLabel.TextSize = 24
	dialogueLabel.TextWrapped = true
	dialogueLabel.TextXAlignment = Enum.TextXAlignment.Center
	dialogueLabel.TextYAlignment = Enum.TextYAlignment.Center
	dialogueLabel.ZIndex = 2
	dialogueLabel.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(10, 10, 10)
	stroke.Transparency = 0
	stroke.Parent = dialogueLabel

	return billboard, dialogueLabel
end

local function createOptionsBillboard(targetPart, options)
	local _speechOffset = Vector3.new()
	local optionsOffset = Vector3.new()
	_speechOffset, optionsOffset = computeOffsets(targetPart)

	-- Move options to the right
	optionsOffset = Vector3.new(-2.5, optionsOffset.Y, optionsOffset.Z)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NPCOptions"
	billboard.Active = true
	billboard.AlwaysOnTop = true
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Size = UDim2.new(0, 460, 0, (#options * 38) + 24)
	billboard.StudsOffsetWorldSpace = optionsOffset
	billboard.LightInfluence = 0
	billboard.MaxDistance = 90
	billboard.Adornee = targetPart
	billboard.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Parent = billboard

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = frame

	for index, option in ipairs(options) do
		local optionButton = Instance.new("TextButton")
		optionButton.Name = "Option" .. index
		optionButton.Size = UDim2.new(1, -12, 0, 32)
		optionButton.Position = UDim2.new(0, 0, 0, 0)
		optionButton.BackgroundTransparency = 1
		optionButton.BorderSizePixel = 0
		optionButton.Text = "#" .. tostring(option.id) .. "  [\"" .. option.text .. "\"]"
		optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		optionButton.Font = Enum.Font.GothamBlack
		optionButton.TextSize = 24
		optionButton.TextXAlignment = Enum.TextXAlignment.Left
		optionButton.AutoButtonColor = false
		optionButton.LayoutOrder = index
		optionButton.ZIndex = 2
		optionButton.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(10, 10, 10)
		stroke.Transparency = 0
		stroke.Parent = optionButton

		-- Store original position for hover animation
		local originalPadding = UDim.new(0, 0)

		optionButton.MouseEnter:Connect(function()
			-- Slide right and change color on hover
			TweenService:Create(optionButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextColor3 = THEME.GoldLeaf,
				Position = UDim2.new(0, 20, 0, 0),
			}):Play()
		end)

		optionButton.MouseLeave:Connect(function()
			-- Slide back and reset color
			TweenService:Create(optionButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Position = UDim2.new(0, 0, 0, 0),
			}):Play()
		end)

		optionButton.MouseButton1Click:Connect(function()
			NPCDialogueHandler.HandleOptionSelected(currentNPCType, option)
		end)
	end

	return billboard
end

local function createDialogueUI(npcModel, greeting, options)
	if currentSpeechUI then
		currentSpeechUI:Destroy()
	end

	if currentOptionsUI then
		currentOptionsUI:Destroy()
	end

	local targetPart = resolveNPCPart(npcModel) or resolveNPCPart(player.Character)
	if not targetPart then
		warn("[NPCDialogueHandler] No valid part for billboard dialogue")
		return nil, nil
	end

	currentAdornee = targetPart
	local speechGui, dialogueLabel = createSpeechBillboard(targetPart)
	local optionsGui = createOptionsBillboard(targetPart, options)

	currentSpeechUI = speechGui
	currentOptionsUI = optionsGui

	return speechGui, dialogueLabel
end

-- Close dialogue UI
local function closeDialogueUI()
	if distanceCheckConnection then
		distanceCheckConnection:Disconnect()
		distanceCheckConnection = nil
	end

	if currentSpeechUI then
		currentSpeechUI:Destroy()
		currentSpeechUI = nil
	end

	if currentOptionsUI then
		currentOptionsUI:Destroy()
		currentOptionsUI = nil
	end

	currentAdornee = nil
	currentNPCType = nil
	currentNPCModel = nil
	isDialogueOpen = false
end

-- Open dialogue for an NPC
function NPCDialogueHandler.OpenDialogue(npcType, npcModel)
	local dialogue = NPC_DIALOGUES[npcType]

	if not dialogue or npcType == "SeedShop" then
		local uiHandler = getUIHandler()
		if uiHandler and uiHandler.OpenShopWindow then
			uiHandler.OpenShopWindow()
		end
		return
	end

	currentNPCType = npcType
	currentNPCModel = npcModel
	isDialogueOpen = true

	local _, dialogueLabel = createDialogueUI(npcModel, dialogue.greeting, dialogue.options)
	if not dialogueLabel then
		currentNPCType = nil
		currentNPCModel = nil
		isDialogueOpen = false
		return
	end

	typeText(dialogueLabel, dialogue.greeting)

	-- Start distance check loop after a short delay
	if distanceCheckConnection then
		distanceCheckConnection:Disconnect()
	end

	-- Small delay to prevent immediate closure
	task.delay(0.5, function()
		if not isDialogueOpen then return end
		
		distanceCheckConnection = RunService.Heartbeat:Connect(function()
			if not isDialogueOpen then
				if distanceCheckConnection then
					distanceCheckConnection:Disconnect()
					distanceCheckConnection = nil
				end
				return
			end

			-- Get player position
			local character = player.Character
			if not character then
				closeDialogueUI()
				return
			end

			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then
				closeDialogueUI()
				return
			end

			-- Get NPC position
			local npcPart = resolveNPCPart(currentNPCModel)
			if not npcPart or not npcPart:IsA("BasePart") then
				return -- Don't close, just skip this frame
			end

			local npcPosition = npcPart.Position
			local distance = (hrp.Position - npcPosition).Magnitude
			if distance > DIALOGUE_MAX_DISTANCE then
				closeDialogueUI()
			end
		end)
	end)
end

-- Handle option selection
function NPCDialogueHandler.HandleOptionSelected(npcType, option)
	local action = option.action
	
	closeDialogueUI()
	
	local uiHandler = getUIHandler()
	
	-- Handle actions
	if action == "close" then
		-- Just close, already done
		
	elseif action == "open_egg_shop" then
		-- Open pet shop (egg shop) UI
		if uiHandler and uiHandler.OpenPetShopWindow then
			uiHandler.OpenPetShopWindow()
		end
		
	elseif action == "open_pet_sell" then
		-- Open pets inventory window for selling
		if uiHandler and uiHandler.OpenPetsWindow then
			uiHandler.OpenPetsWindow()
		end
		
	elseif action == "show_pet_info" then
		-- Open pets inventory window to see pet info
		if uiHandler and uiHandler.OpenPetsWindow then
			uiHandler.OpenPetsWindow()
		end
		
	elseif action == "open_sell_shop" then
		-- Open fruit selling shop
		if uiHandler and uiHandler.OpenSellWindow then
			uiHandler.OpenSellWindow()
		end
		
	elseif action == "show_prices" then
		-- Open sell window to show prices
		if uiHandler and uiHandler.OpenSellWindow then
			uiHandler.OpenSellWindow()
		end
		
	elseif action == "open_gear_shop" then
		-- Open gear shop window
		if uiHandler and uiHandler.OpenGearShopWindow then
			uiHandler.OpenGearShopWindow()
		end
	end
end

-- Handle keyboard input (only Escape to close)
local function handleKeyboardInput(input, gameProcessed)
	if gameProcessed then return end
	if not isDialogueOpen then return end

	-- Escape to close
	if input.KeyCode == Enum.KeyCode.Escape then
		closeDialogueUI()
	end
end

-- Setup NPC interaction detection
-- NOTE: Prompt creation and triggering is handled by HighlightProximityHandler
-- This function is kept for backward compatibility but does nothing
local function setupNPCInteraction(npcModel, npcType)
	-- No longer creates prompts - HighlightProximityHandler handles this
end

-- Find NPCs and set up interactions
-- NOTE: Prompt creation and triggering is handled by HighlightProximityHandler
local function findAndSetupNPCs()
	-- No longer needed - HighlightProximityHandler handles this
end

-- Initialize
function NPCDialogueHandler.Initialize()
	-- Setup keyboard input for dialogue option selection
	UserInputService.InputBegan:Connect(handleKeyboardInput)
end

return NPCDialogueHandler
