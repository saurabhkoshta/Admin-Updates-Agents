[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("core", "simple", "personalized")]
    [Alias("Profile")]
    [string]$ProfileName,

    [string]$SourceRoot = (Split-Path -Parent $PSScriptRoot),

    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

if ($ProfileName -eq "simple") {
    Write-Warning "The 'simple' profile name is deprecated. Use 'core'."
    $ProfileName = "core"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $SourceRoot "dist/$ProfileName"
}

$manifestPath = Join-Path $SourceRoot "profiles/$ProfileName.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Profile manifest not found: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$resolvedSourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$resolvedOutputParent = Split-Path -Parent $OutputPath

if (-not (Test-Path -LiteralPath $resolvedOutputParent)) {
    New-Item -ItemType Directory -Path $resolvedOutputParent -Force | Out-Null
}

if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Recurse -Force
}

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

foreach ($relativePath in $manifest.includes) {
    $sourcePath = Join-Path $resolvedSourceRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Profile '$ProfileName' references a missing path: $relativePath"
    }

    $destinationPath = Join-Path $OutputPath $relativePath
    $destinationParent = Split-Path -Parent $destinationPath
    if (-not (Test-Path -LiteralPath $destinationParent)) {
        New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
    }

    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Recurse
}

if ($null -ne $manifest.overlays) {
    foreach ($relativeOverlayPath in $manifest.overlays) {
        $overlayPath = Join-Path $resolvedSourceRoot $relativeOverlayPath
        if (-not (Test-Path -LiteralPath $overlayPath -PathType Container)) {
            throw "Profile '$ProfileName' references a missing overlay: $relativeOverlayPath"
        }

        Copy-Item -Path (Join-Path $overlayPath "*") -Destination $OutputPath -Recurse -Force
    }
}

Get-ChildItem -LiteralPath $OutputPath -File -Recurse -Filter "*.template" | ForEach-Object {
    $materializedPath = $_.FullName.Substring(0, $_.FullName.Length - ".template".Length)
    Move-Item -LiteralPath $_.FullName -Destination $materializedPath -Force
}

Write-Output "Built '$($manifest.name)' profile at $OutputPath"