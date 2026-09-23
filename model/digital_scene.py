"""Reproducible OFDM communication and structural-motion scene.

One slow-time sample represents one known OFDM training symbol. Data symbols
at that instant traverse the same channel. The scene is deliberately digital:
no RF front end, antenna, or physical distance measurement is implied.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .ofdm import (
    OFDMConfig,
    build_tx_frame,
    estimate_channel_from_training,
    extract_data_bits,
)
from .phase_displacement import (
    C_LIGHT,
    dominant_frequency,
    recover_incremental_displacement,
)


@dataclass(frozen=True)
class DigitalTarget:
    delay_samples: int
    amplitude: float
    vibration_amplitude_m: float = 0.0
    vibration_hz: float = 0.0
    vibration_phase_rad: float = 0.0
    static_phase_rad: float = 0.0

    def validate(self, config: OFDMConfig, sample_rate_hz: float) -> None:
        if not isinstance(self.delay_samples, (int, np.integer)) or not 0 <= self.delay_samples < config.cp_len:
            raise ValueError("target delay must be an integer shorter than the cyclic prefix")
        values = (
            self.amplitude,
            self.vibration_amplitude_m,
            self.vibration_hz,
            self.vibration_phase_rad,
            self.static_phase_rad,
        )
        if not all(np.isfinite(value) for value in values):
            raise ValueError("target parameters must be finite")
        if self.amplitude <= 0.0 or self.vibration_amplitude_m < 0.0:
            raise ValueError("amplitude must be positive and vibration amplitude non-negative")
        if not 0.0 <= self.vibration_hz < sample_rate_hz / 2.0:
            raise ValueError("vibration must be below slow-time Nyquist frequency")


@dataclass(frozen=True)
class SceneConfig:
    ofdm: OFDMConfig = OFDMConfig(n_data_symbols=1)
    slow_sample_rate_hz: float = 100.0
    n_slow_samples: int = 4096
    carrier_hz: float = 5.8e9

    def __post_init__(self) -> None:
        if (not np.isfinite(self.slow_sample_rate_hz) or not np.isfinite(self.carrier_hz)
                or self.slow_sample_rate_hz <= 0.0 or self.n_slow_samples < 4 or self.carrier_hz <= 0.0):
            raise ValueError("slow-time rate, length, and carrier must be positive")


def scene_response(
    targets: tuple[DigitalTarget, ...],
    config: SceneConfig,
    sample_indices: np.ndarray,
) -> np.ndarray:
    """Return H[m,k] for the same targets seen by comm and sensing."""
    if not targets:
        raise ValueError("at least one digital target is required")
    if len({target.delay_samples for target in targets}) != len(targets):
        raise ValueError("targets must occupy distinct integer delay bins")
    indices = np.asarray(sample_indices)
    if indices.ndim != 1 or np.any(indices < 0) or np.any(indices != np.floor(indices)):
        raise ValueError("sample_indices must be non-negative integers")
    time = indices / config.slow_sample_rate_hz
    k = np.arange(config.ofdm.n_fft)
    response = np.zeros((indices.size, config.ofdm.n_fft), dtype=np.complex128)
    for target in targets:
        target.validate(config.ofdm, config.slow_sample_rate_hz)
        displacement = target.vibration_amplitude_m * np.sin(
            2.0 * np.pi * target.vibration_hz * time + target.vibration_phase_rad
        )
        phase = target.static_phase_rad - 4.0 * np.pi * displacement * config.carrier_hz / C_LIGHT
        reflection = target.amplitude * np.exp(1j * phase)
        delay_ramp = np.exp(-2j * np.pi * k * target.delay_samples / config.ofdm.n_fft)
        response += reflection[:, None] * delay_ramp[None, :]
    return response


def add_awgn(
    grid: np.ndarray, snr_db: float | None, rng: np.random.Generator
) -> np.ndarray:
    """Add complex noise using power on the active transmitted bins."""
    signal = np.asarray(grid, dtype=np.complex128)
    if snr_db is None:
        return signal.copy()
    if not np.isfinite(snr_db):
        raise ValueError("snr_db must be finite")
    nonzero = signal[np.abs(signal) > 0]
    if nonzero.size == 0:
        raise ValueError("signal must contain at least one non-zero reference bin")
    active_power = np.mean(np.abs(nonzero) ** 2)
    sigma = np.sqrt(active_power / (2.0 * 10.0 ** (snr_db / 10.0)))
    return signal + sigma * (
        rng.standard_normal(signal.shape) + 1j * rng.standard_normal(signal.shape)
    )


def sense_target(
    response: np.ndarray,
    target_bin: int,
    config: SceneConfig,
    snr_db: float | None,
    rng: np.random.Generator,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Return target-gate IQ, relative displacement, and per-frame peaks.

    The sparse 52-carrier H=Y/X measurement mirrors the FPGA range branch.
    Guard and DC bins are zero before the range IFFT.
    """
    h = np.asarray(response, dtype=np.complex128)
    if h.ndim != 2 or h.shape[0] == 0 or h.shape[1] != config.ofdm.n_fft:
        raise ValueError("response must have shape (slow samples, n_fft)")
    if not 0 <= target_bin < config.ofdm.cp_len:
        raise ValueError("target_bin lies outside the cyclic prefix")
    measured = np.zeros_like(h)
    active = config.ofdm.indices(config.ofdm.active_bins)
    measured[:, active] = h[:, active]
    measured[:, active] = add_awgn(measured[:, active], snr_db, rng)
    profiles = np.fft.ifft(measured, axis=1)
    gates = profiles[:, target_bin]
    peaks = np.argmax(np.abs(profiles), axis=1)
    displacement = recover_incremental_displacement(gates, carrier_hz=config.carrier_hz)
    return gates, displacement, peaks


def communication_ber(
    response: np.ndarray,
    config: SceneConfig,
    snr_db: float | None,
    rng: np.random.Generator,
) -> tuple[float, int, int]:
    """Send random QPSK data through each measured H[m,k] and count errors.

    Training is estimated from noisy known bins. A pilot correlation removes
    the data symbol's residual common phase before hard decisions.
    """
    h = np.asarray(response, dtype=np.complex128)
    if h.ndim != 2 or h.shape[0] == 0 or h.shape[1] != config.ofdm.n_fft:
        raise ValueError("response must have shape (slow samples, n_fft)")
    active = config.ofdm.indices(config.ofdm.active_bins)
    pilots = config.ofdm.indices(config.ofdm.pilot_bins)
    data = config.ofdm.indices(config.ofdm.data_bins)
    error_count = 0
    bit_count = 0
    for row in h:
        bits = rng.integers(0, 2, config.ofdm.n_bits_per_frame, dtype=np.uint8)
        tx = build_tx_frame(bits, config.ofdm)
        rx = add_awgn(tx * row[None, :], snr_db, rng)
        estimate = estimate_channel_from_training(rx, tx, config.ofdm)
        corrected = rx[:, active] / estimate[active][None, :]
        rx_equalized = np.zeros_like(rx)
        rx_equalized[:, active] = corrected
        pilot_phase = np.angle(np.sum(rx_equalized[1:, pilots], axis=1))
        rx_equalized[1:, data] *= np.exp(-1j * pilot_phase[:, None])
        decided = extract_data_bits(rx_equalized, config.ofdm)
        error_count += int(np.count_nonzero(bits != decided))
        bit_count += bits.size
    return error_count / bit_count, error_count, bit_count


def evaluate_scene(
    targets: tuple[DigitalTarget, ...],
    target_bin: int,
    config: SceneConfig = SceneConfig(),
    sensing_snr_db: float | None = None,
    communication_snr_db: float | None = None,
    seed: int = 20260923,
) -> dict[str, float | int]:
    """Summarize one deterministic, shared-channel scene."""
    rng = np.random.default_rng(seed)
    response = scene_response(targets, config, np.arange(config.n_slow_samples))
    _, displacement, peaks = sense_target(response, target_bin, config, sensing_snr_db, rng)
    frequency = dominant_frequency(displacement, config.slow_sample_rate_hz)
    ber, errors, bits = communication_ber(response, config, communication_snr_db, rng)
    return {
        "target_bin": target_bin,
        "peak_correct_fraction": float(np.mean(peaks == target_bin)),
        "dominant_frequency_hz": frequency,
        "displacement_peak_to_peak_um": float(np.ptp(displacement) * 1e6),
        "bit_errors": errors,
        "bit_count": bits,
        "ber": ber,
    }
