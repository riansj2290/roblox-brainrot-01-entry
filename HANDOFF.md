# HANDOFF — publish Steal a Snack and finish the entry

The game is built and tested here, but two things can only be done by the
account owner in Roblox Studio on a Windows/Mac PC. **Do these before the
deadline: Friday 21 Nov 2026, 21:30 WIB.** Nothing is submitted until they are done.

## What you need

- A Roblox account that can already publish (made at least 2 days ago, age check
  passed). A brand-new account cannot publish for 2 days.
- Roblox Studio installed, signed in to that account.

## 1. Open the game in Studio

Clone this repo (or download it), then open `game.rbxl` in Roblox Studio.
Press **Play** (F5) and check it runs: snacks walk the Snackway, hold **E** near
one to buy it, it flies to your base and the cash ticks up in the HUD.

## 2. Publish it as a Public experience

1. In Studio: **File → Publish to Roblox As… → Create New Experience**.
2. Name it **Steal a Snack**.
3. Description: write a short description of the game, and paste in the **play
   code** (ask the assistant for it — it looks like `makefun-xxx-xxx-xxx`).
   Roblox refuses descriptions that read like a web address, so do not put
   `make.fun` in it.
4. On the Creator Dashboard (https://create.roblox.com/dashboard/creations),
   open the experience → **Configure**: set a genre, answer the content
   questions (a simple game is about fifteen answers, or one question if you
   answer "No" to age-restricted content), then set it to **Public**.

## 3. Take 3–4 screenshots in Studio (while the game is running)

- **1-start.png** — the spawn view: the STEAL A SNACK sign and the plaza.
- **2-play.png** — walk onto the Snackway (W) next to a snack, HUD visible.
- **3-steal.png** — the Snack Snatcher at your base. In Studio's command bar
  run `require(game.ReplicatedStorage.Shared.Tour).spawnThief("1")` to send one
  on demand (it gives you a snack first if your base is empty).
- **4-rebirth.png** — the HUD with big money. In the command bar run
  `require(game.ReplicatedStorage.Shared.Tour).grantMoney("100000")` first.
- Each shot 16:9 (e.g. 1280×720), each at most **256 KiB** — re-encode as JPEG
  or scale down if Studio's capture is bigger. Keep HUD text out of the
  top-left corner (Roblox's own menu buttons sit there).
- The **first by name is the cover** and is shown largest to the judge, so make
  1-start.png your best shot.

## 4. Upload the icon and the thumbnail

On the Creator Dashboard, select the experience → **Configurations → Places** →
choose its start place (marked with a star) → **Icon** (a square picture,
512×512 is best) and **Thumbnails** (Experience Detail Page tab, your thumbnail
first). **Upload `1-start.png` as the first thumbnail** — it must be the same
picture as one of the screenshots in the repo. Wait until the experience's page
on Roblox shows both; Roblox reviews each upload first.

## 5. Fill in PLAY.json

In the repo, replace the zeros in `PLAY.json`:

- `place_id`: the number in the play link, `https://www.roblox.com/games/<placeId>`.
- `universe_id`: the number after `experiences/` in the experience's address on
  the Creator Dashboard (or `game.GameId` in Studio — not `game.PlaceId`).

## 6. Hand the files back

Commit `screenshots/` (the 3–4 shots) and the filled-in `PLAY.json` to this repo
and push, or send the files to the assistant. The assistant then re-runs the
checks and submits. **Do not change any game file after this point** — the
submitted commit is snapshotted as-is.

## If publishing fails

If Roblox will not let the account publish (age check, account too new, content
questions), stop here and tell the assistant — the entry cannot be submitted
from an unpublished experience, and no other account's experience can be used.
