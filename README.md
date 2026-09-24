# UI Scaler

A World of Warcraft addon that resizes the default windows — character sheet,
bags (including the all-in-one bag), world map, spellbook, talents, and more —
each on its own tab with a percentage slider.

## Install

**Easiest:** download
[UIScaler.zip](https://github.com/jimmythegent2/UIScaler/releases/latest/download/UIScaler.zip)
(also under **Releases** on the right of the repo page), unzip it, and move
the `UIScaler` folder into your WoW `Interface/AddOns` folder. Don't use the
green **Code → Download ZIP** button — that names the folder `UIScaler-main`
and WoW won't load it.

**With git**, clone into your client's AddOns folder instead, so updates are
a `git pull`:

```bash
cd "C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns"
git clone https://github.com/jimmythegent2/UIScaler.git
```

Swap `_classic_beta_` for `_retail_`, `_classic_`, or `_classic_era_` for
other clients. To update: `git pull` inside the `UIScaler` folder, then
`/reload` in game.

Releases are built automatically by `.github/workflows/release.yml` on every
push to `main`, named after the `## Version` line in `UIScaler.toc`.

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
