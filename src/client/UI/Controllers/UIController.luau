--!strict
-- UIController.luau
-- Main UI controller that initializes all UI components and handles global state

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- UI Modules
local Theme = require(script.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent:WaitForChild("Styles"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

-- Components
local CurrencyDisplay = require(script.Parent:WaitForChild("Components"):WaitForChild("CurrencyDisplay"))
local WeatherDisplay = require(script.Parent:WaitForChild("Components"):WaitForChild("WeatherDisplay"))
local Hotbar = require(script.Parent:WaitForChild("Components"):WaitForChild("Hotbar"))
local Notification = require(script.Parent:WaitForChild("Components"):WaitForChild("Notification"))

-- Controllers
local ShopController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("ShopController"))
local InventoryController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("InventoryController"))

local UIController = {}

local player = Players.LocalPlayer
local screenGui: ScreenGui? = nil
local uiRoot: Frame? = nil
local hudLayer: Frame? = nil
local windowLayer: Frame? = nil
local hudContainer: Frame? = nil
local initialized = false

-- Remote events
local updateCurrency: RemoteEvent? = nil
local updateInventory: RemoteEvent? = nil
local weatherChanged: RemoteEvent? = nil

-- Tool controller reference (set externally)
local toolController: any = nil

-- Audio manager reference (set externally)
local audioManager: any = nil

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function UIController.Initialize()
	if initialized then return end
	
	-- Wait for PlayerGui
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create or find screen gui
	screenGui = playerGui:FindFirstChild("FeyGardenUI") :: ScreenGui
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "FeyGardenUI"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.IgnoreGuiInset = true
		screenGui.Parent = playerGui
	end

	-- Root container with aspect ratio to keep UI consistent across devices
	uiRoot = screenGui:FindFirstChild("UIRoot") :: Frame?
	if not uiRoot then
		local root = Instance.new("Frame")
		root.Name = "UIRoot"
		root.Size = UDim2.new(1, 0, 1, 0)
		root.Position = UDim2.new(0.5, 0, 0.5, 0)
		root.AnchorPoint = Vector2.new(0.5, 0.5)
		root.BackgroundTransparency = 1
		Styles.AddAspectRatio(root, 16 / 9)
		root.Parent = screenGui
		uiRoot = root
	end

	-- Layer frames for HUD and windows
	hudLayer = uiRoot:FindFirstChild("HUDLayer") :: Frame?
	if not hudLayer then
		local hud = Instance.new("Frame")
		hud.Name = "HUDLayer"
		hud.Size = UDim2.new(1, 0, 1, 0)
		hud.BackgroundTransparency = 1
		hud.Parent = uiRoot
		hudLayer = hud
	end

	windowLayer = uiRoot:FindFirstChild("WindowLayer") :: Frame?
	if not windowLayer then
		local layer = Instance.new("Frame")
		layer.Name = "WindowLayer"
		layer.Size = UDim2.new(1, 0, 1, 0)
		layer.BackgroundTransparency = 1
		layer.ZIndex = 50
		layer.Parent = uiRoot
		windowLayer = layer
	end

	-- HUD container (top-left stack) for compact HUD elements
	hudContainer = hudLayer and hudLayer:FindFirstChild("HUDContainer") :: Frame?
	if hudLayer and not hudContainer then
		local container = Instance.new("Frame")
		container.Name = "HUDContainer"
		container.Size = UDim2.new(0, 0, 0, 60)
		container.AutomaticSize = Enum.AutomaticSize.XY
		container.BackgroundTransparency = 1
		container.Position = UDim2.new(0, 0, 0, 0)
		container.ZIndex = 5
		container.Parent = hudLayer

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, Styles.GetTopPadding() + 10)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.Parent = container

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.Padding = UDim.new(0, 10)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = container

		hudContainer = container
	end
	
	-- Get remote events
	local events = ReplicatedStorage:FindFirstChild("Events")
	if events then
		updateCurrency = events:FindFirstChild("UpdateCurrency") :: RemoteEvent?
		updateInventory = events:FindFirstChild("UpdateInventory") :: RemoteEvent?
		weatherChanged = events:FindFirstChild("WeatherChanged") :: RemoteEvent?
	end
	
	-- Initialize HUD components
	local hudParent = hudContainer or hudLayer or screenGui
	CurrencyDisplay.Create(hudParent)
	WeatherDisplay.Create(hudParent)
	Hotbar.Create(hudParent, function(slotIndex)
		UIController.OnHotbarSelect(slotIndex)
	end)
	
	-- Initialize controllers
	local windowParent = windowLayer or screenGui
	ShopController.Initialize(windowParent)
	InventoryController.Initialize(windowParent)
	
	-- Set up seed selection callback
	InventoryController.SetOnSeedSelected(function(seedType)
		-- Could trigger planting mode here
	end)
	
	-- Connect remote events
	UIController.ConnectRemotes()
	
	-- Set up keyboard shortcuts
	UIController.SetupKeyboardShortcuts()
	
	initialized = true
	
	local notifParent = hudLayer or screenGui
	Notification.Show(notifParent, "Welcome to Fey Garden! 🌿", "info", 3)
end

-- =============================================================================
-- REMOTE EVENT HANDLERS
-- =============================================================================

function UIController.ConnectRemotes()
	if updateCurrency then
		updateCurrency.OnClientEvent:Connect(function(coins: number)
			ClientState.SetCoins(coins)
		end)
	end
	
	if updateInventory then
		updateInventory.OnClientEvent:Connect(function(inventoryData)
			if typeof(inventoryData) == "table" then
				-- Update individual components
				if inventoryData.Seeds then
					ClientState.UpdateSeeds(inventoryData.Seeds)
				end
				if inventoryData.Pets then
					ClientState.UpdatePets(inventoryData.Pets)
				end
				if inventoryData.Fruits then
					ClientState.UpdateFruits(inventoryData.Fruits)
				end
				if inventoryData.Eggs then
					ClientState.UpdateEggs(inventoryData.Eggs)
				end
				if inventoryData.EquippedPets then
					ClientState.UpdateEquippedPets(inventoryData.EquippedPets)
				end
				if inventoryData.GardenPets then
					ClientState.UpdateGardenPets(inventoryData.GardenPets)
				end
			end
		end)
	end
	
	if weatherChanged then
		weatherChanged.OnClientEvent:Connect(function(weather: string)
			ClientState.SetWeather(weather)
		end)
	end
end

-- =============================================================================
-- KEYBOARD SHORTCUTS
-- =============================================================================

function UIController.SetupKeyboardShortcuts()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Number keys for hotbar
		if input.KeyCode == Enum.KeyCode.One then
			Hotbar.SelectSlot(1)
			UIController.OnHotbarSelect(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			Hotbar.SelectSlot(2)
			UIController.OnHotbarSelect(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			Hotbar.SelectSlot(3)
			UIController.OnHotbarSelect(3)
		end
		
		-- I for inventory
		if input.KeyCode == Enum.KeyCode.I then
			InventoryController.Toggle()
		end
		
		-- Escape to close windows
		if input.KeyCode == Enum.KeyCode.Escape then
			if ClientState.ActiveWindow then
				UIController.CloseActiveWindow()
			end
		end
	end)
end

-- =============================================================================
-- HOTBAR HANDLING
-- =============================================================================

function UIController.OnHotbarSelect(slotIndex: number)
	local slotData = ClientState.HotbarData[slotIndex]
	if not slotData then return end
	
	if toolController and slotData.ToolName then
		toolController.EquipTool(slotData.ToolName)
	elseif toolController and not slotData.ToolName then
		toolController.UnequipAll()
	end
	
	if audioManager then
		audioManager.PlaySFX("UIClick")
	end
end

-- =============================================================================
-- WINDOW MANAGEMENT
-- =============================================================================

function UIController.CloseActiveWindow()
	local active = ClientState.ActiveWindow
	if active == "Shop" then
		ShopController.Hide()
	elseif active == "Inventory" then
		InventoryController.Hide()
	end
	ClientState.SetActiveWindow(nil)
end

function UIController.OpenShop()
	UIController.CloseActiveWindow()
	ShopController.Show()
end

function UIController.OpenInventory()
	UIController.CloseActiveWindow()
	InventoryController.Show()
end

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

function UIController.ShowNotification(message: string, notifType: string?, duration: number?)
	local parent = hudLayer or uiRoot or screenGui
	if parent then
		Notification.Show(parent, message, notifType or "info", duration or 3)
	end
end

-- =============================================================================
-- EXTERNAL REFERENCES
-- =============================================================================

function UIController.SetToolController(controller: any)
	toolController = controller
end

function UIController.SetAudioManager(manager: any)
	audioManager = manager
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

-- Get the currently selected seed for planting
function UIController.GetSelectedPlantType(): string?
	return InventoryController.GetSelectedSeed()
end

-- Get screen gui
function UIController.GetScreenGui(): ScreenGui?
	return screenGui
end

function UIController.GetRoot(): GuiObject?
	return uiRoot
end

return UIController
