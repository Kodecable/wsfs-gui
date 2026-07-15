#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
container_engine="${CONTAINER_ENGINE:-podman}"
image_name="${WSFS_GUI_BUILDER_IMAGE:-localhost/wsfs-gui-appimage-builder:local}"
cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/wsfs-gui/pacman"

command -v "${container_engine}" >/dev/null || {
    echo "${container_engine} is required; set CONTAINER_ENGINE to a supported OCI engine" >&2
    exit 1
}

mkdir -p "${cache_dir}"

if [[ "${container_engine}" != "podman" ]]; then
    echo "build-container.sh is intended for local Podman use; CI builds this Containerfile with Docker Buildx" >&2
    exit 1
fi

build_args=(
    build
    --layers
    --volume "${cache_dir}:/var/cache/pacman/pkg:Z"
    --file "${root_dir}/release/linux/Containerfile"
    --tag "${image_name}"
)

if [[ -d /var/cache/pacman/pkg ]]; then
    build_args+=(--volume "/var/cache/pacman/pkg:/host-pacman-cache:ro,Z")
fi

"${container_engine}" "${build_args[@]}" "${root_dir}"

exec "${container_engine}" run --rm \
    --userns=keep-id \
    --env HOME=/tmp/wsfs-gui-home \
    --volume "${root_dir}:/workspace:Z" \
    --workdir /workspace \
    "${image_name}" \
    bash release/linux/build-appimage.sh "$@"
