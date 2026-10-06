<#
Builds samples/benign_cosmetic.pak for the pak-corpus.

Creates a benign cosmetic material under the mod's own namespace (via
make_benign_cosmetic.py), cooks it, paks it under ../../../TBL/Content/Mods/PakCorpusBenign/,
runs UnrealPak integrity + listing, and hashes the result. Installs nothing into the game.

Pass your own paths; nothing machine-specific is committed:
  -EngineRoot  : UE 4.25 engine root (default: standard Epic install)
  -Project     : full path to ArgonSDK TBL.uproject (REQUIRED)

Example:
  .\build_benign_cosmetic.ps1 -Project "D:\path\to\ArgonSDK\TBL.uproject"
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
$makePy    = Join-Path $scriptDir 'make_benign_cosmetic.py'

if (-not (Test-Path -LiteralPath $editor))    { throw "UE4Editor-Cmd.exe not found at $editor" }
if (-not (Test-Path -LiteralPath $unrealPak)) { throw "UnrealPak.exe not found at $unrealPak" }
if (-not (Test-Path -LiteralPath $Project))   { throw "Project not found at $Project" }
# UE4Editor-Cmd mis-resolves a relative .uproject at startup (GConfig null ->
# VirtualTextureChunkDDCCache assertion crash before any script runs). Force absolute.
$Project = (Resolve-Path -LiteralPath $Project).Path
New-Item -ItemType Directory -Path $build, $samples -Force | Out-Null

# 1. Create the benign asset.
& $editor $Project "-ExecutePythonScript=$makePy" '-EnablePlugins=EditorScriptingUtilities' `
    '-unattended' '-nop4' '-nosplash' "-abslog=$build\make.log"
if ($LASTEXITCODE -ne 0) { throw 'Asset creation failed. See build\make.log.' }
if (-not (Select-String -LiteralPath "$build\make.log" -SimpleMatch 'PAKCORPUS_BENIGN_OK')) {
    throw 'Asset creation did not report success.'
}

# 2. Cook the mod package.
& $editor $Project '-run=cook' '-targetplatform=WindowsNoEditor' `
    '-map=' '-unattended' '-nop4' '-NullRHI' "-abslog=$build\cook.log"
if ($LASTEXITCODE -ne 0) { throw 'Cook failed. See build\cook.log.' }

$projectRoot = Split-Path -Parent $Project
$cooked = Join-Path $projectRoot 'Saved\Cooked\WindowsNoEditor\TBL\Content\Mods\PakCorpusBenign'
if (-not (Test-Path -LiteralPath $cooked)) { throw "Cooked output missing at $cooked" }

# 3. Build the UnrealPak create-manifest (map cooked files into the mod's own namespace).
$files = @(Get-ChildItem -LiteralPath $cooked -File -Recurse)
if ($files.Count -eq 0) { throw 'No cooked files found.' }
$manifest = foreach ($f in $files) {
    $rel = $f.FullName.Substring($cooked.Length).TrimStart('\').Replace('\', '/')
    '"{0}" "../../../TBL/Content/Mods/PakCorpusBenign/{1}"' -f $f.FullName, $rel
}
$manifest | Set-Content -LiteralPath "$build\pak-input.txt" -Encoding UTF8

# 4. Pak, verify, list, hash.
$out = Join-Path $samples 'benign_cosmetic.pak'
& $unrealPak $out "-create=$build\pak-input.txt" '-compress'
if ($LASTEXITCODE -ne 0) { throw 'UnrealPak create failed.' }
& $unrealPak $out '-Test'
if ($LASTEXITCODE -ne 0) { throw 'PAK integrity check failed.' }
& $unrealPak $out '-List' | Set-Content -LiteralPath "$build\pak-list.txt"

$hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "benign_cosmetic.pak built: $hash"
Write-Output "Entries listed in build\pak-list.txt (confirm all are under TBL/Content/Mods/)."
