-- EggModule.luau
-- Spawns egg models for incubation/hatching.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))

local EggModule = {}

local function getEggTemplateForType(eggType: string): Instance?
	local eggConfig = Constants.EGG_CONFIG[eggType]
	if not eggConfig then
		return nil
	end

	local eggsFolder = ReplicatedStorage:FindFirstChild("Eggs")
	if not eggsFolder then
		warn("[EggModule] ReplicatedStorage.Eggs missing")
		return nil
	end

	local rarityName = eggConfig.Rarity
	if type(rarityName) ~= "string" then
		return nil
	end

	local template = eggsFolder:FindFirstChild(rarityName)
	if not template then
		warn(string.format("[EggModule] Egg template missing for rarity '%s' (eggType=%s)", rarityName, eggType))
		return nil
	end

	return template
end

local function ensureModel(instance: Instance): Model?
	if instance:IsA("Model") then
		return instance
	end

	if instance:IsA("BasePart") then
		local model = Instance.new("Model")
		model.Name = instance.Name
		instance.Parent = model
		model.PrimaryPart = instance
		return model
	end

	return nil
end

local function findPrimaryPart(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	local basePart = model:FindFirstChildWhichIsA("BasePart", true)
	if basePart then
		model.PrimaryPart = basePart
		return basePart
	end

	return nil
end

function EggModule.CreateEggModel(eggType: string, position: Vector3): Model?
	local template = getEggTemplateForType(eggType)
	if not template then
		return nil
	end

	local clone = template:Clone()
	local model = ensureModel(clone)
	if not model then
		clone:Destroy()
		warn("[EggModule] Egg template must be a Model or BasePart")
		return nil
	end

	model.Name = eggType
	local primary = findPrimaryPart(model)
	if not primary then
		model:Destroy()
		warn("[EggModule] Egg model has no BasePart")
		return nil
	end

	model:PivotTo(CFrame.new(position))
	return model
end

return EggModule
