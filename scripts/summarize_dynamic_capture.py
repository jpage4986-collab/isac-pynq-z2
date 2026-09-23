"""Check spaced ILA snapshots of the on-board digital vibration demo."""

import csv
import sys
from pathlib import Path


def signed(value: str, width: int) -> int:
    number = int(value, 16)
    return number - (1 << width) if number & (1 << (width - 1)) else number


def snapshot(path: Path) -> dict[str, int]:
    with path.open(newline="", encoding="utf-8-sig") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) < 2 or not rows[0]["Sample in Buffer"].startswith("Radix"):
        raise ValueError(f"Invalid Vivado ILA CSV: {path}")
    row = rows[-1]
    return {
        "bits": int(row["bit_count[31:0]"], 16),
        "errors": int(row["bit_errors[31:0]"], 16),
        "bin": int(row["peak_bin[5:0]"], 16),
        "slow_count": int(row["slow_sample_count[31:0]"], 16),
        "gate_i": signed(row["gate_i[15:0]"], 16),
        "gate_q": signed(row["gate_q[15:0]"], 16),
        "phase_product_q": signed(row["phase_product_q[32:0]"], 33),
    }


def main(directory: Path) -> int:
    files = sorted(directory.glob("integrated_slow_*.csv"))
    if len(files) != 12:
        raise ValueError(f"Expected 12 spaced ILA snapshots, got {len(files)}")
    rows = [snapshot(path) for path in files]
    counts = [row["slow_count"] for row in rows]
    gates = {(row["gate_i"], row["gate_q"]) for row in rows}
    phase_products = {row["phase_product_q"] for row in rows}
    print(f"board snapshots: {len(rows)}")
    print(f"QPSK bits: {rows[0]['bits']}..{rows[-1]['bits']}")
    print(f"bit errors: {sorted({row['errors'] for row in rows})}")
    print(f"range bins: {sorted({row['bin'] for row in rows})}")
    print(f"100 Hz sample count: {counts[0]}..{counts[-1]}")
    print(f"distinct complex target-gate samples: {len(gates)}")
    print(f"distinct phase-product imaginary values: {len(phase_products)}")
    if rows[-1]["bits"] <= rows[0]["bits"]:
        raise ValueError("QPSK checker did not advance between snapshots")
    if any(row["errors"] for row in rows):
        raise ValueError("QPSK checker reported bit errors")
    if any(row["bin"] != 5 for row in rows):
        raise ValueError("Target range peak was not consistently bin 5")
    if any(right <= left for left, right in zip(counts, counts[1:])):
        raise ValueError("100 Hz sample counter did not advance every snapshot")
    if len(gates) < 3 or len(phase_products) < 3:
        raise ValueError("Target phase did not vary measurably on the board")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/summarize_dynamic_capture.py ILA_DIRECTORY")
    raise SystemExit(main(Path(sys.argv[1])))
