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
`NONE -> DIVING`: an impulse sends V airborne, horizontally, toward the aim direction. The first
pass reuses an existing jump/dodge animation rather than a bespoke dive pose — see "Open question"
below.

### Bullet-time (C2SD-T8) and responsive aim/fire (C2SD-T9)
On entering `DIVING`, world time dilation drops (default 0.2x) via the game's time system, the
same lever Sandevistan-style effects use. V's own camera turn-speed and weapon fire-rate are
exempted from that dilation so aiming/shooting during the dive feels fast even though everything
else is slow. Dilation must unconditionally clear when the state leaves `DIVING`/`AIRBORNE`
(including a mid-dive pause-menu open) — a stuck slow-mo is the one failure mode that must never
happen.

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
