# Garden Setup Guide

This guide explains how to set up the 10 pre-made gardens in your Roblox Studio workspace.

## Garden Structure Overview

Each garden should be a **Folder** (not Model) containing:

- **Floor** part (where players can walk)
- **PlayerSign** Model containing:
  - **Sign** part with SurfaceGui showing current player name
- **Plots** folder containing:
  - **16 PlantAnchors** (PlantAnchor1 through PlantAnchor16) positioned in a 4x4 grid

**Complete Hierarchy:**

```
workspace
  └─ Gardens (Folder)
       ├─ Garden1 (Folder)
       │    ├─ Floor (Part)
       │    ├─ PlayerSign (Model)
       │    │    └─ Sign (Part with SurfaceGui > TextLabel)
       │    └─ Plots (Folder)
       │         ├─ PlantAnchor1 (Part)
       │         ├─ PlantAnchor2 (Part)
       │         └─ ... (up to PlantAnchor16)
       └─ ... (Garden2 through Garden10)
```

## Step-by-Step Setup

### 1. Create Gardens Folder

1. In **Workspace**, create a **Folder** named `Gardens`

### 2. Create a Garden Template

#### Garden Folder

1. Inside `Gardens`, create a **Folder** (not Model!)
2. Name it `Garden1`

#### Floor Part

1. Inside `Garden1`, create a **Part** named `Floor`
2. Recommended size: `20, 0.5, 20` studs (or adjust to your preference)
3. Set **Anchored** to `true`
4. Set **Color** to grass green (e.g., `0, 180, 0` RGB)

#### PlayerSign Model

1. Inside `Garden1`, create a **Model** named `PlayerSign`
2. Inside the `PlayerSign` Model, create a **Part** named `Sign`
3. Recommended size: `4, 6, 0.5` studs
4. Position it at the entrance/edge of the garden
5. Set **Anchored** to `true`
6. Add a **SurfaceGui** to the `Sign` part:
   - Set **Face** to `Front`
   - Set **Adornee** to the `Sign` part (if needed)
7. Inside the SurfaceGui, add a **TextLabel**:
   - Set **Size** to `{1, 0}, {1, 0}` (full size)
   - Set **Text** to `"Available"` (default)
   - Set **TextScaled** to `true`
   - Set **Font** to `SourceSansBold`
   - Set **BackgroundTransparency** to `1`
   - Set **TextColor3** to white

#### Plots Folder with PlantAnchors

1. Inside `Garden1`, create a **Folder** named `Plots`
2. Inside the `Plots` folder, create 16 **Parts**
3. Name them `PlantAnchor1`, `PlantAnchor2`, ... `PlantAnchor16`
4. For each anchor:
   - Set **Size** to `1, 0.5, 1` studs (small marker)
   - Set **Transparency** to `0.5` (semi-visible for setup, can be changed to `1` later)
   - Set **Anchored** to `true`
   - Set **CanCollide** to `false`
   - Optional: Set **Color** to brown (e.g., `139, 69, 19` RGB)

5. **Position the anchors in a 4x4 grid** (example positions relative to garden center):

   ```
   Row 1: PlantAnchor1  PlantAnchor2  PlantAnchor3  PlantAnchor4
   Row 2: PlantAnchor5  PlantAnchor6  PlantAnchor7  PlantAnchor8
   Row 3: PlantAnchor9  PlantAnchor10 PlantAnchor11 PlantAnchor12
   Row 4: PlantAnchor13 PlantAnchor14 PlantAnchor15 PlantAnchor16
   ```

   **Example positions** (assuming Floor at Y=0.25, spacing of 4 studs):
   - PlantAnchor1: `(-6, 0.75, -6)`
   - PlantAnchor2: `(-2, 0.75, -6)`
   - PlantAnchor3: `(2, 0.75, -6)`
   - PlantAnchor4: `(6, 0.75, -6)`
   - PlantAnchor5: `(-6, 0.75, -2)`
   - ... and so on in a grid pattern

   > **Tip**: Use the **Move** tool with **Grid Snap** enabled (4 studs) for precise positioning

### 3. Duplicate for All 10 Gardens

1. **Duplicate** `Garden1` 9 times (select the folder and Ctrl+D)
2. Rename the copies to: `Garden2`, `Garden3`, ... `Garden10`
3. **Spread them out** in the workspace so they don't overlap
   - Recommended spacing: 30-40 studs apart
   - You can arrange them in rows (e.g., 2 rows of 5 gardens each)

### 4. Optional Customization

- Add decorative parts (fences, rocks, flowers) to each garden
- Make each garden unique with different colors/themes
- Add lighting for atmosphere
- Create paths between gardens
- Customize PlantAnchor transparency (set to `1` to make invisible in game)

## Configuration Reference

The following values in `Config.luau` control the garden system:

```lua
Config.World.GardensFolder = "Gardens"       -- Folder name in Workspace
Config.World.PlayerSignName = "PlayerSign"   -- Name of PlayerSign Model
Config.World.PlayerSignPartName = "Sign"     -- Name of Part within PlayerSign
Config.World.PlotsFolder = "Plots"           -- Name of folder containing PlantAnchors

Config.Garden.SlotsPerGarden = 16            -- Must match number of PlantAnchors
Config.Garden.PlantAnchorPrefix = "PlantAnchor"  -- Prefix before slot number
Config.Garden.GardenNames = {                -- Expected garden names
    "Garden1", "Garden2", ... "Garden10"
}
```

## Testing

After setup, test in Roblox Studio:

1. **Press Play** in Studio
2. Your player should be **automatically assigned** a garden (check the PlayerSign)
3. **Buy seeds** from the shop (🛒 SHOP button)
4. **Click a seed** in inventory to select it
5. **Click anywhere** in your garden to plant (system will find next available slot)
6. Watch the plant grow!

## Troubleshooting

**No garden assigned?**
- Check that `Gardens` folder exists in Workspace
- Verify garden names match config: `Garden1`, `Garden2`, etc.
- Check console for errors (View → Output)

**Plants not appearing?**
- Verify PlantAnchors are named correctly: `PlantAnchor1` through `PlantAnchor16`
- Check that anchors are inside the garden Model
- Ensure PlantAnchors have `Anchored = true` and `CanCollide = false`

**PlayerSign not updating?**
- Verify the sign has a SurfaceGui with a TextLabel child
- Check that part is named exactly `PlayerSign`

## Advanced: Custom Layouts

You can customize the PlantAnchor positions to create unique garden layouts:
- **Circular pattern** instead of grid
- **Irregular spacing** for organic look
- **Different heights** for terraced gardens

Just ensure you have exactly **16 PlantAnchors** named `PlantAnchor1` to `PlantAnchor16`.

---

**Note**: After creating the gardens, you may want to set PlantAnchor **Transparency** to `1` (invisible) so they don't show in the final game.
