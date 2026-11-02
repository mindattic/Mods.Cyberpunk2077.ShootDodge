# MindAttic project agent entrypoint

Read the shared protocol at ..\mindattic-agent-standard\AGENTS.md and this project's own
documentation. Common prompt commands are implemented by the shared runner; do not add a second
copy under a provider-specific command folder.

## ShootDodge: dist zip

`dist/ShootDodge-<version>.zip` is rebuilt automatically whenever a commit lands mod files
(`bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/`, `r6/scripts/ShootDodge/`,
`r6/input/ShootDodge.xml`): the pre-commit hook runs `tools/package.ps1` and adds the zip to the same. Install it once per clone with `powershell -NoProfile -File tools/install-hooks.ps1`.
