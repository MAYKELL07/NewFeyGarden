# 🎨 General Game UI Design Document  
**Theme:** Fantasy Nature / Enchanted Forest  
**Platform:** Roblox  
**UI Type:** Stylized 2D Interface  

---

## 🌿 1. Visual Direction

### **Art Style**
- **Core Aesthetic:** Hand-painted fantasy style with natural, organic shapes (vines, wood, petals, and gems).  
- **Color Palette:** Deep forest tones — dark blues, greens, and browns — with accent colors like gold or teal for contrast.  
- **Lighting:** Soft, glowing elements resembling bioluminescence.  
- **Textures:** Matte wood, leaf veins, subtle moss overlays; avoid flat or overly modern looks.  
- **Mood:** Calm, magical, and nature-aligned. The UI should feel like it grew out of the environment, not pasted on top.

---

## 🧭 2. Layout Overview

### **Top Section**
- **Title Area:** Centered logo or game name in ornate frame.
- **Currency Display:** Right-aligned area showing player currencies (coins, gems, etc.), using small iconography and clear counters.

### **Left Panel (Navigation)**
- A vertical menu with 3–5 main buttons (e.g., *Play*, *Shop*, *Inventory*, *Quests*).  
- Each button uses consistent shape, glow, and spacing.  
- Active or hovered button highlights softly (e.g., leaf shimmer or glowing border).  

### **Center Panel (Character/Status)**
- Displays the player’s avatar or active companion.
- Simple nameplate or title beneath.
- Room for customization later (e.g., changing outfits, companions, or titles).

### **Right Panel (Dynamic Content Area)**
- Contextual window for actions like store, upgrades, or settings.
- Scrollable frame or tabbed interface.
- Uses decorative frames that match the fantasy theme.

### **Bottom Section**
- **Dialogue / Notifications Bar:**  
  Displays text feedback, greetings, or quest prompts, accompanied by a small portrait (NPC or character).  
- Can double as a tutorial guide channel.

---

## ⚙️ 3. UI Components

| Component | Description |
|------------|-------------|
| **Buttons** | Rounded corners, soft wooden or stone textures. Hover transitions via glow or pulse tween. |
| **Frames** | Decorated edges (vines, petals). Soft shadows to lift from background. |
| **Icons** | Use consistent style — semi-realistic, painted look. Each type (currency, item, ability) has clear color coding. |
| **Text Labels** | Serif or fantasy-friendly fonts. Use `UIStroke` for contrast; color palette: pale yellow, off-white, or light blue. |
| **Tooltips** | Appear above or beside items with a fade-in tween. Include short text and item rarity color outline. |

---

## 🧠 4. User Experience (UX) Principles

- **Clarity First:** Avoid clutter; keep each panel focused on one function.  
- **Feedback:** Every action (button click, purchase, quest complete) gives audio and visual confirmation.  
- **Consistency:** Same button shape, frame style, and animation language across all UI screens.  
- **Guided Flow:** Use friendly dialogue bar or subtle highlights to teach new players step-by-step.  
- **Immersion:** UI sounds and visuals should match the fantasy tone — no harsh clicks or modern beeps.  

---

## 🧩 5. Roblox Implementation Overview

| Layer | Roblox Object | Key Notes |
|--------|----------------|-----------|
| Base UI | `ScreenGui` | Parent for all frames; use `ZIndexBehavior = Sibling`. |
| Panels | `Frame` + `ImageLabel` | Decorated borders, `UICorner` for rounded edges. |
| Buttons | `TextButton` or `ImageButton` | Tween `ImageColor3` for hover. Add gentle glow. |
| Text | `TextLabel` / `TextButton` | Scalable fonts with `UITextSizeConstraint`. |
| Animations | `TweenService` | Smooth transitions for hover, fade, or open/close effects. |

---

## 📱 6. Responsiveness & Accessibility

- **Scaling:** Use `UDim2` scale for adaptive resizing across PC, tablet, and mobile.  
- **Aspect Constraints:** Maintain proportional shapes for icons and panels.  
- **Contrast:** Ensure light text over dark backgrounds for readability.  
- **Audio Cues:** Gentle tones for navigation, avoid repetitive or sharp sounds.  

---

## 💫 7. Thematic Consistency

- Use **natural motifs**: vines, wood frames, petals, stones.  
- Maintain **magical glow elements** around interactive UI.  
- Avoid modern flat UI or neon highlights — stay within hand-painted and organic direction.  
- All interactions should feel part of the “living world,” not external menus.

---

## 🔮 8. Expansion-Ready Design

- Scalable UI framework to support:
  - Additional panels (e.g., Crafting, World Map)
  - Pop-up notifications (e.g., Achievements)
  - Progress displays (e.g., Level bar, XP bloom animation)
- Consistent aesthetic to ensure future updates blend naturally.

