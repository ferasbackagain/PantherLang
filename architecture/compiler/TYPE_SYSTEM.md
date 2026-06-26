# Panther Type System — Phase 1

## Goal
The Panther type system makes code safe, clear, AI-readable, and scalable.

## Primitive Types
int, float, decimal, bool, string, char, bytes, uuid, date, time, datetime, duration, json, any, void

## Collections
list<T>, array<T>, map<K,V>, set<T>, tuple<T...>

## Advanced
optional<T>, result<T,E>, future<T>, stream<T>

## Rules
1. Non-null by default.
2. Nullable must be explicit.
3. Required fields must be validated.
4. Prices use decimal.
5. Dangerous implicit casts are forbidden.
