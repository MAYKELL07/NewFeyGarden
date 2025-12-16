--!strict
-- ShopController.luau
-- Handles shop window logic and server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent.Parent:WaitForChild("Styles"))
local ClientState = require(script.Parent.Parent:WaitForChild("ClientState"))
local ItemCard = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ItemCard"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local Notification = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Notification"))

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local ShopController = {}

local shopWindow: Frame? = nil
local shopGrid: ScrollingFrame? = nil
local screenGui: ScreenGui? = nil

-- Remote events (initialized on setup)
local buySeedEvent: RemoteEvent? = nil
local getShopInventory: RemoteFunction? = nil
local shopInventoryUpdate: RemoteEvent? = nil

-- Get seed display info
local function getSeedInfo(seedType: string): (string, string, number, string)
	local config = Constants.PLANT_CONFIG[seedType]
	if config then
		return config.DisplayName or seedType, config.Icon or "🌱", config.SeedPrice or 10, config.Rarity or "Common"
	end
	return seedType, "🌱", 10, "Common"
end

-- Create a shop item card
local function createShopItem(seedType: string, shopData: ClientState.ShopItem, parent: GuiObject)
	local displayName, icon, price, rarity = getSeedInfo(seedType)
	local stock = shopData.Stock
	local maxStock = shopData.MaxStock
	
	local canAfford = ClientState.HasEnoughCoins(price)
	local inStock = stock > 0
	
	local card = ItemCard.Create({
		Name = displayName,
		Icon = icon,
		Price = price,
		Rarity = rarity,
		Count = stock,
		ButtonText = inStock and (canAfford and "Buy" or "💰") or "Sold",
		ButtonColor = inStock and (canAfford and Theme.TealGem or Theme.WarningGold) or Theme.StonePanel,
		Disabled = not inStock or not canAfford,
		OnClick = function()
			if inStock and canAfford and buySeedEvent then
				-- Optimistic update
				ClientState.UpdateShopStock(seedType, stock - 1)
				buySeedEvent:FireServer(seedType)
				
				if screenGui then
					Notification.Show(screenGui, "Purchased " .. displayName .. "!", "success", 2)
				end
			elseif not canAfford then
				if screenGui then
					Notification.Show(screenGui, "Not enough coins!", "warning", 2)
				end
			end
		end,
	}, parent)
	
	-- Add stock indicator
	local stockLabel = Instance.new("TextLabel")
	stockLabel.Name = "StockLabel"
	stockLabel.Size = UDim2.new(0, 60, 0, 20)
	stockLabel.Position = UDim2.new(1, -160, 0, 10)
	stockLabel.BackgroundTransparency = 1
	stockLabel.Text = stock .. "/" .. maxStock
	stockLabel.TextColor3 = stock > 0 and Theme.TextMoss or Color3.fromRGB(200, 100, 100)
	stockLabel.Font = Theme.FontSecondary
	stockLabel.TextSize = 14
	stockLabel.TextXAlignment = Enum.TextXAlignment.Right
	stockLabel.Parent = card
	
	return card
end

-- Refresh the shop display
function ShopController.RefreshShop()
	if not shopGrid then return end
	
	-- Clear existing items
	for _, child in shopGrid:GetChildren() do
		if child:IsA("Frame") and child.Name:find("ItemCard") then
			child:Destroy()
		end
	end
	
	-- Add items from shop inventory
	for seedType, shopData in ClientState.ShopInventory do
		createShopItem(seedType, shopData, shopGrid)
	end
end

-- Initialize the shop controller
function ShopController.Initialize(gui: ScreenGui)
	screenGui = gui
	
	-- Get remote references
	local events = ReplicatedStorage:FindFirstChild("Events")
	if events then
		buySeedEvent = events:FindFirstChild("BuySeed") :: RemoteEvent?
		getShopInventory = events:FindFirstChild("GetShopInventory") :: RemoteFunction?
		shopInventoryUpdate = events:FindFirstChild("ShopInventoryUpdate") :: RemoteEvent?
	end
	
	-- Create shop window
	shopWindow = Window.Create({
		Name = "ShopWindow",
		Title = "🌱 Seed Shop",
		Size = UDim2.new(0, 420, 0, 500),
		OnClose = function()
			ClientState.SetActiveWindow(nil)
		end,
	}, gui)
	
	-- Create scrolling grid for items
	local content = Window.GetContent(shopWindow)
	if content then
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Name = "ShopGrid"
		scrollFrame.Size = UDim2.new(1, 0, 1, 0)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.BorderSizePixel = 0
		scrollFrame.ScrollBarThickness = 6
		scrollFrame.ScrollBarImageColor3 = Theme.TealGem
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scrollFrame.Parent = content
		
		Styles.AddListLayout(scrollFrame, 8)
		Styles.AddPadding(scrollFrame, 5)
		
		shopGrid = scrollFrame
	end
	
	-- Subscribe to shop updates
	ClientState.Subscribe("ShopChanged", function()
		ShopController.RefreshShop()
	end)
	
	-- Listen for server shop updates
	if shopInventoryUpdate then
		shopInventoryUpdate.OnClientEvent:Connect(function(inventory)
			-- Convert array to map if needed
			local shopMap: {[string]: ClientState.ShopItem} = {}
			if typeof(inventory) == "table" then
				for key, value in inventory do
					if typeof(key) == "string" then
						shopMap[key] = value
					elseif typeof(value) == "table" and value.SeedType then
						shopMap[value.SeedType] = value
					end
				end
			end
			ClientState.SetShopInventory(shopMap)
		end)
	end
	
	-- Request initial shop inventory
	if getShopInventory then
		task.spawn(function()
			local success, inventory = pcall(function()
				return getShopInventory:InvokeServer()
			end)
			
			if success and inventory then
				local shopMap: {[string]: ClientState.ShopItem} = {}
				for key, value in inventory do
					if typeof(key) == "string" then
						shopMap[key] = value
					elseif typeof(value) == "table" and value.SeedType then
						shopMap[value.SeedType] = value
					end
				end
				ClientState.SetShopInventory(shopMap)
			end
		end)
	end
end

-- Show the shop window
function ShopController.Show()
	if shopWindow then
		Window.Show(shopWindow)
		ClientState.SetActiveWindow("Shop")
		ShopController.RefreshShop()
	end
end

-- Hide the shop window
function ShopController.Hide()
	if shopWindow then
		Window.Hide(shopWindow)
		if ClientState.ActiveWindow == "Shop" then
			ClientState.SetActiveWindow(nil)
		end
	end
end

-- Toggle the shop window
function ShopController.Toggle()
	if shopWindow then
		if shopWindow.Visible then
			ShopController.Hide()
		else
			ShopController.Show()
		end
	end
end

-- Get the window
function ShopController.GetWindow(): Frame?
	return shopWindow
end

return ShopController
