# UI Scaler

A World of Warcraft addon that resizes the default windows — character sheet,
bags (including the all-in-one bag), world map, spellbook, talents, and more —
each on its own tab with a percentage slider.

## Install

Clone into your client's AddOns folder, so the folder is named `UIScaler`:

```bash
cd "C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns"
git clone https://github.com/jimmythegent2/UIScaler.git
```

Swap `_classic_beta_` for `_retail_`, `_classic_`, or `_classic_era_` for
other clients. No git? Use **Code → Download ZIP** on GitHub, unzip into
AddOns, and rename the folder from `UIScaler-main` to `UIScaler`.

To update: `git pull` inside the `UIScaler` folder, then `/reload` in game.

## Use

- `/uis` or `/uiscaler` opens the window. It's also under Options → AddOns.
- Pick a window on the left, then drag the slider, type a percentage, or use a
  preset. Changes apply live and are saved per account.
- Windows the game hasn't loaded yet (talents, auction house, professions…)
  pick up their scale the first time you open them.
- Scaling a protected window waits until you leave combat.

## Adding a window

Run `/fstack` in game and hover the window to find its frame name, then add it
to `ns.MODULES` in `Core.lua`.

If the addon shows as out of date, get your client's interface number with
`/dump select(4, GetBuildInfo())` and add it to the `## Interface:` line in
`UIScaler.toc`.
