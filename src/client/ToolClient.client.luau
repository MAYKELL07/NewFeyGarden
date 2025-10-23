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
	
	-- Function to setup tool activation
	local function setupTool(tool)
		if not tool:IsA("Tool") then return end
		
		-- Only handle our specific tools
		local toolName = tool.Name
		if toolName ~= Config.Tools.Shovel.Name and toolName ~= Config.Tools.WateringCan.Name then
			return
		end
		
		tool.Equipped:Connect(function()
			currentTool = tool.Name
			print("Equipped tool:", currentTool)
		end)
		
		tool.Unequipped:Connect(function()
			currentTool = nil
			print("Unequipped tool")
		end)
		
		-- Handle tool activation (when player clicks with tool)
		tool.Activated:Connect(function()
			print("Tool activated:", toolName)
			
			-- Raycast from camera
			local rayOrigin = camera.CFrame.Position
			local rayDirection = camera.CFrame.LookVector * Config.Tools.MaxUseDistance
			
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = {player.Character}
			
			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			
			if rayResult and rayResult.Instance then
				-- Send tool action to server
				toolActionEvent:FireServer(toolName, rayResult.Instance, rayResult.Position)
				print("Tool used:", toolName, "on", rayResult.Instance:GetFullName())
			else
				print("Tool click didn't hit anything")
			end
		end)
	end
	
	-- Track backpack tools
	backpack.ChildAdded:Connect(setupTool)
	
	-- Track existing tools in backpack
	for _, tool in ipairs(backpack:GetChildren()) do
		setupTool(tool)
	end
	
	-- Track character tools (when equipped)
	player.CharacterAdded:Connect(function(char)
		char.ChildAdded:Connect(setupTool)
	end)
end

-- Initialize tool tracking
setupToolTracking()

print("🔧 Tool Client Handler Loaded")
