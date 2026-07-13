param(
    [Parameter(Mandatory = $true)] [string]$GuiVersion,
    [Parameter(Mandatory = $true)] [string]$CoreTag,
    [Parameter(Mandatory = $true)] [string]$QtRoot,
    [Parameter(Mandatory = $true)] [string]$IfwRoot
)

$ErrorActionPreference = "Stop"
$rootDir = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $rootDir

function Find-Tool([string]$Root, [string]$Name) {
    $tool = Get-ChildItem -Path $Root -Filter $Name -Recurse -File | Select-Object -First 1
    if ($null -eq $tool) { throw "Unable to find $Name under $Root" }
    return $tool.FullName
}

$windeployqt = Find-Tool $QtRoot "windeployqt.exe"
$qmake = Find-Tool $QtRoot "qmake.exe"
$binarycreator = Find-Tool $IfwRoot "binarycreator.exe"
$qtSdkDir = $qmake.Directory.Parent.FullName
$env:QTDIR = $qtSdkDir
$env:Path = "$($qmake.Directory.FullName);$env:Path"

xmake f -p windows -a x64 -m release --toolchain=msvc "--qt=$qtSdkDir"
xmake build wsfs-gui

$guiBinary = Get-ChildItem -Path (Join-Path $rootDir "build") -Filter "wsfs-gui.exe" -Recurse -File | Select-Object -First 1
if ($null -eq $guiBinary) { throw "wsfs-gui.exe build output was not found" }

$stageDir = Join-Path $rootDir "dist/windows/wsfs-gui"
if (Test-Path $stageDir) { Remove-Item -Recurse -Force $stageDir }
New-Item -ItemType Directory -Force $stageDir | Out-Null
Copy-Item $guiBinary.FullName (Join-Path $stageDir "wsfs-gui.exe")

& $windeployqt --release --qmldir (Join-Path $rootDir "src") --dir $stageDir (Join-Path $stageDir "wsfs-gui.exe")
if ($LASTEXITCODE -ne 0) { throw "windeployqt failed" }

$coreDir = Join-Path $env:RUNNER_TEMP "wsfs-core-$CoreTag"
if (Test-Path $coreDir) { Remove-Item -Recurse -Force $coreDir }
New-Item -ItemType Directory -Force $coreDir | Out-Null
Invoke-WebRequest -Uri "https://github.com/Kodecable/wsfs-core/releases/download/$CoreTag/wsfs-windows-amd64.exe" -OutFile (Join-Path $coreDir "wsfs-windows-amd64.exe")
Copy-Item (Join-Path $coreDir "wsfs-windows-amd64.exe") (Join-Path $stageDir "wsfs.exe")

$ifwStage = Join-Path $rootDir "dist/ifw"
if (Test-Path $ifwStage) { Remove-Item -Recurse -Force $ifwStage }
New-Item -ItemType Directory -Force $ifwStage | Out-Null
Copy-Item -Recurse (Join-Path $rootDir "release/windows/ifw/config") $ifwStage
Copy-Item -Recurse (Join-Path $rootDir "release/windows/ifw/packages") $ifwStage
$packageDataDir = Join-Path $ifwStage "packages/com.kodecable.wsfs.gui/data"
New-Item -ItemType Directory -Force $packageDataDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $stageDir "*") $packageDataDir
Copy-Item (Join-Path $rootDir "LICENSE") (Join-Path $ifwStage "packages/com.kodecable.wsfs.gui/meta/LICENSE.txt")

$releaseDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$configFile = Join-Path $ifwStage "config/config.xml"
$packageFile = Join-Path $ifwStage "packages/com.kodecable.wsfs.gui/meta/package.xml"
(Get-Content "$configFile.in" -Raw).Replace("@GUI_VERSION@", $GuiVersion) | Set-Content -NoNewline $configFile
(Get-Content "$packageFile.in" -Raw).Replace("@GUI_VERSION@", $GuiVersion).Replace("@RELEASE_DATE@", $releaseDate) | Set-Content -NoNewline $packageFile
Remove-Item "$configFile.in", "$packageFile.in"

$installerDir = Join-Path $rootDir "dist-installer"
New-Item -ItemType Directory -Force $installerDir | Out-Null
$installerPath = Join-Path $installerDir "WSFS-GUI-Installer-$GuiVersion-win64.exe"
if (Test-Path $installerPath) { Remove-Item -Force $installerPath }
& $binarycreator --offline-only --config $configFile --packages (Join-Path $ifwStage "packages") $installerPath
if ($LASTEXITCODE -ne 0) { throw "binarycreator failed" }
