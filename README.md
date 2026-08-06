# WSFS-GUI

WSFS-GUI is a graphical interface for [WSFS-Core](https://github.com/Kodecable/wsfs-core), available for Windows and Linux.

Prebuilt x64 releases are available from the [latest release page](https://github.com/Kodecable/wsfs-gui/releases/latest).

## Windows Installer

Windows releases are packaged as installers with [Inno Setup](https://jrsoftware.org/isinfo.php). The installer installs WSFS-GUI bundled with the required runtime files and a copy of WSFS-Core, but requires the [Microsoft Visual C++ 2022 x64 Redistributable](https://aka.ms/vc14/vc_redist.x64.exe) and [WinFsp](https://winfsp.dev/rel/) to be installed separately.

## Linux AppImage

Linux releases are distributed as [AnyLinux AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages). The package includes the runtimes required by the application like Qt, libc, and WSFS-Core. A graphical environment and FUSE 3 must be provided by the host system.

On NixOS, you may need to disable `appimage-run` before launching the AppImage. See the [AnyLinux AppImages FAQ](https://github.com/pkgforge-dev/Anylinux-AppImages/blob/main/FAQ.md#i-get-error-cant-find-a-valid-squashfs-superblock-in-nixos) for details.

### Build Locally

Build an AppImage with:

```sh
release/linux/build-container.sh <gui-version> <wsfs-core-tag>
```

The helper builds an Arch Linux-based packaging image, reuses the host Pacman cache when available, and writes the output to:

```text
dist/WSFS-GUI-<gui-version>-AnyLinux-x86_64.AppImage
```

GitHub Actions uses the same `release/linux/Containerfile` with Docker Buildx. Local builds use Podman by default, so Docker is not required for the command above.
