-- AdminUI.client.luau
-- Simple admin command UI for testing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for admin command event
local adminCommandEvent = ReplicatedStorage:WaitForChild("AdminCommand", 10)
if not adminCommandEvent then
	warn("AdminCommand RemoteEvent not found")
	return
end

-- Create admin UI
local function createAdminUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.Parent = playerGui
	
	-- Command input frame
	local commandFrame = Instance.new("Frame")
	commandFrame.Name = "CommandFrame"
	commandFrame.Size = UDim2.new(0, 500, 0, 40)
	commandFrame.Position = UDim2.new(0.5, -250, 1, -60)
	commandFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	commandFrame.BorderSizePixel = 0
	commandFrame.Visible = false
	commandFrame.Parent = screenGui
	
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = commandFrame
	
	-- Command prefix label
	local prefixLabel = Instance.new("TextLabel")
	prefixLabel.Size = UDim2.new(0, 30, 1, 0)
	prefixLabel.BackgroundTransparency = 1
	prefixLabel.Text = "/"
	prefixLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	prefixLabel.Font = Enum.Font.SourceSansBold
	prefixLabel.TextSize = 20
	prefixLabel.Parent = commandFrame
	
	-- Command input box
	local commandBox = Instance.new("TextBox")
	commandBox.Name = "CommandBox"
	commandBox.Size = UDim2.new(1, -35, 1, 0)
	commandBox.Position = UDim2.new(0, 30, 0, 0)
	commandBox.BackgroundTransparency = 1
	commandBox.Text = ""
	commandBox.PlaceholderText = "Type admin command (e.g. addcoins 1000)"
	commandBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	commandBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	commandBox.Font = Enum.Font.SourceSans
	commandBox.TextSize = 18
	commandBox.TextXAlignment = Enum.TextXAlignment.Left
	commandBox.ClearTextOnFocus = false
	commandBox.Parent = commandFrame
	
	-- Output label
	local outputLabel = Instance.new("TextLabel")
	outputLabel.Name = "OutputLabel"
	outputLabel.Size = UDim2.new(0, 500, 0, 30)
	outputLabel.Position = UDim2.new(0.5, -250, 1, -105)
	outputLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	outputLabel.BorderSizePixel = 0
	outputLabel.Text = ""
	outputLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	outputLabel.Font = Enum.Font.SourceSans
	outputLabel.TextSize = 16
	outputLabel.Visible = false
	outputLabel.Parent = screenGui
	
	local outputCorner = Instance.new("UICorner")
	outputCorner.CornerRadius = UDim.new(0, 8)
	outputCorner.Parent = outputLabel
	
	return screenGui, commandFrame, commandBox, outputLabel
end

local adminGui, commandFrame, commandBox, outputLabel = createAdminUI()

-- Show output message
local function showOutput(success, message)
	outputLabel.Text = message
	outputLabel.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	outputLabel.Visible = true
	
	-- Auto-hide after 5 seconds
	task.delay(5, function()
		if outputLabel.Text == message then
			outputLabel.Visible = false
		end
	end)
end

-- Toggle command frame with / key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Slash then
		commandFrame.Visible = not commandFrame.Visible
		if commandFrame.Visible then
			commandBox:CaptureFocus()
		else
			commandBox:ReleaseFocus()
		end
	elseif input.KeyCode == Enum.KeyCode.Escape and commandFrame.Visible then
		commandFrame.Visible = false
		commandBox:ReleaseFocus()
	end
end)

-- Send command on enter
commandBox.FocusLost:Connect(function(enterPressed)
	if enterPressed and commandBox.Text ~= "" then
		local commandText = commandBox.Text
		commandBox.Text = ""
		
		-- Send to server
		adminCommandEvent:FireServer(commandText)
		
		commandFrame.Visible = false
	end
end)

-- Listen for responses
adminCommandEvent.OnClientEvent:Connect(function(success, message)
	showOutput(success, message)
	print("[Admin]", message)
end)

print("🔧 Admin UI Loaded - Press '/' to open command console")
