-- NPCModule.luau
-- Handles NPC data, dialogs, and interactions

local NPCModule = {}

-- NPC Types
NPCModule.NPC_TYPES = {
	SEED_SHOP = "SeedShop",
	FRUIT_SELLER = "FruitSeller",
	PET_STORE = "PetStore"
}

-- NPC Configurations
NPCModule.NPC_CONFIG = {
	[NPCModule.NPC_TYPES.SEED_SHOP] = {
		Name = "Seed Shop",
		Title = "Buy Magical Seeds",
		Shopkeeper = "Flora the Gardener",
		Description = "Purchase mystical seeds to grow in your garden",
		Color = Color3.fromRGB(100, 200, 100),
		Icon = "�",
		CameraPartName = "ShopCamera", -- Camera will look for this part in workspace
		Dialogs = {
			Welcome = {
				"Welcome to the Seed Shop!",
				"Browse our collection of mystical seeds.",
				"Each seed grows into something magical!"
			},
			Browse = {
				"Looking for something specific?",
				"Rare seeds cost more but yield better profits!",
				"Start with cheaper seeds if you're new.",
				"All our seeds are guaranteed to grow!"
			},
			Purchase = {
				"Excellent choice!",
				"Plant it carefully and watch it grow!",
				"Come back when you need more seeds!"
			},
			NoMoney = {
				"Not enough coins for that seed.",
				"Sell some fruits to earn more coins!",
				"Try the cheaper seeds first!"
			}
		}
	},
	
	[NPCModule.NPC_TYPES.FRUIT_SELLER] = {
		Name = "Fruit Market",
		Title = "Sell Your Harvest",
		Shopkeeper = "Trader Goldleaf",
		Description = "Sell your harvested fruits for coins",
		Color = Color3.fromRGB(255, 200, 100),
		Icon = "🍎",
		CameraPartName = "SellCamera",
		Dialogs = {
			Welcome = {
				"Welcome to the Fruit Market!",
				"I buy all types of mystical fruits.",
				"Show me what you've harvested!"
			},
			Browse = {
				"Those fruits look delicious!",
				"Rare fruits are worth more coins!",
				"I always pay fair prices!",
				"The fresher the fruit, the better!"
			},
			Sell = {
				"Sold! Here's your payment!",
				"Pleasure doing business!",
				"Come back with more anytime!",
				"Your garden produces quality fruits!"
			},
			NoFruits = {
				"No fruits to sell yet?",
				"Harvest some plants first!",
				"I'll be here when you have fruits to sell!"
			}
		}
	},
	
	[NPCModule.NPC_TYPES.PET_STORE] = {
		Name = "Pet Emporium",
		Title = "Adopt Mystical Companions",
		Shopkeeper = "Keeper Moonwhisper",
		Description = "Adopt magical pets that help your garden grow faster",
		Color = Color3.fromRGB(200, 150, 255),
		Icon = "�",
		CameraPartName = "PetCamera",
		Dialogs = {
			Welcome = {
				"Welcome to the Pet Emporium!",
				"Looking for a magical companion?",
				"Each pet has special growth-boosting powers!"
			},
			Browse = {
				"Pets help your plants grow faster!",
				"Only one pet can be active at a time.",
				"The rarer the pet, the stronger the boost!",
				"Choose your companion wisely!"
			},
			Purchase = {
				"Wonderful choice!",
				"Your new friend will serve you well!",
				"Equip your pet from the Pets menu!",
				"May your bond grow strong!"
			},
			NoMoney = {
				"That pet costs more than you have.",
				"Save up coins by selling fruits!",
				"There are cheaper pets available!"
			}
		}
	}
}

-- Get random dialog from category
function NPCModule.GetDialog(npcType, category)
	local npcConfig = NPCModule.NPC_CONFIG[npcType]
	if not npcConfig then return nil end
	
	local dialogs = npcConfig.Dialogs[category]
	if not dialogs or #dialogs == 0 then return nil end
	
	return dialogs[math.random(1, #dialogs)]
end

-- Get all dialogs from category
function NPCModule.GetDialogSequence(npcType, category)
	local npcConfig = NPCModule.NPC_CONFIG[npcType]
	if not npcConfig then return {} end
	
	return npcConfig.Dialogs[category] or {}
end

-- Get NPC info
function NPCModule.GetNPCInfo(npcType)
	return NPCModule.NPC_CONFIG[npcType]
end

return NPCModule
