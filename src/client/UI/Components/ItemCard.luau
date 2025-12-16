--!strict
-- ItemCard.luau
-- Reusable item card component for Shop, Inventory, and Sell windows
-- Supports: Icon, Name, Count, Price, Action Button

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local Styles = require(script.Parent.Parent:WaitForChild("Styles"))

local ItemCard = {}

export type ItemCardConfig = {
	Name: string,
	Icon: string?,
	IconImage: string?,
	Count: number?,
	Price: number?,
	PriceLabel: string?, -- "Buy" | "Sell" | "Stock"
	Rarity: string?,
	ButtonText: string?,
	ButtonColor: Color3?,
	OnClick: (() -> ())?,
	Disabled: boolean?,
}

-- Get rarity color
local function getRarityColor(rarity: string?): Color3
	if not rarity then return Theme.TextLight end
	
	local colors = {
		Common = Theme.RarityCommon,
		Uncommon = Theme.RarityUncommon,
		Rare = Theme.RarityRare,
		Epic = Theme.RarityEpic,
		Legendary = Theme.RarityLegendary,
	}
	
	return colors[rarity] or Theme.TextLight
end

-- Create an item card
function ItemCard.Create(config: ItemCardConfig, parent: GuiObject?): Frame
	local card = Instance.new("Frame")
	card.Name = "ItemCard_" .. config.Name
	card.Size = UDim2.new(1, 0, 0, 90)
	card.BackgroundColor3 = Theme.WoodPanel
	card.BorderSizePixel = 0
	
	Styles.AddCorner(card, 12)
	Styles.AddStroke(card, Theme.VineStroke, 2, 0.3)
	Styles.AddGradient(card, Theme.WoodPanel, Theme.StonePanel, 90)
	
	-- Rarity glow if legendary/epic
	if config.Rarity == "Legendary" or config.Rarity == "Epic" then
		local glow = Styles.AddGlow(card, getRarityColor(config.Rarity))
		glow.Thickness = 2
		glow.Transparency = 0.4
	end
	
	-- Icon container
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 70, 0, 70)
	iconFrame.Position = UDim2.new(0, 10, 0.5, 0)
	iconFrame.AnchorPoint = Vector2.new(0, 0.5)
	iconFrame.BackgroundColor3 = Theme.ForestDeep
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = card
	
	Styles.AddCorner(iconFrame, 8)
	Styles.AddStroke(iconFrame, getRarityColor(config.Rarity), 2, 0.4)
	
	-- Icon (emoji or image)
	if config.IconImage then
		local iconImage = Instance.new("ImageLabel")
		iconImage.Name = "IconImage"
		iconImage.Size = UDim2.new(0.9, 0, 0.9, 0)
		iconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
		iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
		iconImage.BackgroundTransparency = 1
		iconImage.Image = config.IconImage
		iconImage.ScaleType = Enum.ScaleType.Fit
		iconImage.Parent = iconFrame
	else
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = config.Icon or "🌱"
		iconLabel.TextColor3 = Theme.TextLight
		iconLabel.Font = Theme.FontBody
		iconLabel.TextScaled = true
		iconLabel.Parent = iconFrame
	end
	
	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 120, 0, 24)
	nameLabel.Position = UDim2.new(0, 90, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = config.Name
	nameLabel.TextColor3 = getRarityColor(config.Rarity)
	nameLabel.Font = Theme.FontPrimary
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card
	
	-- Count label (if provided)
	if config.Count then
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(0, 80, 0, 20)
		countLabel.Position = UDim2.new(0, 90, 0, 38)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = "x" .. tostring(config.Count)
		countLabel.TextColor3 = Theme.TextMoss
		countLabel.Font = Theme.FontSecondary
		countLabel.TextSize = 16
		countLabel.TextXAlignment = Enum.TextXAlignment.Left
		countLabel.Parent = card
	end
	
	-- Price/Info label (if provided)
	if config.Price then
		local priceFrame = Instance.new("Frame")
		priceFrame.Name = "PriceFrame"
		priceFrame.Size = UDim2.new(0, 80, 0, 24)
		priceFrame.Position = UDim2.new(0, 90, 0, 58)
		priceFrame.BackgroundTransparency = 1
		priceFrame.Parent = card
		
		local coinIcon = Instance.new("TextLabel")
		coinIcon.Name = "CoinIcon"
		coinIcon.Size = UDim2.new(0, 20, 1, 0)
		coinIcon.BackgroundTransparency = 1
		coinIcon.Text = "🪙"
		coinIcon.Font = Theme.FontBody
		coinIcon.TextScaled = true
		coinIcon.Parent = priceFrame
		
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(1, -24, 1, 0)
		priceLabel.Position = UDim2.new(0, 24, 0, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = tostring(config.Price)
		priceLabel.TextColor3 = Theme.GoldLeaf
		priceLabel.Font = Theme.FontSecondary
		priceLabel.TextSize = 16
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = priceFrame
	end
	
	-- Action button (if callback provided)
	if config.ButtonText and config.OnClick then
		local button = Instance.new("TextButton")
		button.Name = "ActionButton"
		button.Size = UDim2.new(0, 80, 0, 36)
		button.Position = UDim2.new(1, -90, 0.5, 0)
		button.AnchorPoint = Vector2.new(0, 0.5)
		button.BackgroundColor3 = config.ButtonColor or Theme.TealGem
		button.BorderSizePixel = 0
		button.Text = config.ButtonText
		button.TextColor3 = Theme.TextLight
		button.Font = Theme.FontPrimary
		button.TextSize = 16
		button.AutoButtonColor = false
		button.Parent = card
		
		Styles.AddCorner(button, 8)
		Styles.AddStroke(button, Theme.TealGlow, 1, 0.4)
		
		if config.Disabled then
			button.BackgroundColor3 = Theme.StonePanel
			button.TextColor3 = Theme.TextMoss
		else
			-- Hover effects
			button.MouseEnter:Connect(function()
				button.BackgroundColor3 = Theme.TealGlow
			end)
			
			button.MouseLeave:Connect(function()
				button.BackgroundColor3 = config.ButtonColor or Theme.TealGem
			end)
			
			button.Activated:Connect(function()
				if config.OnClick then
					config.OnClick()
				end
			end)
		end
	end
	
	if parent then
		card.Parent = parent
	end
	
	return card
end

-- Create a compact grid item (for inventory slots)
function ItemCard.CreateGridItem(config: ItemCardConfig, parent: GuiObject?): Frame
	local card = Instance.new("Frame")
	card.Name = "GridItem_" .. config.Name
	card.Size = UDim2.new(0, 90, 0, 90)
	card.BackgroundColor3 = Theme.ForestDeep
	card.BorderSizePixel = 0
	
	Styles.AddCorner(card, 10)
	Styles.AddStroke(card, getRarityColor(config.Rarity), 2, 0.4)
	Styles.AddAspectRatio(card, 1)
	
	-- Icon
	if config.IconImage then
		local iconImage = Instance.new("ImageLabel")
		iconImage.Name = "IconImage"
		iconImage.Size = UDim2.new(0.7, 0, 0.7, 0)
		iconImage.Position = UDim2.new(0.5, 0, 0.4, 0)
		iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
		iconImage.BackgroundTransparency = 1
		iconImage.Image = config.IconImage
		iconImage.ScaleType = Enum.ScaleType.Fit
		iconImage.Parent = card
	else
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.new(0.8, 0, 0.6, 0)
		iconLabel.Position = UDim2.new(0.5, 0, 0.35, 0)
		iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = config.Icon or "🌱"
		iconLabel.TextColor3 = Theme.TextLight
		iconLabel.Font = Theme.FontBody
		iconLabel.TextScaled = true
		iconLabel.Parent = card
	end
	
	-- Count badge
	if config.Count and config.Count > 0 then
		local countBadge = Instance.new("Frame")
		countBadge.Name = "CountBadge"
		countBadge.Size = UDim2.new(0, 28, 0, 20)
		countBadge.Position = UDim2.new(1, -4, 0, 4)
		countBadge.AnchorPoint = Vector2.new(1, 0)
		countBadge.BackgroundColor3 = Theme.TealGem
		countBadge.BorderSizePixel = 0
		countBadge.Parent = card
		
		Styles.AddCorner(countBadge, 6)
		
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(1, 0, 1, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = tostring(config.Count)
		countLabel.TextColor3 = Theme.TextLight
		countLabel.Font = Theme.FontPrimary
		countLabel.TextSize = 14
		countLabel.Parent = countBadge
	end
	
	-- Name tooltip on bottom
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -4, 0, 16)
	nameLabel.Position = UDim2.new(0.5, 0, 1, -4)
	nameLabel.AnchorPoint = Vector2.new(0.5, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = config.Name
	nameLabel.TextColor3 = Theme.TextMoss
	nameLabel.Font = Theme.FontSecondary
	nameLabel.TextSize = 11
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card
	
	-- Click handler
	if config.OnClick then
		local clickButton = Instance.new("TextButton")
		clickButton.Name = "ClickArea"
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.Parent = card
		
		clickButton.Activated:Connect(function()
			if config.OnClick and not config.Disabled then
				config.OnClick()
			end
		end)
		
		-- Hover effect
		clickButton.MouseEnter:Connect(function()
			card.BackgroundColor3 = Theme.StonePanel
		end)
		
		clickButton.MouseLeave:Connect(function()
			card.BackgroundColor3 = Theme.ForestDeep
		end)
	end
	
	if parent then
		card.Parent = parent
	end
	
	return card
end

return ItemCard
