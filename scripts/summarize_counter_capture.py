"""Summarize Vivado ILA's counter_capture.csv from the PYNQ-Z2 board."""

import csv
import sys
from pathlib import Path


COUNTERS = (
    "frame_count[31:0]",
    "data_frame_count[31:0]",
    "bit_count[31:0]",
    "bit_errors[31:0]",
)


def main(path: Path) -> int:
    with path.open(newline="", encoding="utf-8-sig") as stream:
        rows = list(csv.DictReader(stream))
    if not rows or not rows[0]["Sample in Buffer"].startswith("Radix"):
        raise ValueError("This does not look like a Vivado ILA CSV export")
    samples = [{key: int(row[key], 16) for key in COUNTERS} for row in rows[1:]]
    if not samples:
        raise ValueError("ILA CSV contains no samples")
    first, last = samples[0], samples[-1]
    for label, key in (
        ("frames", COUNTERS[0]),
        ("data_frames", COUNTERS[1]),
        ("bits", COUNTERS[2]),
        ("bit_errors", COUNTERS[3]),
    ):
        print(f"{label}: {first[key]} -> {last[key]} (delta {last[key] - first[key]})")
    print(f"samples: {len(samples)}")
    print(f"loopback_error_ratio: {last[COUNTERS[3]]}/{last[COUNTERS[2]]}")

    if last[COUNTERS[0]] <= first[COUNTERS[0]]:
        raise ValueError("No complete OFDM frame was observed in this capture")
    if last[COUNTERS[2]] <= first[COUNTERS[2]]:
        raise ValueError("No QPSK data bits were observed in this capture")
    if any(last[key] < first[key] for key in COUNTERS):
        raise ValueError("A counter decreased during the capture")
    if not (0 <= last[COUNTERS[2]] - 96 * last[COUNTERS[1]] <= 96):
        raise ValueError("Bit count does not match 96 bits per completed data frame")
    if last[COUNTERS[3]] > last[COUNTERS[2]]:
        raise ValueError("Bit errors exceed counted bits")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/summarize_counter_capture.py PATH_TO_CSV")
    raise SystemExit(main(Path(sys.argv[1])))
