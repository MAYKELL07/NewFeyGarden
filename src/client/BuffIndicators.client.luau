-- BuffIndicators.client.luau
-- Shows visual indicators for active buffs on plants

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
if not sharedFolder then
	warn("[BuffIndicators] Shared folder missing; aborting buff indicators")
	return
end

local ok, Config = pcall(function()
	return require(sharedFolder:WaitForChild("Config", 5))
end)
if not ok or not Config then
	warn("[BuffIndicators] Config module missing; aborting buff indicators")
	return
end

local player = Players.LocalPlayer

-- Create a buff indicator above a plant
local function createBuffIndicator(plant, buffType)
	local existing = plant:FindFirstChild("BuffIndicator")
	if existing then
		existing:Destroy()
	end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BuffIndicator"
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = plant
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.3
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = billboard
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = frame
	
	-- Set text based on buff type
	if buffType == "water" then
		label.Text = "💧 Watered!"
		frame.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	elseif buffType == "weather" then
		label.Text = "☀️ Weather Boost!"
		frame.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
	elseif buffType == "pet" then
		label.Text = "🐾 Pet Nearby!"
		frame.BackgroundColor3 = Color3.fromRGB(255, 150, 255)
	end
	
	-- Fade out after 3 seconds
	task.delay(3, function()
		if billboard then
			for i = 0, 1, 0.1 do
				task.wait(0.1)
				if billboard then
					frame.BackgroundTransparency = 0.3 + (i * 0.7)
					label.TextTransparency = i
				end
			end
			if billboard then
				billboard:Destroy()
			end
		end
	end)
end

-- Monitor plants for buff changes
local function monitorPlants()
	RunService.Heartbeat:Connect(function()
		-- Get plots folder directly from workspace
		local plotsFolder = Workspace:FindFirstChild(Config.World.PlotsFolder)
		if not plotsFolder then return end
		
		-- Find player's plot
		for _, plot in ipairs(plotsFolder:GetChildren()) do
			if plot:GetAttribute("Owner") == player.UserId then
				-- Check each plant for buff changes
				for _, child in ipairs(plot:GetChildren()) do
					if child:IsA("Model") and child:GetAttribute("PlantType") then
						-- Check for water buff
						local waterEnd = child:GetAttribute("WaterBuffEnd")
						if waterEnd and waterEnd > os.time() then
							if not child:GetAttribute("_WaterIndicatorShown") then
								child:SetAttribute("_WaterIndicatorShown", true)
								createBuffIndicator(child, "water")
								task.delay(3, function()
									if child then
										child:SetAttribute("_WaterIndicatorShown", nil)
									end
								end)
							end
						end
						
						-- Check for pet boost
						local petBoost = child:GetAttribute("PetBoost")
						if petBoost == true then
							if not child:GetAttribute("_PetIndicatorShown") then
								child:SetAttribute("_PetIndicatorShown", true)
								createBuffIndicator(child, "pet")
								task.delay(3, function()
									if child then
										child:SetAttribute("_PetIndicatorShown", nil)
									end
								end)
							end
						end
					end
				end
				break
			end
		end
	end)
end

-- Start monitoring
task.delay(2, monitorPlants) -- Small delay to ensure everything is loaded

-- print("BuffIndicators client initialized")
