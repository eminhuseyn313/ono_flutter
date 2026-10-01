#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# ONO Test Runner — Pretty output with per-feature results
# Usage:  bash scripts/test_runner.sh [feature_name]
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

PASS=0
FAIL=0
SKIP=0
ERRORS=()
START_TIME=$(date +%s)

# ─── Header ──────────────────────────────────────────────────
echo ""
echo -e "${PURPLE}${BOLD}  ╔══════════════════════════════════════════════╗${RESET}"
echo -e "${PURPLE}${BOLD}  ║            🧪  ONO Test Suite  🧪            ║${RESET}"
echo -e "${PURPLE}${BOLD}  ╚══════════════════════════════════════════════╝${RESET}"
echo ""

# ─── Find test files ─────────────────────────────────────────
if [ -n "${1:-}" ]; then
  FILES=$(find test -name "*${1}*_test.dart" 2>/dev/null | sort)
  if [ -z "$FILES" ]; then
    echo -e "  ${RED}No test files matching '${1}'${RESET}"
    echo ""
    echo "  Available tests:"
    find test -name "*_test.dart" -exec basename {} \; | sed 's/_test.dart//' | sort | sed 's/^/    /'
    exit 1
  fi
else
  FILES=$(find test -name "*_test.dart" | sort)
fi

TOTAL=$(echo "$FILES" | wc -l | tr -d ' ')
CURRENT=0

echo -e "  ${DIM}Found ${TOTAL} test file(s)${RESET}"
echo ""

# ─── Run each test file ─────────────────────────────────────
while IFS= read -r file; do
  CURRENT=$((CURRENT + 1))
  # Extract feature name from filename
  FEATURE=$(basename "$file" | sed 's/_test.dart//' | sed 's/_/ /g')

  printf "  [%d/%d] %-40s " "$CURRENT" "$TOTAL" "$FEATURE"

  # Run the test and capture output
  OUTPUT=$(flutter test "$file" 2>&1) && RESULT=0 || RESULT=$?

  if [ $RESULT -eq 0 ]; then
    # Count passed tests from output
    COUNT=$(echo "$OUTPUT" | grep -oP '\+\d+' | tail -1 | tr -d '+' || echo "?")
    echo -e "${GREEN}✓ PASS${RESET} ${DIM}(${COUNT} tests)${RESET}"
    PASS=$((PASS + 1))
  else
    # Check if it's a skip (no tests found) or actual failure
    if echo "$OUTPUT" | grep -q "No tests ran"; then
      echo -e "${YELLOW}⊘ SKIP${RESET} ${DIM}(no tests)${RESET}"
      SKIP=$((SKIP + 1))
    else
      echo -e "${RED}✗ FAIL${RESET}"
      FAIL=$((FAIL + 1))
      ERRORS+=("$file")
      # Show failure details indented
      echo "$OUTPUT" | grep -E "(FAILED|Expected|Actual|Error)" | head -5 | sed 's/^/      /'
    fi
  fi
done <<< "$FILES"

# ─── Summary ─────────────────────────────────────────────────
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "  ────────────────────────────────────────────"
echo -e "  ${BOLD}Results:${RESET}  ${GREEN}${PASS} passed${RESET}  ${RED}${FAIL} failed${RESET}  ${YELLOW}${SKIP} skipped${RESET}  ${DIM}(${DURATION}s)${RESET}"

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo -e "  ${RED}${BOLD}Failed tests:${RESET}"
  for err in "${ERRORS[@]}"; do
    echo -e "    ${RED}→ ${err}${RESET}"
  done
fi

echo ""

if [ $FAIL -gt 0 ]; then
  echo -e "  ${RED}${BOLD}✗ Some tests failed${RESET}"
  exit 1
else
  echo -e "  ${GREEN}${BOLD}✓ All tests passed!${RESET}"
fi
echo ""
