# WSFS-GUI

WSFS-GUI is an GUI of [WSFS-Core](https://github.com/Kodecable/wsfs-core) for Windows and Linux.

## Linux AppImage

Linux releases are built as AnyLinux AppImages. The package bundles the Qt and KDE runtime needed by the application, uses the host XDG Desktop Portal for native file dialogs, and is compressed with DwarFS.

### Manual build with Podman

```sh
release/linux/build-container.sh <gui-version> <wsfs-core-tag>
```

The helper builds the Arch packaging image, reuses the host pacman cache when available, and writes the result to:

```text
dist/WSFS-GUI-<gui-version>-AnyLinux-x86_64.AppImage
```

The same `release/linux/Containerfile` is used by GitHub Actions with Docker Buildx. Local builds intentionally use Podman; no Docker setup is required for the documented command.

### Credits

The Linux packaging workflow is based on [AnyLinux-AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages).
