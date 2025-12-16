--!strict
-- UI/init.luau
-- Entry point for the modular UI system
-- Exports all public UI modules for easy access

local UI = {}

-- Core modules
UI.Theme = require(script:WaitForChild("Theme"))
UI.Styles = require(script:WaitForChild("Styles"))
UI.ClientState = require(script:WaitForChild("ClientState"))

-- Components
UI.Components = {
	ItemCard = require(script:WaitForChild("Components"):WaitForChild("ItemCard")),
	Notification = require(script:WaitForChild("Components"):WaitForChild("Notification")),
	Window = require(script:WaitForChild("Components"):WaitForChild("Window")),
	CurrencyDisplay = require(script:WaitForChild("Components"):WaitForChild("CurrencyDisplay")),
	WeatherDisplay = require(script:WaitForChild("Components"):WaitForChild("WeatherDisplay")),
	Hotbar = require(script:WaitForChild("Components"):WaitForChild("Hotbar")),
}

-- Controllers
UI.Controllers = {
	UIController = require(script:WaitForChild("Controllers"):WaitForChild("UIController")),
	ShopController = require(script:WaitForChild("Controllers"):WaitForChild("ShopController")),
	InventoryController = require(script:WaitForChild("Controllers"):WaitForChild("InventoryController")),
}

-- Quick access to main controller
UI.Controller = UI.Controllers.UIController

-- Initialize the entire UI system
function UI.Initialize()
	UI.Controller.Initialize()
end

-- Show notification (convenience function)
function UI.Notify(message: string, notifType: string?, duration: number?)
	UI.Controller.ShowNotification(message, notifType :: any, duration)
end

return UI
