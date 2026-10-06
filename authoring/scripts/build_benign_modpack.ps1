<#
Builds samples/benign_modpack.pak - ONE pak with TWO legitimate mods, each an ArgonSDKModBase
actor WITH its own DA_ModMarker (both menu-visible, neither hidden, neither dangerous).

The honest multi-mod "mod pack" case: must scan benign, proving the hidden_mod rule does not
false-positive on marker'd mods.

Prerequisite: author PakCorpusBenignModA and PakCorpusBenignModB (actor + <Name>_Marker each)
per authoring/benign_modpack.md, compiled + saved.

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
$editor    = Join-Path $EngineRoot 'Binaries\Win64\UE4Editor-Cmd.exe'
$unrealPak = Join-Path $EngineRoot 'Binaries\Win64\UnrealPak.exe'
if (-not (Test-Path -LiteralPath $editor))    { throw "UE4Editor-Cmd.exe not found at $editor" }
if (-not (Test-Path -LiteralPath $unrealPak)) { throw "UnrealPak.exe not found at $unrealPak" }
if (-not (Test-Path -LiteralPath $Project))   { throw "Project not found at $Project" }
$Project = (Resolve-Path -LiteralPath $Project).Path
$projectRoot = Split-Path -Parent $Project
New-Item -ItemType Directory -Path $build, $samples -Force | Out-Null

$mods = @('PakCorpusBenignModA', 'PakCorpusBenignModB')

# 1. Cook.
& $editor $Project '-run=cook' '-targetplatform=WindowsNoEditor' '-map=' `
    '-unattended' '-nop4' '-NullRHI' "-abslog=$build\cook.log"
if ($LASTEXITCODE -ne 0) { throw 'Cook failed. See build\cook.log.' }

$cookedRoot = Join-Path $projectRoot 'Saved\Cooked\WindowsNoEditor\TBL\Content\Mods\AgMods'
$lines = @()
foreach ($mod in $mods) {
    $dir = Join-Path $cookedRoot $mod
    if (-not (Test-Path $dir)) { throw "Missing cooked mod: $dir (author + compile it first)" }
    Get-ChildItem -LiteralPath $dir -File -Recurse | ForEach-Object {
        $rel = $_.FullName.Substring($dir.Length).TrimStart('\').Replace('\', '/')
        $lines += ('"{0}" "../../../TBL/Content/Mods/AgMods/{1}/{2}"' -f $_.FullName, $mod, $rel)
    }
}
if ($lines.Count -eq 0) { throw 'No cooked files found for either mod.' }
$lines | Set-Content -LiteralPath "$build\modpack-input.txt" -Encoding UTF8

$out = Join-Path $samples 'benign_modpack.pak'
& $unrealPak $out "-create=$build\modpack-input.txt" '-compress'
if ($LASTEXITCODE -ne 0) { throw 'UnrealPak create failed.' }
& $unrealPak $out '-Test'
if ($LASTEXITCODE -ne 0) { throw 'PAK integrity check failed.' }
& $unrealPak $out '-List' | Set-Content -LiteralPath "$build\modpack-list.txt"
$hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "benign_modpack.pak built: $hash"
Write-Output "Confirm both <Mod>.uasset and both <Mod>_Marker.uasset are in build\modpack-list.txt."
