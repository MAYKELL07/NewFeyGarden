-- TradingService.luau
-- Handles player-to-player trading

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

local TradingService = {}

-- Active trades: { tradeId = { player1, player2, offer1, offer2, confirmed1, confirmed2 } }
local activeTrades = {}
-- Pending trade requests: { requesterId_targetId = { requester, target, timestamp } }
local pendingRequests = {}
-- Trade cooldowns: { requesterId_targetId = timestamp }
local tradeCooldowns = {}

-- Reference to DataService (set during initialization)
local DataService = nil

-- RemoteEvents
local tradeRequestEvent
local tradeResponseEvent
local tradeUpdateEvent
local tradeConfirmEvent
local tradeCancelEvent
local tradeCompleteEvent
local tradeIncomingEvent

-- Generate unique trade ID
local function generateTradeId()
	return game:GetService("HttpService"):GenerateGUID(false)
end

-- Get distance between two players
local function getPlayerDistance(player1, player2)
	local char1 = player1.Character
	local char2 = player2.Character
	if not char1 or not char2 then return math.huge end
	
	local hrp1 = char1:FindFirstChild("HumanoidRootPart")
	local hrp2 = char2:FindFirstChild("HumanoidRootPart")
	if not hrp1 or not hrp2 then return math.huge end
	
	return (hrp1.Position - hrp2.Position).Magnitude
end

-- Check if player can trade (not in another trade)
local function canPlayerTrade(player)
	for _, trade in pairs(activeTrades) do
		if trade.player1 == player or trade.player2 == player then
			return false, "Already in a trade"
		end
	end
	return true
end

-- Get active trade for a player
local function getPlayerTrade(player)
	for tradeId, trade in pairs(activeTrades) do
		if trade.player1 == player or trade.player2 == player then
			return tradeId, trade
		end
	end
	return nil
end

-- Validate items exist in player's inventory
local function validateItems(player, items)
	if not DataService then return false end
	
	local profile = DataService.GetPlayerData(player)
	if not profile then return false end
	
	-- Check each item
	for _, item in ipairs(items) do
		local found = false
		
		if item.Type == "Seed" then
			-- Check seeds inventory
			for _, seed in ipairs(profile.Inventory.Seeds or {}) do
				if seed.Id == item.Id and seed.SeedType == item.SeedType then
					found = true
					break
				end
			end
		elseif item.Type == "Pet" then
			-- Check pets inventory (not equipped or garden pets)
			for _, pet in ipairs(profile.Inventory.Pets or {}) do
				if pet.Id == item.Id and pet.PetType == item.PetType then
					-- Make sure it's not equipped
					local isEquipped = false
					for _, eqPet in ipairs(profile.EquippedPets or {}) do
						if eqPet.Id == item.Id then
							isEquipped = true
							break
						end
					end
					for _, gPet in ipairs(profile.GardenPets or {}) do
						if gPet.Id == item.Id then
							isEquipped = true
							break
						end
					end
					if not isEquipped then
						found = true
						break
					end
				end
			end
		elseif item.Type == "Fruit" then
			-- Check fruits inventory
			for _, fruit in ipairs(profile.Inventory.Fruits or {}) do
				if fruit.Id == item.Id and fruit.FruitType == item.FruitType then
					found = true
					break
				end
			end
		elseif item.Type == "Coins" then
			-- Check if player has enough coins
			if profile.Coins >= item.Amount then
				found = true
			end
		end
		
		if not found then
			return false, "Item not found: " .. (item.Id or item.Type)
		end
	end
	
	return true
end

-- Transfer items between players
local function transferItems(fromPlayer, toPlayer, items)
	if not DataService then return false end
	
	for _, item in ipairs(items) do
		if item.Type == "Seed" then
			DataService.RemoveSeed(fromPlayer, item.Id)
			DataService.AddSeed(toPlayer, item.SeedType, item)
		elseif item.Type == "Pet" then
			DataService.RemovePet(fromPlayer, item.Id)
			DataService.AddPet(toPlayer, item.PetType, item)
		elseif item.Type == "Fruit" then
			DataService.RemoveFruit(fromPlayer, item.Id)
			DataService.AddFruit(toPlayer, item.FruitType, item)
		elseif item.Type == "Coins" then
			DataService.RemoveCoins(fromPlayer, item.Amount)
			DataService.AddCoins(toPlayer, item.Amount)
		end
	end
	
	return true
end

-- Handle trade request from client
local function onTradeRequest(player, targetPlayer)
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		return { success = false, message = "Invalid target player" }
	end
	
	if player == targetPlayer then
		return { success = false, message = "Cannot trade with yourself" }
	end
	
	-- Check if either player is already trading
	local canTrade, reason = canPlayerTrade(player)
	if not canTrade then
		return { success = false, message = reason }
	end
	
	canTrade, reason = canPlayerTrade(targetPlayer)
	if not canTrade then
		return { success = false, message = "Target player is already trading" }
	end
	
	-- Check cooldown
	local cooldownKey = player.UserId .. "_" .. targetPlayer.UserId
	local cooldown = tradeCooldowns[cooldownKey]
	if cooldown and (os.time() - cooldown) < Constants.TRADING_CONFIG.RequestCooldown then
		local remaining = Constants.TRADING_CONFIG.RequestCooldown - (os.time() - cooldown)
		return { success = false, message = "Please wait " .. remaining .. " seconds" }
	end
	
	-- Check distance if configured
	local maxDistance = Constants.TRADING_CONFIG.MaxTradeDistance
	if maxDistance > 0 then
		local distance = getPlayerDistance(player, targetPlayer)
		if distance > maxDistance then
			return { success = false, message = "Target player is too far away" }
		end
	end
	
	-- Create pending request
	local requestKey = player.UserId .. "_" .. targetPlayer.UserId
	pendingRequests[requestKey] = {
		requester = player,
		target = targetPlayer,
		timestamp = os.time()
	}
	
	-- Notify target player
	if tradeIncomingEvent then
		tradeIncomingEvent:FireClient(targetPlayer, {
			requester = player,
			requesterId = player.UserId,
			requesterName = player.Name
		})
	end
	
	-- Set cooldown
	tradeCooldowns[cooldownKey] = os.time()
	
	-- Set timeout to auto-expire request
	task.delay(Constants.TRADING_CONFIG.RequestTimeout, function()
		if pendingRequests[requestKey] then
			pendingRequests[requestKey] = nil
		end
	end)
	
	return { success = true, message = "Trade request sent" }
end

-- Handle trade response (accept/decline)
local function onTradeResponse(player, requesterId, accepted)
	local requestKey = requesterId .. "_" .. player.UserId
	local request = pendingRequests[requestKey]
	
	if not request then
		return { success = false, message = "No pending trade request" }
	end
	
	local requester = request.requester
	pendingRequests[requestKey] = nil
	
	if not accepted then
		-- Notify requester of decline
		if tradeResponseEvent then
			tradeResponseEvent:FireClient(requester, {
				accepted = false,
				message = player.Name .. " declined your trade request"
			})
		end
		return { success = true, message = "Trade declined" }
	end
	
	-- Check if both players can still trade
	local canTrade1, reason1 = canPlayerTrade(requester)
	local canTrade2, reason2 = canPlayerTrade(player)
	
	if not canTrade1 or not canTrade2 then
		if tradeResponseEvent then
			tradeResponseEvent:FireClient(requester, {
				accepted = false,
				message = "Trade could not be started"
			})
		end
		return { success = false, message = "Trade could not be started" }
	end
	
	-- Create active trade
	local tradeId = generateTradeId()
	activeTrades[tradeId] = {
		player1 = requester,
		player2 = player,
		offer1 = {},
		offer2 = {},
		confirmed1 = false,
		confirmed2 = false,
		timestamp = os.time()
	}
	
	-- Notify both players
	if tradeResponseEvent then
		tradeResponseEvent:FireClient(requester, {
			accepted = true,
			tradeId = tradeId,
			partner = player,
			partnerName = player.Name
		})
		tradeResponseEvent:FireClient(player, {
			accepted = true,
			tradeId = tradeId,
			partner = requester,
			partnerName = requester.Name
		})
	end
	
	-- Set timeout for trade
	task.delay(Constants.TRADING_CONFIG.ConfirmTimeout * 2, function()
		if activeTrades[tradeId] then
			-- Cancel trade due to timeout
			local trade = activeTrades[tradeId]
			activeTrades[tradeId] = nil
			
			if tradeCancelEvent then
				if trade.player1 and trade.player1.Parent then
					tradeCancelEvent:FireClient(trade.player1, { reason = "Trade timed out" })
				end
				if trade.player2 and trade.player2.Parent then
					tradeCancelEvent:FireClient(trade.player2, { reason = "Trade timed out" })
				end
			end
		end
	end)
	
	return { success = true, tradeId = tradeId }
end

-- Handle trade update (add/remove items)
local function onTradeUpdate(player, action, item)
	local tradeId, trade = getPlayerTrade(player)
	if not trade then
		return { success = false, message = "Not in a trade" }
	end
	
	-- Reset confirmations when offer changes
	trade.confirmed1 = false
	trade.confirmed2 = false
	
	-- Determine which offer to modify
	local isPlayer1 = trade.player1 == player
	local offer = isPlayer1 and trade.offer1 or trade.offer2
	local partner = isPlayer1 and trade.player2 or trade.player1
	
	if action == "add" then
		-- Check max items
		if #offer >= Constants.TRADING_CONFIG.MaxItemsPerTrade then
			return { success = false, message = "Maximum items reached" }
		end
		
		-- Validate item exists
		local valid, reason = validateItems(player, {item})
		if not valid then
			return { success = false, message = reason }
		end
		
		-- Check if item already in offer
		for _, existingItem in ipairs(offer) do
			if existingItem.Id == item.Id then
				return { success = false, message = "Item already in offer" }
			end
		end
		
		table.insert(offer, item)
	elseif action == "remove" then
		-- Find and remove item
		for i, existingItem in ipairs(offer) do
			if existingItem.Id == item.Id then
				table.remove(offer, i)
				break
			end
		end
	elseif action == "setCoins" then
		-- Update coin amount in offer
		-- Remove existing coin entry
		for i, existingItem in ipairs(offer) do
			if existingItem.Type == "Coins" then
				table.remove(offer, i)
				break
			end
		end
		-- Add new coin amount if > 0
		if item.Amount and item.Amount > 0 then
			local valid, reason = validateItems(player, {{Type = "Coins", Amount = item.Amount}})
			if not valid then
				return { success = false, message = "Not enough coins" }
			end
			table.insert(offer, { Type = "Coins", Amount = item.Amount, Id = "coins" })
		end
	end
	
	-- Notify both players of update
	if tradeUpdateEvent then
		local updateData = {
			offer1 = trade.offer1,
			offer2 = trade.offer2,
			confirmed1 = trade.confirmed1,
			confirmed2 = trade.confirmed2
		}
		tradeUpdateEvent:FireClient(trade.player1, updateData)
		tradeUpdateEvent:FireClient(trade.player2, updateData)
	end
	
	return { success = true }
end

-- Handle trade confirm
local function onTradeConfirm(player)
	local tradeId, trade = getPlayerTrade(player)
	if not trade then
		return { success = false, message = "Not in a trade" }
	end
	
	local isPlayer1 = trade.player1 == player
	
	if isPlayer1 then
		trade.confirmed1 = true
	else
		trade.confirmed2 = true
	end
	
	-- Notify both players
	if tradeUpdateEvent then
		local updateData = {
			offer1 = trade.offer1,
			offer2 = trade.offer2,
			confirmed1 = trade.confirmed1,
			confirmed2 = trade.confirmed2
		}
		tradeUpdateEvent:FireClient(trade.player1, updateData)
		tradeUpdateEvent:FireClient(trade.player2, updateData)
	end
	
	-- Check if both confirmed
	if trade.confirmed1 and trade.confirmed2 then
		-- Final validation
		local valid1, reason1 = validateItems(trade.player1, trade.offer1)
		local valid2, reason2 = validateItems(trade.player2, trade.offer2)
		
		if not valid1 or not valid2 then
			-- Cancel trade - items no longer valid
			activeTrades[tradeId] = nil
			if tradeCancelEvent then
				tradeCancelEvent:FireClient(trade.player1, { reason = "Trade items no longer valid" })
				tradeCancelEvent:FireClient(trade.player2, { reason = "Trade items no longer valid" })
			end
			return { success = false, message = "Trade items invalid" }
		end
		
		-- Execute trade
		transferItems(trade.player1, trade.player2, trade.offer1)
		transferItems(trade.player2, trade.player1, trade.offer2)
		
		-- Remove trade
		activeTrades[tradeId] = nil
		
		-- Notify both players
		if tradeCompleteEvent then
			tradeCompleteEvent:FireClient(trade.player1, {
				success = true,
				received = trade.offer2
			})
			tradeCompleteEvent:FireClient(trade.player2, {
				success = true,
				received = trade.offer1
			})
		end
		
		-- Sync inventories
		if DataService then
			DataService.SyncPlayerData(trade.player1)
			DataService.SyncPlayerData(trade.player2)
		end
		
		return { success = true, completed = true }
	end
	
	return { success = true, waiting = true }
end

-- Handle trade cancel
local function onTradeCancel(player)
	local tradeId, trade = getPlayerTrade(player)
	if not trade then
		return { success = false, message = "Not in a trade" }
	end
	
	local partner = trade.player1 == player and trade.player2 or trade.player1
	
	-- Remove trade
	activeTrades[tradeId] = nil
	
	-- Notify both players
	if tradeCancelEvent then
		tradeCancelEvent:FireClient(player, { reason = "You cancelled the trade" })
		if partner and partner.Parent then
			tradeCancelEvent:FireClient(partner, { reason = player.Name .. " cancelled the trade" })
		end
	end
	
	return { success = true }
end

-- Clean up when player leaves
local function onPlayerRemoving(player)
	-- Cancel any active trade
	local tradeId, trade = getPlayerTrade(player)
	if trade then
		local partner = trade.player1 == player and trade.player2 or trade.player1
		activeTrades[tradeId] = nil
		
		if tradeCancelEvent and partner and partner.Parent then
			tradeCancelEvent:FireClient(partner, { reason = player.Name .. " left the game" })
		end
	end
	
	-- Remove pending requests
	for key, request in pairs(pendingRequests) do
		if request.requester == player or request.target == player then
			pendingRequests[key] = nil
		end
	end
end

-- Initialize the service
function TradingService.Initialize(dataServiceRef)
	DataService = dataServiceRef
	
	-- Create RemoteEvents
	tradeRequestEvent = Instance.new("RemoteFunction")
	tradeRequestEvent.Name = Constants.EVENTS.TRADE_REQUEST
	tradeRequestEvent.Parent = ReplicatedStorage
	
	tradeResponseEvent = Instance.new("RemoteEvent")
	tradeResponseEvent.Name = Constants.EVENTS.TRADE_RESPONSE
	tradeResponseEvent.Parent = ReplicatedStorage
	
	tradeUpdateEvent = Instance.new("RemoteEvent")
	tradeUpdateEvent.Name = Constants.EVENTS.TRADE_UPDATE
	tradeUpdateEvent.Parent = ReplicatedStorage
	
	tradeConfirmEvent = Instance.new("RemoteEvent")
	tradeConfirmEvent.Name = Constants.EVENTS.TRADE_CONFIRM
	tradeConfirmEvent.Parent = ReplicatedStorage
	
	tradeCancelEvent = Instance.new("RemoteEvent")
	tradeCancelEvent.Name = Constants.EVENTS.TRADE_CANCEL
	tradeCancelEvent.Parent = ReplicatedStorage
	
	tradeCompleteEvent = Instance.new("RemoteEvent")
	tradeCompleteEvent.Name = Constants.EVENTS.TRADE_COMPLETE
	tradeCompleteEvent.Parent = ReplicatedStorage
	
	tradeIncomingEvent = Instance.new("RemoteEvent")
	tradeIncomingEvent.Name = Constants.EVENTS.TRADE_INCOMING
	tradeIncomingEvent.Parent = ReplicatedStorage
	
	-- Set up handlers
	tradeRequestEvent.OnServerInvoke = onTradeRequest
	
	tradeResponseEvent.OnServerEvent:Connect(function(player, requesterId, accepted)
		onTradeResponse(player, requesterId, accepted)
	end)
	
	tradeUpdateEvent.OnServerEvent:Connect(function(player, action, item)
		onTradeUpdate(player, action, item)
	end)
	
	tradeConfirmEvent.OnServerEvent:Connect(function(player)
		onTradeConfirm(player)
	end)
	
	tradeCancelEvent.OnServerEvent:Connect(function(player)
		onTradeCancel(player)
	end)
	
	-- Clean up on player leave
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	print("[TradingService] Initialized")
end

return TradingService
