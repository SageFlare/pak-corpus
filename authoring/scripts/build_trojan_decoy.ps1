<#
Builds samples/trojan_decoy.pak - a single pak carrying TWO mods:
  - a benign cosmetic material under the mod's own namespace (the visible-ish decoy), and
  - a hidden ArgonSDKModBase LaunchURL actor at the AgMods convention path with NO DA_ModMarker
    (invisible in the Mod Manager menu, but server-force-loadable by name -> auto-spawns -> fires).

Demonstrates the "menu can't be trusted, scan the file" threat: a player sees/enables the
friendly mod while a server silently force-loads the hidden one. The scanner must flag the hidden
mod flagged-active despite the decoy.

Prerequisite: the cooked assets already exist from the delivered + cosmetic builds
(Content/Mods/AgMods/PakCorpusLaunchUrlMod/ and Content/Mods/PakCorpusBenign/). Re-run those
builds first if the cooked output is missing.

Pass your own paths; nothing machine-specific is committed:
  -EngineRoot : UE 4.25 engine root (default: standard Epic install)
  -Project    : full path to ArgonSDK TBL.uproject (REQUIRED)
#>
param(
    [string]$EngineRoot = 'C:\Program Files\Epic Games\UE_4.25\Engine',
    [Parameter(Mandatory = $true)][string]$Project
)
$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
$repoRoot  = Split-Path -Parent (Split-Path -Parent $scriptDir)
$samples   = Join-Path $repoRoot 'samples'
$build     = Join-Path $scriptDir 'build'
$unrealPak = Join-Path $EngineRoot 'Binaries\Win64\UnrealPak.exe'
if (-not (Test-Path -LiteralPath $unrealPak)) { throw "UnrealPak.exe not found at $unrealPak" }
$Project = (Resolve-Path -LiteralPath $Project).Path
$projectRoot = Split-Path -Parent $Project
New-Item -ItemType Directory -Path $build, $samples -Force | Out-Null

$cookedRoot = Join-Path $projectRoot 'Saved\Cooked\WindowsNoEditor\TBL\Content'
$hidden = Join-Path $cookedRoot 'Mods\AgMods\PakCorpusLaunchUrlMod'
$decoy  = Join-Path $cookedRoot 'Mods\PakCorpusBenign'
if (-not (Test-Path $hidden)) { throw "Missing cooked hidden mod: $hidden (run build_launch_url_delivered first)" }
if (-not (Test-Path $decoy))  { throw "Missing cooked decoy: $decoy (run build_benign_cosmetic first)" }

# Combine into one pak-input, each mod at its own path. Exclude the hidden mod's marker so it is
# the markerless (menu-invisible) variant.
$lines = @()
Get-ChildItem -LiteralPath $hidden -File -Recurse | Where-Object { $_.Name -notlike '*ModMarker*' } | ForEach-Object {
    $rel = $_.FullName.Substring($hidden.Length).TrimStart('\').Replace('\', '/')
    $lines += ('"{0}" "../../../TBL/Content/Mods/AgMods/PakCorpusLaunchUrlMod/{1}"' -f $_.FullName, $rel)
}
Get-ChildItem -LiteralPath $decoy -File -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($decoy.Length).TrimStart('\').Replace('\', '/')
    $lines += ('"{0}" "../../../TBL/Content/Mods/PakCorpusBenign/{1}"' -f $_.FullName, $rel)
}
$lines | Set-Content -LiteralPath "$build\trojan-input.txt" -Encoding UTF8

$out = Join-Path $samples 'trojan_decoy.pak'
& $unrealPak $out "-create=$build\trojan-input.txt" '-compress'
if ($LASTEXITCODE -ne 0) { throw 'UnrealPak create failed.' }
& $unrealPak $out '-Test'
if ($LASTEXITCODE -ne 0) { throw 'PAK integrity check failed.' }
& $unrealPak $out '-List' | Set-Content -LiteralPath "$build\trojan-list.txt"
$hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "trojan_decoy.pak built: $hash"
Write-Output "Contains a benign cosmetic (decoy) + a hidden markerless LaunchURL mod."
