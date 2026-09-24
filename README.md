# NakedBars

A World of Warcraft addon that hides your action bars and UI elements with a single toggle — so you can enjoy the world without the clutter.

> **YOU'RE NAKED!!!**

## Features

- **One-key toggle** — hide (and restore) selected UI elements instantly
- **Per-element configuration** — choose exactly which bars and UI pieces are included in the toggle via a Blizzard-style settings panel
- **Cooldown overlay** — optionally display Blizzard's cooldown viewers (and CMC trackers) *while* bars are hidden, so you never lose track of your abilities
- **Combat-safe** — toggling during combat is deferred until combat ends
- **Persistent** — your hidden/shown state and settings survive `/reload` and log-outs
- **Keybind support** — bind the toggle in **Key Bindings → Other**

## Supported Elements

### Action Bars
| Element | Config Key | Default |
|---------|-----------|---------|
| Action Bar 1 (buttons 1-12) | `actionBar1` | ✅ |
| Action Bar 2 | `actionBar2` | ✅ |
| Action Bar 3 | `actionBar3` | ✅ |
| Action Bar 4 | `actionBar4` | ✅ |
| Action Bar 5 | `actionBar5` | ⬜ |
| Action Bar 6 | `actionBar6` | ⬜ |
| Action Bar 7 | `actionBar7` | ⬜ |
| Action Bar 8 | `actionBar8` | ⬜ |

### UI Elements
| Element | Config Key | Default |
|---------|-----------|---------|
| Pet Action Bar | `petBar` | ✅ |
| Micro Menu | `microMenu` | ✅ |
| Bags Bar | `bagsBar` | ✅ |
| XP / Rep Bar | `xpBar` | ✅ |
| Chat | `chat` | ⬜ |
| Objectives Tracker | `objectives` | ⬜ |
| Minimap | `minimap` | ⬜ |

### Cooldown Manager (Inverse Toggle)
When bars are hidden, cooldown trackers can be shown *instead* — so you can monitor abilities without visible bars. Each tracker can be individually enabled or disabled, and a master toggle controls the entire overlay.

| Tracker | Config Key | Default |
|---------|-----------|---------|
| Essential Cooldowns | `essentialCooldowns` | ✅ |
| Utility Cooldowns | `utilityCooldowns` | ✅ |
| Buff Icon Cooldowns | `buffIconCooldowns` | ✅ |
| Buff Bar Cooldowns | `buffBarCooldowns` | ✅ |
| CMC Tracker 1 | `cmcTracker1` | ✅ |
| CMC Tracker 2 | `cmcTracker2` | ✅ |

## Commands

| Command | Description |
|---------|-------------|
| `/bars` | Toggle bar visibility |
| `/bars config` | Open the settings panel |
| `/bars options` | Open the settings panel (alias) |
| `/nakedbars` | Toggle bar visibility (alias) |

## Settings Panel

Open with `/bars config` or navigate to **Game Menu → Settings → AddOns → NakedBars**.

The panel lets you:
- See your current keybind (set it in Key Bindings → Other)
- Check/uncheck individual action bars (1–8)
- Check/uncheck UI elements (pet bar, micro menu, bags, XP bar, chat, objectives, minimap)
- Enable or disable the cooldown overlay master toggle
- Pick exactly which cooldown trackers appear when bars are hidden

Changes take effect immediately.

## Installation

1. Download or clone this repository.
2. Copy the `NakedBars` folder into your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/NakedBars/
   ```
   For WoW: Forever, use that client's `Interface/AddOns/` folder instead.
3. Restart WoW or type `/reload`.
4. The addon appears in your AddOns list. Type `/bars` to toggle!

## Compatibility

One package supports both clients via a multi-interface TOC line:

- **WoW Retail 12.x** (Interface 120001, 120100)
- **WoW: Forever 1.60.x** (Interface 16001) — Forever runs the modern (Midnight) addon API, so the same code loads on both
- MainMenuBar does not exist in 12.x — bar 1 is handled via `ActionButton1-12`
- Cooldown Manager frames: `EssentialCooldownViewer`, `UtilityCooldownViewer`, `BuffIconCooldownViewer`, `BuffBarCooldownViewer`
  (Forever's native Cooldown Manager is still incomplete for some classes)
- Third-party CMC addon: `CMCTracker1`, `CMCTracker2`

Any frame that doesn't exist on the current client is skipped. Cooldown trackers whose frame is missing
(e.g. CMC not installed) are greyed out in the settings panel and marked "(not available)".

## Releasing

Releases are packaged and uploaded to CurseForge automatically by the
[BigWigs packager](https://github.com/BigWigsMods/packager) GitHub Action
(`.github/workflows/release.yml`).

One-time setup: add a CurseForge API token as the `CF_API_KEY` repository secret
(CurseForge → Account → API Tokens).

To release, tag and push:

```
git tag v1.1.0
git push origin v1.1.0
```

The packager replaces `@project-version@` in the TOC with the tag and uploads the zip to
CurseForge project `1469362` for both Retail and Forever. Tags containing `alpha`/`beta`
are uploaded as alpha/beta releases.

## File Structure

```
NakedBars/
├── .github/workflows/
│   └── release.yml          # Tag-triggered CurseForge release
├── .pkgmeta                 # Packager config
├── NakedBars.toc            # Addon manifest
├── Bindings.xml             # Keybind registration
├── NakedBars.lua            # Core toggle logic & element registry
├── NakedBars_Options.lua    # Blizzard-style settings panel
└── README.md
```

## License

Do whatever you want with it. You're naked anyway.
