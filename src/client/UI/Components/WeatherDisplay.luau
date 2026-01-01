--!strict
-- WeatherDisplay.luau
-- HUD component showing current weather status

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent.Parent:WaitForChild("Styles"))
local ClientState = require(script.Parent.Parent:WaitForChild("ClientState"))

local WeatherDisplay = {}

local displayFrame: Frame? = nil
local weatherIcon: TextLabel? = nil
local weatherLabel: TextLabel? = nil

local WEATHER_ICONS = {
	Sunny = "☀️",
	Rainy = "🌧️",
	Stormy = "⛈️",
}

local WEATHER_COLORS = {
	Sunny = Color3.fromRGB(255, 220, 100),
	Rainy = Color3.fromRGB(100, 180, 220),
	Stormy = Color3.fromRGB(140, 120, 180),
}

-- Create the weather display
function WeatherDisplay.Create(parent: GuiObject): Frame
	local scale = Styles.GetDeviceScale()
	local topPadding = Styles.GetTopPadding()

	local frame = Instance.new("Frame")
	frame.Name = "WeatherFrame"
	frame.Size = UDim2.new(0, 140, 0, 50)
	frame.Position = UDim2.new(0, 210, 0, 20 + topPadding)
	frame.BackgroundColor3 = Theme.WoodPanel
	frame.BorderSizePixel = 0
	frame.ZIndex = 10

	if scale ~= 1 then
		local uiScale = Instance.new("UIScale")
		uiScale.Scale = scale
		uiScale.Parent = frame
	end
	
	Styles.AddCorner(frame, 12)
	Styles.AddStroke(frame, Theme.VineStroke, 2, 0.3)
	Styles.AddGradient(frame, Theme.WoodPanel, Theme.StonePanel, 90)
	Styles.AddShadow(frame)
	
	-- Weather icon
	local icon = Instance.new("TextLabel")
	icon.Name = "WeatherIcon"
	icon.Size = UDim2.new(0, 36, 0, 36)
	icon.Position = UDim2.new(0, 8, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = WEATHER_ICONS[ClientState.CurrentWeather] or "☀️"
	icon.Font = Theme.FontBody
	icon.TextScaled = true
	icon.ZIndex = 11
	icon.Parent = frame
	
	-- Weather text
	local label = Instance.new("TextLabel")
	label.Name = "WeatherLabel"
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 46, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = ClientState.CurrentWeather
	label.TextColor3 = WEATHER_COLORS[ClientState.CurrentWeather] or Theme.TextLight
	label.Font = Theme.FontSecondary
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
	label.Parent = frame
	
	frame.Parent = parent
	
	displayFrame = frame
	weatherIcon = icon
	weatherLabel = label
	
	-- Subscribe to weather changes
	ClientState.Subscribe("WeatherChanged", function()
		WeatherDisplay.Update()
	end)
	
	return frame
end

-- Update the display
function WeatherDisplay.Update()
	local weather = ClientState.CurrentWeather
	
	if weatherIcon then
		weatherIcon.Text = WEATHER_ICONS[weather] or "☀️"
	end
	
	if weatherLabel then
		weatherLabel.Text = weather
		
		local targetColor = WEATHER_COLORS[weather] or Theme.TextLight
		local tween = TweenService:Create(weatherLabel, TweenInfo.new(0.3), {
			TextColor3 = targetColor
		})
		tween:Play()
	end
end

-- Get the frame
function WeatherDisplay.GetFrame(): Frame?
	return displayFrame
end

return WeatherDisplay
