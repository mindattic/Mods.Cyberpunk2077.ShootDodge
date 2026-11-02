# Testing in game

A checklist for confirming the mod works, one case at a time. Every expected result below matches what
the code does today; if the game shows something else, that's a bug worth a ticket. Note each result in
the table at the end. Cases marked **(M)** and **(F)** are run once on a male V and once on a female V.

## Setup

1. Install Cyber Engine Tweaks and redscript (Phone Extension too, for the text cases; it may go in before or after ShootDodge;
   RED4ext + Input Loader too, for the `/` default key, cases I3-I3d), then ShootDodge: the release zip
   through Vortex (section N) or extracted into the game folder, or from the repo copy
   `bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/`, `r6/scripts/ShootDodge/` and `r6/input/` into the game's
   matching folders (see the README).
2. Start the game with Cyber Engine Tweaks installed. Load a save in an area with room to move and a few
   enemies (or a training dummy).
3. Open the CET overlay and find the **ShootDodge** window. Tick **Enabled** (it starts off every session).
   Keep the overlay open for the cases that read it; close it for a few play-feel cases.
4. Logs: the CET console and `cyber_engine_tweaks.log`. Search for `[ShootDodge]`. Healthy lines are
   `[ShootDodge] loaded`, `state X -> Y`, `combo detected`, `landing #N`, `get-up ...`. Lines ending in
   `error` or the overlay's "... problem:" lines are failures.
5. Have on hand: a pistol (the loadout's Lexington is fine), a revolver or SMG if you have one, a rifle or
   shotgun, a sniper rifle, and melee or fists. For section P (dual wielding), a V with Cool 9 and the
   **Double Trouble** perk (game 2.5 or later) and the loadout's two Lexingtons.

Abbreviations: **combo** = Ctrl + Space (either Ctrl), with or without a movement direction. **Overlay** = the ShootDodge window.

## A. Install and loading

**A1. The mod loads.** Start the game and open the CET overlay.
Expected: a **ShootDodge** window exists with an "Enabled" tick (off) and State reads `NONE`. The console
shows `[ShootDodge] loaded`.

**A2. No errors.** Load a save and play for a minute.
Expected: no `[ShootDodge] ... error` lines in the console and no "... problem:" lines in the overlay.

**A3. Overlay only while open.** Close the CET overlay.
Expected: the ShootDodge window disappears, but the hourglass (case I1) stays on screen.

## B. Input detection (C2SD-T5)

**B1. No false triggers.** Enabled. For about 1 minute with the overlay open, jump (Space) alone, Ctrl
alone, aim alone, move alone, aim and move without jumping, and jump while moving and aiming.
Expected: the Combo line's detected count stays 0, and "Last jump not a combo" gives a sensible reason
(for example "Ctrl not held").

**B2. The real combo.** Equip a pistol. Stand still on the ground, hold forward, press Ctrl + Space together (no aim).
Expected: exactly one trigger: the detected count goes from 0 to 1, the console prints one `combo detected`
line with the move direction, and V leaps.

**B3. Ctrl alone and Space alone.** Press Ctrl alone, then Space alone, on the ground.
Expected: no dive; Space is a normal jump and "Last jump not a combo" says "Ctrl not held".

**B4. Cooldown.** Complete a dive and get up, then repeat the combo within a second of the previous
trigger.
Expected: refused with "cooldown" if inside the second; works after it.

**B5. Left Ctrl dodge caveat.** Run forward, then press Left Ctrl and Space.
Expected: vanilla Left Ctrl is Dodge, so a vanilla dodge dash may start before Space; the Shootdodge
may or may not fire. Note which. Then stand still and press Left Ctrl + Space together: a clean
Shootdodge (the documented clean input). Also press Ctrl alone while moving: only the vanilla dodge.

**B6. Right Ctrl.** Stand still, press Right Ctrl + Space (Right Ctrl is Crouch, hold). Repeat with
Toggle Crouch on and V already crouched, and with Input Loader installed and removed.
Expected: a Shootdodge each time, with no vanilla dodge dash; Ctrl is read from Dodge, Crouch,
Toggle Crouch or the mod's `ShootDodgeModifier` action.

**B5. Disabled.** Untick Enabled and try the combo.
Expected: nothing happens; no state change.

## C. State machine (C2SD-T6)

**C1. NONE through normal play.** Enabled, play normally for several minutes without using the combo
(walk, sprint, jump, aim, shoot, driving).
Expected: State reads `NONE` the whole time and the combo's detected count doesn't rise.

**C2. Order of states.** Do one full dive and get up.
Expected: the state goes `NONE -> DIVING -> AIRBORNE -> PRONE -> GETUP -> NONE`, each line printed in the
console, and "Last change" in the overlay shows the latest.

**C3. Never stuck.** Do a dive, then at several points (in the air, prone, mid get-up) untick Enabled;
separately, reload CET (CET's reload) mid-dive.
Expected: State returns to `NONE`, world speed returns to normal, the camera returns to standing height.

**C4. Refused events.** Press the combo while a dive is in progress (in the air or prone).
Expected: nothing happens; no second dive starts.

## D. The dive (C2SD-T7) (M) (F)

**D1. Strafe left.** Strafe left, press Ctrl + Space.
Expected: V leaves the ground moving left of where the camera faced; the overlay reads `DIVING`, then
`AIRBORNE`, with a locked dive direction line.

**D2. Strafe right.** As D1 to the right.
Expected: V leaps right.

**D3. Backpedal.** Hold back, press Ctrl + Space.
Expected: V leaps backward.

**D4. Forward and diagonal.** Forward, then forward-left.
Expected: V leaps forward, then diagonally.

**D5. Locked direction.** In the air, press other directions and the opposite direction.
Expected: the path doesn't bend.

**D6. Free aim.** In the air, turn the camera and aim at something.
Expected: the camera turns freely and the shot goes where you aim.

**D7. First person.** Throughout D1-D6.
Expected: the camera never leaves first person.

**D8. No re-trigger.** Repeat the combo mid-air.
Expected: nothing happens; State is unchanged.

**D9. Blocked.** Try the combo in the air (after a normal jump), in a vehicle, and with no direction held.
Expected: no dive in each case; "Last jump not a combo" gives "airborne", "blocked" or "no movement
direction".

**D10. Blocked leap.** Aim and dive straight at a wall from close range.
Expected: no crash; the dive ends cleanly within about 0.6 s ("Last dive ended" in the overlay) and State
returns to `NONE`.

## E. Bullet-time (C2SD-T8)

**E1. World slows.** Dive.
Expected: enemies, NPCs, projectiles and the environment visibly slow; the overlay shows World time
`0.20x (slowed)`.

**E2. Clears on landing.** Dive and land.
Expected: World time returns to `1.00x` the frame V touches down; no lingering slow-mo.

**E3. Pause mid-dive.** Dive, open the pause menu while airborne, wait, then resume.
Expected: the world isn't stuck slowed after resume. While paused the overlay says "game paused". If V
is still in the air on resume the slow-mo returns and ends on landing; if V landed while paused it stays
normal.

**E4. Death.** Dive while taking damage until V dies (or use a safe way to die).
Expected: slow-mo does not persist after death.

**E5. Time scale slider.** Set Time scale to 0.5, dive, then to 0.05, dive, then 1.00, dive.
Expected: the world speed follows the slider each time. At 1.00 the dive still happens at normal speed,
with no slow-mo.

**E6. Bullet-time tick.** Untick Bullet-time, dive.
Expected: the dive happens with no slow-mo; re-tick it and slow-mo returns.

## F. Aim and fire stay fast (C2SD-T9)

**F1. Fire rate.** Dive and fire a pistol continuously, with the world slowed.
Expected: shots fire at the same cadence as when not diving (count the shots per second against normal
fire) while everything else is visibly slow.

**F2. Aim speed with the mouse.** In the dive, flick the mouse.
Expected: the camera turns at normal speed.

**F3. Things that stay slow.** Watch bullets, enemies and V's fall arc.
Expected: all slowed.

**F4. Weapon swap.** Swap between two allowed weapons during the dive.
Expected: the new weapon fires at full cadence too (the overlay "Exempt now: weapons 1").

**F5. Gamepad.** On a pad, dive and turn.
Expected (known limitation): turning is slow. Tick "All of V at normal speed" and it turns at normal speed,
but V's fall arc is faster.

**F6. Exemption clears.** Land.
Expected: the overlay says "Exempt now: weapons 0 | V no"; the weapon fires normally.

## G. Landing (C2SD-T10)

**G1. One landing per dive.** Dive and land, movement released.
Expected: the Landings count rises by exactly 1; the console prints one `landing #N` line saying
"movement not held".

**G2. Held flag.** Dive and keep holding a direction through the touchdown.
Expected: one landing line saying "movement held".

**G3. Always prone.** Each landing in G1-G2.
Expected: State goes to `PRONE` either way, never directly to `NONE`.

**G4. Graze.** Dive past a low obstacle or ledge so V clips it mid-air.
Expected: no early landing: the dive carries on (the landing line shows grazes counted) and slow-mo lasts
until the real touchdown.

**G5. Cap.** (Optional) Dive off a very high ledge.
Expected: it lands whenever V touches down, or aborts to `NONE` at the 4 second cap; slow-mo still clears.

## H. Prone and get-up (C2SD-T11, C2SD-T12) (M) (F)

**H1. Prone shooting.** Dive, release movement before landing.
Expected: V ends prone: the first-person view drops close to the floor (eye about 0.4 m high) within a
fraction of a second. The overlay says Prone: down, with the eye height. Aim 360 degrees and fire.
V shoots in every direction without standing up.

**H2. No timer.** Stay prone for 30 seconds or more.
Expected: V stays prone and State stays `PRONE`.

**H3. Get up with a move key.** From prone, press forward.
Expected: State goes `PRONE -> GETUP -> NONE`; the camera rises over about 0.7 s while V scrambles a
short way in that direction at a capped speed; full control returns when it ends. First person throughout.

**H4. Any direction.** Repeat with left, right and back.
Expected: the get-up works with each.

**H5. Held through the landing.** Dive and keep holding forward through touchdown.
Expected: V hits the ground, stays down for about a quarter second, then gets up on its own without a new
press.

**H6. Jump does not stand.** From prone, press jump only.
Expected: V stays prone.

**H7. Held key must be released.** Dive while holding a direction and then, after landing, release it and
press it again (rather than letting the held-at-impact rule stand V up: do this by releasing before
touchdown, then pressing within 0.25 s of impact).
Expected: a press within the first 0.25 s after impact does not stand V up; a press after that does.

**H8. Knocked off a ledge.** Go prone at a ledge edge and push V off (or roll over it).
Expected: after about 0.4 s of being off the ground, State aborts to `NONE` and the camera rises.

**H9. Eye drop slider.** Change Prone eye drop to 0.5 and 1.6, dive.
Expected: the camera's prone height changes to match.

**H10. Standing hitbox.** (Known limitation.) Lie prone in cover and let an enemy shoot.
Expected: V's collision is still standing, so shots hit as if standing. Note it only.

## I. Hourglass and Bullet Time mode (C2SD-T15)

**I1. HUD.** Close the CET overlay.
Expected: an hourglass shows in the lower left, full at the start, with white sand. It hides in menus and
while paused.

**I2. HUD toggle.** In the overlay, untick Hourglass HUD.
Expected: the hourglass hides; tick it and it returns.

**I3. The hotkey.** With Input Loader installed (and RED4ext), leave the CET binding
"Bullet-time mode (Max Payne 2, toggle)" **unbound**. The I4/I5 "hotkey" is **`/`**. Do not
use V for the CET binding: it summons the vehicle. Confirm `/` does nothing else on foot.
Expected: the binding is listed under ShootDodge and can be bound; the overlay line "Bullet Time key"
says "game key route: listening".

**I3a. `/` with no binding (C2SD-T37, C2SD-T39).** Input Loader installed, CET binding unbound, Enabled
ticked, on foot. Press `/`.
Expected: Bullet Time mode starts; press again, it stops. `red4ext/logs/input_loader.log` lists
`ShootDodge.xml` with no error; the overlay's "Bullet Time key" line counts the presses and says
"game press ... toggled". Main and Numpad Enter do nothing now. In a
vehicle and in menus, `/` does not toggle.

**I3b. Once per press (C2SD-T37).** Also bind `/` in the CET Bindings tab. Press it once,
then several times at a normal pace.
Expected: each press toggles exactly once (the overlay shows "... ignored (same press as ...)" for the
second route); the mode never flips on and straight back off.

**I3c. No Input Loader (C2SD-T37).** Remove Input Loader (or its `r6/input/ShootDodge.xml` effect:
disable the plugin), start the game, bind the CET binding to `/`.
Expected: no error at startup; the overlay says "0 presses (none = Input Loader missing?)" and
`/` toggles the mode through the CET binding alone, once per press. Unbind it again: `/` does nothing.

**I3d. Dialogue Enter (C2SD-T39).** On foot with Input Loader, pick a dialogue choice with
Enter, then press main and `/` in normal play.
Expected: Bullet Time does not toggle (the default is `/`, which no vanilla context uses).

**I4. Mode on.** Press the hotkey in normal play with Enabled ticked.
Expected: the world slows to the time scale; aim and fire stay fast; the hourglass sand drains from the
top bulb; the overlay says mode ON and the button reads "Stop bullet-time mode".

**I5. Mode off.** Press the hotkey again.
Expected: the world returns to normal at once and the sand stops draining and starts refilling.

**I6. Drain rate.** From full, leave the mode on.
Expected: it runs about 10 seconds, then ends on its own with the world back at normal speed, and the
overlay says "Bullet-time mode last ended" with the reason.

**I7. Won't start empty.** Press "Empty meter", then press the hotkey.
Expected: the mode doesn't start (under 2% sand).

**I8. Passive refill.** From empty, wait with the mode off.
Expected: the level climbs steadily to full in about 80 seconds.

**I9. Kills refill.** From a low level, kill an enemy.
Expected: the level jumps by about 15% (overlay "last +0.150"), Kills counted rises by 1, and the sand
turns yellow, fading back to white over a few seconds. Killing several in quick succession is yellower.
Level never exceeds full.

**I10. Not for non-V kills.** Watch an enemy killed by another NPC or by a car not driven by V.
Expected: no refill and the kills count doesn't rise.

**I11. A dive costs nothing.** Note the level, dive and land.
Expected: the level didn't go down (it only rises by regen); a dive with an empty hourglass still slows
time.

**I12. Dive ends the mode.** Turn the mode on, then do the combo.
Expected: the mode ends ("Bullet-time mode last ended" gives the dive as reason) and the dive slow-mo
carries on.

**I13. Mode can't start mid-dive.** Press the hotkey while airborne from a dive.
Expected: it does nothing.

**I14. Mode with slow-mo off.** Untick Bullet-time (or set Time scale to 1.00) and press the hotkey.
Expected: the mode refuses to start and the hourglass doesn't drain.

**I15. Pause.** Turn the mode on and open the pause menu.
Expected: the sand doesn't drain while paused and the world isn't stuck slowed after resume.

**I16. Persistence.** Note the level, save, reload the save.
Expected: the hourglass returns to about the saved level. A save made before the mod was installed starts full.

**I17. Disable ends the mode.** Turn the mode on and untick Enabled.
Expected: the mode ends and the world returns to normal.

**I18. Chain dives to empty.** Chain several dives, then try to enter the mode.
Expected: dives always slow time; only Bullet Time mode is refused with an empty hourglass.

## J. Weapon restriction (C2SD-T13)

**J1. Sniper blocked.** Equip a sniper rifle and try the combo.
Expected: no trigger; "Last jump not a combo: weapon not allowed".

**J2. Pistol allowed.** Switch to a pistol and try it again without any restart.
Expected: it triggers normally.

**J3. Each type.** Try pistol, revolver, SMG (all allowed), then assault rifle, shotgun, LMG, melee weapon
and bare fists (all blocked), and holstered or unarmed.
Expected: exactly the pistols, revolvers and SMGs trigger.

**J4. Swap on the fly.** Alternate allowed and blocked weapons within one session.
Expected: each jump follows the weapon equipped at that moment.

## K. Camera and audio polish (C2SD-T14)

**K1. FOV.** Dive and watch the camera.
Expected: the FOV widens by about 12 degrees over about 0.15 s while airborne, then returns smoothly
(about 0.25 s) after landing, to the exact FOV it had before. The overlay shows the FOV applied.

**K2. Whoosh.** Dive.
Expected: one whoosh plays on dive entry, exactly once per dive. The overlay's Play button plays it too.

**K3. Music duck.** Play with music audible (driving with the radio is good), then dive.
Expected: the music drops to about 35% of its volume during the dive and returns on landing.

**K4. Independent toggles.** Untick FOV pull-back, then Whoosh on dive, then Muffle music/ambience, one at a
time, dive each time.
Expected: only the unticked effect is missing; the other two still work.

**K5. Sliders.** Set Pull-back to 0 and 30; Music kept to 0 and 1.
Expected: each takes effect on the next dive (0 = no FOV change; 1 = no duck).

**K6. Both exit paths.** Dive then stay prone; dive then get up.
Expected: all three effects start at dive entry and revert on landing in both cases.

**K7. Abort and pause.** Untick Enabled mid-dive; pause mid-dive.
Expected: FOV and music return to normal.

**K8. Crash safety.** Mid-dive, reload CET or kill the game, restart and load.
Expected: your music volume is back to your own setting.

**K9. Low-pass events.** With the two event fields empty (default), dive.
Expected: no error; only the volume duck acts. (Optionally type event names in and confirm they play.)

## L. Max Payne 2 loadout (C2SD-T4) (M) (F)

**L1. First grant.** Load a save that never had the mod. Wait a couple of seconds, open the inventory.
Expected: two Lexington pistols, a coat, a formal shirt, formal trousers and formal shoes appear. The
overlay shows a granted result.

**L2. Equip.** Equip every piece.
Expected: they equip and render correctly on this V's body. Note the coat colour (a darker variant is a
note, not a failure) and that there is no tie.

**L3. Twin pistols.** Put one Lexington in hand and the other on the weapon wheel.
Expected: both are listed as separate items, and the equipped one passes the weapon gate (the combo works).

**L4. No duplicates.** Reload the save, restart the game, and reload CET.
Expected: nothing is added again.

**L5. Sold stays sold.** Sell the coat and reload.
Expected: it isn't given back.

**L6. Check loadout now.** Press the button.
Expected: nothing is added when the fact is set; the result line says it is already granted.

**L7. New save.** Start a new game or a different V and check the inventory.
Expected: the loadout is granted once again for that save.

Run L1-L7 on both a male V and a female V.

## M. Everything together

**M1. Combat run.** In a fight, dive, shoot a few enemies from the air, land prone, shoot more from the
floor, stand, and repeat with the hourglass mode in between.
Expected: no stuck slow-mo, no stuck camera, no console errors, and the hourglass refills with kills.

**M2. Save and load mid-states.** Save while prone, while in the air (if possible), and in Bullet Time mode,
then load.
Expected: on load State is `NONE`, the world is at normal speed and the camera at standing height.

## N. Vortex install (C2SD-T27)

Build the zip first: `powershell -ExecutionPolicy Bypass -File tools/package.ps1` (it prints the
entries). Use a Vortex profile with Cyber Engine Tweaks, redscript and Phone Extension already
installed, and no copy of ShootDodge in the game folder.

**N1. Zip layout.** Open `dist/ShootDodge-<version>.zip`.
Expected: only `bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua`, its `modules/*.lua`,
`r6/scripts/ShootDodge/*.reds` (the phone contact and `ShootDodgeBulletTimeKey.reds`) and `r6/input/ShootDodge.xml`. No docs, no `polish_restore.txt`, no `db.sqlite3`,
no logs.

**N2. Install From File.** In Vortex's Mods page, **Install From File** and pick the zip.
Expected: it installs with no "manual install", "fallback installer" or "install as-is" prompt. Vortex's
log (Settings > Vortex > open the log, or `%APPDATA%\Vortex\vortex.log`) has a `MultiType` line
for this mod.

**N3. Deploy.** Enable the mod and deploy.
Expected: `<game>/bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua` and
`<game>/r6/scripts/ShootDodge/ShootDodgePhone.reds` and `<game>/r6/input/ShootDodge.xml` exist (as Vortex links), and nothing landed
anywhere else (no stray `bin` or `ShootDodge` folder at the game root).

**N4. It runs.** Start the game.
Expected: no redscript compile error at startup, and cases A1 and O1 pass.

**N5. Uninstall.** Disable and remove the mod in Vortex, then deploy.
Expected: the mod's files are gone from the game folder, and the game starts with no redscript error.

## O. Text from Max Payne (C2SD-T27)

Needs redscript and Phone Extension (setup step 1). The text does not depend on the **Enabled** tick.

**O1. First text.** Load a save that never had the mod (or start a new game). Wait about 10 seconds
after V appears, unpaused.
Expected: the phone's "new message" notification pops with the sender **Max Payne** and the line
"The sun went down with practiced bravado." The overlay line reads `Text from Max Payne: sent`, and
the console shows `[ShootDodge] text from Max Payne sent to V's phone`.

**O2. A real phone text.** Open the phone (or use the notification's action) and go to Messages.
Expected: a **Max Payne** contact with an unread badge and the generic "unknown" avatar. Opening it
shows a thread of 14 texts from Max Payne, in his first person, ending with "The dead never check
their messages." No popup or on-screen banner text is used anywhere.

**O3. Content.** Read the thread.
Expected: it covers Ctrl + Space with a direction, pistol/revolver/SMG only, the slow-mo with aim and fire at
full speed, landing prone and shooting or moving/jumping to get up, holding the direction through the
landing, and binding Bullet Time in the overlay's Bindings tab with the hourglass (drains while on,
refills on its own and with kills, a shootdodge costs nothing).

**O4. Read state.** Close and reopen the phone's Messages.
Expected: the unread badge is gone after opening the thread once.

**O5. Never re-sent.** Save, reload that save, restart the game, and reload CET (overlay's Reload all
mods) in game.
Expected: no notification ever again on that save. The Max Payne thread is still in Messages (read),
and the overlay says `already sent for this save (read)`.

**O6. Unread survives a reload.** On a fresh save, let the text arrive, don't open it, save and
reload.
Expected: no new notification, and the thread is still there with its unread badge; the overlay says
`already sent for this save (unread)`.

**O7. Another save.** Load a different save that never had the mod.
Expected: the text arrives once for that save, as in O1.

**O8. Missing framework.** Remove Phone Extension only (keep ShootDodge's `.reds`) and load a save.
Expected: redscript compiles with no error (the phone script compiles to nothing), the game and all
other redscript mods work, no text, no on-screen substitute, and the overlay shows `Intro message
problem: phone route missing ...`. Put Phone Extension back afterwards.

The overlay's **Re-send to phone** button (under **Texts from Max Payne**) pops the notification
again for retesting O2-O4 without a new save; it does not change the save's fact.

## P. Dual wielding with Double Trouble (C2SD-T30)

Needs game 2.5 or later and a V with Cool 9 and the **Double Trouble** perk (Cool tree). Equip one
Lexington in the primary weapon slot and the other in the secondary slot the perk adds, and draw them
so V holds one in each hand. Keep the overlay open.

**P1. Lexingtons qualify.** Open the inventory with the perk bought.
Expected: the second Lexington can go in the secondary (dual-wield) slot; drawn, V holds both.

**P2. The combo arms.** With both guns drawn, do the combo.
Expected: it triggers and V leaps (the combo's detected count rises by 1).

**P3. Both guns at full cadence.** Dive and fire continuously.
Expected: both guns fire at the same cadence as out of the dive while the world is slowed; the overlay
reads "Exempt now: weapons 2".

**P4. Clears on landing.** Land.
Expected: "Exempt now: weapons 0 | V no", and the world and both guns are back at normal speed.

**P5. Clears on weapon swap.** Dive with both guns, then swap to a single weapon (or holster) mid-dive.
Expected: the count follows what is held (1, or 0 when holstered), and on landing it reads 0. Swap back
to the pair in a later dive and it reads 2 again.

**P6. Clears on a CET reload.** Dive with both guns and reload CET mid-dive, then trigger a game slow-mo
(Kerenzikov or Sandevistan) after landing.
Expected: both guns slow with the world under the game's own slow-mo (neither was left exempted).

**P7. Off-hand not allowed.** (Only if a mod such as Dual Wield Any Weapon lets you pair a pistol with
a non-allowed gun.) Hold the pair and do the combo.
Expected: no trigger; "Last jump not a combo: weapon not allowed (off-hand ...)".

**P8. Single weapon unchanged.** Unequip the secondary gun and repeat B2, F1 and F6.
Expected: exactly as before ("Exempt now: weapons 1" during the dive).

**P9. Independent Pistol Controls (optional, untested).** If you use
[Independent Pistol Controls](https://www.nexusmods.com/cyberpunk2077/mods/35649), note whether the
combo still detects Ctrl + Space and whether each gun fires at full cadence in the dive.
Expected: note the result only; it is not a requirement.

## Q. Space is the Shootdodge in Bullet Time mode (C2SD-T38)

Enabled, a pistol drawn, a full hourglass (overlay **Refill meter**), the Bullet Time hotkey bound
(case I3). Keep the overlay open.

**Q1. Overlay hint.** Start Bullet Time mode.
Expected: the overlay shows "Space = Shootdodge (Bullet Time)" under the Combo line; stop the mode and
the line disappears.

**Q2. Space with a direction.** Start Bullet Time mode, hold strafe left (no aim, no Ctrl), press Space.
Expected: V dives left relative to the camera, locked as usual; the detected count rises by 1, the
mode ends ("Bullet-time mode last ended: shootdodge") and the dive's slow-mo carries on to the landing.

**Q3. Space with no direction.** Start Bullet Time mode, stand still, no aim, press Space.
Expected: V dives straight forward (where the camera faces); the console's `combo detected` line
shows move 0.00, 1.00.

**Q4. Disallowed weapon.** Draw a rifle or shotgun (or fists), start Bullet Time mode, press Space
(with and without a direction).
Expected: a normal jump, no dive; "Last jump not a combo: weapon not allowed (...)"; the mode stays on.

**Q5. Guards still apply.** In Bullet Time mode: press Space mid-air (jump first, then Space again),
and right after a Q2 dive's landing restart the mode and press Space within a second of the last
trigger.
Expected: no dive mid-air ("airborne"), none while prone or getting up (Space never stands V up), and
"cooldown" inside the second.

**Q6. Space outside Bullet Time mode.** Mode off, press Space alone, then with a direction held.
Expected: normal jumps, no dive ("Ctrl not held"); Ctrl + Space (B2) still works.

## Results

| Case | Pass / Fail | Notes |
|---|---|---|
| A1 |  |  |
| A2 |  |  |
| A3 |  |  |
| B1 |  |  |
| B2 |  |  |
| B3 |  |  |
| B4 |  |  |
| B5 |  |  |
| B6 |  |  |
| B5 |  |  |
| C1 |  |  |
| C2 |  |  |
| C3 |  |  |
| C4 |  |  |
| D1 (M) |  |  |
| D1 (F) |  |  |
| D2 |  |  |
| D3 |  |  |
| D4 |  |  |
| D5 |  |  |
| D6 |  |  |
| D7 |  |  |
| D8 |  |  |
| D9 |  |  |
| D10 |  |  |
| E1 |  |  |
| E2 |  |  |
| E3 |  |  |
| E4 |  |  |
| E5 |  |  |
| E6 |  |  |
| F1 |  |  |
| F2 |  |  |
| F3 |  |  |
| F4 |  |  |
| F5 |  |  |
| F6 |  |  |
| G1 |  |  |
| G2 |  |  |
| G3 |  |  |
| G4 |  |  |
| G5 |  |  |
| H1 (M) |  |  |
| H1 (F) |  |  |
| H2 |  |  |
| H3 |  |  |
| H4 |  |  |
| H5 |  |  |
| H6 |  |  |
| H7 |  |  |
| H8 |  |  |
| H9 |  |  |
| H10 |  |  |
| I1 |  |  |
| I2 |  |  |
| I3 |  |  |
| I4 |  |  |
| I5 |  |  |
| I6 |  |  |
| I7 |  |  |
| I8 |  |  |
| I9 |  |  |
| I10 |  |  |
| I11 |  |  |
| I12 |  |  |
| I13 |  |  |
| I14 |  |  |
| I15 |  |  |
| I16 |  |  |
| I17 |  |  |
| I18 |  |  |
| J1 |  |  |
| J2 |  |  |
| J3 |  |  |
| J4 |  |  |
| K1 |  |  |
| K2 |  |  |
| K3 |  |  |
| K4 |  |  |
| K5 |  |  |
| K6 |  |  |
| K7 |  |  |
| K8 |  |  |
| K9 |  |  |
| L1 (M) |  |  |
| L1 (F) |  |  |
| L2 (M) |  |  |
| L2 (F) |  |  |
| L3 |  |  |
| L4 |  |  |
| L5 |  |  |
| L6 |  |  |
| L7 |  |  |
| M1 |  |  |
| M2 |  |  |
| N1 |  |  |
| N2 |  |  |
| N3 |  |  |
| N4 |  |  |
| N5 |  |  |
| O1 |  |  |
| O2 |  |  |
| O3 |  |  |
| O4 |  |  |
| O5 |  |  |
| O6 |  |  |
| O7 |  |  |
| O8 |  |  |
| P1 |  |  |
| P2 |  |  |
| P3 |  |  |
| P4 |  |  |
| P5 |  |  |
| P6 |  |  |
| P7 |  |  |
| P8 |  |  |
| P9 |  |  |
| Q1 |  |  |
| Q2 |  |  |
| Q3 |  |  |
| Q4 |  |  |
| Q5 |  |  |
| Q6 |  |  |
