-- VFXModule.luau
-- Manages visual effects for growth, watering, and pet interactions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local VFXModule = {}

-- Helper function to pulse a particle emitter
local function pulseEmitter(emitter, duration)
	if not emitter or not emitter:IsA("ParticleEmitter") then return end
	
	duration = duration or 0.6
	emitter.Enabled = true
	
	task.delay(duration, function()
		if emitter then
			emitter.Enabled = false
		end
	end)
end

-- Try to emit water splash effect
function VFXModule.TryEmitWater(target)
	if not Config.VFX.Enable then return end
	
	local emitter = target:FindFirstChild(Config.VFX.WaterSplashParticleName, true)
	if emitter then
		pulseEmitter(emitter, 0.8)
		return true
	end
	
	-- Create placeholder effect if no particle found
	print("VFXModule: Water splash effect triggered on", target.Name)
	return false
end

-- Try to emit growth sparkle effect
function VFXModule.TryEmitGrowth(target)
	if not Config.VFX.Enable then return end
	
	local emitter = target:FindFirstChild(Config.VFX.GrowthSparkleParticleName, true)
	if emitter then
		pulseEmitter(emitter, 1.0)
		return true
	end
	
	-- Create placeholder effect if no particle found
	print("VFXModule: Growth sparkle effect triggered on", target.Name)
	return false
end

-- Try to emit pet cheer effect
function VFXModule.TryEmitPetCheer(target)
	if not Config.VFX.Enable then return end
	
	local emitter = target:FindFirstChild(Config.VFX.PetCheerParticleName, true)
	if emitter then
		pulseEmitter(emitter, 0.5)
		return true
	end
	
	-- Create placeholder effect if no particle found
	print("VFXModule: Pet cheer effect triggered on", target.Name)
	return false
end

-- Create a simple sparkle effect (fallback for when particles don't exist)
function VFXModule.CreateSparkleEffect(position, color)
	if not Config.VFX.Enable then return end
	
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Color = color or Color3.fromRGB(255, 255, 100)
	part.Material = Enum.Material.Neon
	part.Transparency = 0
	part.Parent = workspace
	
	-- Fade out and destroy
	task.spawn(function()
		for i = 0, 1, 0.1 do
			task.wait(0.05)
			if part then
				part.Transparency = i
				part.Size = part.Size * 0.9
			end
		end
		if part then
			part:Destroy()
		end
	end)
end

-- Show watering effect (enhanced fallback)
function VFXModule.ShowWateringEffect(position)
	if not Config.VFX.Enable then return end
	
	VFXModule.CreateSparkleEffect(position + Vector3.new(0, 1, 0), Color3.fromRGB(100, 150, 255))
	print("VFXModule: Watering effect shown at", position)
end

-- Show growth effect (enhanced fallback)
function VFXModule.ShowGrowthEffect(position)
	if not Config.VFX.Enable then return end
	
	VFXModule.CreateSparkleEffect(position + Vector3.new(0, 2, 0), Color3.fromRGB(100, 255, 100))
	print("VFXModule: Growth effect shown at", position)
end

return VFXModule
