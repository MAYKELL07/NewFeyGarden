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
	-- Track backpack tools
	player.Backpack.ChildAdded:Connect(function(tool)
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
	for _, tool in ipairs(player.Backpack:GetChildren()) do
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
		if not currentTool then return end
		
		-- Raycast from camera
		local rayOrigin = camera.CFrame.Position
		local rayDirection = camera.CFrame.LookVector * Config.Tools.MaxUseDistance
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = {player.Character}
		
		local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		
		if rayResult and rayResult.Instance then
			-- Send tool action to server
			toolActionEvent:FireServer(currentTool, rayResult.Instance, rayResult.Position)
			print("Tool used:", currentTool, "on", rayResult.Instance.Name)
		end
	end
end)

-- Initialize tool tracking
setupToolTracking()

print("🔧 Tool Client Handler Loaded")
