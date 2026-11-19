# Steal a Snack — roblox-brainrot-01

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/riansj2290/roblox-brainrot-01-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/riansj2290/roblox-brainrot-01-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D Roblox brainrot game for make.fun's **roblox-brainrot-01** bounty ($1,000, 50 paid places).
Absurd snack creatures walk the Snackway conveyor; buy them, park them on your base,
and they earn snack cash every second while you climb the rarity ladder — and while
the Snack Snatcher tries to steal them from under you.

## The game

- **The Snackway**: a conveyor through a 3D plaza. Snacks spawn at the arch and walk
  to the chute. Walk up to one and hold **E** to buy it.
- **The cast**: 10 original snack creatures — Sir Fry, Baron Bagel, Count Croissant,
  Duchess Donut, King Kebab, Queen Queso, Emperor Espresso, The Forbidden Pickle,
  Grandma's Lasagna and The Last Slice — across 6 rarities (Common → Secret) and
  4 mutations (Golden, Diamond, Rainbow).
- **Your base**: 8 snack slots. Your claimed base starts with 4 snacks already on
  it — your starter set. Snacks on your base earn $/s, shown live in the HUD.
  Neighbour bots own the other three bases — walk over and steal their snacks.
- **The threat**: the Snack Snatcher, a hooded thief who slips in every minute or so,
  grabs your richest snack and runs for the exit. **Touch him or click him** to make
  him drop it and flee. Lock your base (20s, 60s recharge) and he turns away.
- **Progression**: rebirth for a permanent +50% income multiplier, and the Snack
  Stampede floods the belt with rare snacks every few minutes.

## Run it

1. Install [Rojo 7.7](https://github.com/rojo-rbx/rojo) (`rojo --version`).
2. Build the place: `rojo build default.project.json --output game.rbxl`
3. Open `game.rbxl` in Roblox Studio and press Play. One player gets the first base;
   the other three belong to neighbour bots whose snacks can be stolen.

## Hand it in

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`,
`screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json`
with `vendor/makefun-roblox.ts` (the kit's copy, unchanged):

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`screenshots/` holds 3–4 captures of the game running in Studio (16:9, each at most
256 KiB; the first by name is the cover and the game's first thumbnail on Roblox).
`PLAY.json` names the published Public experience (see `HANDOFF.md`).

## Layout

- `src/shared/Config.luau` — rarities, mutations, the snack cast, prices, timings
- `src/server/World.luau` — the 3D plaza: conveyor, bases, trees, lamps, signs
- `src/server/Creatures.luau` — snack models, belt walking, carrying to a slot
- `src/server/Bases.luau` — plot ownership, slots, the lock barrier, NPC stock
- `src/server/Thieves.luau` — the Snack Snatcher's pathfinding and theft
- `src/server/Game.luau` — money, buying, stealing, rebirth, lock, stampede
- `src/client/HUD.client.luau` — cash, income, rebirth and lock buttons, banners
- `src/shared/Tour.luau` — helpers for `TOUR.json` (grant cash, send a thief, stampede)
- `vendor/makefun-roblox.ts` — the kit's dossier library, unchanged
- `TOUR.json` — the optional reviewer tour (one step per screenshot)
- `HANDOFF.md` — the publish + screenshot steps the owner takes in Studio

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's
RULES.txt.
