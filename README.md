# Glamdoc Color Wheel

A standalone CET overlay that gives you a **full HSV color wheel** for the
primary and secondary colors of your equipped arm cyberware (Mantis Blades,
Gorilla Arms, Monowire, Projectile Launch System) — replacing the five
predefined brand swatches the 2.5 Glamdoc vendors offer.

Pure Cyber Engine Tweaks mod: no redscript, no RED4ext, no archive edits.
Zero footprint at save-load time — it cannot crash your game on load.

## Features

- True HSV color pickers (hue ring + saturation/value) for primary and
  secondary colors
- Any RGB color, independent of brand palettes
- Colors are stored in a plain file (`gcw_colors.txt`) and **survive
  save/reload automatically** — re-applied at 10s/25s/45s after loading so
  the engine's own load-time setup can never override them
- Re-applied automatically when you **switch Glamdoc styles**
- Opening the window re-applies instantly as a manual fallback

## Requirements

- Cyber Engine Tweaks (CET) 1.38.0 or newer (2.5-compatible)

## Install

### Via mod manager (Vortex / Nexus app)

Download and install the archive — it mirrors the game's folder structure
(`bin\x64\plugins\cyber_engine_tweaks\mods\...`) so the manager deploys it
automatically.

### Manual

Unzip, then copy the `GlamdocColorWheelOverlay` folder into:

```
<game>\bin\x64\plugins\cyber_engine_tweaks\mods\
```

so you end up with:

```
<game>\bin\x64\plugins\cyber_engine_tweaks\mods\GlamdocColorWheelOverlay\init.lua
<game>\bin\x64\plugins\cyber_engine_tweaks\mods\GlamdocColorWheelOverlay\info.json
```

## Bind the key

1. Launch the game, open the CET overlay (tilde ` by default).
2. Go to **Bindings** → **GlamdocColorWheelOverlay** →
   **"Open Glamdoc Color Wheel"** and bind a key.
3. Close the overlay, press your key. The **Arm Cyberware Colors** window
   opens.

## Use

1. Pick primary and secondary colors with the pickers.
2. Press **Apply** — the colors go straight onto your equipped arm
   cyberware.
3. Save/reload or switch styles freely; your colors return on their own.

A Glamdoc style must be equipped on the arms for colors to show (visit any
Glamdoc and equip one first).

## Troubleshooting

- Every action is logged to `gcw_overlay.log` in the mod folder — check it
  if something doesn't apply.
- `gcw_colors.txt` holds your saved colors; delete it to reset to defaults.
- If colors ever look wrong after an unusual load path, just press your
  keybind — opening the window re-applies instantly.

## Uninstall

Delete the `GlamdocColorWheelOverlay` folder. No game files are modified
by this mod, so nothing else needs cleanup.

## Technical notes

The 2.5 Glamdoc system persists colors as a `Uint8` palette index
(0–4) that native code resolves against per-brand palettes — writing any
larger index into the save crashes the game on load. This mod sidesteps
that entirely: it never touches the save's palette indices. It calls the
native raw-color API directly
(`CyberwareCustomizationSystem.SetCustomizationParameters(force, Color, Color)`
— the engine natively accepts arbitrary RGB) and stores the chosen colors
in its own file, re-applying them whenever the customization state is
(re)initialized.

Material finishes (plastic/metallic) are baked into per-style mlsetup
assets and are not script-exposed — out of scope for this mod.
