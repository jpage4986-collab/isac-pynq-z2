from __future__ import annotations

import numpy as np

from model.ofdm import (
    OFDMConfig,
    apply_common_phase_channel,
    apply_multipath_channel,
    build_tx_frame,
    correct_common_phase,
    estimate_common_phase,
    estimate_channel_from_training,
    extract_data_bits,
    equalize_frequency_response,
    ofdm_demodulate,
    ofdm_modulate,
    qpsk_demod,
    bit_error_rate,
    qpsk_mod,
    vibration_trace,
    single_target_frequency_response,
    range_profile,
    range_profile_from_training,
    delay_bin_distance_m,
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


def test_training_equalizer_handles_multipath_and_noise() -> None:
    config = OFDMConfig(n_data_symbols=16)
    rng = np.random.default_rng(20260922)
    bits = rng.integers(0, 2, config.n_bits_per_frame, dtype=np.uint8)
    tx_grid = build_tx_frame(bits, config)
    phase = np.linspace(-0.4, 0.4, config.n_ofdm_symbols)
    taps = np.array([1.0 + 0.0j, 0.35 * np.exp(1j * 0.6), 0.15j])
    rx_grid = apply_multipath_channel(tx_grid, phase, config, taps=taps, snr_db=30.0, rng=rng)
    channel = estimate_channel_from_training(rx_grid, tx_grid, config)
    equalized = equalize_frequency_response(rx_grid, channel)
    residual_phase = estimate_common_phase(equalized, tx_grid, config)
    corrected = correct_common_phase(equalized, residual_phase)
    recovered = extract_data_bits(corrected, config)
    assert bit_error_rate(bits, recovered) < 0.01


def test_integer_delay_target_has_correct_range_peak() -> None:
    config = OFDMConfig()
    response = single_target_frequency_response(5, config, amplitude=0.6, phase_rad=0.3)
    profile = range_profile(response)
    assert int(np.argmax(np.abs(profile))) == 5
    assert np.isclose(np.abs(profile[5]), 0.6)
    assert np.count_nonzero(np.abs(profile) > 1e-12) == 1
    assert np.isclose(delay_bin_distance_m(5), 37.47405725)


def test_training_range_profile_detects_delay_with_guard_bins_zeroed() -> None:
    config = OFDMConfig()
    bits = np.zeros(config.n_bits_per_frame, dtype=np.uint8)
    tx_grid = build_tx_frame(bits, config)
    response = single_target_frequency_response(5, config, amplitude=0.6, phase_rad=0.3)
    rx_grid = tx_grid * response[None, :]
    profile = range_profile_from_training(rx_grid, tx_grid, config)
    assert int(np.argmax(np.abs(profile))) == 5
    # 52 of 64 range-IFFT inputs contain the measured channel response.
    assert np.isclose(np.abs(profile[5]), 0.6 * 52.0 / 64.0)


def test_shared_training_channel_equalizes_qpsk_and_reports_range() -> None:
    """One delayed channel serves both the QPSK and sensing reference paths."""
    config = OFDMConfig(n_data_symbols=4)
    rng = np.random.default_rng(20260923)
    bits = rng.integers(0, 2, config.n_bits_per_frame, dtype=np.uint8)
    tx_grid = build_tx_frame(bits, config)
    response = single_target_frequency_response(5, config)
    rx_grid = tx_grid * response[None, :]
    channel = estimate_channel_from_training(rx_grid, tx_grid, config)
    recovered = extract_data_bits(equalize_frequency_response(rx_grid, channel), config)
    profile = range_profile_from_training(rx_grid, tx_grid, config)
    assert bit_error_rate(bits, recovered) == 0.0
    assert int(np.argmax(np.abs(profile))) == 5
