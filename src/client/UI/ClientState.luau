--!strict
-- ClientState.luau
-- Centralized client-side state management
-- All UI controllers read from and write to this module

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

export type InventoryData = {
	Seeds: {[string]: number},
	Pets: {[string]: number},
	Fruits: {[string]: number},
	Eggs: {[string]: number},
	EquippedPets: {string},
	GardenPets: {string},
}

export type ShopItem = {
	SeedType: string,
	Stock: number,
	MaxStock: number,
	Rarity: string,
}

export type HotbarSlot = {
	Name: string,
	Icon: string,
	ToolName: string?,
}

local ClientState = {}

-- =============================================================================
-- STATE DATA
-- =============================================================================

-- Player Resources
ClientState.Coins = 0

-- Inventory
ClientState.Inventory = {
	Seeds = {},
	Pets = {},
	Fruits = {},
	Eggs = {},
	EquippedPets = {},
	GardenPets = {},
}

-- Current Weather
ClientState.CurrentWeather = Constants.WEATHER_TYPES.SUNNY

-- Shop Data
ClientState.ShopInventory = {}

-- Hotbar
ClientState.HotbarData = {
	{Name = "Move", Icon = "🚶", ToolName = nil},
	{Name = "Water", Icon = "💧", ToolName = "WateringCan"},
	{Name = "Shovel", Icon = "⛏️", ToolName = "Shovel"},
}

ClientState.SelectedHotbarSlot = 1

-- Trading State
ClientState.TradingActive = false
ClientState.TradingPartner = nil
ClientState.TradeOffer = {
	Seeds = {},
	Pets = {},
	Fruits = {},
	Coins = 0,
}

-- UI State
ClientState.ActiveWindow = nil -- "Shop", "Inventory", "Pets", "Sell", "Trading", etc.

-- =============================================================================
-- INTERNAL REMOTE HOOKS
-- =============================================================================

local weatherConnection: RBXScriptConnection? = nil

local function tryConnectWeatherChanged()
	if weatherConnection then
		return
	end

	local function findWeatherEvent(): RemoteEvent?
		local direct = ReplicatedStorage:FindFirstChild(Constants.EVENTS.WEATHER_CHANGED)
		if direct and direct:IsA("RemoteEvent") then
			return direct
		end

		local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
		if eventsFolder then
			local nested = eventsFolder:FindFirstChild(Constants.EVENTS.WEATHER_CHANGED)
			if nested and nested:IsA("RemoteEvent") then
				return nested
			end
		end

		return nil
	end

	local weatherEvent = findWeatherEvent()
	if not weatherEvent then
		-- The server may not have created it yet; wait briefly.
		weatherEvent = ReplicatedStorage:WaitForChild(Constants.EVENTS.WEATHER_CHANGED, 15) :: RemoteEvent?
		if not (weatherEvent and weatherEvent:IsA("RemoteEvent")) then
			local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
			if eventsFolder then
				local nested = eventsFolder:WaitForChild(Constants.EVENTS.WEATHER_CHANGED, 5) :: RemoteEvent?
				if nested and nested:IsA("RemoteEvent") then
					weatherEvent = nested
				end
			end
		end
	end

	if weatherEvent and weatherEvent:IsA("RemoteEvent") then
		weatherConnection = weatherEvent.OnClientEvent:Connect(function(weather: string)
			ClientState.SetWeather(weather)
		end)
	end
end

-- =============================================================================
-- CALLBACKS (UI components can subscribe to state changes)
-- =============================================================================

type Callback = () -> ()

local callbacks: {[string]: {Callback}} = {
	CoinsChanged = {},
	InventoryChanged = {},
	WeatherChanged = {},
	ShopChanged = {},
	HotbarChanged = {},
	WindowChanged = {},
}

function ClientState.Subscribe(event: string, callback: Callback)
	if callbacks[event] then
		table.insert(callbacks[event], callback)
	end
end

local function notifySubscribers(event: string)
	if callbacks[event] then
		for _, callback in callbacks[event] do
			task.spawn(callback)
		end
	end
end

-- =============================================================================
-- SETTERS (Update state and notify subscribers)
-- =============================================================================

function ClientState.SetCoins(amount: number)
	ClientState.Coins = amount
	notifySubscribers("CoinsChanged")
end

function ClientState.SetInventory(inventory: InventoryData)
	ClientState.Inventory = inventory
	notifySubscribers("InventoryChanged")
end

function ClientState.UpdateSeeds(seeds: {[string]: number})
	ClientState.Inventory.Seeds = seeds
	notifySubscribers("InventoryChanged")
end

function ClientState.UpdatePets(pets: {[string]: number})
	ClientState.Inventory.Pets = pets
	notifySubscribers("InventoryChanged")
end

function ClientState.UpdateFruits(fruits: {[string]: number})
	ClientState.Inventory.Fruits = fruits
	notifySubscribers("InventoryChanged")
end

function ClientState.UpdateEggs(eggs: {[string]: number})
	ClientState.Inventory.Eggs = eggs
	notifySubscribers("InventoryChanged")
end

function ClientState.UpdateEquippedPets(pets: {string})
	ClientState.Inventory.EquippedPets = pets
	notifySubscribers("InventoryChanged")
end

function ClientState.UpdateGardenPets(pets: {string})
	ClientState.Inventory.GardenPets = pets
	notifySubscribers("InventoryChanged")
end

function ClientState.SetWeather(weather: string)
	ClientState.CurrentWeather = weather
	notifySubscribers("WeatherChanged")
end

function ClientState.SetShopInventory(shop: {[string]: ShopItem})
	ClientState.ShopInventory = shop
	notifySubscribers("ShopChanged")
end

function ClientState.UpdateShopStock(seedType: string, newStock: number)
	if ClientState.ShopInventory[seedType] then
		ClientState.ShopInventory[seedType].Stock = newStock
		notifySubscribers("ShopChanged")
	end
end

function ClientState.SelectHotbarSlot(slot: number)
	ClientState.SelectedHotbarSlot = slot
	notifySubscribers("HotbarChanged")
end

function ClientState.SetActiveWindow(window: string?)
	ClientState.ActiveWindow = window
	notifySubscribers("WindowChanged")
end

-- =============================================================================
-- GETTERS (Convenience functions)
-- =============================================================================

function ClientState.GetSeedCount(seedType: string): number
	return ClientState.Inventory.Seeds[seedType] or 0
end

function ClientState.GetPetCount(petType: string): number
	return ClientState.Inventory.Pets[petType] or 0
end

function ClientState.GetFruitCount(fruitType: string): number
	return ClientState.Inventory.Fruits[fruitType] or 0
end

function ClientState.GetEggCount(eggType: string): number
	return ClientState.Inventory.Eggs[eggType] or 0
end

function ClientState.IsPetEquipped(petType: string): boolean
	for _, pet in ClientState.Inventory.EquippedPets do
		if pet == petType then
			return true
		end
	end
	return false
end

function ClientState.IsPetInGarden(petType: string): boolean
	for _, pet in ClientState.Inventory.GardenPets do
		if pet == petType then
			return true
		end
	end
	return false
end

function ClientState.GetEquippedPetCount(): number
	return #ClientState.Inventory.EquippedPets
end

function ClientState.GetGardenPetCount(): number
	return #ClientState.Inventory.GardenPets
end

function ClientState.HasEnoughCoins(amount: number): boolean
	return ClientState.Coins >= amount
end

task.defer(tryConnectWeatherChanged)

return ClientState
