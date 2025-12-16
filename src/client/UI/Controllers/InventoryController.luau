--!strict
-- InventoryController.luau
-- Handles inventory window logic and seed selection for planting

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent.Parent:WaitForChild("Styles"))
local ClientState = require(script.Parent.Parent:WaitForChild("ClientState"))
local ItemCard = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ItemCard"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local InventoryController = {}

local inventoryWindow: Frame? = nil
local inventoryGrid: ScrollingFrame? = nil
local screenGui: ScreenGui? = nil

-- Currently selected seed for planting
local selectedSeedType: string? = nil
local onSeedSelected: ((string?) -> ())?

-- Get seed display info
local function getSeedInfo(seedType: string): (string, string, string)
	local config = Constants.PLANT_CONFIG[seedType]
	if config then
		return config.DisplayName or seedType, config.Icon or "🌱", config.Rarity or "Common"
	end
	return seedType, "🌱", "Common"
end

-- Create an inventory item card
local function createInventoryItem(seedType: string, count: number, parent: GuiObject)
	local displayName, icon, rarity = getSeedInfo(seedType)
	local isSelected = selectedSeedType == seedType
	
	local card = ItemCard.CreateGridItem({
		Name = displayName,
		Icon = icon,
		Count = count,
		Rarity = rarity,
		OnClick = function()
			InventoryController.SelectSeed(seedType)
		end,
	}, parent)
	
	-- Highlight if selected
	if isSelected then
		card.BackgroundColor3 = Theme.TealGem
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = Theme.TealGlow
			stroke.Thickness = 3
		end
	end
	
	return card
end

-- Refresh the inventory display
function InventoryController.RefreshInventory()
	if not inventoryGrid then return end
	
	-- Clear existing items
	for _, child in inventoryGrid:GetChildren() do
		if child:IsA("Frame") and child.Name:find("GridItem") then
			child:Destroy()
		end
	end
	
	-- Add seed items
	for seedType, count in ClientState.Inventory.Seeds do
		if count > 0 then
			createInventoryItem(seedType, count, inventoryGrid)
		end
	end
end

-- Select a seed for planting
function InventoryController.SelectSeed(seedType: string?)
	selectedSeedType = seedType
	InventoryController.RefreshInventory()
	
	if onSeedSelected then
		onSeedSelected(seedType)
	end
end

-- Get the currently selected seed
function InventoryController.GetSelectedSeed(): string?
	return selectedSeedType
end

-- Set the callback for seed selection
function InventoryController.SetOnSeedSelected(callback: (string?) -> ())
	onSeedSelected = callback
end

-- Initialize the inventory controller
function InventoryController.Initialize(gui: ScreenGui)
	screenGui = gui
	
	-- Create inventory window
	inventoryWindow = Window.Create({
		Name = "InventoryWindow",
		Title = "🎒 Inventory",
		Size = UDim2.new(0, 380, 0, 450),
		OnClose = function()
			ClientState.SetActiveWindow(nil)
		end,
	}, gui)
	
	-- Create scrolling grid for items
	local content = Window.GetContent(inventoryWindow)
	if content then
		-- Tab bar for Seeds/Fruits/Eggs
		local tabBar = Instance.new("Frame")
		tabBar.Name = "TabBar"
		tabBar.Size = UDim2.new(1, 0, 0, 40)
		tabBar.Position = UDim2.new(0, 0, 0, 0)
		tabBar.BackgroundTransparency = 1
		tabBar.Parent = content
		
		local tabLayout = Instance.new("UIListLayout")
		tabLayout.FillDirection = Enum.FillDirection.Horizontal
		tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		tabLayout.Padding = UDim.new(0, 10)
		tabLayout.Parent = tabBar
		
		-- Seed tab (active by default)
		local seedTab = Instance.new("TextButton")
		seedTab.Name = "SeedsTab"
		seedTab.Size = UDim2.new(0, 100, 0, 36)
		seedTab.BackgroundColor3 = Theme.TealGem
		seedTab.BorderSizePixel = 0
		seedTab.Text = "🌱 Seeds"
		seedTab.TextColor3 = Theme.TextLight
		seedTab.Font = Theme.FontSecondary
		seedTab.TextSize = 16
		seedTab.Parent = tabBar
		
		Styles.AddCorner(seedTab, 8)
		
		-- Scrolling grid
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Name = "InventoryGrid"
		scrollFrame.Size = UDim2.new(1, 0, 1, -50)
		scrollFrame.Position = UDim2.new(0, 0, 0, 45)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.BorderSizePixel = 0
		scrollFrame.ScrollBarThickness = 6
		scrollFrame.ScrollBarImageColor3 = Theme.TealGem
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scrollFrame.Parent = content
		
		Styles.AddGridLayout(scrollFrame, UDim2.new(0, 85, 0, 85), UDim2.new(0, 8, 0, 8))
		Styles.AddPadding(scrollFrame, 5)
		
		inventoryGrid = scrollFrame
	end
	
	-- Subscribe to inventory updates
	ClientState.Subscribe("InventoryChanged", function()
		InventoryController.RefreshInventory()
	end)
end

-- Show the inventory window
function InventoryController.Show()
	if inventoryWindow then
		Window.Show(inventoryWindow)
		ClientState.SetActiveWindow("Inventory")
		InventoryController.RefreshInventory()
	end
end

-- Hide the inventory window
function InventoryController.Hide()
	if inventoryWindow then
		Window.Hide(inventoryWindow)
		if ClientState.ActiveWindow == "Inventory" then
			ClientState.SetActiveWindow(nil)
		end
	end
end

-- Toggle the inventory window
function InventoryController.Toggle()
	if inventoryWindow then
		if inventoryWindow.Visible then
			InventoryController.Hide()
		else
			InventoryController.Show()
		end
	end
end

-- Get the window
function InventoryController.GetWindow(): Frame?
	return inventoryWindow
end

return InventoryController
