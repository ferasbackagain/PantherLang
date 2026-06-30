from language.testing import PantherTestFramework

r = PantherTestFramework().run()
assert r["status"] == "PASS"
assert r["failed"] == 0
print("✅ Phase 1.14 testing framework tests passed.")
