# Nexus Mods page: ShootDodge

Not published yet (live link goes here once uploaded). Copy each field into the Nexus Mods upload form.
The description is BBCode, which is what Nexus's editor accepts in source mode.

## Before uploading

The mod hasn't been played in game yet. Work through [TESTING.md](TESTING.md), the full in-game
checklist with expected results. At minimum these must pass:

- [ ] A1-A3: the ShootDodge window appears in the CET overlay, no `[ShootDodge]` errors after loading a save.
- [ ] B1-B2: a minute of ordinary play gives zero false combo triggers; the real combo gives exactly one.
- [ ] C1-C4: State reads `NONE` in normal play, walks `NONE -> DIVING -> AIRBORNE -> PRONE -> GETUP -> NONE`,
      and never gets stuck.
- [ ] D1-D10 (male and female V): the leap goes left, right, back, forward and diagonally, is locked in
      the air, keeps the camera free and first person, and can't be re-triggered mid-air.
- [ ] E1-E6, F1-F6: slow-mo starts and clears the frame V lands (also after a pause and on death), and
      aim and fire stay at normal speed while the world is slow.
- [ ] G1-G5, H1-H9 (male and female V): one landing per dive with the right held flag, prone shooting
      360 degrees, no timer, get up by a move key or by holding through the landing.
- [ ] I1-I18: the hourglass HUD, Bullet Time mode (the / key by default with Input Loader, CET binding as fallback, never V), drain, passive and kill refill, and
      save persistence.
- [ ] J1-J4: only pistols, revolvers and SMGs arm the combo, and swaps apply at once.
- [ ] K1-K9: FOV, whoosh and music duck start and revert on both exit paths, each toggleable.
- [ ] L1-L7 (male and female V): the loadout is granted once, equips and renders, never duplicates.
- [ ] M1-M2: a combat run and save/load in each state leave nothing stuck.
- [ ] N1-N5: the release zip installs through Vortex's "Install From File" with no manual-install
      prompt, deploys to both folders, and uninstalls cleanly.
- [ ] O1-O8: the text from Max Payne arrives in the phone's Messages app once per save and never again.
- [ ] Take the in-game screenshots listed under Images and put their links in the description.

## Mod name

ShootDodge (Max Payne 2 Shootdodge)

## Version

1.0.0. Upload `dist/ShootDodge-1.0.0.zip`, built by `tools/package.ps1` (see the README's "Building
and packaging"; the version comes from `version` in `init.lua`). It is rooted at the game folder and
holds `bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/` (`init.lua` and `modules/`) and
`r6/scripts/ShootDodge/ShootDodgePhone.reds`, nothing else.

On the Files tab: category **Main files**, name "ShootDodge", version 1.0.0, and leave Vortex
installation on (the default). Vortex's Cyberpunk 2077 extension installs this layout on its own.

## Changelog

- **1.0.0:** first release.
  - The Shootdodge: aim + jump + a movement direction leaps V in that direction, locked in the air.
  - Slow-mo with full-speed aim and fire; lands prone and keeps shooting; a move key stands V back up.
  - Pistols, revolvers and SMGs only.
  - Dual pistols with the game's Double Trouble perk (Update 2.5): both guns arm the combo and fire
    at full speed in the slow-mo.
  - Max Payne 2's bullet-time hourglass with a bindable Bullet Time mode, kill refill and a HUD.
  - Camera FOV pull-back, whoosh and music duck.
  - The Max Payne 2 outfit and twin Lexington pistols, once per save.
  - A once-per-save text thread from Max Payne himself in V's phone, explaining the mod in his
    noir voice with genuine Max Payne quotes.
  - A Vortex-ready zip.
  - A debug overlay with every setting.

## Category

Gameplay (alternative: Combat)

## Summary (max 350 characters)

Max Payne 2's Shootdodge in first person. Aim, hold a direction, jump: V dives, time slows while your aim and fire stay fast, then you hit the floor prone and keep shooting or get up. Bullet-time hourglass, Max's outfit, twin pistols with Double Trouble, and Max Payne himself texts you. Needs CET and redscript; Phone Extension optional.

## Tags

Gameplay, Combat, Slow Motion, Bullet Time, Animation, Weapons, Cyber Engine Tweaks, Max Payne

## Requirements

Add each of these on the upload form's Requirements tab ("Nexus requirements"), so Vortex offers to
install them and the page lists them:

| Requirement | Link | Note for the requirement |
|---|---|---|
| Cyber Engine Tweaks | https://www.nexusmods.com/cyberpunk2077/mods/107 | Runs the whole mod. |
| redscript | https://www.nexusmods.com/cyberpunk2077/mods/1511 | Compiles the Max Payne phone contact. |
| Phone Extension | https://www.nexusmods.com/cyberpunk2077/mods/24949 | Optional. Lets Max Payne text V in the Messages app. |
| Input Loader | https://www.nexusmods.com/cyberpunk2077/mods/4575 | Optional. Makes the / key the default Bullet Time key (needs RED4ext). Without it, bind the key in CET. |

Plus Cyberpunk 2077 (PC). Nothing else: no TweakXL, ArchiveXL or Codeware, and no RED4ext of its own
(Input Loader runs on RED4ext). Phone Extension itself needs only redscript.

## Install

**Vortex:** click **Mod Manager Download** (or drag the zip into Vortex). It installs and deploys with
no prompts. **By hand:** extract the zip into the game folder so that
`bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/init.lua` and
`r6/scripts/ShootDodge/ShootDodgePhone.reds` exist. Either way, install the three requirements first.
In game, open the CET overlay and tick **Enabled** in the ShootDodge window (it starts off every
session).

## AI disclosure

The code was written with an AI model (Claude). No art is included. Tick Nexus's "contains AI-generated
content" option when uploading.

## Images

Upload these in the Images tab, in this order. Make the first one the primary image.

| File | Use | Caption |
|---|---|---|
| `PLACEHOLDER: assets/Logo.png` (not made yet) | Primary image | ShootDodge |
| `PLACEHOLDER: screenshot 1` | The leap, mid-air, world slowed | Shootdodge |
| `PLACEHOLDER: screenshot 2` | Prone view shooting from the floor | Keep shooting |
| `PLACEHOLDER: screenshot 3` | The hourglass HUD and the CET overlay | The hourglass |

Once uploaded, right-click each one on the mod page, copy its image address, and paste it over
`IMAGE_1_URL`, `IMAGE_2_URL` and `IMAGE_3_URL` in the description below.

## Full description (BBCode)

```
[size=5][b]ShootDodge[/b][/size]
Max Payne 2's signature move, in first person. Aim, jump, press a direction, and V dives: time slows, your aim and fire stay at full speed, and you land prone still shooting.

[img]IMAGE_1_URL[/img]

[size=5][b]How it works[/b][/size]
[list=1]
[*]Equip a pistol, revolver or SMG, or two pistols with the Double Trouble perk.
[*]Hold aim, hold a movement direction, press jump.
[*]V leaps that way. The direction is locked for the whole dive, but the camera and aim stay free.
[*]The world drops to 0.2x speed while your mouse look and your gun's fire rate stay at normal speed.
[*]V lands prone, first-person view down at floor height, slow-mo ends.
[*]Keep shooting from the ground as long as you like, or press a movement key to scramble back up. Hold a direction through the landing and V gets up right after impact.
[*]In Bullet Time mode it's simpler: Space alone sends V flying, no aim needed, in the direction you hold or straight forward.
[/list]
[img]IMAGE_2_URL[/img]

[size=5][b]Features[/b][/size]
[list]
[*][b]The dive:[/b] forward, back, left, right or diagonal, locked in the air. Can't start mid-air, in a vehicle or with no direction held.
[*][b]Aim and fire stay fast:[/b] slow world, normal fire rate and mouse look. Bullets, enemies and V's own fall arc stay slowed for contrast.
[*][b]Prone and get-up:[/b] free-aim and fire 360 degrees from the floor, no timer. A fresh movement press stands V up with a short scramble.
[*][b]Weapon restriction:[/b] pistols, revolvers and SMGs only. Rifles, shotguns, LMGs, snipers, melee and fists don't arm it. Checked live on every swap.
[*][b]Dual pistols, the Max Payne way:[/b] take [b]Double Trouble[/b] in the Cool tree (Cool 9, base game since Update 2.5, no Phantom Liberty needed) and equip the two granted Lexingtons, one per weapon slot. Both guns arm the combo and both fire at full cadence in the slow-mo; an off-hand gun that isn't allowed refuses the combo with a clear reason. Recommended for the full twin-pistol look. [url=https://www.nexusmods.com/cyberpunk2077/mods/35649]Independent Pistol Controls[/url] is optional and untested with ShootDodge.
[*][b]Bullet-time hourglass:[/b] like Max Payne 2, a separate [b]Bullet Time mode[/b] (the / key by default with Input Loader, or bind any key in the CET Bindings tab, never V, which summons your vehicle) drains it for about 10 seconds. A Shootdodge costs nothing. It refills over time and by 15% per kill, the sand turns yellow with kills, and the level is saved with your game. An hourglass HUD sits in the lower left.
[*][b]Space dives in Bullet Time:[/b] while Bullet Time mode is on, Space is the Shootdodge instead of a jump: no aim needed, it dives the way you hold or straight forward. The dive's own slow-mo takes over from the mode, as in Max Payne 2. Outside the mode, and with a weapon that doesn't arm the dive, Space is a normal jump.
[*][b]Cinematic polish:[/b] FOV pull-back, a whoosh on entry and a music duck, each switchable.
[*][b]The Max Payne 2 loadout:[/b] twin Militech Lexington power pistols (they qualify for Double Trouble), a long coat, a formal shirt, trousers and shoes, from vanilla items, granted once per save to male or female V. You equip them yourself.
[*][b]A text from Max Payne:[/b] once per save, Max Payne himself texts V. A real SMS thread in the phone's Messages app, in his over-the-top noir narration, explaining how to Shootdodge between genuine lines from Max Payne 1 and 2. It never re-sends on reload.
[*][b]Debug overlay:[/b] every number is a slider or tick in the CET overlay: slow-mo factor, FOV, music, prone height and more.
[*][b]Safe:[/b] slow-mo, FOV and music always return to normal on landing, death, pause or disabling the mod.
[/list]
[img]IMAGE_3_URL[/img]

[size=5][b]Known limitations[/b][/size]
[list]
[*]Prone is camera-only: V's body and hitbox stay standing, because Cyberpunk has no prone stance.
[*]There is no dive animation (first person shows no body), and no tie, which the game lacks.
[*]Dual wielding comes from the game's Double Trouble perk and has not yet been checked in game with ShootDodge.
[*]Ambience low-pass audio events are blank by default, so only the music volume is ducked.
[*]A gamepad's turn speed follows slow-mo unless you tick "All of V at normal speed" in the overlay, which also speeds up V's fall arc.
[/list]

[size=5][b]Requirements[/b][/size]
[list]
[*]Cyberpunk 2077 (PC)
[*][url=https://www.nexusmods.com/cyberpunk2077/mods/107]Cyber Engine Tweaks[/url]
[*][url=https://www.nexusmods.com/cyberpunk2077/mods/1511]redscript[/url]
[*][url=https://www.nexusmods.com/cyberpunk2077/mods/24949]Phone Extension[/url] (for Max Payne's text)
[*][url=https://www.nexusmods.com/cyberpunk2077/mods/4575]Input Loader[/url] (optional, needs RED4ext: makes the / key the default Bullet Time key)
[/list]
Nothing else: no TweakXL, ArchiveXL or Codeware. Phone Extension is optional and install order does not matter: without it the phone script compiles to nothing, only Max Payne's text is missing, and no other redscript mod is affected. Input Loader is optional too: without it the / key does nothing and you bind Bullet Time in CET instead.

[size=5][b]Install[/b][/size]
[list=1]
[*][b]Vortex:[/b] Mod Manager Download. It installs and deploys on its own, no prompts. [b]Manual:[/b] extract the zip into your Cyberpunk 2077 folder (it contains [i]bin[/i] and [i]r6[/i]).
[*]Start the game, open the CET overlay, and tick [b]Enabled[/b] in the ShootDodge window. It starts off each session.
[*]Bullet Time mode is on [b]/[/b] (slash, main keyboard or numpad) by default with Input Loader installed. Without Input Loader, or for another key, bind it in the CET overlay's Bindings tab. Do not use V, it summons your vehicle.
[*]Check your phone a few seconds in. Max has something to say.
[/list]
Uninstall in Vortex, or delete [i]bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge[/i], [i]r6/scripts/ShootDodge[/i] and [i]r6/input/ShootDodge.xml[/i].

[size=5][b]Shout outs[/b][/size]
[list]
[*][b]Remedy Entertainment[/b] and [b]Max Payne 2: The Fall of Max Payne[/b] for the move this recreates.
[*][b]CD PROJEKT RED[/b] for Cyberpunk 2077, and the Cyber Engine Tweaks team for making this possible.
[*][b]r457 and gh057[/b] for the Phone Extension framework.
[*]Max Payne's lines are quoted from Remedy's games (written by Sam Lake); every quote is listed with its source in the mod's design notes.
[*]Code written with an AI model (Claude).
[/list]

Made by MindAttic. This is an unofficial fan mod.
```
