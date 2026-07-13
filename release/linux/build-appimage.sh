#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
version="${1:?usage: build-appimage.sh <gui-version> <core-tag>}"
core_tag="${2:?usage: build-appimage.sh <gui-version> <core-tag>}"
linuxdeploy_bin="${LINUXDEPLOY:?LINUXDEPLOY must point to linuxdeploy}"

command -v xmake >/dev/null || { echo "xmake is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }

cd "${root_dir}"
xmake f -p linux -a x86_64 -m release
xmake build wsfs-gui

gui_binary="$(find build -type f -name wsfs-gui -perm -u+x | head -n 1)"
[[ -n "${gui_binary}" ]] || { echo "wsfs-gui build output was not found" >&2; exit 1; }

stage_dir="${root_dir}/dist/AppDir"
output_dir="${root_dir}/dist"
rm -rf "${stage_dir}"
mkdir -p "${stage_dir}/usr/bin" \
         "${stage_dir}/usr/share/applications" \
         "${stage_dir}/usr/share/icons/hicolor/256x256/apps"

install -Dm755 "${gui_binary}" "${stage_dir}/usr/bin/wsfs-gui"
install -Dm644 release/linux/wsfs-gui.desktop "${stage_dir}/usr/share/applications/wsfs-gui.desktop"
install -Dm644 src/assets/app-icon.png "${stage_dir}/usr/share/icons/hicolor/256x256/apps/wsfs-gui.png"

core_dir="$(mktemp -d)"
trap 'rm -rf "${core_dir}"' EXIT
curl --fail --location --retry 3 \
  --output "${core_dir}/wsfs-linux-amd64" \
  "https://github.com/Kodecable/wsfs-core/releases/download/${core_tag}/wsfs-linux-amd64"
install -Dm755 "${core_dir}/wsfs-linux-amd64" "${stage_dir}/usr/bin/wsfs"

# qtkeychain 通过 QLibrary("secret-1") 延迟加载 libsecret，因此常规 ELF 依赖扫描看不到它。
# 显式传入 linuxdeploy，确保 AppImage 在未安装 libsecret 的宿主上仍能加载客户端库。
libsecret_path="$(ldconfig -p | awk '/libsecret-1\\.so\\.0/{print $NF; exit}')"
[[ -n "${libsecret_path}" ]] || { echo "libsecret-1.so.0 was not found" >&2; exit 1; }

rm -f "${output_dir}/WSFS-GUI-${version}-x86_64.AppImage"
ARCH=x86_64 "${linuxdeploy_bin}" \
  --appdir "${stage_dir}" \
  --desktop-file "${stage_dir}/usr/share/applications/wsfs-gui.desktop" \
  --icon-file "${stage_dir}/usr/share/icons/hicolor/256x256/apps/wsfs-gui.png" \
  --executable "${stage_dir}/usr/bin/wsfs-gui" \
  --library "${libsecret_path}" \
  --plugin qt \
  --output appimage

generated_appimage="$(find "${root_dir}" -maxdepth 1 -type f -name '*.AppImage' | head -n 1)"
[[ -n "${generated_appimage}" ]] || { echo "linuxdeploy did not generate an AppImage" >&2; exit 1; }
mv "${generated_appimage}" "${output_dir}/WSFS-GUI-${version}-x86_64.AppImage"
