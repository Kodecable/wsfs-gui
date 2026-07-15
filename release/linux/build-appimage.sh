#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
version="${1:?usage: build-appimage.sh <gui-version> <core-tag>}"
core_tag="${2:?usage: build-appimage.sh <gui-version> <core-tag>}"

command -v xmake >/dev/null || { echo "xmake is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v quick-sharun >/dev/null || { echo "quick-sharun is required" >&2; exit 1; }

cd "${root_dir}"
xmake f -p linux -a x86_64 -m release
xmake build wsfs-gui

gui_binary="$(find build -type f -name wsfs-gui -perm -u+x | head -n 1)"
[[ -n "${gui_binary}" ]] || { echo "wsfs-gui build output was not found" >&2; exit 1; }

output_dir="${root_dir}/dist"
app_dir="${output_dir}/AppDir"
input_dir="${output_dir}/anylinux-input"
appimage_name="WSFS-GUI-${version}-AnyLinux-x86_64.AppImage"
mkdir -p "${output_dir}" "${input_dir}"
rm -rf "${app_dir}"
rm -f "${output_dir}/${appimage_name}"

core_binary="${input_dir}/wsfs"
curl --fail --location --retry 3 \
  --output "${core_binary}" \
  "https://github.com/Kodecable/wsfs-core/releases/download/${core_tag}/wsfs-linux-amd64"
chmod +x "${core_binary}"

# qtkeychain loads libsecret via QLibrary("secret-1"), so it is invisible to a normal ELF dependency scan.
libsecret_path="$(pacman -Ql libsecret | awk '$2 ~ /libsecret-1\.so\.0$/ { print $2; exit }')"
[[ -n "${libsecret_path}" ]] || { echo "libsecret-1.so.0 was not found" >&2; exit 1; }
libproxy_backend_dir=/usr/lib/libproxy
mapfile -t libproxy_backends < <(find "${libproxy_backend_dir}" -maxdepth 1 -type f -name '*.so' -print | sort)
(( ${#libproxy_backends[@]} > 0 )) || { echo "libproxy backends were not found" >&2; exit 1; }

export APPDIR="${app_dir}"
export OUTPATH="${output_dir}"
export MAIN_BIN=wsfs-gui
export DESKTOP="${root_dir}/release/linux/wsfs-gui.desktop"
export ICON="${root_dir}/src/assets/app-icon.png"
export DEPLOY_QT=1
export DEPLOY_QML=1
export DEPLOY_OPENGL=1
export STRACE_TIME=5
# wsfs-core is a static Go executable. Tracing only the GUI avoids terminating the service process group.
export STRACE_BINARY=wsfs-gui

quick-sharun \
  "${gui_binary}" \
  "${core_binary}" \
  "${libsecret_path}" \
  "${libproxy_backends[@]}" \
  /usr/lib/qt6/qml/org/kde/desktop \
  /usr/lib/qt6/plugins/styles/breeze6.so

cat >> "${app_dir}/.env" <<'EOF'
QT_QPA_PLATFORMTHEME=xdgdesktopportal
QT_QUICK_CONTROLS_STYLE=org.kde.desktop
EOF

quick-sharun --make-appimage

generated_appimage="$(find "${output_dir}" -maxdepth 1 -type f -name '*.AppImage' -print -quit)"
[[ -n "${generated_appimage}" ]] || { echo "quick-sharun did not generate an AppImage" >&2; exit 1; }
mv "${generated_appimage}" "${output_dir}/${appimage_name}"
