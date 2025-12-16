--!strict
-- Hotbar.luau
-- HUD component for tool/action selection

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent.Parent:WaitForChild("Styles"))
local ClientState = require(script.Parent.Parent:WaitForChild("ClientState"))

local Hotbar = {}

local hotbarFrame: Frame? = nil
local slotButtons: {TextButton} = {}
local onSlotSelected: ((number) -> ())?

-- Create the hotbar
function Hotbar.Create(parent: GuiObject, onSelect: ((number) -> ())?): Frame
	onSlotSelected = onSelect
	
	local frame = Instance.new("Frame")
	frame.Name = "HotbarFrame"
	frame.Size = UDim2.new(0, 220, 0, 70)
	frame.Position = UDim2.new(0.5, 0, 1, -20)
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.BackgroundColor3 = Theme.WoodPanel
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.ZIndex = 10
	
	Styles.AddCorner(frame, 15)
	Styles.AddStroke(frame, Theme.VineStroke, 2, 0.3)
	Styles.AddShadow(frame)
	
	-- Layout for slots
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = frame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame
	
	-- Create slots
	for i, slotData in ClientState.HotbarData do
		local slot = Instance.new("TextButton")
		slot.Name = "Slot" .. tostring(i)
		slot.Size = UDim2.new(0, 56, 0, 56)
		slot.BackgroundColor3 = Theme.ForestDeep
		slot.BorderSizePixel = 0
		slot.Text = slotData.Icon
		slot.TextColor3 = Theme.TextLight
		slot.Font = Theme.FontBody
		slot.TextScaled = true
		slot.AutoButtonColor = false
		slot.LayoutOrder = i
		slot.ZIndex = 11
		slot.Parent = frame
		
		Styles.AddCorner(slot, 10)
		Styles.AddStroke(slot, Theme.VineStroke, 2, 0.4)
		
		-- Tooltip on hover
		local tooltip = Instance.new("TextLabel")
		tooltip.Name = "Tooltip"
		tooltip.Size = UDim2.new(0, 80, 0, 24)
		tooltip.Position = UDim2.new(0.5, 0, 0, -30)
		tooltip.AnchorPoint = Vector2.new(0.5, 1)
		tooltip.BackgroundColor3 = Theme.ForestDark
		tooltip.BackgroundTransparency = 0.1
		tooltip.Text = slotData.Name
		tooltip.TextColor3 = Theme.TextLight
		tooltip.Font = Theme.FontSecondary
		tooltip.TextSize = 14
		tooltip.Visible = false
		tooltip.ZIndex = 12
		tooltip.Parent = slot
		
		Styles.AddCorner(tooltip, 6)
		
		slot.MouseEnter:Connect(function()
			tooltip.Visible = true
			if i ~= ClientState.SelectedHotbarSlot then
				slot.BackgroundColor3 = Theme.StonePanel
			end
		end)
		
		slot.MouseLeave:Connect(function()
			tooltip.Visible = false
			if i ~= ClientState.SelectedHotbarSlot then
				slot.BackgroundColor3 = Theme.ForestDeep
			end
		end)
		
		slot.Activated:Connect(function()
			Hotbar.SelectSlot(i)
			if onSlotSelected then
				onSlotSelected(i)
			end
		end)
		
		table.insert(slotButtons, slot)
	end
	
	frame.Parent = parent
	hotbarFrame = frame
	
	-- Subscribe to hotbar changes
	ClientState.Subscribe("HotbarChanged", function()
		Hotbar.UpdateSelection()
	end)
	
	-- Initial selection
	Hotbar.UpdateSelection()
	
	return frame
end

-- Select a slot
function Hotbar.SelectSlot(slotIndex: number)
	ClientState.SelectHotbarSlot(slotIndex)
end

-- Update selection visuals
function Hotbar.UpdateSelection()
	local selected = ClientState.SelectedHotbarSlot
	
	for i, slot in slotButtons do
		local stroke = slot:FindFirstChildOfClass("UIStroke")
		
		if i == selected then
			slot.BackgroundColor3 = Theme.TealGem
			if stroke then
				stroke.Color = Theme.TealGlow
				stroke.Thickness = 3
			end
		else
			slot.BackgroundColor3 = Theme.ForestDeep
			if stroke then
				stroke.Color = Theme.VineStroke
				stroke.Thickness = 2
			end
		end
	end
end

-- Get the frame
function Hotbar.GetFrame(): Frame?
	return hotbarFrame
end

return Hotbar
