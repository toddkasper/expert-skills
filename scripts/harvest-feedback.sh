#!/usr/bin/env bash
# Harvest project-local field feedback into the repo inbox.
#
# Skills travel into consuming projects that can't write to this repo. The Feedback Protocol
# footer in each SKILL.md tells the using agent to append entries to
#   <project-root>/.skill-feedback/<skill-name>.md
# in the pipe-delimited format:
#   date | skill last-reviewed | claim or gap | what was observed instead | evidence | suggested fix
#
# This script collects those entries from one or more project paths into feedback/INBOX.md,
# de-duplicating against what is already there. Source is tagged "field".
#
# Usage:  scripts/harvest-feedback.sh <project-path> [<project-path> ...]
#         scripts/harvest-feedback.sh --dry-run <project-path> ...
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="$ROOT/feedback/INBOX.md"

DRY=0
[ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }

if [ "$#" -eq 0 ]; then
  echo "usage: $0 [--dry-run] <project-path> [<project-path> ...]" >&2
  exit 2
fi
[ -f "$INBOX" ] || { echo "inbox not found: $INBOX" >&2; exit 2; }

# Short stable id for an entry, used to dedupe (already-present ids are skipped).
hashid() { printf '%s' "$1" | cksum | awk '{print $1}'; }

added=0
scanned=0

for proj in "$@"; do
  fbdir="$proj/.skill-feedback"
  [ -d "$fbdir" ] || { echo "  (no .skill-feedback in $proj)"; continue; }
  while IFS= read -r file; do
    skill="$(basename "$file" .md)"
    while IFS= read -r line; do
      # skip blanks, markdown headings, and lines that aren't pipe-delimited entries
      case "$line" in
        ''|'#'*|'>'*) continue;;
      esac
      printf '%s' "$line" | grep -q '|' || continue
      # skip a header-ish line like "date | skill last-reviewed | claim ..."
      printf '%s' "$line" | grep -qiE '^[[:space:]]*date[[:space:]]*\|' && continue
      scanned=$((scanned+1))

      # parse fields (1=date 2=last-reviewed 3=claim 4=observed 5=evidence 6=fix)
      f_date="$(printf '%s' "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$1); print $1}')"
      f_claim="$(printf '%s' "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}')"
      f_obs="$(printf '%s' "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$4); print $4}')"
      f_evid="$(printf '%s' "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$5); print $5}')"
      f_fix="$(printf '%s' "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$6); print $6}')"

      id="$(hashid "$skill|$f_date|$f_claim")"
      if grep -q "fb:$id" "$INBOX"; then continue; fi   # already harvested

      # NOTE: fields are split on '|', so a literal pipe inside a cell shifts later fields.
      # In a .skill-feedback entry, escape pipes inside evidence/fix text as '\|'.
      summary="$f_claim"
      [ -n "$f_obs" ] && summary="$summary — observed: $f_obs"
      [ -n "$f_fix" ] && summary="$summary — suggested fix: $f_fix"
      row="| $f_date | $skill | field | — | $summary | ${f_evid:-—} | new <!-- fb:$id --> |"

      if [ "$DRY" -eq 1 ]; then
        echo "  + $row"
      else
        # drop the placeholder row if present, then append before EOF
        if grep -q '_none yet_' "$INBOX"; then
          tmp="$(mktemp)"; grep -v '_none yet_' "$INBOX" > "$tmp" && mv "$tmp" "$INBOX"
        fi
        printf '%s\n' "$row" >> "$INBOX"
      fi
      added=$((added+1))
    done < "$file"
  done < <(find "$fbdir" -maxdepth 1 -name '*.md')
done

if [ "$DRY" -eq 1 ]; then
  echo "dry-run: $added new entr(y/ies) from $scanned scanned line(s) would be added to feedback/INBOX.md"
else
  echo "harvested $added new entr(y/ies) from $scanned scanned line(s) into feedback/INBOX.md"
fi
