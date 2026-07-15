param(
    [Parameter(Mandatory = $true)] [string]$CraftRoot
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Join-Path $CraftRoot "craft/craftenv.ps1"))) {
    $installer = Join-Path $env:RUNNER_TEMP "install-craft.ps1"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/KDE/craft/master/setup/install_craft.ps1" -OutFile $installer
    & $installer -root $CraftRoot -python (Get-Command python).Source -use-defaults
    if ($LASTEXITCODE -ne 0) { throw "Craft bootstrap failed" }
}

. (Join-Path $CraftRoot "craft/craftenv.ps1")
craft --install kde/frameworks/tier3/qqc2-desktop-style kde/plasma/breeze
if ($LASTEXITCODE -ne 0) { throw "Installing the KDE desktop style runtime failed" }
