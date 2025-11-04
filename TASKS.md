# FeyGarden Development Tasks

**Last Updated:** October 31, 2025  
**Project:** FeyGarden V4  
**Status:** In Development

---

## 🔴 Critical Priority

### 1. Fix Weather System
- [ ] Weather transitions not working properly
- [ ] Weather effects not syncing to all clients
- [ ] Weather multipliers not applying to plant growth
- [ ] Add visual weather effects (rain particles, storm clouds, etc.)
- [ ] Test weather cycle timing (currently 60 seconds)
- [ ] Verify weather sounds play correctly on transitions

### 2. Fix Plant Position Offsets
- [ ] Apply `Constants.STAGE_OFFSETS` to all plant spawning
- [ ] Update GardenManager to use position offsets when creating plants
- [ ] Ensure Seed stage appears at Y=0.5 offset
- [ ] Ensure Sprout stage appears at Y=1.5 offset
- [ ] Ensure Bloom stage appears at Y=2.5 offset
- [ ] Test all 15 plant types at each growth stage
- [ ] Fix plants appearing underground or floating

### 3. Fix Sound Effects System
- [ ] Replace placeholder `rbxassetid://` with actual audio IDs
- [ ] Test all SFX triggers (plant, water, harvest, dig, etc.)
- [ ] Verify music tracks loop correctly
- [ ] Add volume sliders to settings UI
- [ ] Test 3D positional audio for world events
- [ ] Ensure sounds cleanup properly (no memory leaks)
- [ ] Add mute/unmute toggle buttons

### 4. Improve UI/UX

- [x] Add NPC system with dialog interface ✅ **COMPLETED**
  - Created NPCModule with 4 NPCs (Gardener, Merchant, Mystic, Collector)
  - Built NPCUIHandler with slide-in panel from right side
  - 3D viewport showing animated NPC model
  - Dialog system with typewriter effect
  - 4 interactive NPC buttons at top-center with tooltips
- [x] Improve UI button interactions ✅ **COMPLETED**
  - Added hover effects to all buttons
  - Added tooltips to NPC buttons
  - Better visual feedback
- [ ] Add loading screen during initial data fetch
- [ ] Add confirmation dialogs for selling items
- [ ] Improve shop layout (better organization by category)
- [ ] Add search/filter functionality to shop
- [ ] Show player statistics (total plants grown, coins earned, etc.)
- [ ] Add settings menu (audio, graphics, keybinds)
- [ ] Improve mobile responsiveness
- [ ] Add camera movement when talking to NPCs
- [ ] Add proximity triggers for NPCs in world

---

## 🟡 High Priority

### Core Gameplay Systems

#### Plant System
- [ ] Add plant watering visual indicators (dry/watered states)
- [ ] Implement plant death/withering if not watered
- [ ] Add seasonal variants for plants
- [ ] Create plant breeding/cross-pollination system
- [ ] Add rare/legendary plant variants
- [ ] Implement plant mutations
- [ ] Add visual growth animations between stages

#### Pet System
- [ ] Create 3D pet models (currently using placeholders)
- [ ] Add pet following animations (walk, idle, etc.)
- [ ] Implement pet happiness/hunger system
- [ ] Add pet leveling and experience
- [ ] Create pet abilities/special effects
- [ ] Add pet customization (colors, accessories)
- [ ] Implement pet breeding system
- [ ] Add pet inventory management

#### Garden System
- [ ] Add garden customization (decorations, fences, paths)
- [ ] Implement garden expansion (unlock more slots)
- [ ] Add garden themes/biomes
- [ ] Create sprinkler system for auto-watering
- [ ] Add scarecrow for plant protection
- [ ] Implement fertilizer system for growth boost
- [ ] Add compost bin for recycling plants

#### Economy System

- [x] Balance seed prices and fruit sell prices ✅ **COMPLETED**
  - Removed confusing `SellPrice` field
  - Created 3-tier progression (Starter → Mid-game → Rare)
  - Balanced for fast early hook, long-term engagement
  - Profit ranges from 15 coins (Lumut) to 600 coins (Willowwhisp)
  - ROI increases from 100% to 200% as you progress
- [ ] Add daily quests for bonus coins
- [ ] Implement achievement rewards
- [ ] Create VIP/premium currency system
- [ ] Add trading system between players
- [ ] Implement auction house
- [ ] Add daily login rewards
- [ ] Create seasonal events with special rewards

---

## 🟢 Medium Priority

### Visual & Effects

#### VFX System
- [ ] Create custom particle effects for each plant type
- [ ] Add harvest sparkle effects
- [ ] Implement weather visual effects
- [ ] Add pet trail particles
- [ ] Create magic circle effects for planting
- [ ] Add glow effects for rare plants
- [ ] Implement day/night cycle visuals

#### UI Improvements
- [ ] Add minimap showing garden layout
- [ ] Create inventory sorting options
- [ ] Add plant encyclopedia/compendium
- [ ] Implement tutorial system for new players
- [ ] Add keybind customization menu
- [ ] Create leaderboard system
- [ ] Add friend list and visiting system

### Social Features
- [ ] Implement player-to-player visits
- [ ] Add garden showcase/rating system
- [ ] Create guild/club system
- [ ] Add chat system
- [ ] Implement gift sending
- [ ] Add cooperative gardening events
- [ ] Create photo mode for gardens

---

## 🔵 Low Priority

### Polish & Quality of Life

#### Optimization
- [ ] Implement object pooling for plants
- [ ] Optimize network replication
- [ ] Add LOD (Level of Detail) for distant objects
- [ ] Reduce server memory usage
- [ ] Optimize client rendering
- [ ] Add graphics quality settings

#### Admin Tools
- [ ] Create admin panel UI
- [ ] Add player management commands
- [ ] Implement economy debugging tools
- [ ] Add analytics dashboard
- [ ] Create ban/kick system
- [ ] Add announcement system

#### Accessibility
- [ ] Add colorblind mode options
- [ ] Implement screen reader support
- [ ] Add text scaling options
- [ ] Create controller support
- [ ] Add language localization system
- [ ] Implement auto-save indicators

---

## 📋 Content Creation Needed

### Assets Required
- [ ] 15 plant 3D models (Seed, Sprout, Bloom stages)
- [ ] 15 pet 3D models with animations
- [ ] Garden decoration models (50+)
- [ ] UI icons and graphics
- [ ] Sound effects library (30+ sounds)
- [ ] Background music tracks (5+ tracks)
- [ ] Particle effect textures
- [ ] Loading screen artwork

### Documentation
- [ ] Player guide/wiki
- [ ] Developer documentation
- [ ] API reference for future features
- [ ] Balance spreadsheet (prices, growth times, etc.)
- [ ] Bug tracking system setup

---

## 🐛 Known Bugs to Fix

### High Priority Bugs
- [ ] Pets sometimes don't spawn visually (workspace shows but not rendered)
- [ ] Plant slots occasionally show wrong plant type after harvest
- [ ] Sell window doesn't always refresh after selling
- [ ] Audio sometimes fails to load on first join
- [ ] Data sometimes fails to save on server shutdown

### Medium Priority Bugs
- [ ] UI windows can overlap incorrectly
- [ ] Notification spam when multiple actions occur quickly
- [ ] Pet boost not applying correctly to all plants in range
- [ ] Weather change doesn't update all plant growth speeds immediately
- [ ] Coins display sometimes desyncs from server value

### Low Priority Bugs
- [ ] Shop items sometimes appear in wrong order
- [ ] PlantAnchor transparency setting doesn't apply in all cases
- [ ] Tool cooldown visual not always accurate
- [ ] Garden sign text occasionally doesn't update

---

## 🎯 Version Milestones

### Version 0.5 (Current - Bug Fixes)
- [x] Core planting system
- [x] Basic UI framework
- [x] Pet equipping system
- [x] Shop and sell systems
- [ ] Weather system fixes
- [ ] Plant offset fixes
- [ ] Sound system completion
- [ ] UI/UX improvements

### Version 0.6 (Content Update)
- [ ] All plant 3D models
- [ ] All pet 3D models
- [ ] Advanced pet system
- [ ] Garden decorations
- [ ] Achievement system

### Version 0.7 (Social Update)
- [ ] Player visits
- [ ] Trading system
- [ ] Guild system
- [ ] Leaderboards

### Version 1.0 (Full Release)
- [ ] All features complete
- [ ] All bugs fixed
- [ ] Performance optimized
- [ ] Tutorial system
- [ ] Full documentation
- [ ] Mobile support

---

## 📝 Notes

### Development Priorities
1. Fix critical systems first (weather, offsets, audio)
2. Improve core gameplay loop (plant → grow → harvest → sell)
3. Add content variety (more plants, pets, decorations)
4. Implement social features for retention
5. Polish and optimize for release

### Testing Checklist
- [ ] Test all 15 plant types through full growth cycle
- [ ] Test all 15 pets for equipping and boosting
- [ ] Test weather changes affect growth correctly
- [ ] Test UI on different screen sizes
- [ ] Test with multiple players in same garden
- [ ] Performance test with 100+ plants
- [ ] Mobile device testing
- [ ] Network latency testing

### Future Considerations
- Seasonal events system
- Battle pass / progression system
- Mini-games within garden
- Fishing system
- Cooking/crafting system
- Housing/interior decoration
- Pet battles/competitions

---

**Remember:** Focus on making core mechanics solid before adding new features!
