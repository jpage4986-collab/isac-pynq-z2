from __future__ import annotations

import numpy as np

from model.ofdm import (
    OFDMConfig,
    apply_common_phase_channel,
    build_tx_frame,
    correct_common_phase,
    estimate_common_phase,
    extract_data_bits,
    ofdm_demodulate,
    ofdm_modulate,
    qpsk_demod,
    qpsk_mod,
    vibration_trace,
)
from model.phase_displacement import displacement_from_phase


def test_qpsk_mapper_round_trip() -> None:
    bits = np.array([0, 0, 0, 1, 1, 0, 1, 1], dtype=np.uint8)
    assert np.array_equal(qpsk_demod(qpsk_mod(bits)), bits)


def test_ofdm_frame_round_trip() -> None:
    config = OFDMConfig(n_data_symbols=3)
    bits = np.arange(config.n_bits_per_frame, dtype=np.uint8) % 2
    tx_grid = build_tx_frame(bits, config)
    rx_grid = ofdm_demodulate(ofdm_modulate(tx_grid, config), config)
    recovered = extract_data_bits(rx_grid, config)
    assert np.allclose(rx_grid, tx_grid, atol=1e-12)
    assert np.array_equal(recovered, bits)


def test_phase_estimation_recovers_vibration() -> None:
    config = OFDMConfig(n_data_symbols=64)
    bits = np.zeros(config.n_bits_per_frame, dtype=np.uint8)
    tx_grid = build_tx_frame(bits, config)
    _, displacement, phase = vibration_trace(
        config, symbol_rate_hz=100.0, amplitude_m=1e-3, frequency_hz=2.0
    )
    rx_grid = apply_common_phase_channel(tx_grid, phase)
    estimated_phase = estimate_common_phase(rx_grid, tx_grid, config)
    recovered = displacement_from_phase(estimated_phase)
    assert np.max(np.abs(recovered - displacement)) < 1e-12


def test_phase_correction_recovers_bits_with_noise() -> None:
    config = OFDMConfig(n_data_symbols=12)
    rng = np.random.default_rng(20260922)
    bits = rng.integers(0, 2, config.n_bits_per_frame, dtype=np.uint8)
    tx_grid = build_tx_frame(bits, config)
    phase = np.linspace(-0.8, 0.8, config.n_ofdm_symbols)
    rx_grid = apply_common_phase_channel(tx_grid, phase, snr_db=35.0, rng=rng)
    estimated_phase = estimate_common_phase(rx_grid, tx_grid, config)
    corrected = correct_common_phase(rx_grid, estimated_phase)
    recovered = extract_data_bits(corrected, config)
    assert np.mean(recovered != bits) < 0.01
