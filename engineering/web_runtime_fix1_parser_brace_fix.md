# Web Runtime Fix 1 Parser Brace Fix

Fixes statement-level expression token collection so object and array literals inside `return` statements are parsed correctly inside `web {}` and `api {}` route blocks.

## Root Cause

The active `statement_parser.py` collected expression tokens using only parenthesis/bracket depth. A `return { ... };` statement stopped at the first `}` because the parser treated it as a block terminator instead of an object-literal delimiter.

## Fix

Restores brace-depth tracking in expression token collection and top-level assignment detection.

## Verification

Targeted tests cover:
- object literal return inside web route
- array literal return inside api route
- object literal assignment/indexing execution
