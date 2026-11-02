# Design notes

Inspiration: *Max Payne 2: The Fall of Max Payne*'s Shootdodge — leap in the aim direction, time
slows but aiming and firing stay sharp, then either stay prone shooting or scramble back up. (The
current alignment with MP2, and what was dropped along the way, is in "Max Payne 2 alignment" at the end.)

## Mechanics, in build order (matches the ticket log)

### Loadout (C2SD-T4)
Max Payne's Max Payne 2 outfit and twin pistols, rebuilt from Cyberpunk 2077's own items, granted
to male or female V once per save. Independent of the gameplay below: inventory setup only.

**Research: what Max wears and carries in Max Payne 2.** Findings, with sources:

- **Character model.** MP2's Max was remodelled on actor Timothy Gibbs (Sam Lake modelled MP1's)
  ([Wikipedia, MP2][wp2]; [TV Tropes, Max Payne trivia][tvt]).
- **Outfit.** Back on the NYPD, Max wears "a relatively smart office suit" and "still has his
  trademark leather trench coat" over it ([Giant Bomb, Max Payne][gbmax]). That is the break
  from MP1, where, undercover, he wore street clothes: leather jacket, white T-shirt, black
  trousers (Max Payne Wiki, *Max Payne*). Piece by piece:
  - *Coat*: long leather trench, black, worn open, reaching past the knee (the sourced "leather
    trench coat"; the colour, length and open wear are from the game's model and cover art).
  - *Shirt and tie*: a dress shirt under the coat, the "office suit" of the source. A tie is
    implied by the suit; no source found describes it, so treat the tie as unconfirmed.
  - *Trousers*: dark suit trousers. *Shoes*: black dress shoes. No source describes either beyond
    "office suit"; both follow from it.
- **Weapons.** Max starts MP2 with a 9 mm pistol ([Wikipedia][wp2]) and can dual-wield it; MP2's
  9 mm is a Beretta 92FS ([IMFDB, Max Payne 2][imfdb]; Max Payne Wiki, *Beretta*). MP2 kept MP1's
  dual Berettas and Ingrams and added dual Desert Eagles (Max Payne Wiki, *Dual-wielding*). The
  twin Berettas are the signature: they are the pair he holds from the first level on, so the
  ticket's Beretta 92 premise is confirmed.

[tvt]: https://tvtropes.org/pmwiki/pmwiki.php/Trivia/MaxPayne
[gbmax]: https://www.giantbomb.com/max-payne/3005-697/
[imfdb]: https://www.imfdb.org/wiki/Max_Payne_2

(The Max Payne Wiki pages are on maxpayne.fandom.com; IMFDB, Giant Bomb and Fandom refused
automated fetches during this research, so their wording above comes from search-result extracts.)

**Choices, slot by slot.** Only vanilla TweakDB records: no meshes, textures, `.archive` art, and
no TweakXL records either (none was needed, so the loadout has no TweakXL dependency). Every record
below was checked against the game's own `r6/cache/tweakdb.bin` (base and `_ep1`), and every
garment there carries both a `&Female` and a `&Male` appearance, so the same record renders with
the right body-gender mesh on either V. The list lives in `modules/Loadout.lua` (`Loadout.items`),
with `Loadout.bodyOverrides` for a per-body swap; both are empty today because no piece needed one.

| Slot | Pick | Why | Runners-up |
|---|---|---|---|
| Weapons (x2) | `Items.Preset_Lexington_Default` (Militech M-10AF Lexington) | The Beretta 92FS is the M9, the US military's service sidearm; Militech is the NUSA's military supplier and the Lexington its standard-issue, full-size semi-auto power pistol, black like Max's. A power pistol (`Wea_Handgun`), so it passes the C2SD-T13 gate. | `Items.Preset_Unity_Default` (Constitutional Arms Unity, also a full-size semi-auto); `Items.Preset_Lexington_Military` (same gun, military finish). The Liberty is a heavier hand cannon, closer to MP2's other pair, the Desert Eagles. |
| Outer torso | `Items.Coat_01_basic_01` | The long coat family (`t2_coat_01`), the nearest CP77 has to a knee-length leather trench; `basic_01` is its plain first variant (colour to confirm in game, see the caveat). | `Coat_01_old_01..03` / `_rich_01..03` (same cut, other finishes), `Coat_03_basic_01` (long corporate coat, the Steel Dragons coat's family), `Coat_04_basic_01`. A `FormalJacket_*` (the suit jacket) can't be worn with it: CP77 puts both in the one outer-torso slot, and the coat is the signature piece. |
| Inner torso | `Items.FormalShirt_01_basic_01` | Collared dress shirt, the "office suit" shirt. | `FormalShirt_01_old_*/rich_*` colour variants, `FormalShirt_02_basic_01`. |
| Tie | none | CP77 has no tie slot; a tie only exists baked into a shirt mesh. No match chosen; if the in-game check finds a tie on a `FormalShirt_02` variant, swap it in the inner-torso row. | `FormalShirt_02_*`. |
| Legs | `Items.FormalPants_01_basic_01` | Suit trousers. | `FormalPants_02_basic_01`, `FormalPants_03_basic_01`. |
| Feet | `Items.FormalShoes_01_basic_01` | Black dress shoes. | `FormalShoes_02_basic_01`, `FormalShoes_03_basic_01`. |

Female V gets the same five records, all with female meshes; no piece needed a female-specific
substitute. The "twin pistols" are two separate Lexingtons in the inventory. Without the 2.5 Double
Trouble perk that means one in hand and one on the wheel; with it, they pair up as real dual pistols
(C2SD-T30: the Lexington inherits the `DualWield` tag, see "Dual-wield support" below).

Caveat: this checkout has no tool to render a garment, so each pick is by item family (the long
coat, formal shirt, formal trousers, formal shoes) and its `basic_01` variant. The in-game check
below is where the colour variant is confirmed; if a `basic_01` isn't the darkest, swap the
variant suffix in `Loadout.items` to the runner-up that is.

**Granting (`modules/LoadoutDriver.lua`).** Once per session (a loaded save, a new game, or CET
reloaded in game), 1.5 s after V exists, the driver reads the save's quest fact
`shootdodge_mp2_loadout`. Unset: it counts what V already holds of each record, gives only the
shortfall (`Game.AddToInventory`, which mints a separate weapon per pistol), and writes the fact
into the save only when every add succeeded (a failed item is reported in the overlay and the fact
stays unset, so "Check loadout now" retries the shortfall). Set: nothing. So reloading the save or restarting CET never re-grants, and a piece
the player later sells stays sold. The overlay shows the last result and the body type read, with
a "Check loadout now" button. Nothing is auto-equipped: V equips the pieces from the inventory.

**Still to verify in game** (not possible from this checkout): on a male and a female V, all
six items arrive, equip, and render; reloading the save adds nothing.

### Input detection (C2SD-T5)
A CET input listener watches for jump while Shift is held (Shift + Space; see C2SD-T51 below; Ctrl + Space
in C2SD-T46, aim + jump + a direction before 3.0.0). Logged to a debug overlay before it drives anything, so false positives against
ordinary play can be ruled out first.

### State machine (C2SD-T6)
One centralized state: `NONE | DIVING | AIRBORNE | PRONE | GETUP`. Every later mechanic reads and
writes this one state rather than inventing its own flags. Shown in the debug overlay at all
times.

### Dive trigger (C2SD-T7)
`NONE -> DIVING`: an impulse sends V airborne, horizontally, in the **held movement direction
relative to the camera** (forward, back, left, right or a diagonal) — not the aim direction. The
direction is captured at launch and locked for the whole dive: mid-air movement input can't steer
it (`modules/Dive.lua` computes the direction and the corrective push that cancels any sideways or
backward drift), while the camera and aim stay free and first person throughout. The leap rides
the stock jump the same button press starts, plus the game's own `PSMImpulse` locomotion impulse
(`modules/DiveDriver.lua`), rather than a bespoke dive pose — see "Open question" below. The state
guard only allows `dive` from `NONE`, so a combo mid-air does nothing. Touching down again ends the
dive in the landing branch below (C2SD-T10).

### Bullet-time (C2SD-T8) and responsive aim/fire (C2SD-T9)
On entering `DIVING`, world time dilation drops (default 0.05x since C2SD-T52, 0.2x before) via the game's time system, the
same lever Sandevistan-style effects use. V's own camera turn-speed and weapon fire-rate are
exempted from that dilation so aiming/shooting during the dive feels fast even though everything
else is slow. Dilation must unconditionally clear when the state leaves `DIVING`/`AIRBORNE`
(including a mid-dive pause-menu open) — a stuck slow-mo is the one failure mode that must never
happen.

**How the exemption works (C2SD-T9, `modules/AimFireExemption.lua`).** The time system has no
camera-only or trigger-only exemption; dilation is per entity. So while this mod's dilation is
applied (dive or Bullet Time mode), the weapon in V's hands gets an individual time dilation of
1.0 that ignores the global one: its fire cycle and shoot-input cadence run at normal speed while
enemies, projectiles, the environment and V's own fall arc stay slowed. A weapon swap moves the
exemption to the new weapon. Mouse look is a per-frame displacement, so it isn't slowed in the
first place. The overlay toggle that also exempts all of V (Sandevistan's "local player zero"
lever) restores gamepad turn rate and V's own animations but speeds V's fall arc back up; it was opt-in,
but since C2SD-T53 it is on by default (see the last section). The exemption is synced right after the world dilation and dropped with it, same frame.
With Double Trouble both held guns are exempted (C2SD-T30, below).

### Bullet-time meter (C2SD-T15)

**Research: how Max Payne 2's hourglass behaves.** Findings, with sources:

- **What drains it.** Only Bullet Time *mode* (the manual slow-mo toggle) drains it, continuously
  while active, "until it is either empty or the player disables bullet time mode"; when it's
  empty "you'll find yourself back in real time". Sources: [Wikipedia, MP2 Gameplay][wp2];
  [GamesFirst review][gf].
- **Whether a shootdodge costs meter.** It does not. "Although bullet time is activated while Max
  or Mona is in mid-air, this will not deplete the bullet time meter" ([Wikipedia][wp2]);
  "performing a shootdodge does not drain the meter this time around" ([Gaming Past Time
  review][gpt]); "there is no limit to the number of times you can make this move"
  ([GamesFirst][gf]). This is a change from Max Payne 1, where diving used the meter.
- **What a shootdodge does with an empty meter.** Since the dive never touches the meter and has
  no use limit, it is a full slow-motion dive whatever the hourglass shows. (No source states the
  empty case in so many words; it follows from the two points above.) Starting a shootdodge
  during Bullet Time mode takes Max out of the mode (Max Payne Wiki, *Shootdodge*).
- **How it refills.** Two ways: passive regeneration whenever the mode is not in use ("the meter
  will eventually increase when not in use", [Wikipedia][wp2]; "Bullet Time will also regenerate
  slowly during gameplay", Rockstar Support), and kills ("can be replenished quickly by killing
  enemies", [Wikipedia][wp2]; "the bullet time meter fills up automatically, as well as getting
  bumped up a certain amount when you kill enemies", [hermiene.net][hn]). Capped at a full
  hourglass. MP1, by contrast, refilled only from kills ([hermiene.net][hn]).
- **The yellow hourglass.** Kills turn the sand yellow, which fades back toward white over time
  ("the more enemies you kill, the more yellow the bullet time meter gets, while constantly going
  towards white again", [hermiene.net][hn]); a yellower hourglass also slows time further in the
  mode. The tint is implemented, and since C2SD-T66 so is the deeper slowdown (see "Max Payne 2
  alignment").
- **Rates.** MP2's internal drain/regen/kill amounts are not published in any source found. The
  values in `BulletTimeMeter.defaults` are estimates (full hourglass ~10 s of mode, empty -> full
  ~80 s passive, +15% per kill) and are the numbers to tune after the in-game check.

[wp2]: https://en.wikipedia.org/wiki/Max_Payne_2:_The_Fall_of_Max_Payne
[gf]: https://gamesfirst.com/articles/2003/max-payne-ii-the-fall-of-max-payne/
[gpt]: https://gamingpastime.com/max-payne-2-pc-review/
[hn]: https://hermiene.net/archive/2003/12/11

**Consequence for this mod.** The ticket's working title says "the dive drains" the meter, but MP2
says it doesn't, and the ticket asks to match MP2 on every point. So, as in MP2, the meter is
drained by a **Bullet Time mode** (a CET binding, "Bullet-time mode (Max Payne 2, toggle)", unbound
by default, plus a button in the overlay) that slows the world with the same dilation as the dive
(C2SD-T8), and the shootdodge stays free and always slowed. The mode can't start mid-dive or with
less than 2% sand, ends when the meter runs dry (the dilation is unset that same frame, see
`BulletTimeDriver.Sync`), on death, on mod disable, on a session end, and when a shootdodge starts.
`diveCost`, `diveDrainPerSec` and `diveNeedsMeter` in the same config table can make the dive pay
(an emptied meter then drops the world to normal speed mid-dive, cleanly), but default to MP2's
zero.

**Implementation.** `modules/BulletTimeMeter.lua` is the pure economy, with every rate and amount
in its one `defaults` table. `modules/BulletTimeMeterDriver.lua` wires it in:
- kills come from the game's own `NPCPuppet:OnDeath` event, counted when the death's instigator is
  the player, once per NPC;
- the level persists across save/load in a quest fact (`shootdodge_bt_meter`, stored inside the
  save file), restored at each session start; a save made before the mod starts full;
- an hourglass HUD in the lower left, always visible in game (hidden only in menus/pause), with the
  sand draining from the top bulb as the level drops and tinted yellow by kills; the debug overlay
  shows the exact level, mode, tint and kill count, plus refill/empty buttons for testing.

### Space is the Shootdodge in Bullet Time mode (C2SD-T38)

While Bullet Time mode is on (`MeterDriver.meter.mode`), a fresh jump press is the Shootdodge on
its own, as in MP2 where you just dive in slow-mo. `Input.Context` passes `bulletTime` to
`ComboDetector:Evaluate`, which then skips the aim checks (held, `minAimHoldSec`) and the movement
hold time (`minMoveHoldSec`); every other guard is unchanged: mod enabled, not blocked (vehicle,
menus, a dive/prone/get-up already in progress), grounded, the weapon gate (C2SD-T13/T30, so with a
disallowed weapon Space stays a plain jump) and the 1 s cooldown. Outside the mode nothing changed.

- **Direction.** The held movement direction (past the 0.5 dead zone), relative to the camera at
  launch and locked as usual (`Dive.Direction`). **No direction held: dive straight forward**
  (the trigger carries move 0, 1). Forward is where the camera, and so the gun, already points, it
  is the safest guess for "just hit Space", and refusing would turn Space into a plain jump in the
  middle of a slow-mo fight, which reads as the mod failing. The hold time is skipped too because
  in this mode every Space is meant as a dive; a direction pressed together with Space counts.
- **Meter interaction: kept as is.** Starting a dive still ends Bullet Time mode
  (`Meter:OnDiveStart`, "shootdodge"), and the dive's own free slow-mo takes over, as in MP2
  (Max Payne Wiki, *Shootdodge*, above). The code offers no better fit: the dive and the mode use the
  same 0.2x dilation, so the switch is seamless, and keeping the mode on would keep draining sand
  for a dive that MP2 makes free. The cost is that after landing, the mode has to be toggled on
  again for the next Space-dive; until then Space is a normal jump again.
- **Overlay.** The debug overlay shows "Space = Shootdodge (Bullet Time)" while the mode is on.

### Landing branch (C2SD-T10, C2SD-T11, C2SD-T12)
As in Max Payne 2, every dive ends lying on the ground and slow-mo ends on impact.

**Ground contact (C2SD-T10, `modules/Dive.lua` + `modules/DiveDriver.lua`).** The dive driver owns
both `DIVING` and `AIRBORNE`: the frame V actually leaves the ground it fires `DIVING -> AIRBORNE`;
the landing is the airborne -> grounded transition of V's locomotion state (the same ground check
the combo uses). It fires once per dive, always `-> PRONE` whatever input is held, and records
whether a movement input was held at impact (`DiveDriver.lastLanding.moveHeld`). Since C2SD-T49 that
flag no longer stands V up by itself (see the get-up below). No false positives from grazes: the touchdown must
stay grounded for `landConfirmFrames` (2) consecutive frames, and a grounded reading while V is
still rising faster than `maxLandingRiseSpeed` doesn't count; a shorter contact is counted as a
graze and the arc carries on. A dive that never lifts off, or hits the 4 s cap, isn't a landing and
aborts to `NONE`. The overlay and the CET log show one landing event per dive with its held flag.

- `PRONE` (C2SD-T11, `modules/Prone.lua` + `modules/ProneDriver.lua`): free-aim/fire from the
  ground, first person, no timer. The prone driver owns `PRONE` and drives the state machine every
  frame, so the driver timeout never stands V up; it ends only on a *fresh* movement press (jump does not count: it would also run the game's real jump, C2SD-T26)
  (an input still held from the dive must be released once first, and none counts in the first
  0.25 s after impact), which `ProneDriver.onStandRequest` hands to the get-up as `PRONE -> GETUP`.
  Aiming and firing are left entirely to the game, so V shoots in any direction from the ground.
  CP77 has no prone stance, so "lying down" is V's first-person camera lowered by `eyeDrop`
  (1.3 m, eye ~0.4 m off the floor; tunable in the overlay), eased down over 0.12 s and back up over
  0.2 s when `PRONE` ends any way (get-up, abort, disable, reload). V's body and collision stay
  standing until the animation follow-up below. Knocked off a ledge while prone aborts to `NONE`.
- Get-up (C2SD-T12, `modules/GetUp.lua` + `modules/GetUpDriver.lua`): `PRONE -> GETUP -> NONE`.
  Two ways in: the prone driver's fresh move press, handed over through
  `ProneDriver.onStandRequest` (pointed at `GetUpDriver.OnStandRequest`, so there is one stand-press
  watcher), or, only if `GetUp.defaults.standIfHeldAtImpact` is set (false since C2SD-T49), movement held
  through the landing (`DiveDriver.lastLanding.moveHeld`), which would stand V up once the 0.25 s
  impact beat has played. By default V stays pinned until a fresh press. Without either, V stays prone and keeps shooting; there is no timer. `GETUP` is a short
  scramble, not a snap to idle: a small push (2 m/s) in the held movement direction (camera
  relative, like the dive), V's horizontal speed held under 2.5 m/s, and the eye easing back up from
  the floor over the same 0.7 s (init.lua sets the prone driver's raise time to the scramble's
  duration). Full normal movement returns only when it completes and fires `recover -> NONE`. However
  `GETUP` is entered, the get-up driver runs it; the camera stays first person throughout.

### Weapon restriction (C2SD-T13)
The input check (C2SD-T5) also reads the equipped weapon type. Originally only pistols, revolvers
and SMGs armed the combo; since C2SD-T57 every ranged weapon does (see the last section). Re-checked
live on every weapon swap.

### Camera + audio polish (C2SD-T14)
FOV pull-back, a one-shot whoosh on dive entry, and a music/ambience low-pass for the duration of
`DIVING`/`AIRBORNE`, all independently toggleable in the debug overlay so each can be verified on
its own. Done last, once the full dive -> prone and dive -> get-up loops already work.

Built as `modules/DivePolish.lua` (pure rules) + `modules/DivePolishDriver.lua` (CET glue):
- **FOV pull-back** — V's first-person camera FOV widens by a configurable amount (12 deg by
  default, overlay slider) while `DIVING`/`AIRBORNE`, eased in over 0.15 s on real time and back
  out over 0.25 s once the dive ends by any path (landing -> prone, abort, mod disable). The FOV the
  camera had before is put back exactly; the camera never leaves first person.
- **Whoosh** — one game sound event on V on `NONE -> DIVING` (the only way into `DIVING`), so once
  per dive. The event name is editable in the overlay, with a Play button to audition it.
- **Music/ambience muffle** — the music volume setting is ducked to a configurable fraction of the
  player's own value, plus an optional on/off pair of audio events (editable in the overlay) for a
  low-pass mix, for the duration of `DIVING`/`AIRBORNE`. Pause and death restore it like they drop
  bullet-time. Because the music volume is a user setting, the original is also written to
  `polish_restore.txt` in the mod folder while ducked, and the next load puts it back if a crash or
  CET reload interrupted the dive.

## Release packaging and Vortex (C2SD-T27)

**How Vortex recognises the zip.** Vortex's Cyberpunk 2077 support is the
[Nexus-Mods/game-cyberpunk2077](https://github.com/Nexus-Mods/game-cyberpunk2077) extension (read at
commit `0ddc3e8`). It tries a list of installers in order (`src/installers.ts`) and uses the first
whose test matches the archive's file tree:

- `src/installer.cet.ts`: a CET mod is canonical when a directory directly under
  `bin/x64/plugins/cyber_engine_tweaks/mods/` holds `init.lua` (`findCanonicalCetDirs`,
  `CET_MOD_CANONICAL_PATH_PREFIX` and `CET_MOD_CANONICAL_INIT_FILE` in `src/installers.layouts.ts`).
- `src/installer.redscript.ts`: a redscript mod is canonical when `.reds` files sit in a named
  folder under `r6/scripts/` (`RedscriptLayout.Canon`, `REDS_MOD_CANONICAL_PATH_PREFIX`).
- `src/installer.multitype.ts`: when an archive has more than one recognised type (here canonical CET
  plus canonical redscript), `testForMultiTypeMod` matches and `installMultiTypeMod` installs each
  part in its canonical place. MultiType comes before the single-type CET and redscript installers
  in the list, and none of these prompt; only the fallback installer asks the user, and it is never
  reached by a canonical layout.

So the release zip is rooted at the game folder with exactly
`bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/{init.lua,modules/*.lua}` and
`r6/scripts/ShootDodge/ShootDodgePhone.reds`. `tools/package.ps1` builds it from git-tracked files
only (so no docs, dev files or runtime state such as `polish_restore.txt`), writes forward-slash entry
names (Windows PowerShell's `Compress-Archive` writes backslashes), and checks the layout before it
reports success. The same zip is a manual install: extract into the game folder.

**What was verified here and what wasn't.** The zip was built and its entry list checked against the
layout rules above by reading the extension's source. Vortex itself was not run in this environment,
so the actual "Install From File" + deploy is TESTING.md section N.

**Requirements** (declared on the Nexus page so Vortex offers them): Cyber Engine Tweaks (everything),
redscript (the phone contact) and, optionally, Phone Extension (the Messages integration; only the
text needs it). `ShootDodgePhone.reds` guards its imports and every declaration with
`@if(ModuleExists("PhoneExtension.Classes"))` / `System`, so without the framework it compiles to
nothing and cannot break other redscript mods (C2SD-T29). Phone Extension is four
`.reds` files (`r6/scripts/PhoneExtension/PhoneExtension.{Classes,DataStructures,Overrides,System}.reds`)
and needs Codeware (it calls `GameInstance.GetInkSystem()`) plus redscript; Codeware needs RED4ext. Without
Codeware redscript fails with `UNRESOLVED_METHOD ... GetInkSystem`, and then no redscript mod loads, ShootDodge's
included (C2SD-T47). ShootDodge's own code uses no TweakXL, ArchiveXL, Codeware or RED4ext.

## In-game text message (C2SD-T27)

**Goal.** Once per save, Max Payne himself texts V: a real SMS thread in the phone's Messages app from
a contact named "Max Payne", explaining how to Shootdodge in his first-person, over-the-top noir
narration, built around genuine quotes. No on-screen popup, no fallback.

**Why redscript and Phone Extension.** CET alone can't add a phone contact or message: vanilla texts
are journal entries authored in WolvenKit (`.journal` plus a quest phase to send them). The
[Phone Extension framework](https://www.nexusmods.com/cyberpunk2077/mods/24949) (r457 and gh057)
wraps the phone's contact list, messenger and notification code so a redscript `PhoneEventsListener`
can be a contact with its own thread (`GetContactData`, `ShowDialog` with `PushMessageCustom`) and
pop the HUD SMS notification (`PhoneExtensionSystem.NotifyNewMessageCustom`). The same pattern, and
the CET-to-redscript bridge through `Game.GetScriptableSystemsContainer():Get(...)`, is used by
[Y4rd13/david-sandevistan-plus](https://github.com/Y4rd13/david-sandevistan-plus)
(`DSPViktorPhone.reds`, `DSPViktorBridge.reds`).

**How it works.**

- `r6/scripts/ShootDodge/ShootDodgePhone.reds`: `ShootDodgePhoneSystem` (a `ScriptableSystem`) owns
  the contact (`ShootDodgeMaxPayneContact`, hash 271027001, avatar `PhoneAvatars.Avatar_Unknown`, an
  existing in-game image) and the thread. It registers the contact with Phone Extension whenever the
  HUD phone controller initialises. The contact is hidden until its thread has texts, appears only
  in the Messages tab (not callable), and opening it marks the thread read by setting the save's fact
  to 2.
- `modules/IntroMessage.lua` (pure Lua) holds the sender, the 17 texts, the quote list with sources,
  and `Plan(fact)`: fact unset = send and notify; 1 = sent but unread; 2 = read.
- `modules/IntroMessageDriver.lua` (CET glue): once per session, 8 s after V appears, unpaused, and
  once the phone reports ready, it fills the thread every session (redscript system state is not
  saved, so the texts are restored like any other SMS history), and only when the fact is unset does
  it pop the notification and write fact = 1. A reload, CET restart or new session on the same save
  never notifies again. If the redscript system isn't there, the overlay reports "phone route
  missing" and nothing else is shown.

**Quotes.** Every quote is word for word from Wikiquote's page source (wikitext), checked by script
against the raw text with only wiki markup (links, bold) removed:
[Max Payne](https://en.wikiquote.org/w/index.php?title=Max_Payne&action=raw) (revision 3707106) and
[Max Payne 2: The Fall of Max Payne](https://en.wikiquote.org/w/index.php?title=Max_Payne_2:_The_Fall_of_Max_Payne&action=raw)
(revision 3707107). The MP2 page lists Max's narration without chapters, so those are cited to the
game only. Each is used whole, unchanged; everything else in the thread is original writing in Max's
voice and is never presented as a quote. `IntroMessage.quotes` holds the same list, and
`IntroMessage.MissingQuotes()` confirms each appears verbatim in the thread.

| # | Quote | Source |
|---|---|---|
| 1 | The sun went down with practiced bravado. | *Max Payne* (2001), Part I, Prologue |
| 2 | But dreams have a nasty habit of going bad when you're not looking. | *Max Payne*, Part I, Prologue |
| 3 | The nightmare was always the same. | *Max Payne*, Part II, Prologue |
| 4 | Somewhere the baby was crying. | *Max Payne*, Part II, Prologue |
| 5 | The devil was in the drug. I knew. I had met him. | *Max Payne*, Part III, Ch. 8 "Pain and Suffering" |
| 6 | I hadn't slept in a million years. | *Max Payne*, Part III, Ch. 4 "Backstabbing Bastard" |
| 7 | I lied to myself that it was over. I was still alive, my loved ones were still dead. It wasn't over. | *Max Payne 2: The Fall of Max Payne* (2003), Max |
| 8 | Throw the rules out the window, odds are you'll go that way too. | *Max Payne 2*, Max |
| 9 | Logic was such a liar. | *Max Payne 2*, Max |
| 10 | When you're looking down the barrel of a gun, time slows down. Your whole life flashes by, heartbreak and scars. | *Max Payne 2*, Max |
| 11 | This hadn't been my first fall in the night, still just a prelude to the real deal, still a long way to the bottom. | *Max Payne 2*, Max |
| 12 | The genius of the hole: no matter how long you spend climbing out, you can still fall back down in an instant. | *Max Payne 2*, Max |
| 13 | I don't know about angels, but it's fear that gives men wings. | *Max Payne*, Part I, Ch. 6 "Fear That Gives Men Wings" |
| 14 | I felt the rise of that old familiar feeling. I hated it. I welcomed it. | *Max Payne 2*, Max |
| 15 | Death is inevitable. Our fear of it makes us play safe, blocks out emotion. It's a losing game. Without passion you are already dead. | *Max Payne 2*, Max |
| 16 | Firing a gun is a binary choice. Either you pull the trigger or you don't. | *Max Payne 2*, Max |
| 17 | In a nightmare, every choice you make is a wrong one. | *Max Payne 2*, Max |
| 18 | Bad things happened in the night, on the streets of that other city. | *Max Payne*, Part III, Ch. 4 "Backstabbing Bastard" |
| 19 | None of us was a saint. | *Max Payne*, Part II, Ch. 2 "An Offer You Can't Refuse" |
| 20 | There were only personal apocalypses. Nothing is a cliché when it's happening to you. | *Max Payne*, Part I, Ch. 9 "An Empire of Evil" |
| 21 | Closing your eyes forces you to look at the darkness inside. | *Max Payne 2*, Max |
| 22 | Your past is like pieces of a broken mirror. You try to pick them up, but you only end up cutting yourself. | *Max Payne 2*, Max |
| 23 | Like always, the dead had all the answers I was missing. | *Max Payne 2*, Max |
| 24 | I didn't deserve to walk away. There are no happy endings. | *Max Payne 2*, Max |
| 25 | I had a dream of my wife. She was dead. But it was all right. | *Max Payne 2*, Max (final narration) |

Several (1, 2, 3, 4, 5, 9, 10, 17, 18, 20, 21, 23) are whole sentences taken out of a longer
Wikiquote entry, cut only at sentence boundaries; nothing inside a sentence was removed or changed.

## Open question: animation fidelity

CP77 has no native prone-and-shoot pose. The ticket order above deliberately defers that: C2SD-T7
ships the leap on a reused stock animation so the state machine, time dilation, and landing branch
can all be built and verified in-game first. A faithful dive/prone pose needs a custom
`.animgraph` state (built in WolvenKit/Blender, injected via REDmod) layered on top once the logic
underneath is proven — that's a follow-up ticket once C2SD-T14 lands, not part of this backlog.

## Tooling

- **Cyber Engine Tweaks (CET)** — input hooks, the state machine, time dilation calls, the ImGui
  debug overlay. Everything in the ticket log above is CET Lua only.
- **redscript + optional Phone Extension (which needs Codeware)** — only for Max Payne's phone text (C2SD-T27,
  `r6/scripts/ShootDodge/ShootDodgePhone.reds`); everything else stays CET Lua.
- **TweakXL** — not needed: the loadout grant (C2SD-T4) gives vanilla TweakDB records as they are.
- **WolvenKit + REDmod**, if/when the animation follow-up is picked up: extracting the player
  skeleton, authoring the dive/prone `.animgraph` states, packaging as a REDmod archive.

## Akimbo / dual wielding (research, C2SD-T28)

Question: Max Payne dual-wields Berettas; can ShootDodge support real akimbo pistols?
Researched 2026-11-01 (web search plus secondary articles; the Nexus Mods pages returned HTTP 403 to
automated fetches, so mod details below come from search snippets and guides and are marked
unverified where the mod page itself was not read).

### Finding 1: the base game now has dual wielding (Update 2.5)

- Update 2.5 (released 2026-10-22 on PC, PS5, Xbox Series X|S) added the **Double Trouble** perk in
  the Cool tree: real dual wielding, free, Phantom Liberty not required. Sources:
  [TheFPSReview](https://www.thefpsreview.com/?p=156171),
  [TweakTown](https://tweaktown.com/news/114231/cyberpunk-2077-patch-2-5-adds-dual-wield-pistols-edgerunners-2-quests-and-cross-platform-mods),
  [Of Zen and Computing guide](https://www.ofzenandcomputing.com/how-to-dual-wield-pistols-in-cyberpunk-2077/).
- Per the guide: needs Cool 9 and Double Trouble rank 1; only Power pistols and Power revolvers
  qualify (Tech and Smart pistols can be equipped but do not qualify; no SMGs, rifles or melee);
  a secondary weapon slot appears in the inventory; both guns fire on the same input; each gun does
  37.5% less damage while dual wielded; rank 2 replaces Quick Melee with the Heywood Hurricane
  (auto-fires both guns for one second). Exact controls and Deadeye/Focus interaction were not
  confirmed by the sources. Guides written before 2.5 (and old Steam threads) correctly say vanilla
  had none; they are out of date.

### Finding 2: third-party dual-wield mods

None of these could be opened (Nexus 403), so license, exact last-update date and issues are not
verified; check each page before relying on it.

| Mod | Link | Type | Notes (from guides/search) |
| --- | --- | --- | --- |
| Independent Pistol Controls (Dual Wielding) | https://www.nexusmods.com/cyberpunk2077/mods/35649 | Real: left click fires left gun, right click fires right gun (and controller equivalent); builds on the native 2.5 feature | Author states it works with 2.5; changes bindings |
| Expanded Dual Wielding (Independent Triggers / CET Menu) | https://www.nexusmods.com/cyberpunk2077/mods/35626 | Real: pairs guns with guns or melee; allowed set selectable (power pistols and revolvers, all handguns, all guns) | Uses Native Settings UI menu; CET likely needed (unconfirmed) |
| Dual Wield Any Weapon | https://www.nexusmods.com/cyberpunk2077/mods/35631 | Removes the weapon-category restriction | Requirements unknown |
| Real Dual Wielding | https://www.nexusmods.com/cyberpunk2077/mods/34669 | Older mod, separate aiming | Pre-2.5 mods can conflict with the official slot |
| Dual-wield mod (id 17006) | https://www.nexusmods.com/cyberpunk2077/mods/17006 | Pre-2.5 era | A forum poster said it looked like it needed an update; treat as outdated |

Mod ids 356xx are recent (2.5 era); the dual wielding they add depends on, or conflicts with, the
native slot. Compatibility with ShootDodge has not been tested.

### What building akimbo from scratch would take

Not needed now that the engine feature exists, but for the record: a second weapon slot and
equip logic, a dual-pistol animgraph (idle, aim, fire, reload, and the dive/prone poses
ShootDodge would need to blend with), per-hand fire input, and weapon-handling changes. That is
WolvenKit/animgraph work of the same size as the existing "animation fidelity" open question, and
Update 2.5 did the base of it for us. Sources for the tooling layer: the
[RED4ext/Codeware/redscript framework notes](https://wiki.redmodding.org/cyberpunk-2077-modding/for-mod-creators-theory/core-mods-explained).

### Recommendation

Support it, but through the **native 2.5 Double Trouble perk, not a third-party mod**. No new
optional dependency.

1. Do not require any mod. Do not pursue building akimbo ourselves.
2. Optional later integration, small: the loadout grant (C2SD-T4) could grant a second Power
   pistol and note that V needs Cool 9 plus Double Trouble to wield both; ShootDodge's slow-mo
   dilation and weapon-exemption code (C2SD-T24) should be checked to confirm it exempts both
   held pistols, not just the active weapon.
3. Mention in the Nexus page that Independent Pistol Controls (35649) is a suggested companion,
   once someone has tested it alongside ShootDodge.
4. Before any of this, verify in game on 2.5+: does ShootDodge's hold-weapon logic behave with two
   pistols equipped? That belongs in a follow-up ticket, not here (research only).

## Dual-wield support (C2SD-T30)

### How the game represents the off-hand weapon (research)

Read from the 2.5 decompiled game scripts and TweakDB sources, not guessed. Sources:
[CDPR-Modding-Documentation/Cyberpunk-Scripts](https://github.com/CDPR-Modding-Documentation/Cyberpunk-Scripts)
(script dump, last pushed 2026-10-31, after 2.5's release; it has the 2.5 dual-wield code) and
[CDPR-Modding-Documentation/Cyberpunk-Tweaks](https://github.com/CDPR-Modding-Documentation/Cyberpunk-Tweaks)
(TweakDB `.tweak` sources). Paths below are inside those repos.

- **Two hand slots, two entities.** The main gun sits in `AttachmentSlots.WeaponRight`, the off-hand
  gun in `AttachmentSlots.WeaponLeft`; each is its own `WeaponObject` entity.
  `ScriptedPuppet.GetWeaponRight(obj)` / `GetWeaponLeft(obj)` read them
  (`TransactionSystem.GetItemInSlot(obj, slot) as WeaponObject`; `cyberpunk/puppet/scriptedPuppet.script`),
  and `ScriptedPuppet.GetActiveWeapons(obj)` returns both. `GetActiveWeapon` returns the right one,
  falling back to the left only when the right slot is empty. `WeaponObject.IsLeftHandWeapon()` is
  `GetAttachedSlotID() == T"AttachmentSlots.WeaponLeft"` (`cyberpunk/items/weapon.script`). The game's
  own code treats the pair this way everywhere: `ReloadWeaponEffector` reloads `GetWeaponRight` then
  `GetWeaponLeft` (`core/gameplay/effectors/reloadWeaponEffector.script`), the shoot state machine has
  a `WeaponLeft` instance with its own `LastSecondaryShotTime` (`cyberpunk/player/psm/weaponTransitions.script`),
  and the equip anim feature sets `dualWield` when both slots hold an item (`cyberpunk/player/psm/equipment.script`).
- **The same left slot holds other things.** Quick-throw grenades, the mine dispenser and some
  cyberware use `AttachmentSlots.WeaponLeft` too (`combatGadgetTransitions.script`,
  `mineDispenserTransitions.script`). The `as WeaponObject` cast in `GetWeaponLeft` filters out a
  grenade (not a `WeaponObject`).
- **Upper-body state.** While dual wielding the player state machine's `UpperBody` blackboard value is
  `gamePSMUpperBodyStates.DualWield` (`cyberpunk/player/psm/upperBodyTransitions.script`).
- **Which guns qualify.** `gameItemData.CanDualWield(owner)` (`core/data/itemData.script`) is: the item
  has the `DualWield` tag **and** V bought `gamedataNewPerkType.Cool_Central_Milestone_2`, whose
  record (`new_perks/cool_new_perks.tweak`) is commented "Double Trouble". A `QuestPreventDualWield`
  tag adds a quest-fact check (the Lexington Toygun and the Nova carry it).
- **The Lexington qualifies.** `Base_Power_Handgun : Base_Handgun` has tags `"DualWield", "PowerWeapon"`
  (`items/weapons/ranged/bases/base_handgun.tweak`); the chain is `Preset_Lexington_Default :
  Preset_Base_Lexington : Base_Lexington : Base_Power_Handgun`, and both Lexington records only append
  tags (`tags +=`), so `Items.Preset_Lexington_Default` (the loadout's twin pistols, C2SD-T4) inherits
  `DualWield` and has no `QuestPreventDualWield`. **The grant needs no change.** (TweakDB also has
  `Preset_*_Left_Hand` records tagged `Left_Hand`, `HideInUI`, `IgnoreInventory`; they derive from
  `Preset_Base_Lexington`, so they share its handgun base.) Revolvers carry `DualWield` too (`base_revolver.tweak`).

### What ShootDodge does with it

- **Slow-mo exemption** (`AimFireExemption.lua`, `BulletTimeDriver.lua`). The rules track a set of
  exempted weapon keys instead of one. The driver reads both hand slots every sync (right first, then
  `GetWeaponLeft`, same entity counted once) and exempts each held gun with its own individual time
  dilation; a swap of either hand unsets only that hand's old gun. Landing, pause, death, disable and
  `Clear()` (shutdown, CET reload at init) unset every tracked gun **and** both guns V holds now
  (the C2SD-T24 clean-up, extended to the left hand). With one weapon this is the old single-key
  behaviour. The overlay shows "Exempt now: weapons N".
- **Weapon gate** (`WeaponGate.ClassifyPair`, `Input.lua`). The jump-press check reads both slots. One
  weapon: exactly `Classify` as before. Two: both must be on the allow-list (every ranged type since C2SD-T57); a
  bad main gun refuses with its type, a bad off-hand gun refuses with "weapon not allowed (off-hand
  <type>)". Vanilla Double Trouble only pairs power pistols and revolvers, so the off-hand refusal
  only shows with mods that widen the pairing (Dual Wield Any Weapon, Expanded Dual Wielding).
- **Docs** recommend Double Trouble for the Max Payne twin-pistol look; Independent Pistol Controls
  (Nexus 35649) is optional and untested with ShootDodge.

**Still to verify in game** (TESTING.md section P): the combo arms with the pair, both guns fire at
normal cadence in slow-mo, and the exemptions clear on landing, on a weapon swap and on a CET reload.

## Bullet Time hotkey (C2SD-T36)

V (where the user first bound it) is the base game's vehicle summon, so it is wrong for the toggle.

- **Chosen by the user: Numpad Enter.** Alternative (keyboards without a numpad): Mouse 4, the thumb
  side button, which no source found assigns.
- **Default key: not possible from a mod.** The CET wiki states mods cannot define default
  hotkeys; the player binds each one in the Bindings tab. `registerInput` / `registerHotkey` take
  no key argument. CET's Lua sandbox also keeps a mod's file access to its own folder, so seeding
  CET's `bindings.json` is not available either, and Lua has no raw key poll outside the overlay.
  Reading the key through the game would need a new input action in `r6/input` XML plus an input
  loader dependency, which is out of scope here. So the binding stays user-set; docs and Max's text
  recommend Numpad Enter and say it can be rebound in the Bindings tab. (Superseded by C2SD-T37
  below: the game-input route now gives Numpad Enter as the default when Input Loader is installed.)
- **Is Numpad Enter unused? Not verified.** No Cyberpunk 2077 install exists on this machine
  (checked D:\Games), so `r6/config/inputUserMappings.xml` and `inputContexts.xml` could not be
  read. The published control lists below do not show Numpad Enter assigned, but menus accept
  Enter for confirm and the game may treat Numpad Enter the same, so check in game (Controls menu,
  on foot, in a vehicle, in menus, photo mode, dual wield).
- Sources: https://wiki.redmodding.org/cyber-engine-tweaks/cet-functions/hotkeys ,
  https://wiki.redmodding.org/cyber-engine-tweaks/console/bindings ,
  https://www.magicgameworld.com/?p=125476 (PC keyboard controls) ,
  https://www.gosunoob.com/cyberpunk-2077/rebind-controls-change-keybinds/ ,
  https://steamcommunity.com/app/1091500/discussions/0/5876659925420076318

## Bullet Time default key through Input Loader (C2SD-T37)

CET can't give a binding a default key (above), so the default comes from the game's own input
system: a new input action, added by the Input Loader mod, read by a small redscript listener.

**How Input Loader works.** A RED4ext plugin (Nexus mod 4575, jackhumbert). At startup it reads every
`r6/input/*.xml`, merges each `<bindings>` child into the game's `r6/config` input files (`mapping`,
`buttonGroup`, `pairedAxes`, `preset` into `inputUserMappings.xml`; `context`, `blend`, `hold`,
`multitap`, `repeat`, `toggle`, `acceptedEvents` into `inputContexts.xml`), writes the result to
`r6/cache/` and points the game at it through `engine/config/platform/pc/input_loader.ini`.
`append="true"` on a node adds to the existing definition instead of replacing it. Log:
`red4ext/logs/input_loader.log`. The vanilla `r6/config` input files must be unmodified.

**The file**, `r6/input/ShootDodge.xml`: a context `ShootDodgeActions` with the action
`ShootDodgeBulletTime` mapped to `ShootDodgeBulletTime_Button`; the vanilla `Locomotion` context gets
`<include name="ShootDodgeActions" />` with `append="true"`; the mapping is `type="Button"` with
`<button id="IK_Enter" />`. `Locomotion` is included by `Exploration` (the main on-foot context) and so
by `Aiming`, and not by the vehicle or menu contexts, so the key works on foot only.

**The key name: `IK_Enter`. There is no `IK_NumEnter`.** The game's `EInputKey` enum (RED4ext.SDK
`EInputKey.hpp`, 334 keys) follows Windows virtual-key codes: `IK_Enter = 13`, `IK_NumPad0..9 = 96..105`,
`IK_NumStar`, `IK_NumPlus`, `IK_Separator = 108`, `IK_NumMinus`, `IK_NumPeriod`, `IK_NumSlash`, and no
numpad Enter entry, because Windows reports both Enter keys as `VK_RETURN` (13). Community posts on
editing `inputUserMappings.xml` say the same (`IK_Enter` is both Enter and Numpad Enter). So the default is
Numpad Enter **and** main Enter; the input XML cannot tell them apart. (`IK_Separator` is the
separator key of some non-US keypads, not Numpad Enter.)

**Enter's other uses on foot.** The vanilla `inputContexts.xml` maps `DialogConfirm` (Enter) to
`ChoiceApply` and `Apply_Button` to `UI_Apply` in `InteractionActions`, which `Exploration` includes
through `UIExploration`. The game delivers an action to every listener for it, so picking a dialogue
choice with Enter on foot can also toggle Bullet Time. This is accepted and documented (TESTING.md
I3d); F and the mouse pick choices too. Menus, the phone, chat (`EnterChat`) and photo mode use other
contexts and are unaffected.

**The listener.** Whether CET's `Observe("PlayerPuppet", "OnAction")` (used by `Input.lua`) also
sees a mod-added action is not documented anywhere found; a listener registered by action name is the
documented pattern, so `r6/scripts/ShootDodge/ShootDodgeBulletTimeKey.reds` registers its own listener
for the action name: a `ScriptableSystem` (`ShootDodgeBulletTimeKeySystem`) wraps
`PlayerPuppet.OnGameAttached` and calls `player.RegisterInputListener(listener, n"ShootDodgeBulletTime")`
(the pattern from jackhumbert's Mod Settings readme); the listener's `cb func OnAction` counts
`ListenerAction.IsButtonJustPressed` presses. `modules/BulletTimeKeyDriver.lua` takes the count each
frame through `Game.GetScriptableSystemsContainer():Get(...)` (the same bridge as the phone text) and
toggles through `MeterDriver.ToggleMode`. The file needs nothing but redscript; it is not guarded,
since it uses only vanilla classes.

**Fallback and debounce.** The CET binding stays (rebinding, and the only route without Input Loader
or redscript: the action then never fires and the system reports 0 presses). Both routes go through
`modules/BulletTimeKey.lua`: a press from the other route within 0.25 s of the last accepted one is
the same physical press and is dropped; presses from one route are never dropped. So a player who
also binds Numpad Enter in CET still toggles once per press.

**Requirement.** Input Loader is optional (README, NEXUS_PAGE): without it everything works, Bullet
Time just has no default key. It needs RED4ext; ShootDodge itself still has no RED4ext code.

**Vortex.** The Nexus-Mods/game-cyberpunk2077 extension (commit `0ddc3e8`) treats `r6/input/*.xml` as
the `ConfigXmlLayout.Mergeable` layout (`src/installers.layouts.ts`), which `installer.config.xml.ts`
allows in MultiType without a prompt (only the `Protected` `r6/config` files prompt). So the zip
(CET + redscript + mergeable XML) still installs with no prompt. `tools/package.ps1` adds
`r6/input/*.xml` and checks that `r6/input/ShootDodge.xml` is in the zip.

**Not verified in game** (no Cyberpunk 2077 install here): that the merged action fires on Numpad
Enter (I3a), once per press with both routes (I3b), the no-Input-Loader fallback (I3c) and the
dialogue overlap (I3d). The context names come from a vanilla `inputContexts.xml` copy from 2021
(game 1.x); `Locomotion`/`Exploration` are still the on-foot contexts mods append to, but check
`input_loader.log` if the key does nothing.

Sources: https://github.com/jackhumbert/cyberpunk2077-input-loader (readme: file locations, node
routing, `append`, log) ,
https://www.nexusmods.com/cyberpunk2077/mods/4575 (Input Loader) ,
https://github.com/jackhumbert/mod_settings (readme: `RegisterInputListener(this, n"...")` +
`OnAction` with `ListenerAction.GetName`) ,
https://github.com/ElysiumRL/CustomHackingSystem (readme: listener class registered from a
`PlayerPuppet.OnGameAttached` wrap) ,
https://raw.githubusercontent.com/WopsS/RED4ext.SDK/master/include/RED4ext/Scripting/Natives/Generated/EInputKey.hpp
(key names) ,
https://github.com/themaoci/Cyberpunk2077/blob/HEAD/inputContexts.xml (vanilla contexts) ,
https://gist.github.com/gemakie/fbc84e7c17bbd89f37492f4caaa10230 (an `inputUserMappings.xml`:
`<mapping name=... type="Button"><button id="IK_Enter" />`, Enter's vanilla uses) ,
https://github.com/Nexus-Mods/game-cyberpunk2077 (`src/installers.layouts.ts`,
`src/installer.config.xml.ts`, `src/installer.multitype.ts`).

## Bullet Time default key moved to Mouse 4 (C2SD-T39)

C2SD-T37 put the default on `IK_Enter`, but the game has one key code for main Enter and Numpad Enter,
and on foot Enter is also the dialogue confirm, so picking a dialogue option toggled Bullet Time. The
sections above that say Numpad Enter / `IK_Enter` are superseded by this one.

- **Chosen default: `IK_Mouse4`** (EInputKey 193, RED4ext.SDK `EInputKey.hpp`), the thumb side button.
  **Alternative: `IK_Mouse5`** (194), the other thumb button. `r6/input/ShootDodge.xml` maps the
  `ShootDodgeBulletTime` action to `IK_Mouse4`; the CET binding stays as the rebind and the
  fallback without Input Loader, debounced as before.
- **Verified from the user's install** (read only): `D:\Games\Steam\steamapps\common\Cyberpunk 20776\config\inputUserMappings.xml`
  (102 KB, vanilla, no ShootDodge or other mod entries). Every `<button id="IK_...">` in it was
  listed. `inputContexts.xml` only names actions and mappings (it has no `IK_` keys), so the key list
  comes from the mappings file, which covers on foot, combat, vehicle, menus, photo mode, braindance,
  scanner and dialogue. `IK_Mouse4` and `IK_Mouse5` (and every other `IK_Mouse*`, `IK_Unknown*`)
  appear nowhere in it.
- **Keyboard and mouse keys vanilla binds** (by the file): mouse `LeftMouse`, `RightMouse`,
  `MiddleMouse`, `MouseWheelUp/Down`, `MouseX/Y/Z`; letters `A B C D E F G H I J K L M N O P Q R S T
  U V W X Y Z`; digits `0-9`; `Space`, `Tab`, `Enter`, `Escape`, `Backspace`, `CapsLock`, `Home`,
  `Equals`, `Minus`, `Up/Down/Left/Right`, `LShift`, `RShift`, `LControl`, `RControl`, `Alt`, `F1`,
  `F3`, `F4`, `F5`, `F9`, `CAPTURE`. Also gamepad (`IK_Pad_*`, `IK_PS4_*`, `IK_PAD_LR_THUMB`, gyro,
  `IK_Jcms*`) and touch (`IK_Touch_*`) keys, which a keyboard or mouse never produces.
- **Not bound by vanilla, so free**: `Mouse4..8`, `Insert`, `Delete`, `End`, `PageUp/PageDown`,
  `Pause`, `ScrollLock`, `NumPad0-9` and the numpad operators, `F2`, `F6-F8`, `F10-F12`, `Tilde`
  (CET overlay key by default), among others.
- **Why not the others.** Numpad keys and `End`/`Delete`/`PageUp` are far from the left hand and the
  mouse; `Insert` is the user's CET overlay key; `Tilde` and `F10`/`F11`/`F12` are CET or Windows
  uses; Mouse 4 sits under the thumb mid-fight with no other job. Mice without side buttons bind
  another free key in CET's Bindings tab.

## Bullet Time default key moved to `/` (C2SD-T40)

The user's mouse has no Mouse 4 button, so the default moved to `/`. `r6/input/ShootDodge.xml` binds both
`IK_Slash` (191, the main-keyboard `/`) and `IK_NumSlash` (111, numpad `/`), with names and codes from
RED4ext.SDK `EInputKey.hpp`. Neither appears anywhere in the vanilla `r6/config/inputUserMappings.xml` of
the user's install (checked 2026-11-01: 0 matches each), so `/` does nothing else in vanilla. Mouse 4 / Mouse 5
remain good choices for mice that have them, via the CET binding.

## Shootdodge is Ctrl + Space (C2SD-T46, superseded by C2SD-T51)

**Superseded.** The key became Shift + Space in C2SD-T51 (next sections). The rationale below still holds; the Ctrl reading and the Left Ctrl dodge caveat no longer apply, and the 20% slow-mo became 5% (C2SD-T52).

**Why.** Aim + a direction + jump needed three coordinated inputs and clashed with normal play
(aiming while strafing and jumping is common). Ctrl + Space is the crouch + jump pair, the same
gesture as diving in Max Payne 2, and plain Space stays a normal jump, so false triggers are rare.
No aim is needed; the aim checks and the movement hold time are gone from `ComboDetector:Evaluate`.
V dives in the held direction, or straight forward with none, locked in the air, with the world at
20% while aim and fire stay full speed. The weapon gate, grounded check, vehicle/menu block and 1 s
cooldown are unchanged. Bullet Time mode (the `/` key) still lets Space alone dive (C2SD-T38). The
overlay's reject reason was "Ctrl not held" (now "Shift not held").

**How Ctrl is read** (`modules/Input.lua`). Four sources, any of which counts as Ctrl held:
the vanilla actions `Dodge` (Left Ctrl), `Crouch` (Right Ctrl, hold) and `ToggleCrouch`, and the
mod's own Input Loader action `ShootDodgeModifier`, mapped to `IK_LControl` and `IK_RControl` in
`r6/input/ShootDodge.xml` and listened for in `r6/scripts/ShootDodge/ShootDodgeBulletTimeKey.reds`.
The vanilla actions cover users without Input Loader; the own action covers cases where vanilla
swallows the key in a context.

**Caveat.** Vanilla Left Ctrl is Dodge, so pressing it while already moving can start a vanilla
dodge dash before Space arrives. Ctrl + Space together, or Ctrl while standing, is the clean input
(tests B5 and B6 in `TESTING.md`).

**Session gate (C2SD-T45, shipped in 3.0.0).** The main menu is a world with its own player, and
acting there crashed the game. The mod now makes no game calls until a real save is loaded (player
present, not `IsPreGame`) and has settled for 1.5 s.

## Shootdodge is Shift + Space (C2SD-T51)

**Why.** Ctrl had a real conflict: vanilla Left Ctrl is Dodge, so Ctrl while moving could start a dodge dash
before Space arrived (the T46 caveat, tests B5/B6). Shift is sprint, and sprinting into a dive is the
intended feel, with no competing vanilla action. The rest of T46 is unchanged: no aim needed, the held
direction (or straight forward) locked in the air, weapon gate, grounded check, vehicle/menu block and 1 s
cooldown. Space alone still dives in Bullet Time mode (the `/` key, C2SD-T38). The overlay's reject reason is
now "Shift not held".

**How Shift is read** (`modules/Input.lua`, `MODIFIER_ACTIONS`). Any of: the vanilla actions `Sprint` (Right
Shift, hold) and `ToggleSprint` (Left Shift), and the mod's Input Loader action `ShootDodgeModifier`, now
mapped to `IK_LShift` and `IK_RShift` in `r6/input/ShootDodge.xml` and listened for in
`r6/scripts/ShootDodge/ShootDodgeBulletTimeKey.reds`.

## Dive slow-mo is 5% (C2SD-T52)

The dive's world time dilation (`BulletTime.defaults.factor`) went from 0.2 to **0.05**: enemies have RPG health
and need several hits, so at 20% they were still too quick to land them in the air. Bullet Time mode uses the
same dilation. The overlay's Time scale slider minimum (`minFactor`) is now 0.01.

## Flat leap, slam and pinned prone (C2SD-T49, C2SD-T50)

*SUPERSEDED in part. The flat leap's rise cut, the apex slam (`slamSpeed`) and the `landingStop` are gone or replaced: since C2SD-T63 the dive is one launch impulse (C2SD-T65 sets its shape) and `slamSpeed` is 0. The pinned-prone landing is no longer the default but is the optional lie-down landing (C2SD-T68, Prone `slide = false`). The airborne detection (C2SD-T50) still applies, and C2SD-T63 added a landing rule on top of it.*

**Leap (C2SD-T49, `modules/Dive.lua`).** `launchLift` is 0 (no extra lift above the stock jump), and just after
lift-off (`flattenAfterSec` 0.05 s) the rise is cut to `flattenKeep` 0.4 of its speed, so the dive is a low flat
leap. When the arc stops rising V gets one extra downward push (`slamSpeed` 5 m/s), and `landingStop` stops the
slide on impact.

**Pinned prone (C2SD-T49, `modules/GetUp.lua`; superseded by the slide, C2SD-T53, but still the behaviour when `slide = false`).** `standIfHeldAtImpact` is false: the direction is held through
every dive, so the old held-at-impact rule stood V straight back up. Now V stays prone (look and shoot freely)
until a fresh direction press, release then press, as in MP2. `moveHeld` is still recorded in the landing log.

**Airborne detection (C2SD-T50, `modules/DiveDriver.lua`).** The PSM locomotion check never reported airborne in
game, so every dive aborted with "never left the ground". V now counts as airborne when it is more than
`AIR_HEIGHT` 0.08 m above the launch point or falling faster than `AIR_FALL_SPEED` 0.5 m/s, alongside the PSM check.

## V at full speed and the landing slide (C2SD-T53)

*SUPERSEDED for the landing slide. C2SD-T62 removed the fake slide (camera drop, pushes along the dive line, get-up speed cap): V now lands on their feet and keeps the momentum through the game's own physics. The full-speed V exemption below is still current, except that the dive arc is now about 0.7 s, not 0.4 s (C2SD-T65).*

**V exempt by default (`modules/AimFireExemption.lua`).** `exemptPlayer` now defaults to true, so all of V
runs at full speed during the 5% world slow-mo, not just the weapon entity. Before, V's own weapon raise and
ADS animations ran at 5%, so the weapon was not ready in time. Now draw, raise, aim and fire are instant. The side
effect is that V's dive arc also plays at full speed (about 0.4 s) while enemies and the world stay at 5%. The
overlay tick "All of V at normal speed" still turns it off.

**The landing is a slide (SUPERSEDED by C2SD-T62; `modules/Prone.lua`, `modules/ProneDriver.lua`, `modules/Dive.lua`, `modules/DiveDriver.lua`).**
Like the game's own crouch-slide, instead of lying prone: `Dive.landingStop` is now 0, so V keeps the dive's
momentum along the dive line (the driver records `dirX/dirY/speed` in the landing). `Prone.defaults.slide` is
true: the camera drops by `slideEyeDrop` 0.8 m (crouch height, not the prone `eyeDrop`), and the target speed
drains linearly from the landing speed (clamped to `slideMinSpeed` 4 to `slideMaxSpeed` 8 m/s) to 0 over
`slideSec` 0.9 s of real time. The prone driver holds V's speed along the dive line at that target each frame
(`slideState`, with a per-frame change limit so the slide cannot jolt). When `slideSec` has elapsed, `Prone.End.slideOver`
raises the stand request and V stands through the normal `PRONE -> GETUP -> NONE` path. A fresh direction press
(release, then press, ignored in the first 0.25 s) still ends it early. Internally the state is still named `PRONE`.
`slide = false` restores the C2SD-T49 pinned prone (see "Flat leap, slam and pinned prone").

## V exemption, second lever (C2SD-T55)

**Problem (`modules/BulletTimeDriver.lua`, `exemptPlayer`).** In game, the TimeSystem call
`SetTimeDilationOnLocalPlayerZero` did not take effect: the dive's air phase (0.2 s of game time) took
4 s of real time and V stayed at 5%. **Fix.** V now also gets a per-entity exemption,
`Game.GetPlayer():SetIndividualTimeDilation(reason, 1.0, 0, "", "", true)`, the same lever the weapon
uses. Either call succeeding counts as exempt. Failures are printed to CET's `scripting.log` once per
distinct message, and `unexemptPlayer` drops the per-entity dilation too. Result: V and the weapon (draw,
raise, ADS, fire, reload) run at normal speed while the world is at 5%.

## Lethal headshots mid-dive (C2SD-T56)

**`modules/HeadshotDriver.lua`, wired in `init.lua`.** Enemies have RPG health, so one headshot rarely
kills. While the state is `DIVING` or `AIRBORNE`, the driver adds an additive +1000 stat modifier to V's
`HeadshotDamageMultiplier` (via `RPGManager.CreateStatModifier` and the StatsSystem), so every head hit
is lethal. The modifier is removed the frame the dive ends (state listener), on every `Update` frame
that outlives the state (session end, mod disabled), and on shutdown (`Cancel`). It logs "lethal
headshots on" and "lethal headshots off". Bosses with scripted invulnerability can still survive.

## Every ranged weapon (C2SD-T57)

**`modules/WeaponGate.lua`.** The allow-list grew from pistol, revolver and SMG to every ranged item
type: `Wea_AssaultRifle`, `Wea_Rifle`, `Wea_PrecisionRifle`, `Wea_SniperRifle`, `Wea_Shotgun`,
`Wea_ShotgunDual`, `Wea_LightMachineGun`, `Wea_HeavyMachineGun`. Hip fire or ADS both work; aim is never
required. Melee, fists, cyberware arms and no weapon still block it, and Double Trouble pairs still work.

## Max Payne 2 alignment (C2SD-T61 to C2SD-T68)

Basis: the C2SD-T64 review of how MP2 plays, against what the mod did. Sources:
[ludo.guide, Max Payne 2 part 8](https://www.ludo.guide/guide/max-payne-2/max-payne-2-part-8),
[Wikipedia, Max Payne 2: The Fall of Max Payne][wp2] and
[GamesFirst review][gf]. What those establish, and what the mod does about each point:

- **Bullet Time mode is a toggle whose levels deepen with kills.** MP2's mode slows time more as you
  kill (the yellow sand). The mod's mode now does the same (C2SD-T66, below).
- **A shootdodge costs no hourglass, and its slow-mo lasts only until you hit the ground.** The meter
  already charged nothing (C2SD-T15). The dive's slow-mo now really ends at the ground, because the
  landing check no longer fires at the arc's apex (C2SD-T63).
- **Max can lie and fire after a dive.** Kept as an option, not the default (C2SD-T68).

### Per-frame pushes jolt V: one launch impulse (C2SD-T61 to C2SD-T63, `modules/Dive.lua`, `modules/DiveDriver.lua`)
Per-frame `PSMImpulse` pushes made V's movement jolt in game (a jaggy dive). T61 tried a steered
glide, which overshot against the game's delayed impulses, so T63 removed every per-frame push: the dive is
ONE launch impulse and then the game's own jump arc. The glide (`glideSec` 0), the slam (`slamSpeed` 0) and
the direction lock (`lockGain` 0) are all off; their code and config remain but are inert.

**Landing rule (C2SD-T63, `DiveDriver.Update`).** Past lift-off, a landing counts only once V has come
down (`wasFalling`: vertical speed below -0.5 m/s at some point) and is stopped vertically (vertical speed
between -0.5 and 0.3 m/s), or after `LAND_STILL_SEC` 0.1 s of stillness (a ledge the dive never fell to). Before this
the arc's apex, where vertical speed is also near 0, ended the dive and its slow-mo mid-air.

**The fake slide is gone (C2SD-T62).** The camera drop to crouch height, the pushes along the dive line and
the get-up speed cap fought the game's own landing. Now `Prone.defaults.slideEyeDrop` is 0,
`slideDrive` is false, `slideSec` is 0.15 and `GetUp.maxScrambleSpeed` is 100 (no cap): V lands on their feet
keeping the momentum, and control comes back at once.

### Low flat dive like MP2 (C2SD-T65)
The one launch impulse folds in `launchLift` -1.5 m/s with `launchSpeed` 8.5 m/s (was 7.5, raised so the
lower arc still covers about 6 m). Simulated: about 0.73 s in the air, about 6 m of travel and a peak of
about 0.6 m on flat ground. Each dive prints `[ShootDodge] dive arc: vz after launch ...; peak ... m; air ...s` to
`scripting.log` (first six vertical-speed samples, the peak height above the launch point, the air time), to check the real arc
against the simulation.

### Bullet Time mode depth (C2SD-T66, `modules/BulletTime.lua`)
The mode has its own world speed, like MP2's deepening levels: `modeShallow` 0.35 with no kills, down to
`modeDeep` 0.10 as `meter.yellow` (0 to 1, +0.34 per kill, fading 0.08 per second) rises, quantized in
`modeStep` 0.05 steps so the time dilation isn't re-set every frame. The dive keeps `factor` 0.05. V and the weapon
stay at full speed in both.

### Audio muffle in Bullet Time mode (C2SD-T67, `modules/DivePolish.lua`)
The music and ambience muffle plays whenever the world is slowed, so in Bullet Time mode as well as in
the dive (unless the overlay's muffle tick is off, the game is paused or V is dead). MP2 also tints the
screen yellow in bullet time; no CET lever for that is known, so it is not done.

### Optional MP2 landing: lie down and fire (C2SD-T68, `init.lua`, `modules/Prone.lua`)
The overlay checkbox "Max Payne 2 landing: lie down and fire until you move" sets Prone `slide = false`:
the pinned prone of C2SD-T49 (eye dropped by `eyeDrop`, held until a fresh direction press). Off by default,
so V lands on their feet. Not saved between sessions.
