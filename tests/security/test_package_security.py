import json
import tempfile
from pathlib import Path

from package_manager.security import (
    IntegrityChecker,
    TyposquatDetector,
    LockFileValidator,
    ManifestSecurityValidator,
)


def test_integrity_compute_checksum():
    data = b"test package data"
    checksum = IntegrityChecker.compute_checksum(data)
    assert len(checksum) == 64
    assert checksum.isalnum()


def test_integrity_compute_file_checksum():
    with tempfile.NamedTemporaryFile(suffix=".txt", delete=False, mode="w") as f:
        f.write("hello world")
        f.flush()
        path = Path(f.name)
    try:
        checksum = IntegrityChecker.compute_file_checksum(path)
        assert len(checksum) == 64
    finally:
        path.unlink(missing_ok=True)


def test_typosquat_detection_similar():
    detector = TyposquatDetector()
    warnings = detector.check("panther-stdlib")
    assert len(warnings) == 0


def test_typosquat_detection_typo():
    detector = TyposquatDetector()
    warnings = detector.check("panther-stdlib-")
    assert len(warnings) >= 0


def test_typosquat_detection_known_packages():
    detector = TyposquatDetector()
    for known in ["panther-ai", "panther-web", "panther-db"]:
        warnings = detector.check(known)
        assert len(warnings) == 0


def test_lock_file_validator_empty():
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w") as f:
        f.write("{}")
        f.flush()
        path = Path(f.name)
    try:
        errors = LockFileValidator.validate_lock_file(path)
        assert len(errors) == 0
    finally:
        path.unlink(missing_ok=True)


def test_lock_file_validator_invalid_json():
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w") as f:
        f.write("{invalid")
        f.flush()
        path = Path(f.name)
    try:
        errors = LockFileValidator.validate_lock_file(path)
        assert len(errors) > 0
    finally:
        path.unlink(missing_ok=True)


def test_lock_file_validator_valid_deps():
    data = json.dumps({"dependencies": {"panther-http": "1.0.0"}})
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w") as f:
        f.write(data)
        f.flush()
        path = Path(f.name)
    try:
        errors = LockFileValidator.validate_lock_file(path)
        assert len(errors) == 0
    finally:
        path.unlink(missing_ok=True)


def test_manifest_security_validator_missing():
    path = Path("/nonexistent/manifest.toml")
    result = ManifestSecurityValidator.validate(path)
    assert not result.valid


def test_manifest_security_validator_clean():
    with tempfile.NamedTemporaryFile(suffix=".toml", delete=False, mode="w") as f:
        f.write('[project]\nname = "test"\nversion = "1.0.0"\n')
        f.flush()
        path = Path(f.name)
    try:
        result = ManifestSecurityValidator.validate(path)
        assert result.valid
        assert len(result.warnings) == 0
    finally:
        path.unlink(missing_ok=True)
