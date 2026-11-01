# Mods.Cyberpunk2077.ShootDodge

A Cyberpunk 2077 gameplay mod that replicates *Max Payne 2*'s signature Shootdodge: dive in your
aim direction, drop into bullet-time, keep shooting on the way down, and either stay prone
shooting or scramble back up once you land. Ships with the matching loadout: twin pistols and a
Max Payne style trench coat.

## Status

Early scaffold. No gameplay is implemented yet — this repo currently holds the project shell and
design notes. See [`docs/DESIGN.md`](docs/DESIGN.md) for the planned mechanics and
[`docs/USER_STORIES.md`](docs/USER_STORIES.md) for the ordered ticket log (work this in ticket ID
order — each ticket's `requires` link names what must land first).

## Planned mechanics

- **Loadout** — twin pistols and a trench coat are granted to V's inventory on mod load.
- **Shootdodge trigger** — aim held + jump + a movement direction launches V into a horizontal
  dive in the held movement direction (locked for the whole dive; aim stays free), restricted to pistols/revolvers/small SMGs.
- **Bullet-time** — world time slows dramatically for the dive, while V's own aim turn-speed and
  weapon fire-rate stay at normal speed.
- **Landing branch** — holding movement on landing scrambles V back to their feet; releasing it
  drops V prone, free-aiming and firing from the ground until they choose to get up.
- **Polish** — camera FOV pull-back, a whoosh cue, and a muffled low-pass on music/ambience for
  the duration of the dive.

## Target platform

- Cyberpunk 2077 (patch/version TBD, pinned once implementation starts)
- [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) (Lua) for input hooks,
  time dilation, the state machine, and the debug overlay
- [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) for the loadout items (reskinned existing
  archetypes, not new meshes)
- A custom `.animgraph` dive/prone pose (via WolvenKit + REDmod) is the one piece CET's Lua layer
  can't do alone — see the open question in `docs/DESIGN.md`. Early tickets deliberately reuse a
  stock animation/impulse for the leap so the rest of the state machine can be built and verified
  before that heavier animation work is undertaken.

## Install (once there's something to install)

Drop the contents of `bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/` into your game's
matching `bin/x64/plugins/cyber_engine_tweaks/mods/` folder.
