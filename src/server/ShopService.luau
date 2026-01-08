-- ShopService.luau
-- Manages the seed shop with stock limits + timed restocks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

local ShopService = {}

-- Current shop inventory (shared across all players)
-- Format: { [seedType] = { Stock = number, MaxStock = number, Rarity = string } }
local currentShopInventory = {}
local lastRefreshTime = 0
local shopInitialized = false

-- RemoteEvents
local getShopInventoryEvent
local shopInventoryUpdateEvent

-- Get all plants of a specific rarity
local function getPlantsOfRarity(rarity)
	local plants = {}
	for plantType, plantRarity in pairs(Constants.PLANT_RARITIES) do
		if plantRarity == rarity then
			table.insert(plants, plantType)
		end
	end
	return plants
end

-- Shuffle an array (Fisher-Yates)
local function shuffleArray(arr)
	local shuffled = {}
	for i, v in ipairs(arr) do
		shuffled[i] = v
	end
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

-- Generate a new shop inventory (all seeds always visible; only stock is limited)
local function generateShopInventory()
	local newInventory = {}
	local shopConfig = Constants.SEED_SHOP_CONFIG

	-- Use PLANT_CONFIG as the source of truth for which seeds exist.
	-- This ensures any seed shown in shop also has pricing config.
	for plantType, _plantConfig in pairs(Constants.PLANT_CONFIG) do
		local rarity = Constants.PLANT_RARITIES[plantType] or Constants.RARITIES.COMMON
		local stockAmount = shopConfig.StockPerRarity[rarity] or 10
		newInventory[plantType] = {
			Stock = stockAmount,
			MaxStock = stockAmount,
			Rarity = rarity,
		}
	end
	
	return newInventory
end

-- Get time until next refresh
function ShopService.GetTimeUntilRefresh()
	local refreshInterval = Constants.SEED_SHOP_CONFIG.RefreshInterval
	local timeSinceRefresh = os.time() - lastRefreshTime
	return math.max(0, refreshInterval - timeSinceRefresh)
end

-- Check if shop needs refresh
local function shouldRefreshShop()
	local refreshInterval = Constants.SEED_SHOP_CONFIG.RefreshInterval
	return (os.time() - lastRefreshTime) >= refreshInterval
end

-- Refresh the shop inventory
function ShopService.RefreshShop()
	currentShopInventory = generateShopInventory()
	lastRefreshTime = os.time()
	
	-- Notify all players of the new inventory
	if shopInventoryUpdateEvent then
		for _, player in ipairs(Players:GetPlayers()) do
			shopInventoryUpdateEvent:FireClient(player, {
				inventory = currentShopInventory,
				refreshTime = lastRefreshTime,
				nextRefresh = ShopService.GetTimeUntilRefresh()
			})
		end
	end
end

-- Get current shop inventory
function ShopService.GetInventory()
	-- Check for refresh
	if shouldRefreshShop() then
		ShopService.RefreshShop()
	end
	
	return {
		inventory = currentShopInventory,
		refreshTime = lastRefreshTime,
		nextRefresh = ShopService.GetTimeUntilRefresh()
	}
end

-- Attempt to purchase a seed (returns success, message)
function ShopService.PurchaseSeed(player, seedType, quantity)
	quantity = quantity or 1
	
	-- Check if seed is in current inventory
	local seedData = currentShopInventory[seedType]
	if not seedData then
		return false, "Seed not available in shop"
	end
	
	-- Check stock
	if seedData.Stock < quantity then
		return false, "Not enough stock (only " .. seedData.Stock .. " left)"
	end
	
	-- Get seed config for price
	local plantConfig = Constants.PLANT_CONFIG[seedType]
	if not plantConfig then
		return false, "Invalid seed type"
	end
	
	local totalPrice = plantConfig.SeedPrice * quantity
	
	-- Check if player has enough coins (handled by EconomyService)
	-- This just handles stock reduction
	
	-- Reduce stock
	seedData.Stock = seedData.Stock - quantity
	
	-- If stock hits 0, optionally remove from shop
	if seedData.Stock <= 0 then
		-- Keep in inventory but mark as sold out
		seedData.Stock = 0
	end
	
	-- Notify all players of stock change
	if shopInventoryUpdateEvent then
		for _, p in ipairs(Players:GetPlayers()) do
			shopInventoryUpdateEvent:FireClient(p, {
				inventory = currentShopInventory,
				refreshTime = lastRefreshTime,
				nextRefresh = ShopService.GetTimeUntilRefresh()
			})
		end
	end
	
	return true, "Purchase successful"
end

-- Check if a seed is available (for EconomyService validation)
function ShopService.IsSeedAvailable(seedType, quantity)
	quantity = quantity or 1
	local seedData = currentShopInventory[seedType]
	if not seedData then
		return false, "Seed not in shop"
	end
	if seedData.Stock < quantity then
		return false, "Out of stock"
	end
	return true, "Available"
end

-- Initialize the service
function ShopService.Initialize()
	if shopInitialized then return end
	
	-- Create RemoteEvents
	getShopInventoryEvent = Instance.new("RemoteFunction")
	getShopInventoryEvent.Name = Constants.EVENTS.GET_SHOP_INVENTORY
	getShopInventoryEvent.Parent = ReplicatedStorage
	
	shopInventoryUpdateEvent = Instance.new("RemoteEvent")
	shopInventoryUpdateEvent.Name = Constants.EVENTS.SHOP_INVENTORY_UPDATE
	shopInventoryUpdateEvent.Parent = ReplicatedStorage
	
	-- Handle inventory requests
	getShopInventoryEvent.OnServerInvoke = function(player)
		return ShopService.GetInventory()
	end
	
	-- Initial shop generation
	ShopService.RefreshShop()
	
	-- Set up auto-refresh loop
	task.spawn(function()
		while true do
			task.wait(60) -- Check every minute
			if shouldRefreshShop() then
				ShopService.RefreshShop()
			end
		end
	end)
	
	shopInitialized = true
end

return ShopService
