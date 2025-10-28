# UI Setup Instructions

## Step 1: Run the UI Setup Script

Open **Studio Command Bar** (View → Command Bar) and run:

```lua
require(game.ReplicatedStorage.Setup.UISetup).CreateUI()
```

This will create the entire UI structure in `StarterGui.FeyGardenUI`.

You should see this output:
```
[UISetup] Creating FeyGarden UI...
[UISetup] ✅ FeyGardenUI created successfully!
[UISetup] UI Structure:
  - CurrencyFrame (coins display)
  - WeatherFrame (weather display)
  - InventoryFrame (seeds)
  - FruitsFrame (harvested fruits)
  - ShopWindow (buy seeds & pets)
  - SellWindow (sell fruits)
  - NotificationContainer (feedback messages)
[UISetup] Ready for client scripts to use!
```

## Step 2: Verify the UI

1. Check `StarterGui` → You should see `FeyGardenUI`
2. Expand it to see all frames:
   - CurrencyFrame
   - WeatherFrame
   - InventoryFrame
   - FruitsFrame
   - ShopWindow (hidden by default)
   - SellWindow (hidden by default)
   - NotificationContainer

## Step 3: Play Test

The new `UIHandler_New.client.luau` is already enabled and will automatically use the pre-built UI.

The old `UIHandler.luau` has been disabled in the project config.

## Features

### ✅ New UI System
- **Pre-built UI**: Created once via setup script, not at runtime
- **Lightweight Client**: Uses WaitForChild instead of creating UI
- **Animations**: Fade in/out, scale effects, slide notifications
- **Professional Design**: Scale-based layouts, gradients, shadows
- **Theme Colors**: Mystical garden palette (purples, greens, browns)

### ✅ Shop System
- Browse all seeds and pets
- Shows price, growth time, and boost stats
- Buy button with hover effects
- Auto-updates inventory

### ✅ Sell System
- Displays all harvested fruits
- Sell 1 or Sell All buttons
- Shows sell price (60% of seed price)
- Real-time inventory sync

### ✅ Notifications
- Slide-in animations
- Auto-dismiss after 2 seconds
- Color-coded messages
- Icons for different events

### ✅ Inventory
- Seeds and Fruits in separate frames
- Only shows items with count > 0
- Click to select/unselect seeds
- Auto-unselect when depleted
- Visual selection highlight

## Troubleshooting

**If UI doesn't appear:**
1. Make sure you ran the setup script
2. Check StarterGui for "FeyGardenUI"
3. Verify UIHandler_New.client.luau is in StarterPlayer.StarterPlayerScripts.Client
4. Check Output window for errors

**If shop/sell doesn't work:**
1. Ensure ProximityPrompts exist on ShopPart and SellPart
2. Check Config.World.ShopPartName and SellPartName match workspace parts
3. Verify RemoteEvents exist in ReplicatedStorage

## Notes

- Run the setup script **only once** (or whenever you want to recreate the UI)
- Old UIHandler is disabled but kept for reference
- All client scripts now use the pre-built UI structure
- UI persists across respawns (ResetOnSpawn = false)
