"""Floating-point OFDM reference model for the ISAC project.

The model deliberately keeps the channel simple: each OFDM symbol receives a
common phase rotation representing a slowly varying structural displacement.
This is the golden reference that later RTL/PYNQ blocks will be compared with.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

import numpy as np

from .phase_displacement import phase_from_displacement


@dataclass(frozen=True)
class OFDMConfig:
    """Small, hardware-friendly OFDM configuration used by the first model."""

    n_fft: int = 64
    cp_len: int = 16
    n_data_symbols: int = 8
    pilot_bins: tuple[int, ...] = (-21, -7, 7, 21)

    def __post_init__(self) -> None:
        if self.n_fft < 16 or self.n_fft & (self.n_fft - 1):
            raise ValueError("n_fft must be a power of two and at least 16")
        if not 0 < self.cp_len < self.n_fft:
            raise ValueError("cp_len must be between 1 and n_fft - 1")
        if self.n_data_symbols < 1:
            raise ValueError("n_data_symbols must be positive")
        active = set(self.active_bins)
        if not set(self.pilot_bins) <= active:
            raise ValueError("pilot_bins must be active subcarriers")

    @property
    def active_bins(self) -> tuple[int, ...]:
        """Signed subcarrier numbers, excluding DC and the guard bands."""
        half = self.n_fft // 2
        edge = min(26, half - 1)
        return tuple(range(-edge, 0)) + tuple(range(1, edge + 1))

    @property
    def data_bins(self) -> tuple[int, ...]:
        return tuple(k for k in self.active_bins if k not in self.pilot_bins)

    @property
    def n_bits_per_frame(self) -> int:
        return self.n_data_symbols * len(self.data_bins) * 2

    @property
    def n_ofdm_symbols(self) -> int:
        return 1 + self.n_data_symbols  # one known training symbol

    def indices(self, bins: Iterable[int]) -> np.ndarray:
        """Map signed subcarrier numbers to NumPy FFT-bin indices."""
        return np.asarray(tuple(bins), dtype=int) % self.n_fft


def qpsk_mod(bits: np.ndarray | Iterable[int]) -> np.ndarray:
    """Gray-map pairs of bits to unit-power QPSK symbols."""
    b = np.asarray(tuple(bits) if not isinstance(bits, np.ndarray) else bits)
    if b.ndim != 1 or b.size % 2 or np.any((b != 0) & (b != 1)):
        raise ValueError("bits must be a one-dimensional binary array of even length")
    pairs = b.reshape(-1, 2)
    return ((1.0 - 2.0 * pairs[:, 0]) + 1j * (1.0 - 2.0 * pairs[:, 1])) / np.sqrt(2.0)


def qpsk_demod(symbols: np.ndarray) -> np.ndarray:
    """Hard-decision QPSK demodulator matching :func:`qpsk_mod`."""
    z = np.asarray(symbols, dtype=np.complex128)
    if z.ndim != 1:
        raise ValueError("symbols must be one-dimensional")
    return np.column_stack((z.real < 0.0, z.imag < 0.0)).astype(np.uint8).ravel()


def build_tx_frame(bits: np.ndarray | Iterable[int], config: OFDMConfig) -> np.ndarray:
    """Create a frequency-domain frame with a training symbol and pilots."""
    b = np.asarray(tuple(bits) if not isinstance(bits, np.ndarray) else bits, dtype=np.uint8)
    if b.ndim != 1 or b.size != config.n_bits_per_frame:
        raise ValueError(f"expected exactly {config.n_bits_per_frame} bits")

    grid = np.zeros((config.n_ofdm_symbols, config.n_fft), dtype=np.complex128)
    active = config.indices(config.active_bins)
    pilots = config.indices(config.pilot_bins)
    data = config.indices(config.data_bins)
    grid[0, active] = 1.0 + 0.0j
    symbols = qpsk_mod(b).reshape(config.n_data_symbols, len(config.data_bins))
    for row in range(config.n_data_symbols):
        grid[row + 1, pilots] = 1.0 + 0.0j
        grid[row + 1, data] = symbols[row]
    return grid


def ofdm_modulate(freq_grid: np.ndarray, config: OFDMConfig) -> np.ndarray:
    """IFFT and prepend a cyclic prefix to every OFDM symbol."""
    grid = np.asarray(freq_grid, dtype=np.complex128)
    if grid.ndim != 2 or grid.shape[1] != config.n_fft:
        raise ValueError("freq_grid must have shape (symbols, n_fft)")
    time_grid = np.fft.ifft(grid, axis=1) * np.sqrt(config.n_fft)
    with_cp = np.concatenate((time_grid[:, -config.cp_len :], time_grid), axis=1)
    return with_cp.reshape(-1)


def ofdm_demodulate(samples: np.ndarray, config: OFDMConfig) -> np.ndarray:
    """Remove the cyclic prefix and perform an FFT."""
    x = np.asarray(samples, dtype=np.complex128)
    symbol_len = config.n_fft + config.cp_len
    if x.ndim != 1 or x.size % symbol_len:
        raise ValueError("samples must contain an integer number of OFDM symbols")
    with_cp = x.reshape(-1, symbol_len)
    useful = with_cp[:, config.cp_len :]
    return np.fft.fft(useful, axis=1) / np.sqrt(config.n_fft)


def apply_common_phase_channel(
    tx_grid: np.ndarray,
    phase_rad: np.ndarray,
    snr_db: float | None = None,
    rng: np.random.Generator | None = None,
) -> np.ndarray:
    """Apply one slowly varying phase rotation per OFDM symbol and AWGN."""
    tx = np.asarray(tx_grid, dtype=np.complex128)
    phase = np.asarray(phase_rad, dtype=float)
    if tx.ndim != 2 or phase.ndim != 1 or tx.shape[0] != phase.size:
        raise ValueError("phase_rad must have one value for each OFDM symbol")
    rx = tx * np.exp(1j * phase[:, None])
    if snr_db is not None:
        if not np.isfinite(snr_db):
            raise ValueError("snr_db must be finite")
        generator = np.random.default_rng() if rng is None else rng
        power = float(np.mean(np.abs(tx) ** 2))
        noise_power = power / (10.0 ** (snr_db / 10.0))
        noise = np.sqrt(noise_power / 2.0) * (
            generator.standard_normal(rx.shape) + 1j * generator.standard_normal(rx.shape)
        )
        rx = rx + noise
    return rx


def estimate_common_phase(rx_grid: np.ndarray, tx_grid: np.ndarray, config: OFDMConfig) -> np.ndarray:
    """Estimate per-symbol common phase from known pilot subcarriers."""
    rx = np.asarray(rx_grid, dtype=np.complex128)
    tx = np.asarray(tx_grid, dtype=np.complex128)
    if rx.shape != tx.shape or rx.ndim != 2 or rx.shape[1] != config.n_fft:
        raise ValueError("rx_grid and tx_grid must have the same (symbols, n_fft) shape")
    pilots = config.indices(config.pilot_bins)
    correlation = np.sum(rx[:, pilots] * np.conj(tx[:, pilots]), axis=1)
    return np.unwrap(np.angle(correlation))


def correct_common_phase(rx_grid: np.ndarray, phase_rad: np.ndarray) -> np.ndarray:
    """Remove estimated common phase before QPSK decisions."""
    rx = np.asarray(rx_grid, dtype=np.complex128)
    phase = np.asarray(phase_rad, dtype=float)
    if rx.ndim != 2 or phase.ndim != 1 or rx.shape[0] != phase.size:
        raise ValueError("phase_rad must have one value for each OFDM symbol")
    return rx * np.exp(-1j * phase[:, None])


def extract_data_bits(rx_grid: np.ndarray, config: OFDMConfig) -> np.ndarray:
    """Extract and hard-decision the data subcarriers from a corrected frame."""
    rx = np.asarray(rx_grid, dtype=np.complex128)
    if rx.ndim != 2 or rx.shape != (config.n_ofdm_symbols, config.n_fft):
        raise ValueError("rx_grid has an unexpected frame shape")
    data = config.indices(config.data_bins)
    return qpsk_demod(rx[1:, data].reshape(-1))


def vibration_trace(
    config: OFDMConfig,
    symbol_rate_hz: float,
    amplitude_m: float = 1e-3,
    frequency_hz: float = 2.0,
    phase0_rad: float = 0.0,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Generate a sinusoidal displacement and its round-trip phase trace."""
    if symbol_rate_hz <= 0.0 or amplitude_m < 0.0 or frequency_hz < 0.0:
        raise ValueError("rates, amplitude, and frequency must be non-negative as appropriate")
    t = np.arange(config.n_ofdm_symbols, dtype=float) / symbol_rate_hz
    displacement = amplitude_m * np.sin(2.0 * np.pi * frequency_hz * t + phase0_rad)
    return t, displacement, phase_from_displacement(displacement)


def multipath_frequency_response(
    taps: np.ndarray | Iterable[complex], config: OFDMConfig
) -> np.ndarray:
    """Return the FFT-bin response of a short discrete-time multipath channel."""
    h = np.asarray(tuple(taps) if not isinstance(taps, np.ndarray) else taps, dtype=np.complex128)
    if h.ndim != 1 or h.size == 0 or h.size > config.cp_len:
        raise ValueError("taps must be a non-empty 1-D array no longer than cp_len")
    return np.fft.fft(np.pad(h, (0, config.n_fft - h.size)))


def apply_multipath_channel(
    tx_grid: np.ndarray,
    phase_rad: np.ndarray,
    config: OFDMConfig,
    taps: np.ndarray | Iterable[complex] = (1.0 + 0.0j,),
    snr_db: float | None = None,
    rng: np.random.Generator | None = None,
) -> np.ndarray:
    """Apply a short multipath response plus a per-symbol structural phase."""
    tx = np.asarray(tx_grid, dtype=np.complex128)
    if tx.ndim != 2 or tx.shape[1] != config.n_fft:
        raise ValueError("tx_grid must have shape (symbols, n_fft)")
    response = multipath_frequency_response(taps, config)
    rx = tx * response[None, :] * np.exp(1j * np.asarray(phase_rad)[:, None])
    if snr_db is not None:
        generator = np.random.default_rng() if rng is None else rng
        power = float(np.mean(np.abs(rx) ** 2))
        noise_power = power / (10.0 ** (snr_db / 10.0))
        noise = np.sqrt(noise_power / 2.0) * (
            generator.standard_normal(rx.shape) + 1j * generator.standard_normal(rx.shape)
        )
        rx = rx + noise
    return rx


def estimate_channel_from_training(
    rx_grid: np.ndarray, tx_grid: np.ndarray, config: OFDMConfig
) -> np.ndarray:
    """Estimate the static frequency response from the first known symbol."""
    rx = np.asarray(rx_grid, dtype=np.complex128)
    tx = np.asarray(tx_grid, dtype=np.complex128)
    if rx.shape != tx.shape or rx.shape[1] != config.n_fft:
        raise ValueError("rx_grid and tx_grid must have matching frame shapes")
    channel = np.ones(config.n_fft, dtype=np.complex128)
    active = config.indices(config.active_bins)
    if np.any(np.abs(tx[0, active]) < 1e-12):
        raise ValueError("training symbol must be non-zero on active bins")
    channel[active] = rx[0, active] / tx[0, active]
    return channel


def equalize_frequency_response(rx_grid: np.ndarray, channel: np.ndarray) -> np.ndarray:
    """Equalize active subcarriers with a known or estimated response."""
    rx = np.asarray(rx_grid, dtype=np.complex128)
    h = np.asarray(channel, dtype=np.complex128)
    if rx.ndim != 2 or h.ndim != 1 or rx.shape[1] != h.size:
        raise ValueError("channel must have one coefficient per FFT bin")
    if np.any(np.abs(h) < 1e-12):
        raise ValueError("channel contains an un-equalizable zero")
    return rx / h[None, :]


def bit_error_rate(reference: np.ndarray, estimate: np.ndarray) -> float:
    """Return the fraction of unequal bits."""
    a = np.asarray(reference, dtype=np.uint8)
    b = np.asarray(estimate, dtype=np.uint8)
    if a.shape != b.shape or a.ndim != 1:
        raise ValueError("reference and estimate must be matching 1-D arrays")
    return float(np.mean(a != b))


def single_target_frequency_response(
    delay_samples: int,
    config: OFDMConfig,
    amplitude: float = 1.0,
    phase_rad: float = 0.0,
) -> np.ndarray:
    """Frequency response of one integer-delay digital reflection."""
    if not isinstance(delay_samples, (int, np.integer)) or not 0 <= delay_samples < config.cp_len:
        raise ValueError("delay_samples must be an integer in [0, cp_len)")
    if amplitude < 0.0 or not np.isfinite(amplitude) or not np.isfinite(phase_rad):
        raise ValueError("amplitude and phase_rad must be finite, with amplitude non-negative")
    taps = np.zeros(config.n_fft, dtype=np.complex128)
    taps[delay_samples] = amplitude * np.exp(1j * phase_rad)
    return np.fft.fft(taps)


def range_profile(channel: np.ndarray) -> np.ndarray:
    """Convert one FFT-bin channel response into delay/range bins."""
    response = np.asarray(channel, dtype=np.complex128)
    if response.ndim != 1 or response.size == 0:
        raise ValueError("channel must be a non-empty one-dimensional array")
    return np.fft.ifft(response)


def range_profile_from_training(
    rx_grid: np.ndarray, tx_grid: np.ndarray, config: OFDMConfig
) -> np.ndarray:
    """Form a sparse channel estimate from the training symbol, then IFFT it.

    Only the 52 active OFDM carriers are known in the present FPGA training
    frame.  Guard and DC bins are zeroed here to mirror the hardware path.
    """
    rx = np.asarray(rx_grid, dtype=np.complex128)
    tx = np.asarray(tx_grid, dtype=np.complex128)
    if rx.shape != tx.shape or rx.ndim != 2 or rx.shape[1] != config.n_fft:
        raise ValueError("rx_grid and tx_grid must have matching frame shapes")
    active = config.indices(config.active_bins)
    if np.any(np.abs(tx[0, active]) < 1e-12):
        raise ValueError("training symbol must be non-zero on active bins")
    channel = np.zeros(config.n_fft, dtype=np.complex128)
    channel[active] = rx[0, active] / tx[0, active]
    return range_profile(channel)


def delay_bin_distance_m(delay_samples: int, bandwidth_hz: float = 20e6) -> float:
    """Two-way radar distance associated with an integer OFDM delay bin."""
    if delay_samples < 0 or bandwidth_hz <= 0.0:
        raise ValueError("delay_samples must be non-negative and bandwidth_hz positive")
    speed_of_light_m_s = 299_792_458.0
    return delay_samples * speed_of_light_m_s / (2.0 * bandwidth_hz)
