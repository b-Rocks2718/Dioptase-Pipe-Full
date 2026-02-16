#!/usr/bin/env bash
set -euo pipefail

#------------------------------------------------------------------------------
# sync_pipeline_to_windows.sh
#
# Purpose:
# - Mirror Dioptase-Pipe-Full from WSL to a Windows filesystem path for Vivado.
# - Keep destination in sync (uses --delete).
#
# Usage:
#   ./scripts/sync_pipeline_to_windows.sh --dest /mnt/c/Users/<you>/Dioptase-Pipe-Full
#
# Optional:
#   --dry-run        Show planned changes without writing.
#   --include-git    Include .git directory in mirror (excluded by default).
#   --dest <path>    Destination mirror path (required unless env var set).
#
# Environment fallback:
#   DIOPTASE_PIPELINE_WIN_MIRROR
#------------------------------------------------------------------------------

usage() {
    cat <<'EOF'
Usage:
  sync_pipeline_to_windows.sh --dest <windows_mirror_path> [--dry-run] [--include-git]

Options:
  --dest <path>    Destination path under /mnt/<drive>/...
  --dry-run        Print actions without modifying destination
  --include-git    Include .git in the mirrored output
  -h, --help       Show this help
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src_dir="$(cd "${script_dir}/.." && pwd)"

dest_dir="${DIOPTASE_PIPELINE_WIN_MIRROR:-}"
dry_run=0
include_git=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dest)
            [[ $# -ge 2 ]] || { echo "error: --dest requires a path" >&2; exit 1; }
            dest_dir="$2"
            shift 2
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        --include-git)
            include_git=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown argument '$1'" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "${dest_dir}" ]]; then
    echo "error: destination not provided (--dest or DIOPTASE_PIPELINE_WIN_MIRROR)" >&2
    usage
    exit 1
fi

# Guardrail: this script is intended for Windows-mounted destinations from WSL.
if [[ ! "${dest_dir}" =~ ^/mnt/[a-zA-Z]/ ]]; then
    echo "error: destination must be under /mnt/<drive>/..., got '${dest_dir}'" >&2
    exit 1
fi

mkdir -p "${dest_dir}"

rsync_args=(
    -a
    --delete
    --human-readable
    --info=stats2,progress2
)

if [[ "${dry_run}" -eq 1 ]]; then
    rsync_args+=(--dry-run)
fi

excludes=(
    "obj_dir/"
    "build/vivado/"
    ".Xil/"
    "*.jou"
    "*.log"
    "*.str"
    "*.vcd"
    "*.fst"
    "sim.vvp"
    "sim_debug.vvp"
    "tests/out/"
    "tests/hex/"
    "emu_tests/"
)

if [[ "${include_git}" -eq 0 ]]; then
    excludes+=(".git/")
fi

for pattern in "${excludes[@]}"; do
    rsync_args+=(--exclude "${pattern}")
done

echo "Sync source: ${src_dir}"
echo "Sync dest:   ${dest_dir}"
if [[ "${dry_run}" -eq 1 ]]; then
    echo "Mode:        dry-run"
fi

rsync "${rsync_args[@]}" "${src_dir}/" "${dest_dir}/"

echo "Sync complete."
