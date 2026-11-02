# Mods.Cyberpunk2077.ShootDodge

A Cyberpunk 2077 gameplay mod that recreates *Max Payne 2*'s Shootdodge in first person. Aim, jump and
press a movement direction: V leaps that way, time slows while your aim and fire stay at full speed,
V lands prone and keeps shooting from the floor, and a movement key gets V back on their feet. It
also has Max Payne 2's bullet-time hourglass and grants the matching outfit and twin pistols.

Everything is Lua for [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks), plus one
small redscript file that puts a text thread from Max Payne himself in V's phone. No archive files,
no new meshes, no animation edits.

## Status

All the gameplay tickets (C2SD-T4 to C2SD-T16) are implemented. The mod has not been through the full
in-game checklist yet: work through [`docs/TESTING.md`](docs/TESTING.md) and note each result in its
table. The Nexus Mods page text is ready in [`docs/NEXUS_PAGE.md`](docs/NEXUS_PAGE.md) but the mod is
not published. Design notes and the Max Payne 2 research live in [`docs/DESIGN.md`](docs/DESIGN.md);
[`docs/USER_STORIES.md`](docs/USER_STORIES.md) is the generated ticket log.

## Requirements

- Cyberpunk 2077 (PC).
- [Cyber Engine Tweaks](https://www.nexusmods.com/cyberpunk2077/mods/107) (CET): the whole mod.
- [redscript](https://www.nexusmods.com/cyberpunk2077/mods/1511): compiles the phone contact
  (`r6/scripts/ShootDodge/ShootDodgePhone.reds`).
- [Phone Extension](https://www.nexusmods.com/cyberpunk2077/mods/24949) (by r457 and gh057),
  **optional**: needed only for Max Payne's text. It is the framework that lets that contact text V
  in the phone's Messages app, and itself four redscript files that need nothing but redscript.
- [Input Loader](https://www.nexusmods.com/cyberpunk2077/mods/4575) (by jackhumbert, needs
  [RED4ext](https://www.nexusmods.com/cyberpunk2077/mods/2380)), **optional**: gives Bullet Time mode
  its default key, `/` (`r6/input/ShootDodge.xml`). Without it, bind the key in CET's
  Bindings tab instead.

That is all. The code uses no TweakXL records, ArchiveXL, Codeware or RED4ext of its own (only the
optional Input Loader runs on RED4ext): the loadout gives
vanilla items by their existing TweakDB IDs. The `.reds` file is guarded with
redscript conditional compilation (`@if(ModuleExists(...))`), so without Phone Extension it compiles
to nothing and no redscript mod is affected. Install order does not matter; without Phone Extension
only Max Payne's text is missing.

## Install

### With Vortex

1. Install Cyber Engine Tweaks and redscript, plus Phone Extension if you want Max Payne's text and
   Input Loader if you want `/` as the Bullet Time key out of the box (Vortex lists them as requirements on
   the Nexus page).
2. Download `ShootDodge-<version>.zip` with **Mod Manager Download**, or drag the zip into Vortex's
   Mods page (**Install From File**). Enable and deploy it.
3. Vortex's Cyberpunk 2077 extension recognises the zip on its own (a CET mod plus a redscript mod in
   their standard folders), so there is no manual-install or "fallback installer" prompt.

### By hand

1. Install the three requirements and start the game once so CET creates its folders.
2. Extract `ShootDodge-<version>.zip` into the game folder (the one with `bin` and `r6`), so that
   `<game>/bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua` and
   `<game>/r6/scripts/ShootDodge/ShootDodgePhone.reds` exist. From a clone of this repo, copy those
   two folders to the same paths instead.

### First run

1. Start the game. The CET console and log should show `[ShootDodge] loaded`.
2. Open the CET overlay (its key is set in CET's first-run screen), find the **ShootDodge** window and
   tick **Enabled**. The mod starts disabled every session and does not remember the tick.
3. A few seconds into your first session on each save, Max Payne texts V (see
   [Text from Max Payne](#text-from-max-payne)).

## Uninstall

Remove the mod in Vortex, or delete `<game>/bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/` and
`<game>/r6/scripts/ShootDodge/`. Nothing else is touched. The loadout items already in your inventory
stay (sell or drop them). Three quest facts stay in your saves (`shootdodge_mp2_loadout`,
`shootdodge_bt_meter` and `shootdodge_intro_message`); they are inert without the mod, and the Max
Payne contact disappears from the phone with it.

## How to use it

### The Shootdodge

1. Equip a pistol, revolver or SMG, or two pistols with Double Trouble (see below).
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
its own never triggers it, except in Bullet Time mode (below).

**In Bullet Time mode, Space alone is the Shootdodge.** While the mode is on, press jump (Space) and V
dives, no aim needed: in the direction you hold, or straight forward when you hold none. The weapon
restriction, the on-the-ground check and the cooldown still apply, so with a disallowed weapon Space
is a normal jump. Starting the dive ends Bullet Time mode (the dive's own slow-mo takes over, as in
Max Payne 2), so after you land Space is a normal jump again until you switch the mode back on.
Outside Bullet Time mode nothing changes: you need the aim + direction + jump combo.

### Weapon restriction

Pistols, revolvers and SMGs arm the combo. Rifles, shotguns, LMGs and HMGs, sniper and precision
rifles, melee weapons, fists, cyberware arms and having nothing equipped all block it. The weapon is
checked at the instant you press jump, so swapping weapons takes effect on the very next jump. The
overlay's last-jump line says "weapon not allowed" when this was the reason.

**Dual wielding.** With the base game's **Double Trouble** perk (Cool tree, Update 2.5) V holds a gun
in each hand, and the Shootdodge works with both: both guns must be allowed (Double Trouble only pairs
power pistols and power revolvers, so any pair it gives you is), and both fire at normal speed during
the slow-mo. If the off-hand gun is not allowed, the combo is refused with "weapon not allowed
(off-hand ...)". Single-weapon play is unchanged.

### Dual pistols, the Max Payne way (recommended)

Max Payne's signature is twin pistols. For the full look, take **Double Trouble** in the Cool tree
(Cool 9, one perk point; free, no Phantom Liberty needed) and equip the two granted Lexingtons, one in
the primary weapon slot and one in the secondary slot that the perk adds to the inventory. Then
Shootdodge as usual: both guns fire on the shoot input at full cadence while the world crawls.
[Independent Pistol Controls](https://www.nexusmods.com/cyberpunk2077/mods/35649) (left gun on left
click, right gun on right click) is optional and **untested with ShootDodge**.

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

**The Bullet Time hotkey.** **`/` (the slash key, main keyboard or numpad) is the default** when
[Input Loader](https://www.nexusmods.com/cyberpunk2077/mods/4575) is installed: the mod adds a game
input action (`r6/input/ShootDodge.xml`) on that key, on foot only. No vanilla context binds `/`
(checked against the game's `inputUserMappings.xml`), so it does nothing else. Without Input Loader, or to use another key, open the CET overlay, go to the
**Bindings** tab, find **ShootDodge** and bind **Bullet-time mode (Max Payne 2, toggle)** (CET gives
mods no way to ship a default key, so that binding starts empty; any other key nothing binds works too). Binding `/` there as well is harmless: one press toggles once. **Do not bind it
to V**: V is the vehicle summon in the base game. See [`docs/DESIGN.md`](docs/DESIGN.md) for how the
key was chosen.
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
restriction, and it carries the game's `DualWield` tag, so with Double Trouble the two Lexingtons
pair up as twin pistols (see [Dual pistols](#dual-pistols-the-max-payne-way-recommended)).

- It only grants once per save. A quest fact in the save records that, so reloading, restarting CET
  or selling a piece never re-grants it. If an item failed to arrive, the fact is left unset and the
  overlay says which, and **Check loadout now** (or the next load) gives only what is missing.
- Limits: Cyberpunk has **no tie slot**, so there is no tie. Without Double Trouble, "twin" means
  one Lexington in hand and one on the weapon wheel. The coat colour is a best match; see
  [`docs/DESIGN.md`](docs/DESIGN.md) for the research and the runners-up.

### Text from Max Payne

Once per save, about 8 seconds after V first appears (after the loadout), V's phone buzzes with a
real SMS: a new contact, **Max Payne**, in the phone's Messages app like any other contact. The
thread is a string of texts in Max's own over-the-top noir narration that explains how to
Shootdodge (aim, direction, jump, the slow-mo, landing prone, shooting or getting up, binding the
Bullet Time hotkey and the hourglass), woven around 25 genuine lines from *Max Payne* and *Max Payne
2*, each checked word for word against its source (the list is in
[`docs/DESIGN.md`](docs/DESIGN.md#in-game-text-message-c2sd-t27)).

- The contact uses the phone's existing "unknown" avatar; no new art.
- The notification pops only once per save: a quest fact (`shootdodge_intro_message`) records it, so
  reloading, restarting CET or loading an older save of the same playthrough never sends it again. The
  thread stays in the phone to re-read, and opening it marks it read in the save.
- The overlay shows the result ("sent", "already sent for this save", ...) and keeps the whole thread
  under **Texts from Max Payne**, with a **Re-send to phone** button for testing (it pops the
  notification again without touching the save's fact).
- There is no on-screen fallback. If Phone Extension (or redscript) is missing, no text arrives and the
  overlay shows "Intro message problem: phone route missing ...".

### The debug overlay

Open the CET overlay and find the **ShootDodge** window. It only draws while the CET overlay is
open; the hourglass HUD does not depend on it. Settings are not saved between sessions.

| Control | Default | What it does |
|---|---|---|
| Enabled | off | Master switch for the Shootdodge combo and its state machine. Unticking it cancels any dive in progress. The hourglass and loadout work either way. |
| Prone eye drop (m) | 1.30 (0 to 1.6) | How far the first-person camera drops while prone. |
| Bullet-time | on | World slow-mo on (dive and Bullet Time mode). Off means the dive still happens at normal speed. |
| Time scale | 0.20 (0.05 to 1.00) | World speed during slow-mo. |
| Weapon at normal speed (fire rate) | on | Keeps V's weapon's fire cycle (both guns while dual wielding) at normal speed during slow-mo. |
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
| Re-send to phone | | Under **Texts from Max Payne**: re-pops the text notification (testing; the save's fact is unchanged). |

Read-outs: the current state (`NONE`, `DIVING`, `AIRBORNE`, `PRONE`, `GETUP`) with time in state, the
last state change and last refused one, combo status and the reason the last jump was not a combo, the
locked dive direction and air time, the landing log (one line per dive, movement held or not), prone
and get-up status, world time (and whether the game is paused), how many weapons (2 while dual
wielding) are exempted and whether V is, the exact
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
- No tie (see the loadout). Dual wielding needs the game's Double Trouble perk; it has not yet been
  checked in game with ShootDodge (see `docs/TESTING.md`).
- Settings are per session. Only the hourglass level and the loadout flag are saved (in the save file).

## Building and packaging

There is no compile step: the mod is plain Lua plus one `.reds` file that redscript compiles at game
start. To build the release zip, run from the repo root:

```
powershell -ExecutionPolicy Bypass -File tools/package.ps1
```

It writes `dist/ShootDodge-<version>.zip`, with the version read from `version` in `init.lua`
(override with `-Version x.y.z`). The zip is rooted at the game folder:

```
bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua
bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/modules/*.lua
r6/scripts/ShootDodge/ShootDodgePhone.reds
```

Only git-tracked `.lua` and `.reds` files under those two folders go in (git-add a new file before
building), so docs, dev files and runtime state like `polish_restore.txt` or CET's `db.sqlite3` never
ship. The script checks the result (forward-slash entry names, every entry under one of the two
folders, `init.lua` directly in the mod folder) and prints the file list. `dist/` is tracked in git: it
keeps the released zip of every version, so commit each new `dist/ShootDodge-<version>.zip`. The
runtime files are in `.gitignore`. A quick syntax check of each Lua file is `luac -p <file>`.

## Testing

[`docs/TESTING.md`](docs/TESTING.md) is the full in-game checklist (male and female V where it
matters), with a Results table.

## Repository layout

- `bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua`: wires everything and draws the overlay.
- `.../modules/`: the pure rules modules (`StateMachine`, `ComboDetector`, `Dive`, `Prone`, `GetUp`,
  `BulletTime`, `BulletTimeMeter`, `DivePolish`, `WeaponGate`, `AimFireExemption`, `Loadout`) and the
  CET glue next to each (`*Driver.lua`, `Input.lua`). `IntroMessage` holds Max Payne's text thread.
- `r6/scripts/ShootDodge/ShootDodgePhone.reds`: the "Max Payne" phone contact (redscript, through
  Phone Extension), filled and triggered by `IntroMessageDriver.lua`.
- `r6/input/ShootDodge.xml` + `r6/scripts/ShootDodge/ShootDodgeBulletTimeKey.reds`: Bullet Time
  mode's default key (`/`, through Input Loader), read by `BulletTimeKeyDriver.lua`.
- `tools/package.ps1`: builds the Vortex-ready release zip into `dist/`.
- `docs/`: design notes, Nexus page, testing checklist and the ticket log.
