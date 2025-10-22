# 🌿 FeyGarden - MVP Features Testing Checklist

Use this checklist to verify all features are working correctly!

## 🎮 Initial Game Load

- [ ] Game loads without errors
- [ ] Character spawns correctly
- [ ] Garden plot is created for player
- [ ] Plot has player's name on the sign
- [ ] UI elements appear (currency, weather, inventory, shop button)
- [ ] Starting currency shows 200 coins
- [ ] Starting seeds appear in inventory

## 🌤️ Weather System

- [ ] Weather indicator shows current weather (☀️ Sunny initially)
- [ ] Lighting changes match weather type
- [ ] Weather changes after ~60 seconds
- [ ] All three weather types cycle: Sunny, Rainy, Stormy
- [ ] Weather icon updates in UI
- [ ] Brightness changes visible
- [ ] Color tints apply correctly

## 🌱 Planting System

- [ ] Can select a seed from inventory
- [ ] Selected seed highlights or gives feedback
- [ ] Can click on garden plot floor to plant
- [ ] Plant appears at clicked location
- [ ] Seed count decreases in inventory
- [ ] Multiple plants can be placed (up to 9)
- [ ] Plants appear as small seeds initially

## 🌿 Growth System

- [ ] Plants start at "Seed" stage
- [ ] Plants grow to "Sprout" stage after time
- [ ] Plants grow to "Bloom" stage after more time
- [ ] Visual size changes between stages
- [ ] Glowbud emits light when bloomed
- [ ] Growth speed changes with weather
- [ ] Rainy weather makes plants grow faster
- [ ] Stormy weather affects growth differently

## 💰 Economy System

- [ ] Shop button opens shop window
- [ ] Shop shows seed prices correctly
- [ ] Shop shows pet prices correctly
- [ ] Can buy seeds with coins
- [ ] Coins decrease after purchase
- [ ] Seeds added to inventory after purchase
- [ ] Can't buy if not enough coins
- [ ] Inventory updates immediately

## 🌸 Harvesting System

- [ ] Can click on fully grown (Bloom) plants
- [ ] Plant disappears when harvested
- [ ] Coins increase after harvest
- [ ] Glowbud gives 150 coins
- [ ] Dewleaf gives 80 coins
- [ ] Plot space freed up after harvest
- [ ] Can plant new seeds in harvested spot

## 🐾 Pet System

- [ ] Can buy Sprig pet for 300 coins
- [ ] Pet spawns near player after purchase
- [ ] Pet follows player smoothly
- [ ] Pet has bobbing animation
- [ ] Pet glows green
- [ ] Pet stays at set distance from player
- [ ] Pet respawns when player respawns
- [ ] Can't buy duplicate pets

## 🎨 User Interface

### Currency Display
- [ ] Shows correct coin amount
- [ ] Updates when earning coins
- [ ] Updates when spending coins
- [ ] Positioned top right
- [ ] Easy to read

### Weather Display
- [ ] Shows current weather
- [ ] Weather emoji matches type
- [ ] Updates when weather changes
- [ ] Positioned top left

### Inventory
- [ ] Shows all owned seed types
- [ ] Shows seed counts
- [ ] Updates when buying seeds
- [ ] Updates when planting seeds
- [ ] Seeds are clickable to select

### Shop Window
- [ ] Opens/closes with shop button
- [ ] Close button works
- [ ] Lists all plant types
- [ ] Lists all pet types
- [ ] Shows correct prices
- [ ] Buy buttons work
- [ ] Scrollable if needed

## 🔧 Multiplayer Testing

- [ ] Each player gets their own plot
- [ ] Plots don't overlap
- [ ] Players can see each other's gardens
- [ ] Currency is separate per player
- [ ] Inventory is separate per player
- [ ] Players can't harvest other's plants
- [ ] Multiple players' pets work simultaneously

## 🐛 Edge Cases

- [ ] Can't plant with 0 seeds
- [ ] Can't harvest unripe plants
- [ ] Can't exceed 9 plants per plot
- [ ] Can't buy with insufficient coins
- [ ] Weather changes affect all plants
- [ ] Leaving and rejoining works (no persistence yet)

## 📊 Performance

- [ ] Game runs smoothly (60 FPS)
- [ ] No lag when planting
- [ ] No lag when harvesting
- [ ] Weather changes are smooth
- [ ] Pet follows without stuttering
- [ ] UI is responsive

## 🎯 Fun Factor!

- [ ] Satisfying to watch plants grow
- [ ] Weather adds variety to gameplay
- [ ] Pet is cute and fun to have
- [ ] Economic progression feels good
- [ ] Want to keep playing!

---

## 📝 Notes

**Issues Found:**
- [List any bugs or issues you discover]

**Suggestions:**
- [List any improvements or new features you'd like]

**Overall Rating:** ⭐⭐⭐⭐⭐ (out of 5)

---

**Testing Date:** _________________

**Tester Name:** _________________

**Version:** MVP 1.0
