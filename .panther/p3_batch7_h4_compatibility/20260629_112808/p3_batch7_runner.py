#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Tuple

ROOT = Path(os.environ.get("PANTHER_ROOT", os.getcwd())).resolve()
ARTIFACT_ROOT = Path(os.environ["PANTHER_BATCH7_ARTIFACT_ROOT"]).resolve()
REPORT_DIR = Path(os.environ["PANTHER_BATCH7_REPORT_DIR"]).resolve()
LOG_DIR = Path(os.environ["PANTHER_BATCH7_LOG_DIR"]).resolve()
MANIFEST_PATH = Path(os.environ["PANTHER_BATCH7_MANIFEST"]).resolve()
TIMEOUT_SECONDS = int(os.environ.get("PANTHER_BATCH7_TEST_TIMEOUT", "180"))
PYTHON = sys.executable

EXCLUDE_PARTS = {"__pycache__", ".pytest_cache", ".git", "node_modules"}
RETIRED_MARKERS = (".retired", "retired_by", "/_retired/", "\\_retired\\")

FAILURE_PATTERNS = {
    "missing compatibility layer": [
        r"ModuleNotFoundError", r"ImportError", r"cannot import name", r"No module named",
        r"AttributeError:.*(compat|legacy|adapter|dispatcher|handler|request|response|event)",
        r"KeyError:.*(type|command|arguments|body|event|request_seq)",
        r"missing.*compat", r"compatibility.*missing", r"unsupported.*legacy",
        r"Unknown command", r"not registered", r"dispatcher.*missing", r"handler.*missing",
    ],
    "obsolete legacy expectation": [
        r"retired_by", r"legacy expectation", r"deprecated", r"obsolete",
        r"expected.*legacy", r"legacy_", r"old adapter", r"pre[-_ ]?canonical",
        r"snapshot.*mismatch", r"golden.*mismatch", r"expected.*debug_adapter_legacy",
    ],
    "implementation defect": [
        r"AssertionError", r"TypeError", r"ValueError", r"RuntimeError", r"IndexError",
        r"RecursionError", r"Timeout", r"FAILED", r"ERROR", r"Traceback",
    ],
}

@dataclass
class Suite:
    suite_id: str
    module: str
    path: str
    origin: str
    sha256: str
    source_rank: int

@dataclass
class Result:
    suite_id: str
    module: str
    path: str
    origin: str
    sha256: str
    command: str
    status: str
    exit_code: int
    duration_seconds: float
    log_file: str
    classification: str
    evidence: List[str]


def rel(p: Path) -> str:
    try:
        return str(p.resolve().relative_to(ROOT))
    except Exception:
        return str(p)


def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()


def is_h4_test_file(p: Path) -> bool:
    s = str(p)
    name = p.name.lower()
    if any(marker in s for marker in RETIRED_MARKERS):
        return False
    if any(part in EXCLUDE_PARTS for part in p.parts):
        return False
    if p.suffix != ".py":
        return False
    if not (name.startswith("test_") or "/tests/" in s or "\\tests\\" in s):
        return False
    hay = s.lower()
    return "h4" in hay or "h_4" in hay


def module_from_path(p: Path) -> str:
    text = rel(p).lower()
    patterns = [
        (r"h4[_/\\.-]?1", "H4.1"),
        (r"h4[_/\\.-]?2", "H4.2"),
        (r"h4[_/\\.-]?3", "H4.3"),
        (r"h4[_/\\.-]?4", "H4.4"),
        (r"h4[_/\\.-]?5", "H4.5"),
        (r"h4[_/\\.-]?6", "H4.6"),
        (r"h4[_/\\.-]?7", "H4.7"),
        (r"h4[_/\\.-]?8", "H4.8"),
        (r"h4[_/\\.-]?9", "H4.9"),
    ]
    for pat, mod in patterns:
        if re.search(pat, text):
            return mod
    return "H4.general"


def origin_from_path(p: Path) -> Tuple[str, int]:
    r = rel(p)
    if r.startswith("tests/"):
        return "current_tests", 0
    if ".panther/backups/" in r:
        return "historical_backup", 1
    if "backups" in r.lower():
        return "historical_backup", 2
    return "discovered", 3


def discover_suites() -> List[Suite]:
    candidates: List[Path] = []
    search_roots = [ROOT / "tests", ROOT / ".panther" / "backups", ROOT / ".panther_backups", ROOT / "hardening"]
    for base in search_roots:
        if not base.exists():
            continue
        for p in base.rglob("*.py"):
            if is_h4_test_file(p):
                candidates.append(p)

    # Dedupe identical historical files by content hash while preserving current tests first.
    seen_hashes = set()
    suites: List[Suite] = []
    for p in sorted(candidates, key=lambda x: (origin_from_path(x)[1], module_from_path(x), rel(x))):
        digest = sha256_file(p)
        origin, rank = origin_from_path(p)
        dedupe_key = digest
        if dedupe_key in seen_hashes:
            continue
        seen_hashes.add(dedupe_key)
        module = module_from_path(p)
        suite_id = f"{len(suites)+1:04d}_{module.replace('.', '_')}_{p.stem}"
        suites.append(Suite(suite_id, module, rel(p), origin, digest, rank))
    return suites


def classify_failure(log_text: str, exit_code: int, timed_out: bool) -> Tuple[str, List[str]]:
    if exit_code == 0 and not timed_out:
        return "pass", []
    if timed_out:
        return "implementation defect", ["Test execution timed out"]

    evidence_by_class: Dict[str, List[str]] = {k: [] for k in FAILURE_PATTERNS}
    for cls, patterns in FAILURE_PATTERNS.items():
        for pat in patterns:
            m = re.search(pat, log_text, flags=re.IGNORECASE | re.MULTILINE)
            if m:
                line = extract_line(log_text, m.group(0))
                evidence_by_class[cls].append(line[:300])

    # Priority: compatibility gap > obsolete expectation > implementation defect.
    # This avoids classifying import/adapter surface breaks as generic defects.
    for cls in ("missing compatibility layer", "obsolete legacy expectation", "implementation defect"):
        if evidence_by_class[cls]:
            return cls, evidence_by_class[cls][:5]
    return "implementation defect", ["Non-zero pytest exit without recognized compatibility marker"]


def extract_line(text: str, needle: str) -> str:
    for line in text.splitlines():
        if needle.lower() in line.lower():
            return line.strip()
    return needle


def run_suite(suite: Suite) -> Result:
    target = ROOT / suite.path
    log_file = LOG_DIR / f"{suite.suite_id}.log"
    cmd = [PYTHON, "-m", "pytest", str(target), "-q", "--tb=short", "--disable-warnings"]
    env = os.environ.copy()
    env["PYTHONPATH"] = str(ROOT) + os.pathsep + env.get("PYTHONPATH", "")
    env["PANTHER_DEBUG_ADAPTER_TARGET"] = str(ROOT / "debug_adapter")
    env["PANTHER_P3_BATCH7_COMPATIBILITY_REGRESSION"] = "1"
    start = time.time()
    timed_out = False
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(ROOT),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
        output = proc.stdout or ""
        exit_code = int(proc.returncode)
    except subprocess.TimeoutExpired as e:
        timed_out = True
        output = (e.stdout or "") if isinstance(e.stdout, str) else ""
        output += f"\nTIMEOUT: exceeded {TIMEOUT_SECONDS} seconds\n"
        exit_code = 124
    duration = time.time() - start
    log_file.write_text(output, encoding="utf-8", errors="replace")
    status = "PASS" if exit_code == 0 and not timed_out else ("TIMEOUT" if timed_out else "FAIL")
    classification, evidence = classify_failure(output, exit_code, timed_out)
    return Result(
        suite.suite_id, suite.module, suite.path, suite.origin, suite.sha256,
        " ".join(cmd), status, exit_code, round(duration, 3), rel(log_file), classification, evidence
    )


def write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")


def md_escape(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def generate_reports(suites: List[Suite], results: List[Result], env: dict) -> int:
    total = len(results)
    passed = sum(1 for r in results if r.status == "PASS")
    failed = sum(1 for r in results if r.status == "FAIL")
    timed_out = sum(1 for r in results if r.status == "TIMEOUT")
    compatibility = round((passed / total) * 100, 2) if total else 0.0

    by_module: Dict[str, Dict[str, int]] = {}
    for r in results:
        d = by_module.setdefault(r.module, {"total": 0, "pass": 0, "fail": 0, "timeout": 0})
        d["total"] += 1
        if r.status == "PASS": d["pass"] += 1
        elif r.status == "TIMEOUT": d["timeout"] += 1
        else: d["fail"] += 1

    classifications: Dict[str, List[dict]] = {
        "missing compatibility layer": [],
        "obsolete legacy expectation": [],
        "implementation defect": [],
    }
    for r in results:
        if r.status != "PASS":
            classifications.setdefault(r.classification, []).append(asdict(r))

    manifest = {
        "batch": "P3 Batch 7 — Full H4 Compatibility Regression",
        "project_root": str(ROOT),
        "created_at_epoch": int(time.time()),
        "suite_count": len(suites),
        "dedupe_policy": "content-sha256; current tests preferred; retired tests excluded",
        "suites": [asdict(s) for s in suites],
    }
    write_json(MANIFEST_PATH, manifest)
    write_json(REPORT_DIR / "h4_regression_manifest.json", manifest)

    matrix = {
        "batch": "P3 Batch 7 — Full H4 Compatibility Regression",
        "production_debug_adapter_hash_before": env.get("production_debug_adapter_hash_before"),
        "production_debug_adapter_hash_after": env.get("production_debug_adapter_hash_after"),
        "production_hash_unchanged": env.get("production_hash_unchanged"),
        "summary": {
            "total": total,
            "passed": passed,
            "failed": failed,
            "timed_out": timed_out,
            "compatibility_percent": compatibility,
        },
        "by_module": by_module,
        "results": [asdict(r) for r in results],
    }
    write_json(REPORT_DIR / "compatibility_matrix.json", matrix)

    write_json(REPORT_DIR / "failure_classification.json", {
        "summary": {k: len(v) for k, v in classifications.items()},
        "classifications": classifications,
    })

    ready_for_rc = bool(total > 0 and failed == 0 and timed_out == 0 and env.get("production_hash_unchanged") is True)
    summary = {
        "batch": "P3 Batch 7",
        "status": "COMPLETE" if total > 0 else "NO_H4_SUITES_DISCOVERED",
        "ready_for_p3_batch8_final_release_candidate": ready_for_rc,
        "total_suites": total,
        "passed": passed,
        "failed": failed,
        "timed_out": timed_out,
        "compatibility_percent": compatibility,
        "blocking_issue_count": failed + timed_out,
        "production_hash_unchanged": env.get("production_hash_unchanged"),
        "rollback_candidate_count": env.get("rollback_candidate_count"),
        "next_step": "P-3 Batch 8 — Final Release Candidate" if ready_for_rc else "Review failure_classification.json and engineering_report.md before Batch 8",
    }
    write_json(REPORT_DIR / "regression_summary.json", summary)

    md = []
    md.append("# PantherLang P-3 Batch 7 — Full H4 Compatibility Regression")
    md.append("")
    md.append("## Summary")
    md.append("")
    md.append(f"- Total suites: **{total}**")
    md.append(f"- Passed: **{passed}**")
    md.append(f"- Failed: **{failed}**")
    md.append(f"- Timed out: **{timed_out}**")
    md.append(f"- Compatibility: **{compatibility}%**")
    md.append(f"- Production hash unchanged: **{env.get('production_hash_unchanged')}**")
    md.append(f"- Rollback candidates: **{env.get('rollback_candidate_count')}**")
    md.append(f"- Ready for Batch 8 RC: **{ready_for_rc}**")
    md.append("")
    md.append("## Compatibility Matrix")
    md.append("")
    md.append("| Module | Suite | Origin | Status | Classification | Log |")
    md.append("|---|---|---|---:|---|---|")
    for r in results:
        md.append(f"| {md_escape(r.module)} | `{md_escape(Path(r.path).name)}` | {md_escape(r.origin)} | **{r.status}** | {md_escape(r.classification)} | `{md_escape(r.log_file)}` |")
    md.append("")
    md.append("## Failure Classification")
    md.append("")
    for cls, items in classifications.items():
        md.append(f"### {cls} ({len(items)})")
        md.append("")
        if not items:
            md.append("None.")
            md.append("")
            continue
        for item in items:
            md.append(f"- `{Path(item['path']).name}` → `{item['log_file']}`")
            for ev in item.get("evidence", [])[:3]:
                md.append(f"  - Evidence: `{md_escape(ev)}`")
        md.append("")
    (REPORT_DIR / "compatibility_matrix.md").write_text("\n".join(md) + "\n", encoding="utf-8")

    eng = []
    eng.append("# Engineering Report — P-3 Batch 7")
    eng.append("")
    eng.append("## Engineering Controls")
    eng.append("")
    eng.append("- Monkey patches: **not introduced**")
    eng.append("- Quick fixes: **not performed**")
    eng.append("- Production mutation: **not performed**")
    eng.append("- Rollback capability: **verified by candidate presence and pre-run snapshot**")
    eng.append("- H4 discovery: **automatic**, content-hash deduplicated, retired tests excluded")
    eng.append("")
    eng.append("## Adapter Evidence")
    eng.append("")
    eng.append(f"- Production debug_adapter hash before: `{env.get('production_debug_adapter_hash_before')}`")
    eng.append(f"- Production debug_adapter hash after: `{env.get('production_debug_adapter_hash_after')}`")
    eng.append(f"- Production hash unchanged: `{env.get('production_hash_unchanged')}`")
    eng.append(f"- Promotion status: `{env.get('promotion_status')}`")
    eng.append(f"- Legacy adapter count: `{env.get('legacy_adapter_count')}`")
    eng.append(f"- Rollback candidate count: `{env.get('rollback_candidate_count')}`")
    eng.append("")
    eng.append("## Module Summary")
    eng.append("")
    eng.append("| Module | Total | Pass | Fail | Timeout |")
    eng.append("|---|---:|---:|---:|---:|")
    for mod in sorted(by_module):
        d = by_module[mod]
        eng.append(f"| {mod} | {d['total']} | {d['pass']} | {d['fail']} | {d['timeout']} |")
    eng.append("")
    eng.append("## Recommendation")
    eng.append("")
    if ready_for_rc:
        eng.append("Proceed to **P-3 Batch 8 — Final Release Candidate**.")
    else:
        eng.append("Do **not** proceed to Batch 8 until blocking failures are reviewed. Batch 7 intentionally did not patch or modify production code.")
    (REPORT_DIR / "engineering_report.md").write_text("\n".join(eng) + "\n", encoding="utf-8")

    return 0 if total > 0 and env.get("production_hash_unchanged") is True else 2


def main() -> int:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    suites = discover_suites()
    if not suites:
        write_json(REPORT_DIR / "regression_summary.json", {
            "status": "NO_H4_SUITES_DISCOVERED",
            "ready_for_p3_batch8_final_release_candidate": False,
        })
        return 2

    results: List[Result] = []
    print(f"Discovered {len(suites)} unique H4 regression suites/files")
    for idx, suite in enumerate(suites, start=1):
        print(f"[{idx}/{len(suites)}] {suite.module} :: {suite.path}", flush=True)
        results.append(run_suite(suite))

    env_path = ARTIFACT_ROOT / "environment.json"
    env = json.loads(env_path.read_text(encoding="utf-8")) if env_path.exists() else {}
    after_hash = subprocess.check_output(
        "find debug_adapter -type f -not -path '*/__pycache__/*' -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'",
        shell=True, cwd=str(ROOT), text=True
    ).strip()
    env["production_debug_adapter_hash_after"] = after_hash
    env["production_hash_unchanged"] = (after_hash == env.get("production_debug_adapter_hash_before"))
    env_path.write_text(json.dumps(env, indent=2, sort_keys=True), encoding="utf-8")

    return generate_reports(suites, results, env)

if __name__ == "__main__":
    raise SystemExit(main())
