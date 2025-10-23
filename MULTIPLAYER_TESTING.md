# 🌿 FeyGarden Multiplayer & Persistence - Testing Guide

## ✅ What Was Implemented

### 🗄️ **Persistence System**
- **DataService.server.luau**: Full DataStore integration with retry logic, autosave (60s), and shutdown-safe saves
- **Schema.luau**: Versioned data structure with migration support
- **Player Data Saved**:
  - Coins
  - Owned plot names
  - Inventory (seeds, pets)
  - Per-plot plant states (type, stage, watered status, pet boost)

### 🌍 **Multiplayer Support**
- **Plot Ownership**: Plots have `Owner` attribute (UserId)
- **Plot Claiming**: Players automatically assigned free plots on join
- **Plot Reclaiming**: Players reclaim their saved plots on rejoin
- **Plant State Restoration**: All plants restored with correct growth stage
- **ClaimPlotRequest**: RemoteEvent for manual plot claiming

### 💰 **Economy Integration**
- EconomyService now uses DataService for all coin/inventory operations
- Leaderstats folder shows player coins in player list
- All transactions persist across sessions

### 📊 **Leaderstats**
- Shows "Coins" in the player list
- Updates every second to reflect current balance

---

## 🧪 Testing Checklist

### **1. Single Player Persistence**
- [ ] Join the game
- [ ] Check Output: "DataService: Player joined", "Profile loaded"
- [ ] Use admin command `/addcoins 500`
- [ ] Plant some seeds, water them
- [ ] Wait for autosave (60s) or leave and rejoin
- [ ] Verify: Coins, plants, and garden state restored

### **2. Multiplayer Plot Claiming**
- [ ] Have 2-3 players join simultaneously
- [ ] Each should get assigned a different plot
- [ ] Check Output: "Assigned free plot Plot_X to PlayerName"
- [ ] Verify each player has `Owner` attribute on their plot

### **3. Plot Reclaiming**
- [ ] Player 1: Plant seeds, earn coins
- [ ] Player 1: Leave the game
- [ ] Player 2: Join and get a different plot
- [ ] Player 1: Rejoin
- [ ] Verify: Player 1 reclaims their original plot with plants intact

### **4. Data Persistence Across Sessions**
- [ ] Plant 3 different seeds at various stages
- [ ] Water one plant
- [ ] Buy a pet
- [ ] Note current coins and inventory
- [ ] **Close and reopen Studio**
- [ ] Rejoin game
- [ ] Verify:
  - Coins match previous amount
  - Seeds inventory correct
  - Pet still owned
  - All 3 plants restored at correct stages
  - Watered plant still has buff

### **5. Harvest & Save**
- [ ] Harvest a bloomed plant
- [ ] Check coins increased
- [ ] Leave and rejoin
- [ ] Verify: Harvested plant gone, coins saved

### **6. Autosave (60 seconds)**
- [ ] Join game
- [ ] Plant seeds, use `/addcoins 100`
- [ ] **Wait 60+ seconds**
- [ ] Check Output: "DataService: Autosaved profile for UserID"
- [ ] **Kill Studio process** (don't stop properly)
- [ ] Reopen and rejoin
- [ ] Verify: Recent changes saved

### **7. Shutdown Save**
- [ ] Make changes (plant, coins, etc.)
- [ ] **Press Stop button in Studio**
- [ ] Check Output: "Server shutting down, saving all profiles"
- [ ] Rejoin
- [ ] Verify: All changes saved

### **8. Multiple Players Simultaneously**
- [ ] Use Play > Test with 4 players
- [ ] Each plants different seeds
- [ ] Stop one player mid-session
- [ ] Verify others continue normally
- [ ] Restart stopped player
- [ ] Verify they reclaim their plot

---

## 🐛 Common Issues & Solutions

### **"No profile loaded for PlayerName"**
- **Cause**: DataService not initialized before other systems
- **Check**: MainServer loads DataService before GardenManager
- **Wait time**: 0.5s delay added for profile loading

### **"No free plots available"**
- **Cause**: All premade plots claimed
- **Solution**: Creates new plot using old system
- **Or**: Add more Plot_X models to workspace/GardenPlots

### **Plants not restoring**
- **Check**: Plot has correct Owner attribute
- **Check**: restorePlantState() called in PlayerAdded
- **Debug**: Look for "Restored plant X at slot Y" messages

### **Coins not syncing to leaderstats**
- **Check**: Config.Economy.CurrencyName matches
- **Check**: Polling loop running (1s updates)
- **Debug**: Print DataService.GetCoins() vs leaderstats.Value

### **DataStore errors in Studio**
- **Enable API Services**: Game Settings > Security > Allow HTTP Requests
- **Enable Studio Access**: Enable Studio Access to API Services
- **Note**: Full testing requires Published game

---

## 📝 Output Messages to Look For

### **On Join:**
```
DataService: Player joined: PlayerName UserId: 12345
DataService: Loading profile for UserId 12345
DataService: Successfully loaded profile for 12345
EconomyService: Initialized data for PlayerName - Coins: 100
GardenManager: Player joined: PlayerName
GardenManager: Reclaimed plot Plot_3 for PlayerName
GardenManager: Restored plant Glowbud at slot 1 stage Sprout
```

### **On Autosave:**
```
DataService: Autosaved profile for 12345
```

### **On Leave:**
```
GardenManager: Player leaving: PlayerName
GardenManager: Saved plant states for plot Plot_3
DataService: Player leaving: PlayerName
DataService: Saving profile for UserId 12345
DataService: Successfully saved profile for 12345
```

### **On Shutdown:**
```
DataService: Server shutting down, saving all profiles...
DataService: Saving profile for UserId 12345
DataService: Successfully saved profile for 12345
DataService: All profiles saved on shutdown
```

---

## 🎮 Admin Commands for Testing

Use these commands with the admin console (`/` key):

```
/addcoins 1000          # Test coin persistence
/addseeds Glowbud 5     # Test inventory persistence
/setweather Rainy       # Test weather (not saved)
/grow                   # Speed up plant growth for testing
/clear                  # Clear garden to test state updates
```

---

## 🚀 Next Steps (Future)

- [ ] ProfileService for session locking (prevent data loss on server hop)
- [ ] OrderedDataStores for global leaderboards
- [ ] Offline growth calculations (time-based when offline)
- [ ] Co-op plots (shared ownership)
- [ ] Trade system between players
- [ ] Global market for selling plants

---

## 📊 Current Configuration

- **DataStore Name**: `FeyGarden_Player_v1`
- **Autosave Interval**: 60 seconds
- **Max Retries**: 5 attempts with exponential backoff
- **Starting Coins**: 100 (Config.Economy.StartingCoins)
- **Starting Seeds**: 2 Glowbud, 3 Dewleaf

---

## ✨ Success Criteria

The system is working correctly when:
1. ✅ Players can join, play, leave, rejoin and see their progress restored
2. ✅ Multiple players can play simultaneously with separate plots
3. ✅ Coins, inventory, and plants persist across sessions
4. ✅ Autosave works (check Output every 60s)
5. ✅ Shutdown save protects data when server stops
6. ✅ Leaderstats shows current coins for all players

Ready to test! 🎉
