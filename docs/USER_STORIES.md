---
codex: 1
project: Mods.Cyberpunk2077.ShootDodge
code: C2SD
layer: stories
status: living
updated: 2026-11-01
---
<!-- GENERATED from MindAttic.Tickets/data/Tickets.db by `tickets db render`. Do not edit: this file is rewritten from the database; change stories and tickets with the tickets CLI. -->

# Mods.Cyberpunk2077.ShootDodge — User Stories
> ✅ done (shipped & tested) · 🟡 partial · ⬜ planned. Every ✅ cites the test.

## Priority backlog
_Nothing recorded yet._


## Epic D — Max Payne 2 style Shootdodge: dive, bullet-time, prone/get-up, and signature loadout
- **C2SD-US-D1 ⬜** As V, male or female, I want the exact look and weapons Max Payne wears in Max Payne 2, rebuilt as closely as possible from Cyberpunk 2077's existing items, so the Shootdodge comes with the signature look.
- **C2SD-US-D2 ⬜** As V, I want the mod to recognize a dedicated Shootdodge input combo (aim held + jump + a movement direction) without misfiring during normal play, so the move triggers only when I mean it to.
- **C2SD-US-D3 ⬜** As V, I want the mod's state machine to show my current Shootdodge state (NONE/DIVING/AIRBORNE/PRONE/GETUP) at all times, so every later mechanic is built and debugged against one known state.
- **C2SD-US-D4 ⬜** As V, I want the input combo to launch me into a horizontal leap in the direction I'm moving, locked for the whole dive, so I leave the ground the way Max Payne does.
- **C2SD-US-D5 ⬜** As V, I want world time to slow dramatically for the duration of the dive, so the moment feels like Max Payne's bullet-time instead of an ordinary jump.
- **C2SD-US-D6 ⬜** As V, I want my aim turn-speed and weapon fire-rate to stay at normal speed while the world is slowed, so I can place shots precisely instead of fighting slow-motion input.
- **C2SD-US-D7 ⬜** As V, I want the mod to detect the exact moment I hit the ground after a dive, so slow-mo ends there and I'm put down prone.
- **C2SD-US-D8 ⬜** As V, I want to land prone and keep firing from the ground when I land without holding movement, so I can keep shooting from the floor like Max Payne.
- **C2SD-US-D9 ⬜** As V, lying on the ground after a dive, I want to press a movement input to scramble back to my feet, so the dive flows back into normal play when I choose.
- **C2SD-US-D10 ⬜** As V, I want the Shootdodge restricted to pistols, revolvers and small SMGs, so I can't trigger it while carrying a sniper rifle or a heavy weapon.
- **C2SD-US-D11 ⬜** As V, I want camera FOV pull-back, a whoosh cue, and a muffled low-pass on music/ambience during the dive, so the move reads as cinematic rather than a glitch.
- **C2SD-US-D12 ⬜** As V, I want a Max Payne style bullet-time meter that the dive's slow-mo drains and that refills the way Max Payne's does, so I can't stay in slow-mo forever and have to earn it back.

## Tickets
> Permanent log of every change and fix — this repo's ticket system. Rows are append-only: never
> delete or reword one; only move its Status (open → closed / wont-do) and fill in Ref. Status is
> a word, not a glyph, so tickets don't count toward the story index. Keep this section last.

| ID | Date | Type | Status | Summary | Ref |
|---|---|---|---|---|---|
| C2SD-T1 | 2026-11-01 | docs | closed | Start the permanent ticket log in the ticket database | — |
| C2SD-T2 | 2026-11-01 | docs | closed | Start the permanent ticket log in the ticket database | — |
| C2SD-T3 | 2026-11-01 | chore | closed | Scaffold new repo: Cyberpunk 2077 mod for Max Payne 2 style Shootdodge (dive, bullet-time, prone/get-up) plus twin pistols + trench coat loadout | 7fd712eebb5ef5b40fe6e6e1b5120afbf0c4e96e |
| C2SD-T4 | 2026-11-01 | feature | closed | Max Payne 2 outfit + twin pistols, closest existing items for male and female V, no new assets | ec18bd4c8505e9115cb4063757d7b4f8c37fbc85 |
| C2SD-T5 | 2026-11-01 | feature | closed | Shootdodge input detection: aim+jump+move combo, debounced against normal play | ac06f0e |
| C2SD-T6 | 2026-11-01 | feature | closed | Formalize Shootdodge state machine (NONE/DIVING/AIRBORNE/PRONE/GETUP) + debug overlay | a1bd8b0aa13c44f5f958d12de3c6375bb1f8f8e8 |
| C2SD-T7 | 2026-11-01 | feature | closed | Dive trigger: launch V into a horizontal leap in the held movement direction, locked for the whole dive | e4c815b |
| C2SD-T8 | 2026-11-01 | feature | closed | Bullet-time: world time dilation for the duration of the dive | 0aa816cd4ae6e400f685ebe0894388d73dabe756 |
| C2SD-T9 | 2026-11-01 | feature | closed | Responsive aim+fire during slow-mo: exempt player turn-speed and fire-rate from the dilation | 90d05c1e0d895feebb7bc90efa7de67a0f6be3a0 |
| C2SD-T10 | 2026-11-01 | feature | closed | Ground-contact detection: detect landing, always go prone, record held movement input | 4b73b985c70ee31968ca36e625dd47f7f9ccd3f8 |
| C2SD-T11 | 2026-11-01 | feature | closed | Prone-and-shoot state: land prone, keep free-aim firing from the ground | 1bab021188a8a8878837e510ad572fa1d195f09c |
| C2SD-T12 | 2026-11-01 | feature | closed | Get-up recovery: from prone, a movement input scrambles V back to their feet | 6341258 |
| C2SD-T13 | 2026-11-01 | feature | closed | Weapon restriction: gate the dive trigger to pistols/revolvers/small SMGs only | fb9449d |
| C2SD-T14 | 2026-11-01 | feature | closed | Camera + audio polish: FOV pull-back, whoosh cue, music/ambience low-pass during the dive | b6b96dc99d965432c1c2de4755f0cc8900a030d3 |
| C2SD-T15 | 2026-11-01 | feature | closed | Bullet-time meter: Max Payne 2 style hourglass that the dive drains and that refills the way MP2's does | 223ceb6a |
| C2SD-T16 | 2026-11-01 | fix | closed | init.lua 'Enabled' (line 126) and 'Bullet-time' (line 163) checkboxes read ImGui.Checkbox's returns swapped: CET returns (value, pressed), so the flag is true only on the click frame and the whole mod stays effectively off | ac9944b5c8fccf337d26f2aaaf7b1be8f7094474 |
| C2SD-T17 | 2026-11-01 | docs | closed | Full documentation set like the RogueTrader.* mods: README usage guide, docs/NEXUS_PAGE.md, docs/TESTING.md | 856de32 |
| C2SD-T18 | 2026-11-01 | fix | closed | init.lua:192 onDraw draws the debug window every frame without tracking onOverlayOpen/onOverlayClose, so the debug panel stays over gameplay with the CET overlay closed; only the hourglass HUD should draw then (found by bughunt) | 3cfd4424afe8f35c0612d2d74b5950fe9342ea4a |
| C2SD-T19 | 2026-11-01 | fix | closed | DiveDriver.lua:107-145 dive timers (4 s cap, 0.6 s no-lift-off) keep advancing while the game is paused (TimeScale() returns 1 once slow-mo is lifted), so pausing mid-dive aborts it on resume: no prone, no slow-mo (found by bughunt) | e01586e |
| C2SD-T20 | 2026-11-01 | fix | closed | Dive.lua:149 touchdown only counts once airTime >= minAirSec, so a dive that comes down in under 0.15 s (low ceiling, onto a step) never lands and sits in AIRBORNE slow-mo until the 4 s timeout, ending in NONE instead of prone (found by bughunt) | 855e54a |
| C2SD-T21 | 2026-11-01 | fix | closed | Input.lua:166 Input.Reset() only runs on onShutdown, never on save load/session start, so held aim (with its old aimSince) and stale move axes carry into a loaded save and the combo can fire without aiming (found by bughunt) | 2435523d72fa91e13cc30f164b1f857f0fc33a15 |
| C2SD-T22 | 2026-11-01 | fix | closed | BulletTimeMeter.lua:128 Bullet Time mode drains the meter on self.mode alone, while BulletTime:Wanted (BulletTime.lua:59,64) grants no slow-mo when the Bullet-time checkbox is off or the factor is 1.0, so the hourglass empties with no slow-mo at all (found by bughunt) | 67ef55404042e09c612f1fbd795044c1bef317ef |
| C2SD-T23 | 2026-11-01 | fix | closed | BulletTimeMeterDriver.lua:112-119 meter session tied to QuestTrackerGameController init/uninit: a mid-session HUD rebuild cancels Bullet Time mode and stops saving, and a Restore before the save's facts are readable resets the meter to full then Persist overwrites the real saved level (found by bughunt) | 0ff22150faf8a5e64160c8bece35c61017d93105 |
| C2SD-T24 | 2026-11-01 | fix | closed | BulletTimeDriver.lua:149-156 a CET reload during slow-mo leaves the old weapon's individual time-dilation exemption on for good (the fresh module's exemptWeapon is nil, so Clear() can't unset it), so that weapon ignores later game slow-mo like Kerenzikov (found by bughunt) | 926bec9 |
| C2SD-T25 | 2026-11-01 | fix | closed | LoadoutDriver.lua:79,83 ignores Game.AddToInventory's success return and writes the shootdodge_mp2_loadout save fact anyway, so a failed add (bad item ID after a patch, refused add) marks the loadout granted for good and V never gets the missing pieces (found by bughunt) | 795920568430ae9850093e79c379176920ff5d11 |
| C2SD-T26 | 2026-11-01 | fix | closed | ProneDriver.lua stand-up on jump (Prone.End.jump) + GetUpDriver.lua:78: the jump press is only observed, not consumed, so it also runs the game's real jump and V hops out of prone instead of scrambling up; count only movement as stand-up or block the jump during PRONE/GETUP (found by bughunt) | 8843ddfa6a691cdc32f00010baa4ae0027efd5d0 |
| C2SD-T27 | 2026-11-01 | feature | closed | Vortex-ready release zip + once-per-save in-game text message explaining the mod in Max Payne's over-the-top noir voice, using real sourced Max Payne quotes | af32cdd9410f4141a7c5cb85673afd736a63cf34 |
| C2SD-T28 | 2026-11-01 | docs | closed | Research Cyberpunk 2077 akimbo/dual-wield pistol mods for Max Payne's twin Berettas: what exists, does it work on 2.x, recommend support or not | c554b04 |
| C2SD-T29 | 2026-11-01 | fix | closed | r6/scripts/ShootDodge/ShootDodgePhone.reds hard-depends on Phone Extension: without it redscript compilation fails and breaks every redscript mod the player has; guard the file with redscript conditional compilation (@if(ModuleExists(...)) on Phone Extension's module) so it compiles to nothing when the framework is absent, and update README/NEXUS_PAGE to call Phone Extension optional for the text | 6bc082619f5d7ffee658af03eeaa8dece254e9ca |
| C2SD-T30 | 2026-11-01 | feature | closed | Dual-wield support: Shootdodge with the 2.5 Double Trouble perk, both pistols exempt from slow-mo and passing the weapon gate, docs recommend it | c0fd879 |
| C2SD-T31 | 2026-11-01 | fix | closed | init.lua:150-161 C2SD-T19 pause fix is incomplete: ProneDriver.Update and GetUpDriver.Update still run on real deltaTime while paused, so the 0.25 s held-at-impact beat and the 0.7 s get-up scramble (and its per-frame pushes) advance during the pause menu; skip or zero them when paused like DiveDriver (found by bughunt) | 169c03d85184f514770a5f60eadb1d0a9ade1b48 |
| C2SD-T32 | 2026-11-01 | fix | closed | LoadoutDriver.lua:80-82 C2SD-T25 treats a nil return from Game.AddToInventory as failure; if CET's helper returns nothing, every add counts as failed, the save fact is never written and sold pieces are re-granted every load; judge success by re-counting what V holds after the add instead (found by bughunt) | b51ea4a |
| C2SD-T33 | 2026-11-01 | fix | closed | init.lua:208 overlayOpen starts false, and a CET 'Reload all mods' done with the overlay open never fires onOverlayOpen, so the ShootDodge debug window stays hidden until the overlay is closed and reopened (found by bughunt) | ae0a190 |
| C2SD-T34 | 2026-11-01 | chore | closed | Build the v1.0.0 release zip (dist/ShootDodge-1.0.0.zip) with tools/package.ps1 | c0fd879 dist/ShootDodge-1.0.0.zip |
| C2SD-T35 | 2026-11-01 | chore | closed | Track dist/ in git: dist/ holds the released zips of each version of the mod; un-ignore it and commit dist/ShootDodge-1.0.0.zip | 55c2f5d |
| C2SD-T36 | 2026-11-01 | fix | closed | Bullet Time toggle defaults to Numpad Enter (V summons the vehicle); confirm it's unused, set it as the CET default if possible; Max Payne's texts teach the CET steps (open overlay, tick Enabled, Bindings tab, rebind); update docs | fbebd54 |
| C2SD-T37 | 2026-11-01 | feature | closed | Bullet Time mode defaults to Numpad Enter via an Input Loader input action (r6/input XML), with the CET binding kept as fallback/rebind | 593bf982863edc03934743cafec26a2a1bfbddff |
| C2SD-T38 | 2026-11-01 | feature | closed | In Bullet Time mode, Space is the Shootdodge (no aim needed, held direction or forward) instead of a regular jump | f12aa42 |
| C2SD-T39 | 2026-11-01 | fix | closed | Bullet Time default key: move off IK_Enter (also main Enter and the on-foot dialogue confirm) to a key no vanilla context binds, verified from the user's inputUserMappings.xml; update docs and Max's text | 26224f4 |
| C2SD-T40 | 2026-11-01 | fix | closed | Bullet Time default key: user has no Mouse 4; switch the default to / (IK_Slash), verified unbound in vanilla inputUserMappings.xml; update docs and Max's text | 57d064e |
| C2SD-T41 | 2026-11-01 | chore | closed | Release v2.0.0: bump version, changelog, build dist/ShootDodge-2.0.0.zip, redeploy to the user's Vortex | 5e40b34 |
| C2SD-T42 | 2026-11-01 | fix | closed | ShootDodge: Cyberpunk 2077 never reaches the main menu (crash before launcher completes) | b40eafb |
| C2SD-T43 | 2026-11-01 | fix | closed | Game crashes with only ShootDodge 2.0.0 enabled (diagnose from logs) | f306434 |
| C2SD-T44 | 2026-11-01 | chore | closed | Release v3.0.0: bump version, changelog, build dist/ShootDodge-3.0.0.zip, redeploy to Vortex | 4a26373 |
| C2SD-T45 | 2026-11-01 | fix | closed | Main-menu crash: main menu world spawns a player, so drivers made game calls there; add Session gate (player + not IsPreGame + 1.5s settle) | b40eafb |
| C2SD-T46 | 2026-11-01 | feature | closed | Shootdodge trigger is Ctrl + Space (replaces aim+jump+move combo and Space-in-Bullet-Time) | 4c659c8 |
| C2SD-T47 | 2026-11-01 | fix | closed | Docs: Phone Extension needs Codeware (GameInstance.GetInkSystem), docs say redscript only; list Codeware as required with Phone Extension | dff9393 |
| C2SD-T48 | 2026-11-01 | fix | closed | Input.lua: ctrlHeldByScript defined after Input.Context, so every Space press errors (nil global) and Ctrl+Space never dives | 08226ec |
| C2SD-T49 | 2026-11-01 | feature | closed | Dive is a low, flat leap (not full jump height); landing slams V to the ground and pins V prone until a direction key: look around and shoot freely, no movement | f73b8d0 |
| C2SD-T50 | 2026-11-01 | fix | closed | Every dive aborts with never-left-the-ground: Input.IsGrounded (PSM LocomotionDetailed) never reports airborne in game; add a height and vertical-speed airborne check in DiveDriver | cdea29c |
| C2SD-T51 | 2026-11-01 | feature | closed | Shootdodge trigger moves from Ctrl + Space to Shift + Space (Shift is sprint, sprint-jump into a dive feels natural) | a2e6cbc |
| C2SD-T52 | 2026-11-01 | feature | closed | Bullet-time slows the world to 5% (was 20%): enemies have RPG health, a single headshot does not kill | a2e6cbc |
| C2SD-T53 | 2026-11-01 | feature | closed | Shootdodge: weapon ready instantly (V exempt from the 5% world slow-mo so raise/aim/fire run at full speed), and landing becomes a slide (momentum kept, crouch-height camera, decelerating) instead of prone | 76c5bf9 |
| C2SD-T54 | 2026-11-01 | fix | closed | Max Payne intro text still describes landing prone; update to the slide landing (C2SD-T53) | fa186fc |
| C2SD-T55 | 2026-11-01 | fix | closed | Player exemption from the 5% slow-mo does not take effect in game (dive air 0.2 s game = 4 s real); add per-entity SetIndividualTimeDilation on the player as fallback and log exemption failures | 99c9510 |
| C2SD-T56 | 2026-11-01 | feature | closed | Headshots are lethal while mid-dive (DIVING/AIRBORNE slow-mo): temporary +1000 HeadshotDamageMultiplier stat modifier on V, removed on landing | cb1ac7b |
| C2SD-T57 | 2026-11-01 | feature | closed | Shootdodge works with any ranged weapon (hip fire and ADS), not just pistol/revolver/SMG; melee and unarmed still excluded | 74c8379 |
| C2SD-T58 | 2026-11-01 | chore | closed | Docs for C2SD-T55..T57: player exemption entity fallback, lethal mid-dive headshots, every ranged weapon (hip fire and ADS) | 1466900 |
| C2SD-T59 | 2026-11-01 | fix | closed | Max Payne intro text still says pistol/revolver/SMG only; every ranged weapon works since C2SD-T57 | dd4859a |
| C2SD-T60 | 2026-11-01 | fix | closed | Drop the failing SetTimeDilationOnLocalPlayerZero call (game takes 2-5 params, mod passed 6); the per-entity player exemption is confirmed working in game | e94e983 |
| C2SD-T61 | 2026-11-01 | fix | closed | Dive is a 0.3 s hop now that V runs at full speed: replace the rise cut with a 1.5 s low glide (vertical speed eased from +1.5 to -1.0 m/s, 6.5 m/s along the dive line), then slam and slide | 7202115 |
| C2SD-T62 | 2026-11-01 | fix | closed | Fake slide breaks the landing (camera drop/raise, pushes fighting the game landing, get-up 2.5 m/s brake): land on feet keeping momentum; also landing on a surface higher than launch never registered (time-limit aborts) | 7202115 |
| C2SD-T63 | 2026-11-01 | fix | closed | Dive is jaggy and stops mid-air: per-frame PSM impulses jolt V and the arc apex (vz near 0) is mistaken for a landing; use one launch impulse only and require a fall or 0.1 s of stillness before a landing counts | cca42e0 |
| C2SD-T64 | 2026-11-01 | chore | closed | Review the whole mod against Max Payne 2 bullet time and shootdodge mechanics (research the real MP2 behavior) and list every gap with a fix recommendation | cca42e0 |
| C2SD-T65 | 2026-11-01 | feature | closed | Flatten the dive: fold a downward cut into the single launch impulse (negative launchLift) and log V vertical speed after launch to verify (MP2 dive is low and flat) | c3d5ad0 |
| C2SD-T66 | 2026-11-01 | feature | closed | Bullet Time mode deepens with kills like MP2: own mode factor starting shallow (0.35) and deepening toward 0.10 with kills in the mode; the dive stays at 5% | fb90501 |
| C2SD-T67 | 2026-11-01 | feature | closed | Bullet Time mode cues: music/ambience muffle (and yellow tint if a lever exists) while Bullet Time mode is on, not only during the dive | 14059f8 |
| C2SD-T68 | 2026-11-01 | feature | closed | Optional MP2 lie-and-fire landing: CET overlay switch for prone landing (eye low, hold until a fresh direction press); landing on feet stays the default | 403766f |
| C2SD-T69 | 2026-11-01 | docs | closed | Docs for the Max Payne 2 alignment (C2SD-T63 to T68): clean launch arc, flat dive, Bullet Time mode depth with kills, mode muffle, lie-and-fire option; fix stale comments in DiveDriver.lua and ComboDetector.lua | 03f579d |
| C2SD-T70 | 2026-11-01 | chore | closed | Rebuild dist zip automatically whenever mod files land: local pre-commit hook runs tools/package.ps1 and stages the zip into the same commit | a6257a7 |
| C2SD-T71 | 2026-11-02 | docs | open | Adopt MindAttic.Agency docs-site pipeline, publish README to GitHub Pages (HOUSE-LAW-14) | — |
| C2SD-T72 | 2026-11-02 | fix | closed | Bughunt sweep, two passes: find and fix real bugs across tracked source (user request 2026-11-02) | — |
| C2SD-T73 | 2026-11-02 | fix | closed | Fix the open items the 2026-11-02 bughunt left for decision (stuck Shift/Space on controls inactive, package.ps1 zips index content) | — |
| C2SD-T74 | 2026-11-10 | chore | open | Crash recovery: commit the Nexus Mods page assets (assets/header.png, assets/1920x1080.jpg) and the command-catalog/docs sync left uncommitted by the session crash | — |
