"""Validate a Vivado ILA capture from the PYNQ-Z2 range demonstration."""

import csv
import sys
from pathlib import Path


FIELDS = ("range_frame_valid", "peak_bin[5:0]", "peak_magnitude[16:0]")


def main(path: Path) -> int:
    with path.open(newline="", encoding="utf-8-sig") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) < 2 or not rows[0]["Sample in Buffer"].startswith("Radix"):
        raise ValueError("This does not look like a Vivado ILA CSV export")
    samples = [{field: int(row[field], 16) for field in FIELDS} for row in rows[1:]]
    valid = [sample for sample in samples if sample[FIELDS[0]]]
    if not valid:
        raise ValueError("No completed range profile was observed")
    bins = sorted({sample[FIELDS[1]] for sample in valid})
    magnitudes = [sample[FIELDS[2]] for sample in valid]
    print(f"samples: {len(samples)}")
    print(f"range_frame_valid: {len(valid)}/{len(samples)} samples high")
    print(f"peak_bins_when_valid: {bins}")
    print(f"peak_magnitude_when_valid: {min(magnitudes)}..{max(magnitudes)}")
    if bins != [5]:
        raise ValueError(f"Expected only peak bin 5 after a valid range frame, got {bins}")
    if min(magnitudes) < 8000:
        raise ValueError(f"Range peak is too weak: minimum observed {min(magnitudes)}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/summarize_range_capture.py PATH_TO_CSV")
    raise SystemExit(main(Path(sys.argv[1])))
