# Installs ShootDodge's git hooks into this clone (C2SD-T70). Run once per clone:
#   powershell -NoProfile -File tools/install-hooks.ps1
# Leaves any other hook (for example the orchestrator's commit-msg) untouched.
$root = (git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
$hooks = Join-Path $root '.git\hooks'
$src = Join-Path $root 'tools\pre-commit'
$dst = Join-Path $hooks 'pre-commit'
if ((Test-Path $dst) -and ((Get-FileHash $dst).Hash -ne (Get-FileHash $src).Hash)) {
  Copy-Item $dst "$dst.bak" -Force
  Write-Host "Existing pre-commit hook saved as pre-commit.bak"
}
# Keep LF line endings: Git's sh does not run a CRLF hook.
$text = [IO.File]::ReadAllText($src) -replace "`r`n", "`n"
[IO.File]::WriteAllText($dst, $text)
Write-Host "Installed $dst"
