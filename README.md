
## 🚀 Quick Start

Just copy your raw GitHub link and load it using this script:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rapzxcwxcorparation/DemonOfDarknessUI/refs/heads/main/DOD.luau"))()

local UI = Library({
    Title             = "daemon.wtf | Blade Ball",
    Version           = "v2.0",
    Author            = "rapptezetzee",
    TitleIcon         = "drama",
    Theme             = "Monochrome",
    TabPosition       = "Side",
    CategoryAlign     = "Center",
    ToggleKey         = Enum.KeyCode.LeftControl,
    Acrylic           = true,
    AcrylicBlur       = 24,
    Weather           = { Enabled = true, Type = "Snow", Intensity = 50 },
    Size              = UDim2.fromOffset(900, 580),
    Wallpaper         = "https://raw.githubusercontent.com/rapzxcwxcorparation/DemonOfDarknessUI/refs/heads/main/wallpaperdod/kawaii-cat-girl-3840x2160-26545.png",
    WallpaperTransparency = 0.35,
    SoundsEnabled       = true,
    SoundVolume         = 0.8,
    ReducedMotion       = false,
    LayoutDensity       = "Normal",
    SectionTransparency = 0.15,
    NotificationPosition = "TopRight",
    Tooltip             = true,
    TooltipTransparency = 0.15,
    ThemeAutoLoad       = false,   -- ← matiin auto-load biar opts gak ke-override
})
```

---

## 📚 The Basics (UI Hierarchy)

To keep things organized, the structure works like this:
**Window** ➡️ **Category** ➡️ **Tab** ➡️ **Section** ➡️ **Controls** (Toggles, Sliders, etc.).

### 1. Create Categories & Tabs
Categories are the main menus in the sidebar, and Tabs are the sub-menus inside them.

```lua
-- Usage: UI:CreateCategory("Category Name", "IconName")
UI:CreateCategory("Combat", "sword")
UI:CreateCategory("Visuals", "eye")

-- Usage: UI:CreateTab("Category Name", "Tab Name")
UI:CreateTab("Combat", "Aimbot")
UI:CreateTab("Visuals", "ESP")
```

### 2. Create Sections (The Containers)
A Section is the box/card where you place your controls. You can put them in the Left or Right column.

```lua
-- Usage: UI:CreateSection(Tab, Title, Description, DefaultOpen, "Left/Right", "IconName")
local aimSection = UI:CreateSection("Aimbot", "Aimbot Settings", "Configure your aimbot here", true, "Left", "crosshair")
```

---

## 🎮 The Controls (Buttons & Sliders)

All controls are added into the `Section` variable you created above.

### Toggle (On/Off)
```lua
UI:AddToggle(aimSection, "Enable Aimbot", true, function(state)
    print("Aimbot enabled:", state)
end)
```

### Slider (Drag to change values)
```lua
-- Usage: UI:AddSlider(Section, Text, Min, Max, Default, Decimals, Callback)
UI:AddSlider(aimSection, "Smoothness", 1, 20, 5.5, 1, function(value)
    print("Smoothness:", value)
end)
```

### Dropdown (Select one option)
```lua
UI:AddDropdown(aimSection, "Target Part", {"Head", "Torso", "HumanoidRootPart"}, 1, function(index, value)
    print("Targeting:", value)
end)
```

### Button (Clickable action)
```lua
UI:AddButton(aimSection, "Reset Settings", function()
    UI:Notify("System", "Settings successfully reset!", "success")
end)
```

### Textbox (Type text)
```lua
UI:AddTextbox(aimSection, "Webhook URL", "Paste link here...", function(text)
    print("URL:", text)
end)
```

### Color Picker (Choose a color)
```lua
UI:AddColorPicker(aimSection, "ESP Color", Color3.fromRGB(255, 0, 0), function(color)
    print("New color:", color)
end)
```

### Keybind (Hotkeys)
```lua
UI:AddKeybind(aimSection, "Panic Key", Enum.KeyCode.P, function(key)
    print("Panic key pressed:", key)
end)
```

---

## 🌟 Awesome Features (The Good Stuff)

### 1. Favorites System (Pin Controls) ⭐
Tired of scrolling to find your most-used settings?
- **Right-click** any control (Toggle, Slider, etc.) to add it to your Favorites.
- Click the **Star (⭐)** icon inside the Search Bar to filter and *only* show your favorited controls.

### 2. Confirm Dialog (Prevent Accidental Clicks) 🛡️
For dangerous actions (like deleting configs or resetting), always use a Confirm Dialog to keep the user safe.
```lua
UI:Confirm("Delete Config?", "Your config will be permanently deleted.", function()
    print("User clicked YES, deleting config!")
end)
```

### 3. Rich Text & Icons (Look Professional) ✨
- **Rich Text:** You can make text bold, italic, or monospace inside `AddLabel` and `AddParagraph`.
  ```lua
  UI:AddLabel(aimSection, "This is **Bold** and this is __Italic__ text.")
  ```
- **Section Icons:** Just add an icon name to the 6th parameter of `CreateSection` (e.g., `"settings"`, `"star"`, `"zap"`).

### 4. Wallpaper System (Auto-Cache) 🖼️
You can set images from a GitHub URL (Raw Link) as the UI background.
- **Supports PNG, JPG, WEBP** (Note: Animated GIFs will only show the first frame due to Roblox limitations).
- **No Lag:** The image downloads *once* and is saved to the executor's cache. Future loads are instant!
- Easily configured via the **Theme Customizer** (includes a transparency slider).

### 5. Layout Density & Section Transparency 📏
Customize the UI to fit your screen and eyes perfectly via the Theme tab:
- **Layout Density:** Make spacing compact (`Compact`), normal, or wide (`Spacious`).
- **Section Transparency:** Make the section backgrounds transparent so your custom wallpaper shines through!

### 6. UI Sounds 🔊
The library features satisfying click and hover sounds!
- Toggle sounds on/off.
- Adjust the volume (0% - 100%).
- Both can be configured in the Theme Customizer.

---

## 🛠️ Config System (Save & Load)

You can save the user's settings (Toggles, Sliders, Keybinds, etc.) into a file and load them back anytime.

```lua
-- Save config under a specific name
UI:SaveConfig("my_pro_settings")

-- Load the saved config
UI:LoadConfig("my_pro_settings")

-- Enable Auto-Save so it saves every time the user changes a setting
UI:EnableAutoSave("auto_save")
```

---

## 💡 Troubleshooting & Tips

1. **Wallpaper Not Showing?**
   - Make sure the GitHub link you use is a **RAW** link (it should start with `raw.githubusercontent.com`), not a standard GitHub page link.
   - Ensure your GitHub repository is set to **Public** (not Private).
   - Ensure your executor supports `getcustomasset`. If it doesn't, custom URL wallpapers won't work.
2. **Getting "Executor not supported" warnings?**
   - This means your executor doesn't allow scripts to write files to your device. Try switching to a PC executor like Synapse, Wave, or Delta.
3. **How to change themes?**
   - Just add `UI:CreateThemeCustomizer("YourTabName")` inside your script. It will automatically generate a tab where users can change themes, accent colors, and wallpapers.

---

*Made with ❤️ by RappTzy.*
*Feel free to modify and use this in your own projects!*
