# 🔧 Admin Commands System

A simple admin command system for testing and debugging FeyGarden.

## 📁 Structure

```
src/admin/
├── AdminCommands.luau              # Command definitions and logic
└── AdminCommandHandler.server.luau # Server-side command processor

src/client/
└── AdminUI.client.luau             # Client-side command console
```

## 🎮 How to Use

### Opening the Command Console
Press **`/`** (forward slash) to open the admin command console.

### Command Format
Type commands without the `/` prefix:
```
addcoins 1000
setweather Rainy
grow
```

### Available Commands

| Command | Usage | Description |
|---------|-------|-------------|
| **addcoins** | `addcoins <amount>` | Add coins to yourself |
| **removecoins** | `removecoins <amount>` | Remove coins from yourself |
| **getcoins** | `getcoins` | Check your current coins |
| **addseeds** | `addseeds <type> <amount>` | Add seeds (Glowbud/Dewleaf) |
| **setweather** | `setweather <type>` | Change weather (Sunny/Rainy/Stormy) |
| **grow** | `grow` | Instantly grow all your plants to Bloom |
| **clear** | `clear` | Clear all plants from your garden |
| **spawn** | `spawn` | Teleport to spawn point |
| **help** | `help` | Show command list |

### Examples

```
addcoins 5000          # Add 5000 coins
addseeds Glowbud 10    # Add 10 Glowbud seeds
setweather Stormy      # Change weather to stormy
grow                   # Instantly grow all plants
clear                  # Clear your garden
```

## 🔐 Admin Permissions

### In Studio (Testing)
- **Everyone is admin** - All commands work for testing

### In Published Game
Edit `src/admin/AdminCommands.luau` and add admin User IDs:

```lua
AdminCommands.AdminUsers = {
    123456789,  -- Replace with your Roblox User ID
    987654321,  -- Add more admin IDs here
}
```

To find your User ID:
1. Go to your Roblox profile
2. Look at the URL: `roblox.com/users/USERID/profile`

## 🧪 Testing Workflows

### Quick Plant Testing
```
addseeds Glowbud 5
# Plant some seeds
grow                   # Skip waiting for growth
# Harvest for instant coins
```

### Economy Testing
```
getcoins               # Check starting coins
addcoins 10000         # Add test money
# Buy items from shop
removecoins 5000       # Remove if needed
```

### Weather Testing
```
setweather Sunny       # Test sunny weather
setweather Rainy       # Test rainy weather
setweather Stormy      # Test stormy weather
```

### Garden Management
```
clear                  # Clear all plants
addseeds Dewleaf 9     # Fill with Dewleaf
grow                   # Grow them all
clear                  # Clean up
```

## 📝 Adding New Commands

Edit `src/admin/AdminCommands.luau`:

```lua
-- Add command function
function AdminCommands.YourCommand(player, arg1, arg2)
    -- Your logic here
    return true, "Success message"
end
```

Edit `src/admin/AdminCommandHandler.server.luau`:

```lua
elseif command == "yourcommand" then
    local arg1 = args[2]
    local arg2 = tonumber(args[3])
    success, message = AdminCommands.YourCommand(player, arg1, arg2)
```

Add to help list in `AdminCommands.GetCommandsList()`:

```lua
{name = "yourcommand", usage = "yourcommand <arg1> <arg2>", desc = "What it does"},
```

## 🚨 Troubleshooting

**Command console not opening:**
- Make sure you're pressing `/` (forward slash)
- Check Output window for errors

**Commands not working:**
- Verify you're in Studio (auto-admin mode)
- Check if AdminCommandHandler is running (see Output)
- Look for error messages in Output window

**"Not admin" error in published game:**
- Add your User ID to `AdminCommands.AdminUsers`
- Rebuild with `rojo build`

## 🎯 Best Practices

1. **Don't abuse in production** - These are debugging tools
2. **Remove or secure** - Before publishing, either:
   - Remove admin folder entirely
   - Add proper authentication
   - Set specific admin User IDs
3. **Test thoroughly** - Use commands to test edge cases
4. **Log everything** - Admin actions are logged to console

---

**Built for rapid testing and development! 🚀**
