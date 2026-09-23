"""Validate a PYNQ-Z2 ILA capture of the shared OFDM ISAC baseline."""

import csv
import sys
from pathlib import Path


FIELDS = (
    "frame_count[31:0]",
    "data_frame_count[31:0]",
    "bit_count[31:0]",
    "bit_errors[31:0]",
    "range_frame_valid",
    "peak_bin[5:0]",
    "peak_magnitude[16:0]",
)


def main(path: Path) -> int:
    with path.open(newline="", encoding="utf-8-sig") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) < 2 or not rows[0]["Sample in Buffer"].startswith("Radix"):
        raise ValueError("This does not look like a Vivado ILA CSV export")
    samples = [{field: int(row[field], 16) for field in FIELDS} for row in rows[1:]]
    observed = {field: max(sample[field] for sample in samples) for field in FIELDS}
    valid = [sample for sample in samples if sample["range_frame_valid"]]
    if not valid:
        raise ValueError("No completed range profile was observed")
    bins = sorted({sample["peak_bin[5:0]"] for sample in valid})
    magnitudes = [sample["peak_magnitude[16:0]"] for sample in valid]
    print(f"samples: {len(samples)}")
    print(f"frame_count: 0..{observed['frame_count[31:0]']}")
    print(f"data_frame_count: 0..{observed['data_frame_count[31:0]']}")
    print(f"bit_count: 0..{observed['bit_count[31:0]']}")
    print(f"bit_errors: 0..{observed['bit_errors[31:0]']}")
    print(f"range_frame_valid: {len(valid)}/{len(samples)} samples high")
    print(f"peak_bins_when_valid: {bins}")
    print(f"peak_magnitude_when_valid: {min(magnitudes)}..{max(magnitudes)}")
    if not observed["frame_count[31:0]"] or not observed["data_frame_count[31:0]"]:
        raise ValueError("No alternating training/data OFDM frames were observed")
    if not observed["bit_count[31:0]"]:
        raise ValueError("No QPSK hard decisions were observed")
    if observed["bit_errors[31:0]"]:
        raise ValueError(f"Communication checker reported {observed['bit_errors[31:0]']} bit errors")
    if bins != [5]:
        raise ValueError(f"Expected only peak bin 5 after a valid range frame, got {bins}")
    if min(magnitudes) < 8000:
        raise ValueError(f"Range peak is too weak: minimum observed {min(magnitudes)}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/summarize_integrated_capture.py PATH_TO_CSV")
    raise SystemExit(main(Path(sys.argv[1])))
