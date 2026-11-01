# Design notes

Inspiration: *Max Payne 2: The Fall of Max Payne*'s Shootdodge — leap in the aim direction, time
slows but aiming and firing stay sharp, then either stay prone shooting or scramble back up.

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
substitute. CP77 has no dual-wielding, so the "twin pistols" are two separate Lexingtons in the
inventory (one in hand, one on the wheel), not a two-handed pose.

Caveat: this checkout has no tool to render a garment, so each pick is by item family (the long
coat, formal shirt, formal trousers, formal shoes) and its `basic_01` variant. The in-game check
below is where the colour variant is confirmed; if a `basic_01` isn't the darkest, swap the
variant suffix in `Loadout.items` to the runner-up that is.

**Granting (`modules/LoadoutDriver.lua`).** Once per session (a loaded save, a new game, or CET
reloaded in game), 1.5 s after V exists, the driver reads the save's quest fact
`shootdodge_mp2_loadout`. Unset: it counts what V already holds of each record, gives only the
shortfall (`Game.AddToInventory`, which mints a separate weapon per pistol), and writes the fact
into the save. Set: nothing. So reloading the save or restarting CET never re-grants, and a piece
the player later sells stays sold. The overlay shows the last result and the body type read, with
a "Check loadout now" button. Nothing is auto-equipped: V equips the pieces from the inventory.

**Still to verify in game** (not possible from this checkout): on a male and a female V, all
six items arrive, equip, and render; reloading the save adds nothing.

### Input detection (C2SD-T5)
A CET input listener watches for aim (ADS) held + jump + a movement direction, all within one
short window. Logged to a debug overlay before it drives anything, so false positives against
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
On entering `DIVING`, world time dilation drops (default 0.2x) via the game's time system, the
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
first place. An opt-in overlay toggle also exempts all of V (Sandevistan's "local player zero"
lever), which restores gamepad turn rate too but speeds V's fall arc back up, so it is off by
default. The exemption is synced right after the world dilation and dropped with it, same frame.

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
  mode. The tint is implemented; the extra slowdown tier is not (no ticket asks for it yet).
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

### Landing branch (C2SD-T10, C2SD-T11, C2SD-T12)
As in Max Payne 2, every dive ends lying on the ground and slow-mo ends on impact.

**Ground contact (C2SD-T10, `modules/Dive.lua` + `modules/DiveDriver.lua`).** The dive driver owns
both `DIVING` and `AIRBORNE`: the frame V actually leaves the ground it fires `DIVING -> AIRBORNE`;
the landing is the airborne -> grounded transition of V's locomotion state (the same ground check
the combo uses). It fires once per dive, always `-> PRONE` whatever input is held, and records
whether a movement input was held at impact (`DiveDriver.lastLanding.moveHeld`), so the get-up can
start right after impact without a fresh press. No false positives from grazes: the touchdown must
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
  watcher), or movement held through the landing (`DiveDriver.lastLanding.moveHeld`), which stands V
  up automatically once the 0.25 s impact beat has played: V hits the ground first, no fresh press
  needed. Without either, V stays prone and keeps shooting; there is no timer. `GETUP` is a short
  scramble, not a snap to idle: a small push (2 m/s) in the held movement direction (camera
  relative, like the dive), V's horizontal speed held under 2.5 m/s, and the eye easing back up from
  the floor over the same 0.7 s (init.lua sets the prone driver's raise time to the scramble's
  duration). Full normal movement returns only when it completes and fires `recover -> NONE`. However
  `GETUP` is entered, the get-up driver runs it; the camera stays first person throughout.

### Weapon restriction (C2SD-T13)
The input check (C2SD-T5) also reads the equipped weapon type. Pistols, revolvers, and small SMGs
arm the combo; rifles, shotguns, LMGs, sniper rifles, and melee/fists block it. Re-checked live on
every weapon swap.

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

## Open question: animation fidelity

CP77 has no native prone-and-shoot pose. The ticket order above deliberately defers that: C2SD-T7
ships the leap on a reused stock animation so the state machine, time dilation, and landing branch
can all be built and verified in-game first. A faithful dive/prone pose needs a custom
`.animgraph` state (built in WolvenKit/Blender, injected via REDmod) layered on top once the logic
underneath is proven — that's a follow-up ticket once C2SD-T14 lands, not part of this backlog.

## Tooling

- **Cyber Engine Tweaks (CET)** — input hooks, the state machine, time dilation calls, the ImGui
  debug overlay. Everything in the ticket log above is CET Lua only.
- **TweakXL** — not needed: the loadout grant (C2SD-T4) gives vanilla TweakDB records as they are.
- **WolvenKit + REDmod**, if/when the animation follow-up is picked up: extracting the player
  skeleton, authoring the dive/prone `.animgraph` states, packaging as a REDmod archive.
