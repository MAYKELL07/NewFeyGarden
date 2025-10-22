# 🌿 FeyGarden - Magical Farming Simulator

A cozy farming simulation game built for Roblox where players cultivate magical plants in a dynamic environment affected by weather and supported by pets.

## ✨ Features (MVP)

### Core Systems
- **🌱 Plant Growth System**: Time-based growth stages (Seed → Sprout → Bloom)
- **🌤️ Dynamic Weather**: Weather cycles that affect plant growth (Sunny, Rainy, Stormy)
- **🐾 Pet Companions**: AI pets that follow players and boost plant growth
- **💰 Economy System**: Buy seeds, sell harvested plants, purchase pets
- **🏡 Garden Plots**: Personal plots for each player with 3x3 planting grid
- **🎨 Interactive UI**: Shop, inventory, currency display, and weather indicator

### Plant Types
- **Glowbud**: Emits light when blooming, sells for 150 coins
- **Dewleaf**: Grows faster in rain, sells for 80 coins

### Weather Effects
- **Sunny**: Normal growth (1.0x multiplier)
- **Rainy**: Faster growth (0.8x multiplier)
- **Stormy**: Even faster growth (1.2x multiplier)

### Pets
- **Sprig**: Green glowing companion that boosts plant growth by 10%

## 🚀 Getting Started

### Prerequisites
- Roblox Studio (2025 build)
- Rojo CLI tool
- VS Code (recommended)

### Installation

1. **Clone or download this project**
   ```bash
   cd NewFeyGarden
   ```

2. **Install Rojo** (if not already installed)
   Follow instructions at: https://rojo.space/

3. **Serve the project with Rojo**
   ```bash
   rojo serve
   ```

4. **Connect in Roblox Studio**
   - Open Roblox Studio
   - Install the Rojo plugin if you haven't
   - Click "Connect" in the Rojo plugin
   - The project will sync automatically

5. **Build the place file** (optional)
   ```bash
   rojo build -o FeyGarden.rbxl
   ```

## 📁 Project Structure

```
NewFeyGarden/
├── src/
│   ├── client/               # Client-side scripts
│   │   ├── init.client.luau      # Main client initializer
│   │   ├── UIHandler.client.luau  # UI management
│   │   └── PetController.client.luau # Pet following logic
│   ├── server/               # Server-side scripts
│   │   ├── init.server.luau       # Main server initializer
│   │   ├── WeatherController.server.luau  # Weather system
│   │   ├── GardenManager.server.luau      # Plot & plant management
│   │   └── EconomyService.server.luau     # Currency & transactions
│   └── shared/               # Shared modules
│       ├── Constants.luau         # Game constants & config
│       ├── PlantModule.luau       # Plant growth logic
│       └── Hello.luau             # (legacy, can be removed)
├── default.project.json      # Rojo project configuration
├── aftman.toml              # Tool configuration
└── README.md                # This file
```

## 🎮 How to Play

1. **Start the game** in Roblox Studio (press F5)
2. **You'll spawn** with a personal garden plot and starting currency (200 coins)
3. **Open the shop** (🛒 button) to buy seeds
4. **Select a seed** from your inventory (bottom left)
5. **Click on your garden plot floor** to plant seeds
6. **Wait for plants to grow** - weather affects growth speed!
7. **Click fully grown plants** to harvest them
8. **Sell harvested plants** for coins automatically
9. **Buy a pet** from the shop to boost growth rates
10. **Repeat and expand** your magical garden!

## ⚙️ Configuration

Edit `src/shared/Constants.luau` to adjust:
- Weather cycle duration
- Plant growth times
- Prices for seeds and pets
- Plot sizes and plant limits
- Growth multipliers

## 🛠️ Development

### Adding New Plants
1. Add plant type to `Constants.PLANT_TYPES`
2. Add configuration in `Constants.PLANT_CONFIG`
3. Plants will automatically appear in the shop

### Adding New Pets
1. Add pet type to `Constants.PET_TYPES`
2. Add configuration in `Constants.PET_CONFIG`
3. Pets will automatically appear in the shop

### Adding New Weather Types
1. Add weather type to `Constants.WEATHER_TYPES`
2. Add configuration in `Constants.WEATHER_CONFIG`
3. Weather will automatically cycle through all types

## 📋 MVP Checklist

- [x] Plant growth system with stages
- [x] Dynamic weather affecting growth
- [x] Garden plot assignment per player
- [x] Basic economy (coins, buying, selling)
- [x] Seed inventory system
- [x] Pet companions with follow behavior
- [x] Interactive UI (shop, inventory, currency)
- [x] Two plant types (Glowbud, Dewleaf)
- [x] Weather indicator
- [x] Click to plant and harvest

## 🔮 Future Enhancements

- [ ] Multiplayer co-op gardens
- [ ] Seasonal events and festivals
- [ ] Rare weather events (Aurora, Eclipse)
- [ ] Pet evolution system
- [ ] Garden decoration editor
- [ ] DataStore persistence
- [ ] More plant varieties
- [ ] Fertilizer and tools
- [ ] Achievement system
- [ ] Leaderboards

## 🐛 Known Issues

- DataStore not implemented (progress doesn't save between sessions)
- Plants don't respond to pet proximity yet (global boost only)
- No animation for planting/harvesting
- No sound effects

## 📝 License

This is a personal project for learning purposes.

## 🤝 Contributing

This is an MVP for learning. Feel free to fork and extend!

---

**Built with ❤️ using Roblox Studio, Rojo, and Luau**

Generated by [Rojo](https://github.com/rojo-rbx/rojo) 7.6.0.

## Getting Started
To build the place from scratch, use:

```bash
rojo build -o "NewFeyGarden.rbxlx"
```

Next, open `NewFeyGarden.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).