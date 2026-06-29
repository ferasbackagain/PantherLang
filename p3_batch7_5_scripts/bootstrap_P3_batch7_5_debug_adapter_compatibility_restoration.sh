#!/usr/bin/env bash
set -u -o pipefail

BATCH="P3_batch7_5_debug_adapter_compatibility_restoration"
ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
WORKDIR=".panther/p3_batch7_5_compat_restoration/${STAMP}"
REPORT_DIR="reports/p3_batch7_5_compat_restoration_${STAMP}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log(){ echo "[$BATCH] $*"; }
warn(){ echo "[$BATCH:WARN] $*"; }
fail(){ echo "[$BATCH:FAIL] $*"; exit 1; }

export P75_ROOT="$ROOT"
export P75_STAMP="$STAMP"
export P75_WORKDIR="$ROOT/$WORKDIR"
export P75_REPORT_DIR="$ROOT/$REPORT_DIR"
export P75_SCRIPT_DIR="$SCRIPT_DIR"

log "Starting PantherLang P-3 Batch 7.5 Debug Adapter Compatibility Restoration"
log "Project root: $ROOT"

mkdir -p "$P75_WORKDIR" "$P75_REPORT_DIR" "$P75_WORKDIR/logs" "$P75_WORKDIR/snapshots"

required=(
  "p75_01_environment_and_snapshot.sh"
  "p75_02_restore_reference_modules.sh"
  "p75_03_apply_compatibility_contracts.sh"
  "p75_04_targeted_h4_validation.sh"
  "p75_05_full_h4_regression.sh"
  "p75_06_engineering_reports.sh"
)

for s in "${required[@]}"; do
  [[ -f "$SCRIPT_DIR/$s" ]] || fail "Missing required Batch 7.5 component: $SCRIPT_DIR/$s"
  chmod +x "$SCRIPT_DIR/$s" || true
done

log "Step 1/6: environment, rollback, and production snapshot"
bash "$SCRIPT_DIR/p75_01_environment_and_snapshot.sh" || fail "Step 1 failed"

log "Step 2/6: restore missing compatibility modules from historical references"
bash "$SCRIPT_DIR/p75_02_restore_reference_modules.sh" || fail "Step 2 failed"

log "Step 3/6: apply compatibility contracts and API shims"
bash "$SCRIPT_DIR/p75_03_apply_compatibility_contracts.sh" || fail "Step 3 failed"

log "Step 4/6: run targeted H4 compatibility validation"
bash "$SCRIPT_DIR/p75_04_targeted_h4_validation.sh" || warn "Targeted validation recorded failures; continuing to full regression for evidence"

log "Step 5/6: run full H4 regression"
bash "$SCRIPT_DIR/p75_05_full_h4_regression.sh" || warn "Full H4 regression recorded failures"

log "Step 6/6: generate engineering reports"
bash "$SCRIPT_DIR/p75_06_engineering_reports.sh" || fail "Report generation failed"

if [[ -f "$P75_WORKDIR/status/final_status" ]]; then
  final_status="$(cat "$P75_WORKDIR/status/final_status")"
else
  final_status="UNKNOWN"
fi

log "Batch 7.5 reports generated"
echo ""
echo "Reports directory:"
echo "  $P75_REPORT_DIR"
echo ""
echo "Key reports:"
echo "  $P75_REPORT_DIR/engineering_report.md"
echo "  $P75_REPORT_DIR/restoration_manifest.json"
echo "  $P75_REPORT_DIR/targeted_validation.json"
echo "  $P75_REPORT_DIR/full_h4_compatibility_matrix.md"
echo "  $P75_REPORT_DIR/failure_classification.json"
echo ""

if [[ "$final_status" == "COMPLETE" ]]; then
  log "P-3 Batch 7.5 COMPLETE — compatibility restoration validated. Next: P-3 Batch 8 Final Release Candidate."
  exit 0
else
  warn "P-3 Batch 7.5 executed, but blocking findings remain. Review engineering_report.md and failure_classification.json."
  exit 2
fi
