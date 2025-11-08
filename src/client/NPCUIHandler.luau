-- NPCUIHandler.luau
-- Simple camera controller for shop interactions

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local NPCUIHandler = {}

-- State
local originalCameraCFrame = nil
local originalCameraType = nil

-- Move camera to a preset camera part
function NPCUIHandler.MoveCameraToNPC(cameraPartName)
	local cameraPart = workspace:FindFirstChild(cameraPartName)
	if not cameraPart then
		warn("[NPCUIHandler] Camera part not found:", cameraPartName)
		return
	end
	
	-- Store original camera settings
	originalCameraCFrame = camera.CFrame
	originalCameraType = camera.CameraType
	
	-- Set camera to scripted mode and teleport instantly
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cameraPart.CFrame
end

-- Restore camera to original position
function NPCUIHandler.RestoreCamera()
	if not originalCameraCFrame then return end
	
	-- Restore instantly
	camera.CFrame = originalCameraCFrame
	
	-- Restore camera type
	if originalCameraType then
		camera.CameraType = originalCameraType
		originalCameraType = nil
	end
	originalCameraCFrame = nil
end

function NPCUIHandler.Initialize()
	-- No UI to initialize, only camera functions
end

return NPCUIHandler
