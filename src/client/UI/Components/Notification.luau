--!strict
-- Notification.luau
-- Notification toast component for feedback messages

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent.Parent:WaitForChild("Styles"))

local Notification = {}

export type NotificationType = "info" | "success" | "warning" | "error"

local activeNotifications: {Frame} = {}
local MAX_NOTIFICATIONS = 5

local function getNotificationColor(notifType: NotificationType): (Color3, Color3)
	if notifType == "success" then
		return Color3.fromRGB(60, 180, 100), Color3.fromRGB(80, 200, 120)
	elseif notifType == "warning" then
		return Theme.GoldLeaf, Theme.GoldAccent
	elseif notifType == "error" then
		return Color3.fromRGB(200, 80, 80), Color3.fromRGB(220, 100, 100)
	else -- info
		return Theme.TealGem, Theme.TealGlow
	end
end

-- Show a notification toast
function Notification.Show(screenGui: ScreenGui, message: string, notifType: NotificationType?, duration: number?)
	local container = screenGui:FindFirstChild("NotificationContainer")
	if not container then
		container = Instance.new("Frame")
		container.Name = "NotificationContainer"
		container.Size = UDim2.new(0, 320, 1, 0)
		container.Position = UDim2.new(1, -20, 0, 100)
		container.AnchorPoint = Vector2.new(1, 0)
		container.BackgroundTransparency = 1
		container.Parent = screenGui
		
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = container
	end
	
	-- Remove oldest if at max
	if #activeNotifications >= MAX_NOTIFICATIONS then
		local oldest = table.remove(activeNotifications, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end
	
	local color1, color2 = getNotificationColor(notifType or "info")
	
	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.Size = UDim2.new(1, 0, 0, 50)
	notif.BackgroundColor3 = color1
	notif.BackgroundTransparency = 0.1
	notif.BorderSizePixel = 0
	notif.LayoutOrder = #activeNotifications + 1
	
	Styles.AddCorner(notif, 10)
	Styles.AddStroke(notif, color2, 2, 0.3)
	Styles.AddGradient(notif, color1, color2, 0)
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Message"
	textLabel.Size = UDim2.new(1, -20, 1, 0)
	textLabel.Position = UDim2.new(0, 10, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextColor3 = Theme.TextLight
	textLabel.Font = Theme.FontSecondary
	textLabel.TextSize = 16
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = notif
	
	-- Start offscreen
	notif.Position = UDim2.new(1.5, 0, 0, 0)
	notif.Parent = container
	
	table.insert(activeNotifications, notif)
	
	-- Slide in
	local slideIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0)
	})
	slideIn:Play()
	
	-- Auto-dismiss after duration
	local displayTime = duration or 3
	task.delay(displayTime, function()
		if notif.Parent then
			local slideOut = TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1.5, 0, 0, 0),
				BackgroundTransparency = 1
			})
			slideOut:Play()
			slideOut.Completed:Connect(function()
				local index = table.find(activeNotifications, notif)
				if index then
					table.remove(activeNotifications, index)
				end
				notif:Destroy()
			end)
		end
	end)
	
	return notif
end

-- Clear all notifications
function Notification.ClearAll(screenGui: ScreenGui)
	local container = screenGui:FindFirstChild("NotificationContainer")
	if container then
		for _, child in container:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end
	activeNotifications = {}
end

return Notification
