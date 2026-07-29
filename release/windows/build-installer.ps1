param(
    [Parameter(Mandatory = $true)] [string]$GuiVersion,
    [Parameter(Mandatory = $true)] [string]$CoreTag,
    [Parameter(Mandatory = $true)] [string]$CraftRoot
)

$ErrorActionPreference = "Stop"
$rootDir = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $rootDir

function Find-Tool([string]$Root, [string]$Name) {
    $tool = Get-ChildItem -Path $Root -Filter $Name -Recurse -File | Select-Object -First 1
    if ($null -eq $tool) { throw "Unable to find $Name under $Root" }
    return $tool.FullName
}

function Find-InnoCompiler() {
    $candidates = @()
    if ($env:ProgramFiles) {
        $candidates += (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
    }
    if (${env:ProgramFiles(x86)}) {
        $candidates += (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe")
    }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    $command = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    throw "Unable to find ISCC.exe. Install Inno Setup 6 or add ISCC.exe to PATH."
}

function Quote-InnoPath([string]$Path) {
    return '"' + $Path.Replace('"', '""') + '"'
}

function Test-StagedApplication([string]$StageDir, [string]$ArtifactDir) {
    $stdoutLog = Join-Path $ArtifactDir "wsfs-gui.startup.stdout.log"
    $stderrLog = Join-Path $ArtifactDir "wsfs-gui.startup.stderr.log"
    Remove-Item -Force -ErrorAction SilentlyContinue $stdoutLog, $stderrLog

    $previousDebugPlugins = $env:QT_DEBUG_PLUGINS
    $previousImportTrace = $env:QML_IMPORT_TRACE
    $previousLoggingRules = $env:QT_LOGGING_RULES
    $previousForceStderr = $env:QT_FORCE_STDERR_LOGGING

    try {
        $env:QT_DEBUG_PLUGINS = "1"
        $env:QML_IMPORT_TRACE = "1"
        $env:QT_LOGGING_RULES = "qt.qml.*=true;qt.qpa.*=true"
        $env:QT_FORCE_STDERR_LOGGING = "1"

        $process = Start-Process `
            -FilePath (Join-Path $StageDir "wsfs-gui.exe") `
            -WorkingDirectory $StageDir `
            -RedirectStandardOutput $stdoutLog `
            -RedirectStandardError $stderrLog `
            -PassThru

        if ($process.WaitForExit(10000)) {
            $stdoutText = Get-Content -Raw -ErrorAction SilentlyContinue $stdoutLog
            $stderrText = Get-Content -Raw -ErrorAction SilentlyContinue $stderrLog
            $exitCode = $process.ExitCode
            throw "Staged wsfs-gui.exe exited within 10 seconds with code $exitCode.`nSTDOUT:`n$stdoutText`nSTDERR:`n$stderrText"
        }

        Stop-Process -Id $process.Id -Force
    }
    finally {
        $env:QT_DEBUG_PLUGINS = $previousDebugPlugins
        $env:QML_IMPORT_TRACE = $previousImportTrace
        $env:QT_LOGGING_RULES = $previousLoggingRules
        $env:QT_FORCE_STDERR_LOGGING = $previousForceStderr
    }
}

$windeployqt = Find-Tool $CraftRoot "windeployqt.exe"
$qmake = Find-Tool $CraftRoot "qmake.exe"
$iscc = Find-InnoCompiler
$qtSdkDir = $qmake.Directory.Parent.FullName
$env:QTDIR = $qtSdkDir
$env:Path = "$($qmake.Directory.FullName);$env:Path"

xmake f -p windows -a x64 -m release --toolchain=msvc "--qt=$qtSdkDir"
xmake build wsfs-gui

$guiBinary = Join-Path $rootDir "build/windows/x64/release/wsfs-gui.exe"
if (-not (Test-Path $guiBinary)) {
    throw "wsfs-gui.exe build output was not found at $guiBinary"
}

$stageDir = Join-Path $rootDir "dist/windows/wsfs-gui"
if (Test-Path $stageDir) { Remove-Item -Recurse -Force $stageDir }
New-Item -ItemType Directory -Force $stageDir | Out-Null
Copy-Item $guiBinary (Join-Path $stageDir "wsfs-gui.exe")

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

Copy-Item (Join-Path $rootDir "LICENSE") (Join-Path $stageDir "LICENSE.txt")

$coreDir = Join-Path $env:RUNNER_TEMP "wsfs-core-$CoreTag"
if (Test-Path $coreDir) { Remove-Item -Recurse -Force $coreDir }
New-Item -ItemType Directory -Force $coreDir | Out-Null
Invoke-WebRequest -Uri "https://github.com/Kodecable/wsfs-core/releases/download/$CoreTag/wsfs-windows-amd64.exe" -OutFile (Join-Path $coreDir "wsfs-windows-amd64.exe")
Copy-Item (Join-Path $coreDir "wsfs-windows-amd64.exe") (Join-Path $stageDir "wsfs.exe")

$installerDir = Join-Path $rootDir "dist-installer"
New-Item -ItemType Directory -Force $installerDir | Out-Null
$innoDir = Join-Path $rootDir "dist/inno"
if (Test-Path $innoDir) { Remove-Item -Recurse -Force $innoDir }
New-Item -ItemType Directory -Force $innoDir | Out-Null

Test-StagedApplication $stageDir $installerDir

$scriptTemplate = Join-Path $rootDir "release/windows/inno/setup.iss.in"
$scriptPath = Join-Path $innoDir "setup.iss"
$installerPath = Join-Path $installerDir "WSFS-GUI-Installer-$GuiVersion-win64.exe"
if (Test-Path $installerPath) { Remove-Item -Force $installerPath }
$scriptContent = Get-Content $scriptTemplate -Raw
$scriptContent = $scriptContent.Replace("@APP_ID@", "c14277ab-528f-4823-906d-55b9f103dfdc")
$scriptContent = $scriptContent.Replace("@GUI_VERSION@", $GuiVersion)
$scriptContent = $scriptContent.Replace("@STAGE_DIR@", $stageDir)
$scriptContent = $scriptContent.Replace("@LICENSE_FILE@", (Quote-InnoPath (Join-Path $rootDir "LICENSE")))
$scriptContent = $scriptContent.Replace("@SETUP_ICON_FILE@", (Quote-InnoPath (Join-Path $rootDir "src/assets/app-icon.ico")))
$scriptContent = $scriptContent.Replace("@INSTALLER_OUTPUT_DIR@", (Quote-InnoPath $installerDir))
$scriptContent = $scriptContent.Replace("@INSTALLER_OUTPUT_BASE@", "WSFS-GUI-Installer-$GuiVersion-win64")
Set-Content -Path $scriptPath -Value $scriptContent -NoNewline

& $iscc $scriptPath
if ($LASTEXITCODE -ne 0) { throw "ISCC failed" }
if (-not (Test-Path $installerPath)) { throw "Inno Setup did not produce $installerPath" }
