#!/usr/bin/env bash
# transmission-prune-finished-30d.sh
#
# Removes finished Transmission torrents whose "Date added" is >= THRESHOLD_DAYS
# ago, and deletes their local data.
#
# Usage:
#   ./bin/transmission-prune-finished-30d.sh
#
# Environment variables (all optional):
#   TR_HOST         — Transmission RPC host (default: 127.0.0.1)
#   TR_PORT         — Transmission RPC port (default: 9091)
#   THRESHOLD_DAYS  — Age threshold in days  (default: 30)
#   DRY_RUN         — Set to 1 to only print, not execute deletions (default: 0)
#   TR_AUTH         — user:pass for --auth flag (default: unset / no auth)

set -euo pipefail

TR_HOST="${TR_HOST:-127.0.0.1}"
TR_PORT="${TR_PORT:-9091}"
THRESHOLD_DAYS="${THRESHOLD_DAYS:-30}"
DRY_RUN="${DRY_RUN:-0}"

TR_CMD=(transmission-remote "${TR_HOST}:${TR_PORT}")
if [[ -n "${TR_AUTH:-}" ]]; then
    TR_CMD+=(--auth "${TR_AUTH}")
fi

threshold_seconds=$(( THRESHOLD_DAYS * 86400 ))
now=$(date +%s)

echo "Querying Transmission at ${TR_HOST}:${TR_PORT} for finished torrents..."

# Fetch the list of torrents; keep only lines with an ID and name.
# transmission-remote -l output format:
#   ID   Done  Have  ETA  Up  Down  Ratio  Status  Name
torrent_ids=$(
    "${TR_CMD[@]}" --list \
    | awk 'NR>1 && /100%/ { print $1 }' \
    | tr -d '*'
)

if [[ -z "${torrent_ids}" ]]; then
    echo "No finished torrents found."
    exit 0
fi

pruned=0
skipped=0

while IFS= read -r id; do
    [[ -z "${id}" ]] && continue

    # Fetch torrent info; extract "Date added" line.
    torrent_info=$("${TR_CMD[@]}" --torrent "${id}" --info 2>/dev/null) || {
        echo "  [WARN] Could not fetch info for torrent ${id}, skipping."
        (( skipped++ )) || true
        continue
    }

    date_added_str=$(echo "${torrent_info}" | grep -i 'Date added:' | sed 's/.*Date added: *//' | xargs) || true

    if [[ -z "${date_added_str}" ]]; then
        echo "  [WARN] Could not parse 'Date added' for torrent ${id}, skipping."
        (( skipped++ )) || true
        continue
    fi

    torrent_name=$(echo "${torrent_info}" | grep -i '^ *Name:' | head -n1 | sed 's/.*Name: *//' | xargs) || true

    # Parse the date string into a Unix timestamp.
    added_ts=$(date -d "${date_added_str}" +%s 2>/dev/null) || {
        echo "  [WARN] Could not parse date '${date_added_str}' for torrent ${id} ('${torrent_name}'), skipping."
        (( skipped++ )) || true
        continue
    }

    age_seconds=$(( now - added_ts ))
    age_days=$(( age_seconds / 86400 ))

    if (( age_seconds >= threshold_seconds )); then
        echo "  [PRUNE] id=${id} age=${age_days}d name='${torrent_name}'"
        if [[ "${DRY_RUN}" == "1" ]]; then
            echo "    DRY_RUN: would run: ${TR_CMD[*]} --torrent ${id} --remove-and-delete"
        else
            "${TR_CMD[@]}" --torrent "${id}" --remove-and-delete
        fi
        (( pruned++ )) || true
    else
        echo "  [KEEP]  id=${id} age=${age_days}d name='${torrent_name}'"
    fi
done <<< "${torrent_ids}"

echo ""
echo "Done. Pruned: ${pruned}, skipped: ${skipped}."
