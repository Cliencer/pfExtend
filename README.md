# pfExtend

English | [简体中文](README-zhCN.md)

pfExtend is an extension addon for [pfQuest](https://github.com/shagu/pfQuest) and [pfUI](https://github.com/shagu/pfUI), enhancing the gameplay experience by providing monster loot display and quest chain visualization functionalities. Compatible with **Turtle WoW** (1.12.0 client).

## Features

### ShowLoots - Monster Loot Display

When hovering over a monster, automatically displays its full loot table in the tooltip.
![ShowLoots Browser](img/Snipaste_2026-02-10_17-51-52.jpg)
**Key Features:**
- **Real-time Loot Preview**: Hover over any monster to see its complete drop list directly in the game tooltip
- **Drop Rate Visualization**: Shows exact drop percentages with color-coded indicators (green = common, red = rare)
- **Smart Filtering**: Filter loot by item quality (Poor, Common, Uncommon, Rare, Epic, Legendary)
- **Favorites System**: Mark items as favorites to highlight them in the loot list (favorited items appear at top)
- **Detailed Browser**: Press `Alt+Ctrl` while hovering to open a full loot browser window showing:
  - Item links with quality colors
  - Exact drop rates with percentage coloring
  - Item sources (NPCs, Objects, Vendors)
  - Zone locations for each source
  - Reference loot tables support (indirect drops)
  - Clickable item links for detailed inspection

**Supported Loot Types:**
- **Unit (NPC) Drops**: Direct monster loot
- **Object Loot**: Chests, containers, mining nodes, herbs, etc.
- **Reference Tables**: Complex loot tables linking multiple sources (e.g., "World Drop" tables)

**Configuration Options:**
- Enable/disable the feature
- Set maximum number of items displayed in tooltip
- Filter by minimum item quality (hide junk items)
- Toggle item ID display in browser

---

### QuestHelper - Quest Chain Browser

A powerful quest chain visualization tool integrated into the World Map.
![QuestHelper Browser](img/Snipaste_2026-02-10_17-50-45.jpg)

**Key Features:**
- **Interactive Quest Tree**: Displays all available quests in current zone as an expandable tree structure
- **Quest Chain Visualization**: Automatically builds and displays complete quest chains (prerequisites → follow-ups)
- **Smart Quest Filtering**: Automatically filters quests by:
  - Race compatibility
  - Class requirements
  - Profession requirements
  - Level requirements
  - Event quests
  - Prerequisite completion status

**Quest Status Indicators:**

| Color | Tag | Meaning |
|-------|-----|---------|
| <span style="color:#3eff2b">●</span> Green | Active | Currently in quest log |
| <span style="color:#ffff2b">●</span> Yellow | Available | Can be accepted now |
| <span style="color:#ff2b2b">●</span> Red | Prereq | Missing prerequisite quests |
| <span style="color:#ff2b2b">●</span> Red | High-Level | Level requirement not met |
| <span style="color:#5a5a5a">●</span> Gray | Finished | Completed (dimmed if all follow-ups done) |
| <span style="color:#5a5a5a">●</span> Gray | Race/Class/Skill | Requirements not met |
| <span style="color:#2b3eff">●</span> Blue | Event | Seasonal or event quest |
| <span style="color:#ffff2b">●</span> Yellow | Hidden | Starts from item drop |

**Interactive Map Integration:**
- **Map Toggle Button**: Quick access button on World Map (`QH` button)
- **Quest Pinning**: Click any quest to pin it on the world map
- **Automatic Map Markers**: Shows quest giver locations (NPCs, Objects, Items)
- **Smart Clustering**: Groups nearby quest markers to reduce clutter
- **Cross-Zone Tracking**: 
  - Click to track quests from other zones (auto-switch map)
  - Ctrl+Click to find and track prerequisite quests in their respective zones

**Quest Chain Navigation:**
- **Expandable Tree**: Click `+`/`-` to expand or collapse quest chains
- **Double-Click**: Expand/collapse entire subtree at once
- **Auto-Scroll**: Automatically scrolls to relevant quest when switching zones
- **Persistent Pins**: Quest pins remain on map until manually removed

**Advanced Features:**
- **Prerequisite Finder**: Automatically locates prerequisite quests when current quest is unavailable
- **Multi-Zone Support**: Handles quests available in multiple zones or locations
- **Item-Start Quests**: Tracks quests that begin from item drops (with drop source locations)
- **Unified Cache**: Optimized database for fast quest zone lookups

---

## Dependencies

- **[pfUI](https://github.com/shagu/pfUI)** - Required UI framework
- **[pfQuest](https://github.com/shagu/pfQuest)** - Required database provider
- **[pfQuest-turtle](https://github.com/shagu/pfQuest-turtle)** - Additional database for Turtle WoW (required only for Turtle WoW)

## Installation

1. Download the latest release (`pfExtend_X.X.X.zip`)
2. Extract to your WoW addons folder: `Interface\AddOns\`
3. Ensure the folder is named `pfExtend` (not `pfExtend_X.X.X`)
4. Restart the game or reload UI (`/reload`)

## Commands

| Command | Description |
|---------|-------------|
| `/pfex` | Open pfExtend configuration window |

## Configuration

Access settings via:
- Slash command: `/pfex`
- Browser window settings button (gear icon)
![Configuration Panel](img/Snipaste_2026-02-10_17-52-11.jpg)


## Database Update

Both features require a one-time database initialization:
- Automatically updates on first login after installation
- Manual update available via settings
- Update required when pfQuest database changes

## Compatibility

- **Client**: World of Warcraft 1.12.0 (Vanilla), compatible with **Turtle WoW**
- **Dependencies**: pfUI, pfQuest (and pfQuest-turtle for Turtle WoW)
- **Conflicts**: None known

## Credits

- **Author**: Cliencer
- **Base Framework**: pfQuest by Shagu
- **UI Framework**: pfUI by Shagu

