<#
Builds samples/asset_replacement_attempt.pak - the PRIMARY attack vector.

Creates an inert stand-in material (via make_replacement_asset.py), cooks it, then paks it to
a TRUSTED GAME ASSET PATH so it shadows the real game asset via mount precedence. The asset is
harmless (a magenta material); the danger is the replacement itself. A real attacker would
target a gameplay-critical class - we use a low-risk UI material to keep the sample safe while
still exercising the vector.

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
$makePy    = Join-Path $scriptDir 'make_replacement_asset.py'

if (-not (Test-Path -LiteralPath $editor))    { throw "UE4Editor-Cmd.exe not found at $editor" }
if (-not (Test-Path -LiteralPath $unrealPak)) { throw "UnrealPak.exe not found at $unrealPak" }
if (-not (Test-Path -LiteralPath $Project))   { throw "Project not found at $Project" }
$Project = (Resolve-Path -LiteralPath $Project).Path
New-Item -ItemType Directory -Path $build, $samples -Force | Out-Null

# The trusted game asset this sample shadows (a low-risk UI material that exists in the game).
$shadowTarget = 'UI/Materials/DetailLines/M_DetailLine_gradient'

# 1. Create the inert stand-in.
& $editor $Project "-ExecutePythonScript=$makePy" '-EnablePlugins=EditorScriptingUtilities' `
    '-unattended' '-nop4' '-nosplash' "-abslog=$build\make.log"
if ($LASTEXITCODE -ne 0) { throw 'Asset creation failed. See build\make.log.' }
if (-not (Select-String -LiteralPath "$build\make.log" -SimpleMatch 'PAKCORPUS_REPLACEMENT_OK')) {
    throw 'Asset creation did not report success.'
}

# 2. Cook.
& $editor $Project '-run=cook' '-targetplatform=WindowsNoEditor' '-map=' `
    '-unattended' '-nop4' '-NullRHI' "-abslog=$build\cook.log"
if ($LASTEXITCODE -ne 0) { throw 'Cook failed. See build\cook.log.' }

$projectRoot = Split-Path -Parent $Project
$cooked = Join-Path $projectRoot 'Saved\Cooked\WindowsNoEditor\TBL\Content\Mods\PakCorpusReplacement'
if (-not (Test-Path -LiteralPath $cooked)) { throw "Cooked output missing at $cooked" }

# 3. Pak the cooked stand-in to the TRUSTED game path (shadowing). The asset is already named
#    M_DetailLine_gradient (see make_replacement_asset.py), so we keep its filename and just
#    place it under the game dir — no pak-time rename (which UnrealPak overrides).
$matFiles = @(Get-ChildItem -LiteralPath $cooked -File -Recurse -Filter 'M_DetailLine_gradient*')
if ($matFiles.Count -eq 0) { throw 'Stand-in material not found in cooked output.' }
$targetDir = (Split-Path -Parent $shadowTarget).Replace('\', '/')
$manifest = foreach ($f in $matFiles) {
    '"{0}" "../../../TBL/Content/{1}/{2}"' -f $f.FullName, $targetDir, $f.Name
}
$manifest | Set-Content -LiteralPath "$build\pak-input.txt" -Encoding UTF8

# 4. Pak, verify, list, hash.
$out = Join-Path $samples 'asset_replacement_attempt.pak'
& $unrealPak $out "-create=$build\pak-input.txt" '-compress'
if ($LASTEXITCODE -ne 0) { throw 'UnrealPak create failed.' }
& $unrealPak $out '-Test'
if ($LASTEXITCODE -ne 0) { throw 'PAK integrity check failed.' }
& $unrealPak $out '-List' | Set-Content -LiteralPath "$build\pak-list.txt"

$hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "asset_replacement_attempt.pak built: $hash"
Write-Output "Shadows TBL/Content/$shadowTarget - confirm that path in build\pak-list.txt."
