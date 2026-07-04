from __future__ import annotations

import hashlib
import json
import re
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


_TYPOSQUAT_DATABASE: set[str] = {
    "panther-stdlib", "panther-web", "panther-ai", "panther-db",
    "panther-cli", "panther-utils", "panther-http",
}

_TYPOSQUAT_SIMILARITY_THRESHOLD = 0.85


def _levenshtein_ratio(a: str, b: str) -> float:
    if not a or not b:
        return 0.0
    m, n = len(a), len(b)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            cost = 0 if a[i - 1] == b[j - 1] else 1
            dp[i][j] = min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost)
    max_len = max(m, n)
    return (max_len - dp[m][n]) / max_len if max_len > 0 else 0.0


@dataclass
class PackageIntegrityResult:
    valid: bool = True
    errors: list[str] = field(default_factory=list)
    checksum: str = ""
    file_count: int = 0


class IntegrityChecker:
    @staticmethod
    def compute_checksum(data: bytes) -> str:
        return hashlib.sha256(data).hexdigest()

    @staticmethod
    def compute_file_checksum(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    @staticmethod
    def verify_package_zip(zip_path: Path) -> PackageIntegrityResult:
        result = PackageIntegrityResult()
        if not zip_path.exists():
            result.valid = False
            result.errors.append("Package file not found")
            return result
        try:
            with zipfile.ZipFile(zip_path, "r") as zf:
                names = zf.namelist()
                result.file_count = len(names)
                if not names:
                    result.valid = False
                    result.errors.append("Package is empty")
                    return result
                checksum_data = b""
                for name in sorted(names):
                    info = zf.getinfo(name)
                    checksum_data += name.encode() + str(info.file_size).encode()
                result.checksum = hashlib.sha256(checksum_data).hexdigest()
        except zipfile.BadZipFile as e:
            result.valid = False
            result.errors.append(f"Invalid ZIP: {e}")
        return result


class TyposquatDetector:
    @staticmethod
    def check(name: str) -> list[str]:
        warnings: list[str] = []
        for known in _TYPOSQUAT_DATABASE:
            similarity = _levenshtein_ratio(name.lower(), known.lower())
            if similarity >= _TYPOSQUAT_SIMILARITY_THRESHOLD and name.lower() != known.lower():
                warnings.append(
                    f"Package '{name}' is similar to known package '{known}' "
                    f"(similarity: {similarity:.0%})"
                )
        return warnings


class LockFileValidator:
    @staticmethod
    def validate_lock_file(path: Path) -> list[str]:
        errors: list[str] = []
        if not path.exists():
            return errors
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            return [f"Invalid JSON in lock file: {e}"]
        deps = data.get("dependencies", {})
        if not isinstance(deps, dict):
            errors.append("Lock file 'dependencies' must be an object")
        for name, version in deps.items():
            if not name or not isinstance(name, str):
                errors.append(f"Invalid dependency name: {name!r}")
            if not version or not isinstance(version, str):
                errors.append(f"Invalid version for '{name}': {version!r}")
            version_pattern = re.compile(r"^(\d+\.\d+\.\d+|\*|latest|\^|~|>=?|<=?)?\d*\.?\d*\.?\d*$")
        return errors


@dataclass
class ManifestValidationResult:
    valid: bool = True
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


class ManifestSecurityValidator:
    @staticmethod
    def validate(manifest_path: Path) -> ManifestValidationResult:
        result = ManifestValidationResult()
        if not manifest_path.exists():
            result.valid = False
            result.errors.append("Manifest file not found")
            return result
        content = manifest_path.read_text(encoding="utf-8")
        if any(kw in content.lower() for kw in ("http://", "ftp://")):
            result.warnings.append("Manifest uses insecure protocol (HTTP/FTP)")
        if "eval" in content.lower() or "exec" in content.lower():
            result.warnings.append("Manifest contains potentially unsafe keywords")
        return result
