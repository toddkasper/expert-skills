#!/usr/bin/env bash
# Repo validator for expert-skills. No exotic deps (bash + grep + awk + find).
# Checks every skill against the structural standard and reports per skill.
# Exit 0 only if every check passes.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

FAILS=0
SKILLS=0

fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAILS=$((FAILS+1)); }
pass() { :; }  # silent on pass; uncomment next line to see every check
# pass() { printf '  ok   %s\n' "$1"; }

# Frontmatter value extractor: first `key:` under the leading --- block.
fm() { awk -v k="$1" '/^---$/{c++; next} c==1 && $0 ~ "^[ \t]*"k":" {sub("^[ \t]*"k":[ \t]*",""); print; exit}' "$2"; }
# Body = everything after the second --- (frontmatter close).
body_after_fm() { awk '/^---$/{c++; if(c>=2){p=1; next}} p' "$1"; }

# Exam-logistics keywords that must NOT appear in a SKILL.md (case-insensitive).
# Deliberately NOT a bare "$NN USD" — react-native's App Store/Play fees are legit content.
LOGISTICS_RE='passing score|retake|pearson vue|webassessor|kryterion|proctor|number of scored|unscored pretest|registration fee'

echo "== expert-skills validate =="

while IFS= read -r skill; do
  dir="$(dirname "$skill")"
  folder="$(basename "$dir")"
  SKILLS=$((SKILLS+1))
  echo "[$folder]"

  # 1. name == folder
  name="$(fm name "$skill" | tr -d '\r')"
  [ "$name" = "$folder" ] || fail "frontmatter name '$name' != folder '$folder'"

  # 2. description present and <= 1024 chars
  desc="$(fm description "$skill")"
  if [ -z "$desc" ]; then fail "description missing"; else
    len=${#desc}
    [ "$len" -le 750 ] || fail "description $len chars > 750"
  fi

  # 3. last-reviewed present (YYYY-MM-DD)
  lr="$(fm last-reviewed "$skill" | tr -d ' \r')"
  echo "$lr" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || fail "last-reviewed missing/!=YYYY-MM-DD ('$lr')"

  # Required sections (search whole file; cheap and unambiguous)
  # 4a. Overview
  grep -qiE '^##? +Overview' "$skill" || fail "no Overview section"
  # 4b. Scope block
  grep -qi 'Load this skill when' "$skill" || fail "no Scope block (Load this skill when…)"
  # 4c. Quick Reference
  grep -qi 'Quick Reference' "$skill" || fail "no Quick Reference"
  # 4c-i. Uncertainty & Escalation (D7)
  grep -qiE '^##+ +Uncertainty' "$skill" || fail "no Uncertainty & Escalation section"
  # 4c-ii. Executable Workflows (D8)
  grep -qiE '^##+ +Executable Workflows' "$skill" || fail "no Executable Workflows section"
  # 4c-iii. Feedback protocol (C1)
  grep -qiE '^##+ +Feedback protocol' "$skill" || fail "no Feedback protocol section"
  # 4d. Decision Scenarios — in body OR a linked references/scenarios.md
  if grep -qi 'Decision Scenario' "$skill"; then :; \
  elif [ -f "$dir/references/scenarios.md" ] && grep -q 'scenarios.md' "$skill"; then :; \
  else fail "no Decision Scenarios (section or linked references/scenarios.md)"; fi
  # 4e. Disclaimer
  grep -qiE '## *Disclaimer|not affiliated|independent educational' "$skill" || fail "no disclaimer"

  # 5. no exam-logistics keywords in the body (Changelog provenance bullets are exempt —
  #    they legitimately name the logistics they corrected, which live in study-resources.md)
  hits="$(body_after_fm "$skill" | grep -vE '^- \*\*[0-9]{4}-[0-9]{2}-[0-9]{2}' | grep -inE "$LOGISTICS_RE" | head -3)"
  [ -z "$hits" ] || fail "exam-logistics keyword(s) in body: $(echo "$hits" | tr '\n' '|')"

  # 6. every references/*.md referenced from SKILL.md AND carries a disclaimer (R4)
  if [ -d "$dir/references" ]; then
    while IFS= read -r ref; do
      base="$(basename "$ref")"
      grep -q "$base" "$skill" || fail "references/$base not linked from SKILL.md"
      grep -qiE 'not affiliated|independent educational|Companion reference' "$ref" \
        || fail "references/$base has no disclaimer line"
    done < <(find "$dir/references" -maxdepth 1 -name '*.md')
  fi

  # 7. matching eval set with >=12 numbered items in situations + answer-key
  ev="evals/$folder"
  for kind in situations answer-key; do
    f="$ev/$kind.md"
    if [ ! -f "$f" ]; then fail "missing $f"; else
      n="$(grep -cE '^[0-9]+[.)]' "$f")"
      [ "$n" -ge 12 ] || fail "$f has $n numbered items (<12)"
    fi
  done
  # 7b. trigger tests (Lens 2) and application evals (Lens 4) present
  [ -f "$ev/triggers.md" ] || fail "missing $ev/triggers.md"
  [ -f "$ev/tasks.md" ] || fail "missing $ev/tasks.md"

  # 8. scorecard exists
  [ -f "evals/scorecards/$folder.md" ] || fail "missing evals/scorecards/$folder.md"

done < <(find . -name SKILL.md | sort)

# Reverse checks: no orphaned eval dirs or scorecards (catches a skill rename/removal).
skill_folder() { find . -path "*/skills/$1/SKILL.md" | head -1; }
for d in evals/*/; do
  name="$(basename "$d")"
  [ "$name" = "scorecards" ] && continue
  [ -n "$(skill_folder "$name")" ] || { echo "[orphan]"; fail "evals/$name/ has no matching skill"; }
done
for sc in evals/scorecards/*.md; do
  name="$(basename "$sc" .md)"
  [ "$name" = "_TEMPLATE" ] && continue
  [ -n "$(skill_folder "$name")" ] || { echo "[orphan]"; fail "evals/scorecards/$name.md has no matching skill"; }
done

echo "-----------------------------------------"
if [ "$FAILS" -eq 0 ]; then
  printf '\033[32mPASS\033[0m — %s skills, 0 failures\n' "$SKILLS"
  exit 0
else
  printf '\033[31m%s failure(s)\033[0m across %s skills\n' "$FAILS" "$SKILLS"
  exit 1
fi
