# Mods.Cyberpunk2077.ShootDodge

A Cyberpunk 2077 gameplay mod that recreates *Max Payne 2*'s Shootdodge in first person. Aim, jump and
press a movement direction: V leaps that way, time slows while your aim and fire stay at full speed,
V lands prone and keeps shooting from the floor, and a movement key gets V back on their feet. It
also has Max Payne 2's bullet-time hourglass and grants the matching outfit and twin pistols.

Everything is Lua for [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks). No
archive files, no new meshes, no animation edits.

## Status

All the gameplay tickets (C2SD-T4 to C2SD-T16) are implemented. The mod has not been through the full
in-game checklist yet: work through [`docs/TESTING.md`](docs/TESTING.md) and note each result in its
table. The Nexus Mods page text is ready in [`docs/NEXUS_PAGE.md`](docs/NEXUS_PAGE.md) but the mod is
not published. Design notes and the Max Payne 2 research live in [`docs/DESIGN.md`](docs/DESIGN.md);
[`docs/USER_STORIES.md`](docs/USER_STORIES.md) is the generated ticket log.

## Requirements

- Cyberpunk 2077 (PC).
- [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) (CET). That is the only
  dependency. The code uses no TweakXL records, Codeware or RED4ext: the loadout gives vanilla
  items by their existing TweakDB IDs.

## Install

1. Install Cyber Engine Tweaks and start the game once so CET creates its folders.
2. Copy the `ShootDodge` folder from `bin/x64/plugins/cyber_engine_tweaks/mods/` in this repo into the
   same path in your game folder, so that
   `<game>/bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua` exists.
3. Start the game. The CET console and log should show `[ShootDodge] loaded`.
4. Open the CET overlay (its key is set in CET's first-run screen), find the **ShootDodge** window and
   tick **Enabled**. The mod starts disabled every session and does not remember the tick.

## Uninstall

Delete `<game>/bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/`. Nothing else is touched. The
loadout items already in your inventory stay (sell or drop them). Two quest facts stay in your
saves (`shootdodge_mp2_loadout` and `shootdodge_bt_meter`); they are inert without the mod.

## How to use it

### The Shootdodge

1. Equip a pistol, revolver or SMG (see below).
2. Hold aim (right mouse button or the left trigger) for at least 0.15 s.
3. Hold a movement direction (forward, back, strafe left or right, or a diagonal) for at least 0.05 s.
4. Press jump. With all three, V launches.

What happens next:

- **The leap is locked.** V flies in the direction you were moving, relative to where the camera
  faced at launch. Moving in the air changes nothing; the camera and aim stay free, and the camera
  stays first person the whole time.
- **Time slows.** The world drops to 0.2x speed while V is in the air. Your mouse look and your
  weapon's fire rate stay at normal speed, so you shoot at full pace while everything else crawls.
  The camera pulls back a little (+12 degrees of FOV), a whoosh plays, and music is ducked.
- **V lands prone.** Every dive ends on the ground, whatever you hold. Slow-mo ends on impact. V's
  first-person view drops to near floor height.
- **Then choose.** Keep shooting from the ground in any direction for as long as you like (there is
  no timer), or press a movement key to scramble back up. If you were still holding a direction when
  you touched down, V hits the ground, waits a quarter second, then gets up on its own. Jump alone
  does not stand V up, and a key still held from the dive has to be released once before it counts
  as a stand-up press.
- A new combo can't start while a Shootdodge is still in progress (in the air, prone or getting up),
  and there is a 1 second cooldown between combos.

The combo only fires from the ground, on foot, with an allowed weapon. Jumping, aiming or moving on
its own never triggers it.

### Weapon restriction

Pistols, revolvers and SMGs arm the combo. Rifles, shotguns, LMGs and HMGs, sniper and precision
rifles, melee weapons, fists, cyberware arms and having nothing equipped all block it. The weapon is
checked at the instant you press jump, so swapping weapons takes effect on the very next jump. The
overlay's last-jump line says "weapon not allowed" when this was the reason.

### Bullet-time meter (the hourglass)

The hourglass follows *Max Payne 2*:

- A **Shootdodge costs no meter** and is always slow-motion, even with an empty hourglass.
- **Bullet Time mode** is a separate manual slow-mo toggle. It uses the same 0.2x slowdown, and it is
  the only thing that drains the hourglass: a full one lasts about 10 seconds. Aim and fire stay at
  normal speed in it too. It needs at least 2% sand to start, can't start mid-dive, ends on its own
  when the hourglass is empty, and also ends if you die, disable the mod or start a Shootdodge.
- **Refill**: passively while the mode is off (empty to full in about 80 seconds), and +15% for every
  enemy you kill (counted from the game's own death event, once per NPC, only when V is the killer).
  Capped at full.
- The sand turns **yellow** with each kill (+34%) and fades back to white (8% per second). The tint
  is cosmetic.
- The level is saved with your save game and restored on load. A save made before you installed the
  mod starts with a full hourglass.
- **The hourglass HUD** is drawn in the lower left of the screen (3.5% in from the left, 62% down,
  64 px tall) at all times in game, with or without the CET overlay open. It is hidden in menus and
  while the game is paused. Switch it off with the overlay's **Hourglass HUD** tick.

**Binding the Bullet Time hotkey.** It is unbound by default. Open the CET overlay, go to the
**Bindings** tab, find **ShootDodge** and bind **Bullet-time mode (Max Payne 2, toggle)** to a key.
Pressing it starts the mode, pressing it again stops it. The overlay's **Start/Stop bullet-time
mode** button does the same. Like the dive's slow-mo, the mode refuses to start when the
**Bullet-time** tick is off or the **Time scale** slider is at 1.00, since there would be no slow-mo
to drain the hourglass for.

### Max Payne 2 loadout

Once per save, 1.5 seconds after V appears, the mod gives V Max's Max Payne 2 look, built from
vanilla items:

| Piece | Item |
|---|---|
| Twin pistols | 2 x Militech M-10AF Lexington (`Items.Preset_Lexington_Default`) |
| Coat | `Items.Coat_01_basic_01` |
| Shirt | `Items.FormalShirt_01_basic_01` |
| Trousers | `Items.FormalPants_01_basic_01` |
| Shoes | `Items.FormalShoes_01_basic_01` |

It works for male and female V (every piece has both body appearances). Nothing is equipped for you:
open the inventory and equip the pieces. The Lexington is a power pistol, so it passes the weapon
restriction.

- It only grants once per save. A quest fact in the save records that, so reloading, restarting CET
  or selling a piece never re-grants it. If an item failed to arrive, the fact is left unset and the
  overlay says which, and **Check loadout now** (or the next load) gives only what is missing.
- Limits: Cyberpunk has **no tie slot**, so there is no tie, and no dual-wielding, so "twin" means
  one Lexington in hand and one on the weapon wheel. The coat colour is a best match; see
  [`docs/DESIGN.md`](docs/DESIGN.md) for the research and the runners-up.

### The debug overlay

Open the CET overlay and find the **ShootDodge** window. It only draws while the CET overlay is
open; the hourglass HUD does not depend on it. Settings are not saved between sessions.

| Control | Default | What it does |
|---|---|---|
| Enabled | off | Master switch for the Shootdodge combo and its state machine. Unticking it cancels any dive in progress. The hourglass and loadout work either way. |
| Prone eye drop (m) | 1.30 (0 to 1.6) | How far the first-person camera drops while prone. |
| Bullet-time | on | World slow-mo on (dive and Bullet Time mode). Off means the dive still happens at normal speed. |
| Time scale | 0.20 (0.05 to 1.00) | World speed during slow-mo. |
| Weapon at normal speed (fire rate) | on | Keeps V's weapon's fire cycle at normal speed during slow-mo. |
| All of V at normal speed (pad look; fall not slowed) | off | Also exempts V, which fixes slow gamepad turning but speeds V's fall arc back up. |
| Start/Stop bullet-time mode | | Toggles Bullet Time mode (same as the hotkey). |
| Refill meter / Empty meter | | Test buttons for the hourglass. |
| Hourglass HUD | on | Shows or hides the on-screen hourglass. |
| FOV pull-back | on | Widens the camera while diving. |
| Pull-back (deg) | 12.0 (0 to 30) | How much it widens. |
| Whoosh on dive | on | Plays the whoosh once on dive entry. |
| Whoosh event | `lcm_player_double_jump` | The game sound event used. A **Play** button auditions it. |
| Muffle music/ambience | on | Ducks music while diving. |
| Music kept | 0.35 (0 to 1) | Fraction of your music volume kept while diving. |
| Low-pass on event / Low-pass off event | empty | Optional audio event names for a low-pass on and off. Blank by default, so only the volume duck happens. |
| Check loadout now | | Re-checks the loadout and gives anything missing. |

Read-outs: the current state (`NONE`, `DIVING`, `AIRBORNE`, `PRONE`, `GETUP`) with time in state, the
last state change and last refused one, combo status and the reason the last jump was not a combo, the
locked dive direction and air time, the landing log (one line per dive, movement held or not), prone
and get-up status, world time (and whether the game is paused), which entities are exempted, the exact
meter value, mode, tint and kills counted, polish status, and the loadout result. Problems show as
"... problem:" lines. The mod also prints state changes, combos, landings and get-ups to the CET
console.

While music is ducked the original volume is also written to `polish_restore.txt` in the mod folder.
If the game or CET dies mid-dive, the next load puts your music volume back.

## Known limitations

- **Prone is camera-only.** CP77 has no prone stance, so "lying down" is the first-person camera
  lowered near the floor. V's body and hitbox stay standing, so enemies still hit V as if standing.
  A real prone pose needs a custom animgraph (WolvenKit and REDmod), a future project.
- **No dive animation.** The leap rides the stock jump plus an impulse; in first person you see no body.
- **The ambience low-pass events are blank by default.** No safe low-pass audio event name is known,
  so only the music volume duck is active. If you know event names, type them into the overlay fields.
- **Gamepad turn speed.** Mouse look is unaffected by slow-mo, but a gamepad's turn rate follows time
  dilation unless **All of V at normal speed** is on (which has the side effect that V's fall arc
  is not slowed).
- Max Payne 2's extra slowdown for a yellow hourglass is not implemented; the tint is only visual.
- Drain, refill and kill amounts are estimates (MP2's real numbers are not published) and are the
  values to tune after in-game testing; see `BulletTimeMeter.defaults`.
- No tie, no true dual-wielding (see the loadout).
- Settings are per session. Only the hourglass level and the loadout flag are saved (in the save file).

## Building and packaging

There is no build step: the mod is plain Lua. To release, zip the `bin` folder so the archive has this
layout (this is what Nexus users extract into the game folder):

```
bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua
bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/modules/*.lua
```

Name it `ShootDodge-<version>.zip`. A quick syntax check of each file is `luac -p <file>`. Do not ship
`polish_restore.txt` or any other runtime file.

## Testing

[`docs/TESTING.md`](docs/TESTING.md) is the full in-game checklist (male and female V where it
matters), with a Results table.

## Repository layout

- `bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua`: wires everything and draws the overlay.
- `.../modules/`: the pure rules modules (`StateMachine`, `ComboDetector`, `Dive`, `Prone`, `GetUp`,
  `BulletTime`, `BulletTimeMeter`, `DivePolish`, `WeaponGate`, `AimFireExemption`, `Loadout`) and the
  CET glue next to each (`*Driver.lua`, `Input.lua`).
- `docs/`: design notes, Nexus page, testing checklist and the ticket log.
