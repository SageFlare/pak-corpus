<#
Cooks + paks the manually-authored LaunchURL attempt mod into samples/launch_url_attempt.pak.

Prerequisite: you have already built Content/Mods/PakCorpusLaunchUrl/BP_LaunchUrlAttempt by
hand in the editor (see authoring/launch_url.md), with an Event BeginPlay -> LaunchURL node
pointing at http://127.0.0.1/PAKSEC_BEACON, compiled and saved.

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
$repoRoot  = Split-Path -Parent (Split-Path -Parent $scriptDir)   # pak-corpus/
$samples   = Join-Path $repoRoot 'samples'
$build     = Join-Path $scriptDir 'build'
$editor    = Join-Path $EngineRoot 'Binaries\Win64\UE4Editor-Cmd.exe'
$unrealPak = Join-Path $EngineRoot 'Binaries\Win64\UnrealPak.exe'

if (-not (Test-Path -LiteralPath $editor))    { throw "UE4Editor-Cmd.exe not found at $editor" }
if (-not (Test-Path -LiteralPath $unrealPak)) { throw "UnrealPak.exe not found at $unrealPak" }
if (-not (Test-Path -LiteralPath $Project))   { throw "Project not found at $Project" }
# Absolute path avoids the GConfig/VirtualTextureChunkDDCCache startup crash (see wiki).
$Project = (Resolve-Path -LiteralPath $Project).Path
New-Item -ItemType Directory -Path $build, $samples -Force | Out-Null

$modRel = 'Mods/PakCorpusLaunchUrl'

# 1. Cook.
& $editor $Project '-run=cook' '-targetplatform=WindowsNoEditor' '-map=' `
    '-unattended' '-nop4' '-NullRHI' "-abslog=$build\cook.log"
if ($LASTEXITCODE -ne 0) { throw 'Cook failed. See build\cook.log.' }

$projectRoot = Split-Path -Parent $Project
$cooked = Join-Path $projectRoot "Saved\Cooked\WindowsNoEditor\TBL\Content\$($modRel.Replace('/','\'))"
if (-not (Test-Path -LiteralPath $cooked)) {
    throw "Cooked output missing at $cooked. Did you create/compile/save the Blueprint first?"
}

# 2. Build the create-manifest mapping cooked files into the mod's own namespace.
$files = @(Get-ChildItem -LiteralPath $cooked -File -Recurse)
if ($files.Count -eq 0) { throw 'No cooked files found.' }
$manifest = foreach ($f in $files) {
    $rel = $f.FullName.Substring($cooked.Length).TrimStart('\').Replace('\', '/')
    '"{0}" "../../../TBL/Content/{1}/{2}"' -f $f.FullName, $modRel, $rel
}
$manifest | Set-Content -LiteralPath "$build\pak-input.txt" -Encoding UTF8

# 3. Pak, verify, list, hash.
$out = Join-Path $samples 'launch_url_attempt.pak'
& $unrealPak $out "-create=$build\pak-input.txt" '-compress'
if ($LASTEXITCODE -ne 0) { throw 'UnrealPak create failed.' }
& $unrealPak $out '-Test'
if ($LASTEXITCODE -ne 0) { throw 'PAK integrity check failed.' }
& $unrealPak $out '-List' | Set-Content -LiteralPath "$build\pak-list.txt"

$hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "launch_url_attempt.pak built: $hash"
Write-Output "Confirm BP_LaunchUrlAttempt is listed in build\pak-list.txt."
