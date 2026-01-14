# FeyGarden Copilot Instructions

A Roblox farming simulator in Luau with multiplayer gardens, pets, weather-based growth multipliers, and persistence.

## Development Workflow

**Local development:** Run `serve.ps1` (executes `rojo serve`) for live sync with Roblox Studio via Rojo plugin. Build place file with `build.ps1` (runs `rojo build -o FeyGarden.rbxl`).

**Rojo mapping** (`default.project.json`):
- `src/shared` → `ReplicatedStorage/Shared`
- `src/server` → `ServerScriptService/Server`
- `src/client` → `StarterPlayer/StarterPlayerScripts/Client`
- `src/admin` → `ServerScriptService/Admin`
- `src/tools` → `ReplicatedStorage/ToolScripts`
- `src/setup` → `ReplicatedStorage/Setup`

**UI regeneration:** Run `src/setup/UISetup.luau` once in Studio to create GUI structure. UI consumed from `StarterGui` by `UIHandler`.

## Architecture & Data Flow

### Server Initialization Order (`MainServer.server.luau`)
1. Wait for `ReplicatedStorage/Shared` folder (Constants, Config)
2. **Load DataService first** (persistence layer with session locks)
3. Require services that create RemoteEvents on load: `WeatherController`, `EconomyService`, `ToolServer`, `GardenManager`, `ShopService`, `TradingService`
4. Initialize systems (weather cycling, economy sync, garden assignments)
5. Create leaderstats with 1s polling loop to mirror DataService coins

**Critical:** Services create RemoteEvents during `require()`, not initialization. Server must load before client connects.

### Client Initialization Order (`MainClient.client.luau`)
1. Wait for `ReplicatedStorage/Shared` and Constants
2. Wait for CharacterAdded
3. Initialize immediately (no delay): `UIHandler` → `NPCUIHandler` → `TutorialUI` → `PetController` → `BuffParticles` → `PlantingHandler` → `EggOpeningUI`
4. `PlantingHandler.SetSelectedPlantProvider(UIHandler.GetSelectedPlantType)` links planting to UI selection

### Persistence Layer (`src/server/Persistence`)

**DataService** wraps DataStoreService with:
- Session locking (10-min timeout) to prevent cross-server data conflicts
- Autosave every 120s with retry/exponential backoff (MAX_RETRIES=3)
- Public getters: `GetCoins`, `GetInventory`, `GetAllPlantSlots`, `IsDataLoaded`
- Public setters: `AddCoins`, `RemoveCoins`, `AddSeed`, `RemoveSeed`, `AddPet`, etc.
- `ForceSave(userId)` called by GardenManager after plant writes
- **Always check `DataService.IsDataLoaded(userId)` before accessing profile**

**Schema** (`Schema.luau`):
- Version 1 structure with migration support
- Defaults: **1,000,000,000 starting coins** (placeholder for testing), empty inventories, EquippedPets (max 2), GardenPets (max 5) arrays
- `Config.Economy.EnablePersistence` flag gates actual saving

### Garden System (`src/server/GardenManager.luau`)

**Expected workspace structure:**
```
workspace/Gardens/Garden1..10/
  ├─ Plots/PlantAnchor1..16  (Parts with ClickDetectors)
  ├─ PlayerSign/Sign  (Part with SurfaceGui > TextLabel)
  ├─ TpPart  (spawn location, optional)
  └─ Floor  (main platform)
```

**Flow:**
1. `bootstrapGardens()` clears `OwnerUserId` attributes, adds ClickDetectors to anchors
2. `Config.Garden.AssignOnJoin=true` assigns garden on PlayerAdded, teleports to TpPart, updates sign color/text
3. `RestorePlantsOnJoin=true` reads DataService plant slots, spawns models at anchors, starts growth loops
4. Planting: `Constants.EVENTS.PLANT_SEED` RemoteEvent → validates slot index (1..`SlotsPerGarden`) → consumes seed via EconomyService → creates plant at anchor → caches → starts growth
5. Harvesting: `HARVEST_PLANT` or click Bloom-stage detector → pays fruit value → clears slot → syncs inventory
6. `FreeOnLeave=true` releases garden; `SavePlantsOnLeave=true` persists slots to DataStore

**Known issue (TASKS.md):** Plants spawn at anchor Y=0 instead of applying `Constants.STAGE_OFFSETS` (Seed +0.5, Sprout +1.5, Bloom +2.5). Manually offset `anchorPosition + offset` in spawning code.

### Plant Growth (`src/shared/PlantModule.luau` + `BuffsModule.luau`)

**Assets:** Clone from `ReplicatedStorage/Plants/<plantType>/{seed, plant}` (15 types in `Constants.PLANT_TYPES`).

**Attributes on plant models:**
- `PlantType` (string), `Stage` (Seed/Sprout/Bloom), `WateredUntil` (tick), `PetBoost` (bool)

**Growth stages:** `GrowPlant()` loops Seed → Sprout → Bloom using:
- Base time from `Constants.PLANT_CONFIG[plantType].GrowthTime`
- Multiplier from `BuffsModule.CalculateGrowthMultiplier(plant)`:
  - Weather: `Config.Buffs.Weather[currentWeather]` (Rainy 0.8x faster, Stormy 1.2x)
  - Watered: Linear decay over `Config.Tools.WateringCan.WaterSeconds` (e.g., 30s)
  - Pet boost: +10% if `PetBoost` attribute set by PetController proximity check
- Bloom stage sets `Harvestable=true`, triggers `SetupPlantHarvestDetector` for click-to-collect fruit

**Case-insensitive folder lookup:** `findPlantFolder()` uses `string.lower()` partial matching for asset names.

### Weather Cycling (`src/server/WeatherController.luau`)

Cycles every `Constants.WEATHER_CYCLE_TIME` (60s) through `WEATHER_TYPES.SUNNY/RAINY/STORMY`.
- Tweens Lighting properties (Brightness, ColorShift_Top, ClockTime)
- Updates `BuffsModule.SetCurrentWeather(weather)` for growth calculations
- Fires `Constants.EVENTS.WEATHER_CHANGED` RemoteEvent to all clients for particle FX

**Known issue (TASKS.md):** Weather FX not syncing reliably; verify WeatherEffects.client.luau receives events.

### Economy System (`src/server/EconomyService.luau`)

**RemoteEvents:** BuySeed, BuyPet, BuyEgg, OpenEgg, EquipPet, UnequipPet, AddGardenPet, RemoveGardenPet, SellFruit.

**Data source:** All mutations go through DataService (seeds/pets/fruits/eggs in `profile.Inventory`).

**New player detection:** `coins==100 AND empty inventory` triggers starter seed gift (Constants.STARTER_SEEDS).

**Sync:** `SyncPlayerData(player)` fires UpdateCurrency + UpdateInventory RemoteEvents with full inventory state (Seeds, Pets, Eggs, Fruits, EquippedPets, GardenPets).

**Price config:** `Constants.PLANT_CONFIG` (SeedPrice, FruitSellPrice), `PET_CONFIG` (Price, Boost), `EGG_CONFIG` (Price, Chances).

**Profit formula:** `FruitSellPrice - SeedPrice = Net Profit`. Three-tier progression: Starter (100-200% ROI), Mid-game (150-180%), Rare (200%+). Example: Lumut seed 15c → fruit 30c = +15c profit.

### Shop System (`src/server/ShopService.luau`)

Rotating seed inventory driven by `Constants.SEED_SHOP_CONFIG`:
- `SlotsPerRarity` (Common: 3, Uncommon: 2, Rare: 1)
- `AppearanceChance` weighted rolls
- `StockCounts` (5-10-15 per rarity)
- 12-hour refresh cycle

**Interface:** `GetShopInventory` RemoteFunction returns `{plantType, stock, price}` array. `ShopInventoryUpdate` RemoteEvent broadcasts refreshes. EconomyService checks stock before purchase.

### Trading System (`src/server/TradingService.luau`)

Peer-to-peer with `Constants.TRADING_CONFIG`:
- MaxItemsPerTrade (10), RequestTimeout (30s), ConfirmTimeout (60s), MaxTradeDistance (50 studs), RequestCooldown (5s)
- Validates via DataService (pets must not be equipped/in garden)
- RemoteEvents: TradeRequest, TradeResponse, TradeUpdate, TradeConfirm, TradeCancel, TradeComplete, TradeIncoming

### Client-Side Behaviors

**Planting** (`PlantingHandler.luau`): After 2s delay, finds garden by `OwnerUserId` attribute match, attaches click handlers to anchors with ClickDetectors, reads `UIHandler.GetSelectedPlantType()`, fires `PLANT_SEED` RemoteEvent with slot index from anchor name (`PlantAnchor5` → index 5).

**Pets** (`PetController.luau`): Spawns equipped (max 2, follow player) and garden pets (max 5, roam garden center) from `ReplicatedStorage/Pets/<petType>`. Uses BodyPosition/BodyGyro for floaty physics, PointLight with pet color. Every 5s proximity check within 12 studs sets `PetBoost` attribute on plants.

**UI** (`UIHandler.luau`): Prebuilt structure from `StarterGui`. Handles hotbar, inventory, shop/sell windows, weather HUD, currency display, notifications. Plays sounds via optional `AudioManager`. Theme: Gotham fonts, fantasy palette (blues/purples/golds).

## Configuration & Constants

**Config.luau** documents world hierarchy (detailed comments on GardensFolder, Plots, Sign, TpPart naming). Feature flags: `Config.Garden.AssignOnJoin`, `Config.Economy.EnablePersistence`, `Config.Buffs.Weather`.

**Constants.luau** defines:
- `EVENTS` table (all RemoteEvent names—avoid duplication)
- `PLANT_CONFIG` (15 plant types with GrowthTime, SeedPrice, FruitSellPrice)
- `PET_CONFIG`, `EGG_CONFIG`, `TRADING_CONFIG`, `SEED_SHOP_CONFIG`
- `STAGE_OFFSETS` (Vector3 Y offsets per growth stage)
- `WEATHER_TYPES`, `WEATHER_CONFIG` (multipliers, lighting params)

**Placeholder assets:** Many `rbxassetid://` IDs in audio/VFX configs are TODOs (see TASKS.md). `VFXModule` provides fallback sparkles if emitters missing.

## Common Patterns & Pitfalls

1. **Module load order:** Always wait for `ReplicatedStorage/Shared` before requiring Constants/Config. Server must require services before client connects (RemoteEvents created on require).
2. **Persistence guards:** Check `DataService.IsDataLoaded(userId)` before accessing profiles. Respect `Config.Economy.EnablePersistence` flag.
3. **Plant positioning:** Manually apply `Constants.STAGE_OFFSETS` when spawning (current code spawns at anchor Y=0).
4. **Asset existence:** `ReplicatedStorage/Plants/<type>`, `ReplicatedStorage/Pets/<type>` must exist or plant/pet creation warns and fails.
5. **Garden naming:** Keep consistent naming (`Garden1..10`, `PlantAnchor1..16`, `PlayerSign/Sign`) per Config.World.
6. **Default coins:** Schema uses 1B starting coins for testing; adjust for production.
7. **Remote event names:** Use `Constants.EVENTS` table to avoid string typos and duplicates.

## Priority Tasks (TASKS.md)

**Critical:** Weather FX sync, plant stage Y offsets, sound system finalization (replace placeholder asset IDs).

**High:** UI polish (loading screen, confirmations, settings menu), pet model replacements, garden expansion system.

Refer to `TASKS.md` for detailed roadmap and align fixes with listed priorities.
