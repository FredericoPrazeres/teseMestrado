#!/usr/bin/env python3
"""
Divide CI pipeline durations by X and output as array.
Edit DATA and DIVISOR below, then run: python3 time_calc.py
"""

# ─── Configuration ───────────────────────────────────────────────────────────

# Each entry is [minutes, seconds] for one run
DATA = [
    [3, 24],
    [2, 43],
    [3, 22],
    [3, 29],
    [3, 35],
]

DIVISOR = 6  # Divide each time by this value

# ─── Script ──────────────────────────────────────────────────────────────────

result = []
total = 0
for mins, secs in DATA:
    t = mins * 60 + secs
    total += t
    d = t / DIVISOR
    result.append([int(d // 60), int(d % 60)])

avg = total / len(DATA)
avg_div = avg / DIVISOR

print(result)
print(f"Avg: {int(avg // 60)}min {int(avg % 60):02d}s | Avg ÷ {DIVISOR}: {int(avg_div // 60)}min {int(avg_div % 60):02d}s")
