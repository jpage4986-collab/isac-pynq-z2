"""Validate the exact RTL phasor's 4096-point slow-time frequency and scale."""

import csv
import sys
from pathlib import Path

import numpy as np


def main(path: Path) -> int:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) != 4096:
        raise ValueError(f"Expected 4096 RTL samples, got {len(rows)}")
    if [int(row["sample"]) for row in rows] != list(range(4096)):
        raise ValueError("RTL sample indices are not continuous")
    iq = np.array(
        [complex(int(row["cos_q14"]), int(row["sin_q14"])) for row in rows]
    ) / 16384.0
    wavelength_m = 299_792_458.0 / 5.8e9
    displacement_m = -np.angle(iq) * wavelength_m / (4.0 * np.pi)
    spectrum = np.abs(np.fft.rfft(displacement_m - displacement_m.mean()))
    peak_index = int(np.argmax(spectrum[1:]) + 1)
    peak_hz = peak_index * 100.0 / 4096.0
    amplitude_m = (displacement_m.max() - displacement_m.min()) / 2.0
    print(f"RTL slow samples: {len(rows)}")
    print(f"FFT peak: {peak_hz:.6f} Hz")
    print(f"displacement amplitude: {amplitude_m * 1e6:.2f} um")
    if abs(peak_hz - 2.4) > 100.0 / 4096.0:
        raise ValueError("RTL vibration frequency lies outside one FFT bin")
    if not 490e-6 <= amplitude_m <= 510e-6:
        raise ValueError("RTL phasor amplitude does not represent 500 um")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/verify_vibration_nco.py CSV_PATH")
    raise SystemExit(main(Path(sys.argv[1])))
