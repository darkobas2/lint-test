#!/bin/bash
set -e

RAW_BASE="https://raw.githubusercontent.com/darkobas2/lint-test/main"

REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)" 2>/dev/null || basename "$(pwd)")
REPO_NAME_LOWER=$(echo "$REPO_NAME" | tr '[:upper:]' '[:lower:]')

PROFILES=()

case "$REPO_NAME_LOWER" in
  *cloudformation*|*cfn*)    PROFILES+=(cloudformation) ;;
  *terraform*|*tf-*)         PROFILES+=(terraform) ;;
  *ansible*)                 PROFILES+=(ansible) ;;
  *kubernetes*|*k8s*|*helm*) PROFILES+=(kubernetes) ;;
esac

if [ -f ".pre-commit-profiles" ]; then
  while IFS= read -r p; do
    [[ "$p" =~ ^#.*$ || -z "$p" ]] && continue
    PROFILES+=("$p")
  done < .pre-commit-profiles
fi

PROFILES=($(echo "${PROFILES[@]}" | tr ' ' '\n' | sort -u))

curl -sSf "$RAW_BASE/pre-commit/base.yaml" > .pre-commit-config.yaml || exit 1

for profile in "${PROFILES[@]}"; do
  content=$(curl -sSf "$RAW_BASE/pre-commit/${profile}.yaml" 2>/dev/null) || continue
  echo "$content" | tail -n +2 >> .pre-commit-config.yaml
done

curl -sSfL "$RAW_BASE/.yamllint" -o .yamllint 2>/dev/null || true

echo "Synced: base ${PROFILES[*]}"
