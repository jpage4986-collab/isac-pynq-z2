"""Generate a deterministic Q1.15 OFDM vector for future RTL simulation."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import numpy as np

from model.fixed_point import normalize_for_q15, quantize_complex_q15
from model.ofdm import OFDMConfig, build_tx_frame, ofdm_modulate


def main() -> None:
    config = OFDMConfig(n_data_symbols=2)
    bits = (np.arange(config.n_bits_per_frame, dtype=np.uint8) % 2).astype(np.uint8)
    samples = ofdm_modulate(build_tx_frame(bits, config), config)
    scaled, gain = normalize_for_q15(samples)
    i_values, q_values = quantize_complex_q15(scaled)
    payload = {
        "n_fft": config.n_fft,
        "cp_len": config.cp_len,
        "n_data_symbols": config.n_data_symbols,
        "q_format": "Q1.15",
        "scale_before_quantize": gain,
        "bits": bits.tolist(),
        "samples_i": i_values.tolist(),
        "samples_q": q_values.tolist(),
    }
    output = ROOT / "fpga" / "vectors" / "ofdm_q15_smoke.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {output}")


if __name__ == "__main__":
    main()
