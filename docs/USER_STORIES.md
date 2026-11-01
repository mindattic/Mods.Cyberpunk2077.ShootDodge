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
- **C2SD-US-D1 ⬜** As V, I want twin pistols and a Max Payne style trench coat added to my inventory when the mod loads, so I have the signature loadout without hunting for it.
- **C2SD-US-D2 ⬜** As V, I want the mod to recognize a dedicated Shootdodge input combo (aim held + jump + a movement direction) without misfiring during normal play, so the move triggers only when I mean it to.
- **C2SD-US-D3 ⬜** As V, I want the mod's state machine to show my current Shootdodge state (NONE/DIVING/AIRBORNE/PRONE/GETUP) at all times, so every later mechanic is built and debugged against one known state.
- **C2SD-US-D4 ⬜** As V, I want the input combo to launch me into a horizontal dive toward my aim direction, so I leave the ground the way Max Payne does.
- **C2SD-US-D5 ⬜** As V, I want world time to slow dramatically for the duration of the dive, so the moment feels like Max Payne's bullet-time instead of an ordinary jump.
- **C2SD-US-D6 ⬜** As V, I want my aim turn-speed and weapon fire-rate to stay at normal speed while the world is slowed, so I can place shots precisely instead of fighting slow-motion input.
- **C2SD-US-D7 ⬜** As V, I want the mod to detect the exact moment I hit the ground after a dive and read whether I'm holding a movement input, so the landing can branch correctly.
- **C2SD-US-D8 ⬜** As V, I want to land prone and keep firing from the ground when I land without holding movement, so I can keep shooting from the floor like Max Payne.
- **C2SD-US-D9 ⬜** As V, I want to scramble back to my feet when I land holding movement, so the dive flows back into normal play instead of stopping dead.
- **C2SD-US-D10 ⬜** As V, I want the Shootdodge restricted to pistols, revolvers and small SMGs, so I can't trigger it while carrying a sniper rifle or a heavy weapon.
- **C2SD-US-D11 ⬜** As V, I want camera FOV pull-back, a whoosh cue, and a muffled low-pass on music/ambience during the dive, so the move reads as cinematic rather than a glitch.

## Tickets
> Permanent log of every change and fix — this repo's ticket system. Rows are append-only: never
> delete or reword one; only move its Status (open → closed / wont-do) and fill in Ref. Status is
> a word, not a glyph, so tickets don't count toward the story index. Keep this section last.

| ID | Date | Type | Status | Summary | Ref |
|---|---|---|---|---|---|
| C2SD-T1 | 2026-11-01 | docs | closed | Start the permanent ticket log in the ticket database | — |
| C2SD-T2 | 2026-11-01 | docs | closed | Start the permanent ticket log in the ticket database | — |
| C2SD-T3 | 2026-11-01 | chore | open | Scaffold new repo: Cyberpunk 2077 mod for Max Payne 2 style Shootdodge (dive, bullet-time, prone/get-up) plus twin pistols + trench coat loadout | — |
| C2SD-T4 | 2026-11-01 | feature | open | Grant twin pistols + Max Payne style trench coat on mod load | C2SD-US-D1 |
| C2SD-T5 | 2026-11-01 | feature | open | Shootdodge input detection: aim+jump+move combo, debounced against normal play | C2SD-US-D2 |
| C2SD-T6 | 2026-11-01 | feature | open | Formalize Shootdodge state machine (NONE/DIVING/AIRBORNE/PRONE/GETUP) + debug overlay | C2SD-US-D3 |
| C2SD-T7 | 2026-11-01 | feature | open | Dive trigger: launch V into a horizontal leap toward aim direction | C2SD-US-D4 |
| C2SD-T8 | 2026-11-01 | feature | open | Bullet-time: world time dilation for the duration of the dive | C2SD-US-D5 |
| C2SD-T9 | 2026-11-01 | feature | open | Responsive aim+fire during slow-mo: exempt player turn-speed and fire-rate from the dilation | C2SD-US-D6 |
| C2SD-T10 | 2026-11-01 | feature | open | Ground-contact detection: detect landing and read held movement input | C2SD-US-D7 |
| C2SD-T11 | 2026-11-01 | feature | open | Prone-and-shoot state: land prone, keep free-aim firing from the ground | C2SD-US-D8 |
| C2SD-T12 | 2026-11-01 | feature | open | Get-up recovery: scramble back to normal stance when landing with movement held | C2SD-US-D9 |
| C2SD-T13 | 2026-11-01 | feature | open | Weapon restriction: gate the dive trigger to pistols/revolvers/small SMGs only | C2SD-US-D10 |
| C2SD-T14 | 2026-11-01 | feature | open | Camera + audio polish: FOV pull-back, whoosh cue, music/ambience low-pass during the dive | C2SD-US-D11 |
