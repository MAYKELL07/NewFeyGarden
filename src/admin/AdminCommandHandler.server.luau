-- AdminCommandHandler.server.luau
-- Handles admin command processing on the server

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminCommands = nil
do
	local adminModule = script.Parent:FindFirstChild("AdminCommands") or script.Parent:WaitForChild("AdminCommands", 5)
	if not adminModule then
		warn("[Admin] AdminCommands module missing; admin system disabled")
		return
	end
	local ok, mod = pcall(require, adminModule)
	if not ok then
		warn("[Admin] Failed to require AdminCommands: " .. tostring(mod))
		return
	end
	AdminCommands = mod
end

-- Create RemoteEvent for admin commands
local adminCommandEvent = Instance.new("RemoteEvent")
adminCommandEvent.Name = "AdminCommand"
adminCommandEvent.Parent = ReplicatedStorage

-- Process admin commands
adminCommandEvent.OnServerEvent:Connect(function(player, commandString)
	-- Check if player is admin
	if not AdminCommands.IsAdmin(player) then
		warn(player.Name .. " tried to use admin command but is not admin")
		adminCommandEvent:FireClient(player, false, "You are not authorized to use admin commands")
		return
	end
	
	-- Validate command string
	if not commandString or commandString == "" then
		adminCommandEvent:FireClient(player, false, "No command entered")
		return
	end
	
	-- Parse command
	local args = string.split(commandString, " ")
	local command = string.lower(args[1])
	
	local success, message
	
	-- Execute commands with error protection
	local executeSuccess, executeError = pcall(function()
		if command == "addcoins" then
			local amount = tonumber(args[2]) or 100
			success, message = AdminCommands.AddCoins(player, amount)
			
		elseif command == "removecoins" then
			local amount = tonumber(args[2]) or 100
			success, message = AdminCommands.RemoveCoins(player, amount)
			
		elseif command == "getcoins" then
			success, message = AdminCommands.GetCoins(player)
			
		elseif command == "addseeds" then
			local plantType = args[2] or "Glowbud"
			local amount = tonumber(args[3]) or 5
			success, message = AdminCommands.AddSeeds(player, plantType, amount)
			
		elseif command == "setweather" then
			local weatherType = args[2] or "Sunny"
			success, message = AdminCommands.SetWeather(weatherType)
			
		elseif command == "grow" then
			success, message = AdminCommands.GrowAllPlants(player)
			
		elseif command == "clear" then
			success, message = AdminCommands.ClearGarden(player)
			
		elseif command == "spawn" then
			success, message = AdminCommands.TeleportToSpawn(player)
			
		elseif command == "help" then
			local commands = AdminCommands.GetCommandsList()
			message = "=== Admin Commands (Press P to open) ===\n"
			for _, cmd in ipairs(commands) do
				message = message .. string.format("%s - %s\n", cmd.usage, cmd.desc)
			end
			success = true
			
		else
			success = false
			message = "Unknown command: " .. command .. ". Type 'help' for command list."
		end
	end)
	
	-- Handle execution errors
	if not executeSuccess then
		success = false
		message = "Command error: " .. tostring(executeError)
		warn(string.format("[ADMIN] Error executing command '%s' for %s: %s", commandString, player.Name, executeError))
	end
	
	-- Send response back to client
	adminCommandEvent:FireClient(player, success, message)
	
	-- Log command
	if success then
		print(string.format("[ADMIN] %s executed: %s", player.Name, commandString))
	else
		warn(string.format("[ADMIN] %s failed command: %s - %s", player.Name, commandString, message))
	end
end)

-- Notify admins on join
Players.PlayerAdded:Connect(function(player)
	if AdminCommands.IsAdmin(player) then
		task.wait(2)
		adminCommandEvent:FireClient(player, true, "🔧 Admin commands enabled! Press P and type 'help' for commands.")
		print(string.format("[ADMIN] %s joined as admin (UserId: %d)", player.Name, player.UserId))
	end
end)
