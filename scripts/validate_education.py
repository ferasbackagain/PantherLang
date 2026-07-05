#!/usr/bin/env python3
"""PantherLang Education Validation Tool"""

import subprocess
import sys
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

checks = []
errors = []

def check(name, ok, detail=""):
    checks.append((name, ok, detail))
    if not ok:
        errors.append(f"FAIL: {name} - {detail}")

def run_panther(args):
    result = subprocess.run(
        [sys.executable, "-m", "cli.panther_cli"] + args,
        capture_output=True, text=True, cwd=ROOT
    )
    return result.returncode, result.stdout, result.stderr

def check_solution_files():
    """Verify all .pan solution files pass `check`"""
    solution_dirs = [
        ROOT / "docs/labs/solutions",
        ROOT / "docs/capstones/solutions",
        ROOT / "docs/cookbook/recipes",
    ]
    all_pass = True
    count = 0
    for d in solution_dirs:
        if not d.exists():
            check(f"Directory exists: {d.name}", False, "not found")
            continue
        for f in sorted(d.glob("*.pan")):
            if f.name == "cookbook_all.pan":
                continue
            count += 1
            rc, out, err = run_panther(["check", str(f)])
            if rc != 0:
                all_pass = False
                check(f"Solution check: {f.name}", False, err[:200])
    check(f"All solution files pass check ({count} files)", all_pass)

def check_cookbook_all():
    """Run cookbook_all.pan and verify ALL PASS"""
    f = ROOT / "docs/cookbook/recipes/cookbook_all.pan"
    if not f.exists():
        check("cookbook_all.pan exists", False)
        return
    rc, out, err = run_panther(["run", str(f)])
    if rc != 0:
        check("cookbook_all.pan runs", False, err[:200])
        return
    if "ALL PASS" in out:
        check("cookbook_all.pan all pass", True)
    else:
        check("cookbook_all.pan all pass", False, "Missing 'ALL PASS' in output")

def check_academy_lessons():
    """Verify every lesson has main.pan and verify.pan"""
    academy = ROOT / "academy"
    all_ok = True
    for lesson_dir in sorted(academy.glob("lesson[0-9]*")):
        if not lesson_dir.is_dir():
            continue
        # Skip non-standard lesson directories
        if not lesson_dir.name.lstrip("lesson").isdigit():
            continue
        name = lesson_dir.name
        main_pan = lesson_dir / "main.pan"
        verify_pan = lesson_dir / "verify.pan"
        if not main_pan.exists():
            check(f"Academy {name}: main.pan", False)
            all_ok = False
        elif not verify_pan.exists():
            check(f"Academy {name}: verify.pan", False)
            all_ok = False
        else:
            rc, out, err = run_panther(["run", str(verify_pan)])
            if rc != 0:
                check(f"Academy {name} verify", False, err[:200])
                all_ok = False
    check("Academy lessons verified", all_ok)

def check_book_chapters():
    """Verify all book chapters exist"""
    book_dir = ROOT / "docs/book/chapters"
    expected = 18
    existing = sorted(book_dir.glob("*.md"))
    if len(existing) >= expected:
        check(f"Book chapters ({len(existing)} >= {expected})", True)
    else:
        check(f"Book chapters ({len(existing)} >= {expected})", False,
              f"Expected at least {expected}, found {len(existing)}")

def check_counts():
    """Verify minimum counts for education materials"""
    cookbook_recipes = len(list((ROOT / "docs/cookbook/recipes").glob("*.pan")))
    check(f"Cookbook recipes ({cookbook_recipes} >= 19)", cookbook_recipes >= 19)
    
    labs = len(list((ROOT / "docs/labs").glob("*.md")))
    check(f"Lab files ({labs} >= 21)", labs >= 21)
    
    capstones = len(list((ROOT / "docs/capstones").glob("*.md")))
    check(f"Capstone files ({capstones} >= 7)", capstones >= 7)

def main():
    print("PantherLang Education Validation")
    print("=" * 40)
    
    check_solution_files()
    check_cookbook_all()
    check_academy_lessons()
    check_book_chapters()
    check_counts()
    
    print(f"\n{'=' * 40}")
    print(f"Checks: {len(checks)} total, {len(checks) - len(errors)} passed, {len(errors)} failed")
    
    for name, ok, detail in checks:
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] {name}")
    
    if errors:
        print(f"\n{len(errors)} failure(s) found!")
        sys.exit(1)
    else:
        print("\nAll education content validated!")

if __name__ == "__main__":
    main()
