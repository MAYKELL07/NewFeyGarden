--!strict
-- CurrencyDisplay.luau
-- HUD component showing player's coin balance

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent.Parent:WaitForChild("Styles"))
local ClientState = require(script.Parent.Parent:WaitForChild("ClientState"))

local CurrencyDisplay = {}

local displayFrame: Frame? = nil
local coinLabel: TextLabel? = nil

-- Format large numbers with commas
local function formatNumber(num: number): string
	local formatted = tostring(math.floor(num))
	local result = ""
	local count = 0
	
	for i = #formatted, 1, -1 do
		result = formatted:sub(i, i) .. result
		count += 1
		if count % 3 == 0 and i > 1 then
			result = "," .. result
		end
	end
	
	return result
end

-- Create the currency display
function CurrencyDisplay.Create(parent: GuiObject): Frame
	local scale = Styles.GetDeviceScale()
	local topPadding = Styles.GetTopPadding()

	local frame = Instance.new("Frame")
	frame.Name = "CurrencyFrame"
	frame.Size = UDim2.new(0, 180, 0, 50)
	frame.Position = UDim2.new(0, 20, 0, 20 + topPadding)
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
	
	-- Coin icon
	local coinIcon = Instance.new("TextLabel")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0, 40, 0, 40)
	coinIcon.Position = UDim2.new(0, 8, 0.5, 0)
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "🪙"
	coinIcon.Font = Theme.FontBody
	coinIcon.TextScaled = true
	coinIcon.ZIndex = 11
	coinIcon.Parent = frame
	
	-- Coin amount
	local label = Instance.new("TextLabel")
	label.Name = "CoinLabel"
	label.Size = UDim2.new(1, -55, 1, 0)
	label.Position = UDim2.new(0, 50, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = formatNumber(ClientState.Coins)
	label.TextColor3 = Theme.GoldLeaf
	label.Font = Theme.FontPrimary
	label.TextSize = 24
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
	label.Parent = frame
	
	frame.Parent = parent
	
	displayFrame = frame
	coinLabel = label
	
	-- Subscribe to coin changes
	ClientState.Subscribe("CoinsChanged", function()
		CurrencyDisplay.Update()
	end)
	
	return frame
end

-- Update the display
function CurrencyDisplay.Update()
	if coinLabel then
		local newText = formatNumber(ClientState.Coins)
		if coinLabel.Text ~= newText then
			-- Animate the change
			coinLabel.Text = newText
			
			local originalSize = coinLabel.TextSize
			coinLabel.TextSize = originalSize * 1.2
			
			local tween = TweenService:Create(coinLabel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextSize = originalSize
			})
			tween:Play()
		end
	end
end

-- Get the frame
function CurrencyDisplay.GetFrame(): Frame?
	return displayFrame
end

return CurrencyDisplay
