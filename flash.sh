#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

WAIT_SECONDS="${WAIT_SECONDS:-15}"

./build.sh "$@"

echo "Waiting up to ${WAIT_SECONDS}s for a Go60 bootloader drive to mount..."
echo "  Put the keyboard into bootloader mode: hold the magic key + tap the &bootloader key on the Magic layer."

OS="$(uname -s)"

# Linux only: if a GO60*BOOT partition is attached but not auto-mounted,
# mount it via udisks2 so the search loop below can find it.
try_automount() {
    command -v udisksctl >/dev/null 2>&1 || return 0
    for link in /dev/disk/by-label/GO60*BOOT; do
        [ -e "$link" ] || continue
        dev="$(readlink -f "$link")"
        mp="$(lsblk -no MOUNTPOINT "$dev" 2>/dev/null || true)"
        if [ -z "$mp" ]; then
            udisksctl mount -b "$dev" >/dev/null 2>&1 || true
        fi
    done
}

flash_to() {
    drive="$1"
    echo "Device found: $drive"
    # Stream bytes rather than `cp` — avoids macOS metadata-preserve
    # issues on the bootloader's FAT filesystem.
    if cat go60.uf2 > "$drive/go60.uf2" 2>/dev/null; then
        # Flush buffered writes; the device reboots once the UF2 lands,
        # so a failing sync here just means it already detached.
        sync -f "$drive" 2>/dev/null || sync 2>/dev/null || true
        echo "→ flashed to $drive"
        exit 0
    fi
    if [ "$OS" = "Darwin" ]; then
        cat <<EOF >&2
Permission denied writing to $drive.
On macOS, grant your terminal access to removable volumes:
  System Settings → Privacy & Security → Files and Folders
  (or "Removable Volumes") → enable for your terminal app.
Then re-run: make flash
EOF
    else
        echo "Failed writing to $drive (permissions? read-only mount?). Try: cat go60.uf2 > $drive/go60.uf2" >&2
    fi
    exit 1
}

deadline=$(( $(date +%s) + WAIT_SECONDS ))
while [ "$(date +%s)" -lt "$deadline" ]; do
    if [ "$OS" != "Darwin" ]; then
        try_automount
    fi
    for drive in /Volumes/GO60*BOOT \
                 "/run/media/${USER}"/GO60*BOOT \
                 "/media/${USER}"/GO60*BOOT \
                 /media/GO60*BOOT; do
        if [ -d "$drive" ]; then
            flash_to "$drive"
        fi
    done
    sleep 1
done

echo "No bootloader drive mounted within ${WAIT_SECONDS}s." >&2
exit 1
