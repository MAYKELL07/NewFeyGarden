-- ToolClient.luau
-- Client-side tool input handling

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Config = require(ReplicatedStorage.Shared.Config)

-- Wait for or create ToolAction RemoteEvent
local toolActionEvent = ReplicatedStorage:WaitForChild("ToolAction", 10)
if not toolActionEvent then
	warn("ToolAction RemoteEvent not found - tools won't work!")
	return
end

-- Track currently equipped tool
local currentTool = nil

-- Monitor tool equipping
local function setupToolTracking()
	-- Wait for character and backpack to load
	local character = player.Character or player.CharacterAdded:Wait()
	local backpack = player:WaitForChild("Backpack")
	
	-- Track backpack tools
	backpack.ChildAdded:Connect(function(tool)
		if tool:IsA("Tool") then
			tool.Equipped:Connect(function()
				currentTool = tool.Name
				print("Equipped tool:", currentTool)
			end)
			
			tool.Unequipped:Connect(function()
				currentTool = nil
				print("Unequipped tool")
			end)
		end
	end)
	
	-- Track existing tools
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Equipped:Connect(function()
				currentTool = tool.Name
				print("Equipped tool:", currentTool)
			end)
			
			tool.Unequipped:Connect(function()
				currentTool = nil
			end)
		end
	end
	
	-- Track character tools
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(tool)
			if tool:IsA("Tool") then
				currentTool = tool.Name
			end
		end)
	end)
end

-- Handle mouse click for tool usage
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Check for left mouse click
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Check if player has a tool equipped
		local character = player.Character
		if not character then return end
		
		local equippedTool = character:FindFirstChildOfClass("Tool")
		if not equippedTool then return end
		
		local toolName = equippedTool.Name
		
		-- Only handle Shovel and WateringCan
		if toolName ~= Config.Tools.Shovel.Name and toolName ~= Config.Tools.WateringCan.Name then
			return
		end
		
		-- Raycast from camera
		local rayOrigin = camera.CFrame.Position
		local rayDirection = camera.CFrame.LookVector * Config.Tools.MaxUseDistance
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = {character}
		
		local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		
		if rayResult and rayResult.Instance then
			-- Send tool action to server
			toolActionEvent:FireServer(toolName, rayResult.Instance, rayResult.Position)
			print("Tool used:", toolName, "on", rayResult.Instance.Name)
		end
	end
end)

-- Initialize tool tracking
setupToolTracking()

print("🔧 Tool Client Handler Loaded")
