param(
    [Parameter(Mandatory = $true)] [string]$GuiVersion,
    [Parameter(Mandatory = $true)] [string]$CoreTag,
    [Parameter(Mandatory = $true)] [string]$CraftRoot,
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

$windeployqt = Find-Tool $CraftRoot "windeployqt.exe"
$qmake = Find-Tool $CraftRoot "qmake.exe"
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

function Copy-BreezeRuntime([string]$Root, [string]$Destination) {
    $desktopModule = Get-ChildItem -Path $Root -Filter "qmldir" -Recurse -File |
        Where-Object { $_.FullName -match '[\\/]org[\\/]kde[\\/]desktop[\\/]qmldir$' } |
        Select-Object -First 1
    if ($null -eq $desktopModule) { throw "Craft did not install the org.kde.desktop QML module" }

    $orgDirectory = $desktopModule.Directory.Parent.Parent
    $qmlDestination = Join-Path $Destination "qml"
    New-Item -ItemType Directory -Force $qmlDestination | Out-Null
    Copy-Item -Recurse -Force $orgDirectory.FullName $qmlDestination

    $breezePlugin = Get-ChildItem -Path $Root -Filter "breeze6.dll" -Recurse -File | Select-Object -First 1
    if ($null -eq $breezePlugin) { throw "Craft did not install the Breeze Qt style plugin" }
    $stylesDirectory = Join-Path $Destination "styles"
    New-Item -ItemType Directory -Force $stylesDirectory | Out-Null
    Copy-Item -Force $breezePlugin.FullName (Join-Path $stylesDirectory "breeze6.dll")

    $craftBin = Join-Path $Root "bin"
    if (-not (Test-Path $craftBin)) { throw "Craft binary directory was not found: $craftBin" }
    # Craft owns this Qt/KF runtime prefix. Copying its DLL set keeps the QML modules and Breeze plugin ABI-matched.
    Get-ChildItem -Path $craftBin -Filter "*.dll" -File | ForEach-Object {
        Copy-Item -Force $_.FullName (Join-Path $Destination $_.Name)
    }
}

Copy-BreezeRuntime $CraftRoot $stageDir

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
