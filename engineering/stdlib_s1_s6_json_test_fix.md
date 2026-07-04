# PantherLang Stdlib S1-S6 JSON Test Fix

Status: COMPLETE after tests pass.

Root cause: Python triple-quoted test source consumed backslash escapes before PantherLang parsing, so the Panther source became invalid JSON-string syntax.

Fix: make the embedded Panther source a raw Python string and normalize the demo JSON literals.
