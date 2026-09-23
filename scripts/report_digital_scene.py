"""Write a deterministic JSON acceptance report for the digital ISAC scene."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from model.digital_scene import (  # noqa: E402
    DigitalTarget,
    SceneConfig,
    communication_ber,
    scene_response,
    sense_target,
)
from model.phase_displacement import dominant_frequency  # noqa: E402


def scenario(frequency_hz: float, seed: int) -> dict[str, float | int]:
    config = SceneConfig()
    indices = np.arange(config.n_slow_samples)
    target = DigitalTarget(5, 1.0, vibration_amplitude_m=0.0005, vibration_hz=frequency_hz)
    response = scene_response((target,), config, indices)
    _, displacement, peaks = sense_target(response, 5, config, 30.0, np.random.default_rng(seed))
    truth = 0.0005 * np.sin(2.0 * np.pi * frequency_hz * indices / config.slow_sample_rate_hz)
    rms_error_um = float(np.sqrt(np.mean((displacement - (truth - truth[0])) ** 2)) * 1e6)
    result = {
        "input_frequency_hz": frequency_hz,
        "estimated_frequency_hz": dominant_frequency(displacement, config.slow_sample_rate_hz),
        "displacement_rmse_um": rms_error_um,
        "correct_range_peak_fraction": float(np.mean(peaks == 5)),
        "slow_samples": config.n_slow_samples,
    }
    return result


def main() -> None:
    config = SceneConfig(n_slow_samples=1024)
    target = DigitalTarget(5, 1.0, vibration_amplitude_m=0.0005, vibration_hz=2.4)
    response = scene_response((target,), config, np.arange(config.n_slow_samples))
    sweep = []
    for snr in (0, 5, 10, 15, 20, 30):
        ber, errors, bits = communication_ber(response, config, snr, np.random.default_rng(42))
        sweep.append({"snr_db": snr, "bit_errors": errors, "bit_count": bits, "ber": ber})
    report = {
        "model": "digital_ofdm_shared_channel",
        "seed": 42,
        "carrier_hz": 5.8e9,
        "slow_rate_hz": 100.0,
        "target_delay_bin": 5,
        "target_vibration_amplitude_um": 500.0,
        "sensing_snr_db": 30.0,
        "ber_sweep_slow_samples": 1024,
        "targets": [scenario(2.40, 42), scenario(2.05, 43)],
        "ber_sweep": sweep,
        "limits": {
            "frequency_error_hz": 0.05,
            "displacement_rmse_um": 50.0,
        },
    }
    for target_result in report["targets"]:
        if (abs(target_result["estimated_frequency_hz"] - target_result["input_frequency_hz"])
                >= report["limits"]["frequency_error_hz"]):
            raise RuntimeError("frequency acceptance limit was not met")
        if target_result["displacement_rmse_um"] >= report["limits"]["displacement_rmse_um"]:
            raise RuntimeError("displacement acceptance limit was not met")
        if target_result["correct_range_peak_fraction"] != 1.0:
            raise RuntimeError("digital range peak was not stable")
    path = Path(__file__).resolve().parents[1] / "reports" / "digital_scene_20260923.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"REPORT={path}")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
