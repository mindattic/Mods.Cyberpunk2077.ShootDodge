<#
.SYNOPSIS
  Builds the Vortex-ready release zip: dist/ShootDodge-<version>.zip (C2SD-T27).

.DESCRIPTION
  The zip is rooted at the game folder, in the layouts the Vortex Cyberpunk 2077 extension
  (Nexus-Mods/game-cyberpunk2077) recognises as canonical: the CET mod (init.lua directly inside
  bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge) and the redscript phone contact
  (r6/scripts/ShootDodge/*.reds), plus the Input Loader key file (r6/input/*.xml, the extension's
  "mergeable" config XML layout, C2SD-T37). More than one type goes to its MultiType installer, so
  "Install from file" deploys both with no manual-install/fallback prompt, and a manual install
  is "extract into the game folder".

  Only the mod's own tracked .lua, .reds and r6/input .xml files go in: no docs, no dev files, and no runtime
  state (polish_restore.txt, CET's db.sqlite3, logs), because the file list comes from git, not
  the folder on disk (new files must be git-added before a build). File CONTENTS come from the git
  index too (git checkout-index into a temp folder), not the working tree, so a partial commit
  (`git commit -- <paths>`, which the pre-commit hook packages against the commit's own index)
  never ships unstaged edits in the dist zip (C2SD-T73). Entry names use forward slashes (PowerShell 5.1's Compress-Archive writes
  backslashes, which some extractors and Vortex's archive reader don't treat as folders).

.PARAMETER Version
  Overrides the version read from init.lua (ShootDodge.version).
#>
[CmdletBinding()]
param(
  [string]$Version
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = Split-Path -Parent $PSScriptRoot
$modRel = 'bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge'
$redsRel = 'r6/scripts/ShootDodge'
$inputRel = 'r6/input'

# Tracked files under the mod folders only, then an allow-list of what each needs at run time.
$allowedIn = @{ $modRel = '.lua'; $redsRel = '.reds'; $inputRel = '.xml' }
$tracked = & git -C $repo ls-files -- $modRel $redsRel $inputRel
if ($LASTEXITCODE -ne 0) { throw 'git ls-files failed' }
function Test-Allowed([string]$name) {
  foreach ($root in $allowedIn.Keys) {
    if ($name.StartsWith($root + '/') -and
        [IO.Path]::GetExtension($name).ToLowerInvariant() -eq $allowedIn[$root]) { return $true }
  }
  return $false
}
$files = @($tracked | Where-Object { Test-Allowed $_ } | Sort-Object)
if (-not ($files -contains ($modRel + '/init.lua'))) { throw "init.lua is not tracked under $modRel" }
if (-not ($files | Where-Object { $_.StartsWith($redsRel + '/') })) { throw "no .reds file is tracked under $redsRel" }
if (-not ($files -contains ($inputRel + '/ShootDodge.xml'))) { throw "$inputRel/ShootDodge.xml is not tracked" }

# Export the index (staged) content of those files, not the working tree (C2SD-T73). Honors
# GIT_INDEX_FILE, so inside the pre-commit hook this is exactly what the commit will contain.
$stage = Join-Path ([IO.Path]::GetTempPath()) ('ShootDodge-package-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $stage | Out-Null
try {
$prefix = $stage.Replace('\', '/') + '/'
& git -C $repo checkout-index "--prefix=$prefix" -- $files
if ($LASTEXITCODE -ne 0) { throw 'git checkout-index failed' }
$initPath = Join-Path $stage ($modRel + '/init.lua')

if (-not $Version) {
  $match = Select-String -Path $initPath -Pattern '^\s*version\s*=\s*"([^"]+)"' | Select-Object -First 1
  if (-not $match) { throw "No version = ""x.y.z"" found in $initPath" }
  $Version = $match.Matches[0].Groups[1].Value
}
if ($Version -notmatch '^[0-9A-Za-z.\-]+$') { throw "Unusable version '$Version'" }

$dist = Join-Path $repo 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$zipPath = Join-Path $dist ("ShootDodge-$Version.zip")
if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
  foreach ($rel in $files) {
    $source = Join-Path $stage $rel
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $source, $rel,
      [IO.Compression.CompressionLevel]::Optimal) | Out-Null
  }
} finally {
  $zip.Dispose()
}
} finally {
  Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}

# Check what was written: every entry under one of the canonical prefixes with that prefix's
# file type, forward slashes only, init.lua directly inside the CET mod folder, a .reds file and the
# Input Loader key file (C2SD-T37).
$read = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
  $names = @($read.Entries | ForEach-Object { $_.FullName })
} finally {
  $read.Dispose()
}
$problems = @()
foreach ($name in $names) {
  if ($name.Contains('\')) { $problems += "backslash in entry: $name" }
  if (-not (Test-Allowed $name)) { $problems += "not a $modRel/*.lua, $redsRel/*.reds or $inputRel/*.xml entry: $name" }
}
if (-not ($names -contains ($modRel + '/init.lua'))) { $problems += 'init.lua missing from the mod folder' }
if (-not ($names | Where-Object { $_.StartsWith($redsRel + '/') -and $_.EndsWith('.reds') })) {
  $problems += "no .reds file under $redsRel/"
}
if (-not ($names -contains ($inputRel + '/ShootDodge.xml'))) { $problems += "$inputRel/ShootDodge.xml missing" }
if ($problems.Count -gt 0) {
  Remove-Item -LiteralPath $zipPath -Force
  throw ("Release zip failed its layout check:`n  " + ($problems -join "`n  "))
}

Write-Host "Built $zipPath ($($names.Count) files):"
$names | ForEach-Object { Write-Host "  $_" }
