--!strict
-- UIController.luau
-- Main UI controller that initializes all UI components and handles global state

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- UI Modules
local Theme = require(script.Parent:WaitForChild("Theme"))
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
	
	-- Get remote events
	local events = ReplicatedStorage:FindFirstChild("Events")
	if events then
		updateCurrency = events:FindFirstChild("UpdateCurrency") :: RemoteEvent?
		updateInventory = events:FindFirstChild("UpdateInventory") :: RemoteEvent?
		weatherChanged = events:FindFirstChild("WeatherChanged") :: RemoteEvent?
	end
	
	-- Initialize HUD components
	CurrencyDisplay.Create(screenGui)
	WeatherDisplay.Create(screenGui)
	Hotbar.Create(screenGui, function(slotIndex)
		UIController.OnHotbarSelect(slotIndex)
	end)
	
	-- Initialize controllers
	ShopController.Initialize(screenGui)
	InventoryController.Initialize(screenGui)
	
	-- Set up seed selection callback
	InventoryController.SetOnSeedSelected(function(seedType)
		-- Could trigger planting mode here
	end)
	
	-- Connect remote events
	UIController.ConnectRemotes()
	
	-- Set up keyboard shortcuts
	UIController.SetupKeyboardShortcuts()
	
	initialized = true
	
	Notification.Show(screenGui, "Welcome to Fey Garden! 🌿", "info", 3)
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
	if screenGui then
		Notification.Show(screenGui, message, notifType or "info", duration or 3)
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

return UIController
