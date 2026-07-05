# PantherLang v1.1.6 — Phase Gates

Each phase must pass its gate before the next phase begins.

| Phase | Gate Criteria |
|-------|---------------|
| 0 | Exact root, branch, remote, HEAD, dirty state, version conflicts recorded |
| 1 | Every major repository tree classified (CANONICAL, GENERATED, DUPLICATE, etc.) |
| 2 | Every ambiguous implementation tree has documented canonical decision |
| 3 | Every public language capability classified (IMPLEMENTED_PROVEN, BROKEN, etc.) |
| 4 | All 52 stdlib functions verified against actual registration |
| 5 | Security claims have executable proof; no harmful exploitation included |
| 6 | AI provider classification (REAL/MOCK/CONTRACT_ONLY) documented for all providers |
| 7 | A real browser-accessible application runs from PantherLang execution path |
| 8 | Real persistent CRUD (SQLite) passes end-to-end |
| 9 | Every lesson passes executable validation; all verify.pan files pass |
| 10 | All 18 chapters implementation-aligned; no false claims, TODOs, or placeholders |
| 11 | Every claimed recipe passes `panther run`; 50+ if implementation supports |
| 12 | All labs structurally complete; executable labs validated |
| 13 | Capstones execute according to actual capability; assessment rubric present |
| 14 | Certification blueprint maps to actual curriculum |
| 15 | Machine-readable knowledge is consistent with implementation; no false claims |
| 16 | Flagship application runs end-to-end; acceptance matrix documented |
| 17 | Automated validation detects missing/broken content |
| 18 | README matches implementation truth; founder identity present |
| 19 | Public tree contains canonical project content only; gitignore professional |
| 20 | All active release metadata reports 1.1.6 consistently |
| 21 | Clean environment installation succeeds |
| 22 | Local VSIX 1.1.6 installs and functions |
| 23 | External-user simulation passes (no editable imports, no PYTHONPATH) |
| 24 | Fresh clone behaves as v1.1.6 (no local artifacts) |
| 25 | 0 unexplained failures across all tests |
| 26 | Release candidate reproducible with checksums |
| 27 | Human authorization required; exact commands documented |
| 28 | Website handoff document prepared |
| 29 | Panther Studio handoff document prepared |
| 30 | Panther Platform handoff document prepared |

## Gate Protocol

1. Run phase-specific validation
2. Run broad regression if phase modifies implementation
3. Update evidence matrix
4. Evaluate gate criteria
5. Mark PASS or FAIL
6. If FAIL: document root cause, repair, rerun
7. If PASS: update master state, continue to next phase
