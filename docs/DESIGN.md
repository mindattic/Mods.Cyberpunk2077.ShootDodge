# Design notes

Inspiration: *Max Payne 2: The Fall of Max Payne*'s Shootdodge — leap in the aim direction, time
slows but aiming and firing stay sharp, then either stay prone shooting or scramble back up.

## Mechanics, in build order (matches the ticket log)

### Loadout (C2SD-T4)
Grant twin pistols and a trench coat on mod load, via TweakXL reskins of existing archetypes.
Independent of everything else below — no gameplay dependency, just inventory setup.

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
guard only allows `dive` from `NONE`, so a combo mid-air does nothing. Until the landing branch
(C2SD-T10) exists, touching down again ends the dive back to `NONE`.

### Bullet-time (C2SD-T8) and responsive aim/fire (C2SD-T9)
On entering `DIVING`, world time dilation drops (default 0.2x) via the game's time system, the
same lever Sandevistan-style effects use. V's own camera turn-speed and weapon fire-rate are
exempted from that dilation so aiming/shooting during the dive feels fast even though everything
else is slow. Dilation must unconditionally clear when the state leaves `DIVING`/`AIRBORNE`
(including a mid-dive pause-menu open) — a stuck slow-mo is the one failure mode that must never
happen.

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
A ground-contact check fires once per dive and reads whether movement is held at that instant:
- Held -> `AIRBORNE -> GETUP -> NONE` (scramble-up transition, full control back only once it
  finishes).
- Not held -> `AIRBORNE -> PRONE` (free-aim/fire from the ground, no timer — only a later
  stand/move input exits to `GETUP -> NONE`).

### Weapon restriction (C2SD-T13)
The input check (C2SD-T5) also reads the equipped weapon type. Pistols, revolvers, and small SMGs
arm the combo; rifles, shotguns, LMGs, sniper rifles, and melee/fists block it. Re-checked live on
every weapon swap.

### Camera + audio polish (C2SD-T14)
FOV pull-back, a one-shot whoosh on dive entry, and a music/ambience low-pass for the duration of
`DIVING`/`AIRBORNE`, all independently toggleable in the debug overlay so each can be verified on
its own. Done last, once the full dive -> prone and dive -> get-up loops already work.

## Open question: animation fidelity

CP77 has no native prone-and-shoot pose. The ticket order above deliberately defers that: C2SD-T7
ships the leap on a reused stock animation so the state machine, time dilation, and landing branch
can all be built and verified in-game first. A faithful dive/prone pose needs a custom
`.animgraph` state (built in WolvenKit/Blender, injected via REDmod) layered on top once the logic
underneath is proven — that's a follow-up ticket once C2SD-T14 lands, not part of this backlog.

## Tooling

- **Cyber Engine Tweaks (CET)** — input hooks, the state machine, time dilation calls, the ImGui
  debug overlay. Everything in the ticket log above is CET Lua only.
- **TweakXL** — the loadout grant (C2SD-T4): reskins existing weapon/garment TweakDB records
  rather than shipping new meshes.
- **WolvenKit + REDmod**, if/when the animation follow-up is picked up: extracting the player
  skeleton, authoring the dive/prone `.animgraph` states, packaging as a REDmod archive.
