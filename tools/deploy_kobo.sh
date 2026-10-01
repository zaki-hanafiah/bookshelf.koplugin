#!/bin/sh
# Copy the Bookshelf and Meguru forks onto a USB-mounted Kobo.
#
#   sh tools/deploy_kobo.sh                      # /Volumes/KOBOeReader
#   sh tools/deploy_kobo.sh /Volumes/OTHER       # another mount point
#   MEGURU_DIR=~/src/meguru.koplugin sh tools/deploy_kobo.sh
#
# Both plugins are replaced wholesale (rsync --delete, minus VCS and tests), so
# a file removed in the repo is removed on the device. Eject the Kobo from the
# OS afterwards, then restart KOReader.

set -eu
cd "$(dirname "$0")/.."
BOOKSHELF_DIR="$(pwd)"
MEGURU_DIR="${MEGURU_DIR:-$BOOKSHELF_DIR/../meguru.koplugin}"
MOUNT="${1:-/Volumes/KOBOeReader}"
DEST="$MOUNT/.adds/koreader/plugins"

[ -d "$DEST" ] || { echo "no KOReader plugins dir at $DEST (is the Kobo mounted?)" >&2; exit 1; }
[ -f "$MEGURU_DIR/main.lua" ] || { echo "no Meguru checkout at $MEGURU_DIR (set MEGURU_DIR)" >&2; exit 1; }

push() {
    echo "-> $2"
    rsync -rtv --delete --exclude='.git' --exclude='.github' --exclude='tests' \
        --exclude='.DS_Store' "$1/" "$DEST/$2/"
}
push "$BOOKSHELF_DIR" bookshelf.koplugin
push "$MEGURU_DIR"    meguru.koplugin
echo "done. Eject the Kobo, then restart KOReader."
