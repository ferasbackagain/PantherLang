# PantherLang Fast Practical Plan

1. Stabilize Debug Adapter imports and protocol framing.
2. Confirm project templates exist for CLI and VS Code.
3. Align VS Code release contract with package.json.
4. Run full pytest.
5. If only release/version tests fail, align the release contract immediately.
6. When full regression is green, tag the new release.
7. Continue R3 Batch 2 Part 3.3: Expression Parser.
8. Use reference apps only as pressure tests for the language, not as the final product.

Reference app ladder:
- Console calculator: expressions, variables, input, print.
- Conditional calculator: if/else, equality, operator dispatch.
- Function calculator: functions and returns.
- Runtime calculator: panther run calculator.pan.
- Future web calculator: only after HTTP server and renderer exist.
