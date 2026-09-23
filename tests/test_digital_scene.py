from __future__ import annotations

import numpy as np
import pytest

from model.digital_scene import (
    DigitalTarget,
    SceneConfig,
    communication_ber,
    scene_response,
    sense_target,
)
from model.phase_displacement import dominant_frequency


@pytest.mark.parametrize("frequency_hz", [2.40, 2.05])
def test_4096_point_vibration_frequency_and_displacement(frequency_hz: float) -> None:
    config = SceneConfig()
    indices = np.arange(config.n_slow_samples)
    target = DigitalTarget(5, 1.0, vibration_amplitude_m=0.0005, vibration_hz=frequency_hz)
    response = scene_response((target,), config, indices)
    _, recovered, peaks = sense_target(response, 5, config, 30.0, np.random.default_rng(42))
    truth = 0.0005 * np.sin(2.0 * np.pi * frequency_hz * indices / 100.0)
    relative_truth = truth - truth[0]
    rms_error_m = float(np.sqrt(np.mean((recovered - relative_truth) ** 2)))
    assert np.all(peaks == 5)
    assert rms_error_m < 50e-6
    assert abs(dominant_frequency(recovered, 100.0) - frequency_hz) < 0.05


def test_two_targets_share_comm_and_range_response() -> None:
    config = SceneConfig(n_slow_samples=256)
    targets = (
        DigitalTarget(5, 1.0, vibration_amplitude_m=0.0004, vibration_hz=2.4),
        DigitalTarget(10, 0.3, vibration_amplitude_m=0.0002, vibration_hz=3.0),
    )
    response = scene_response(targets, config, np.arange(config.n_slow_samples))
    _, recovered, peaks = sense_target(response, 5, config, None, np.random.default_rng(1))
    ber, errors, bits = communication_ber(response, config, None, np.random.default_rng(2))
    assert np.all(peaks == 5)
    assert np.ptp(recovered) > 0.0006
    assert ber == 0.0 and errors == 0 and bits == 256 * 96


def test_ber_improves_with_snr_under_reproducible_noise() -> None:
    config = SceneConfig(n_slow_samples=1024)
    target = DigitalTarget(5, 1.0, vibration_amplitude_m=0.0005, vibration_hz=2.4)
    response = scene_response((target,), config, np.arange(config.n_slow_samples))
    low_ber, low_errors, bits = communication_ber(response, config, 5.0, np.random.default_rng(42))
    high_ber, high_errors, high_bits = communication_ber(response, config, 20.0, np.random.default_rng(42))
    assert bits == high_bits == 1024 * 96
    assert low_ber > 0.05 and low_errors > 0
    assert high_ber < 0.001 and high_errors < low_errors


def test_scene_rejects_unresolvable_or_invalid_targets() -> None:
    config = SceneConfig(n_slow_samples=4)
    with pytest.raises(ValueError, match="distinct"):
        scene_response((DigitalTarget(5, 1.0), DigitalTarget(5, 0.2)), config, np.arange(4))
    with pytest.raises(ValueError, match="shorter than the cyclic prefix"):
        scene_response((DigitalTarget(16, 1.0),), config, np.arange(4))
    with pytest.raises(ValueError, match="Nyquist"):
        scene_response((DigitalTarget(5, 1.0, vibration_hz=51.0),), config, np.arange(4))
