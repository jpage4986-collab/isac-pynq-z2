from __future__ import annotations

import numpy as np

from model.fixed_point import (
    complex_evm,
    complex_mul_q15,
    dequantize_complex_q15,
    dequantize_q15,
    normalize_for_q15,
    quantize_complex_q15,
    quantize_q15,
)
from model.ofdm import OFDMConfig, bit_error_rate, build_tx_frame, extract_data_bits, ofdm_demodulate, ofdm_modulate


def test_q15_real_round_trip_has_half_lsb_error() -> None:
    values = np.linspace(-0.99, 0.99, 1001)
    recovered = dequantize_q15(quantize_q15(values))
    assert np.max(np.abs(values - recovered)) <= 1.0 / (1 << 15)


def test_q15_complex_multiply_matches_float_reference() -> None:
    a = np.array([0.5 + 0.25j, -0.2 + 0.4j])
    b = np.array([0.75 - 0.1j, 0.3 + 0.2j])
    ai, aq = quantize_complex_q15(a)
    bi, bq = quantize_complex_q15(b)
    ci, cq = complex_mul_q15(ai, aq, bi, bq)
    recovered = dequantize_complex_q15(ci, cq)
    assert np.max(np.abs(recovered - a * b)) < 3.0 / (1 << 15)


def test_q15_time_waveform_preserves_ofdm_bits() -> None:
    config = OFDMConfig(n_data_symbols=4)
    bits = np.arange(config.n_bits_per_frame, dtype=np.uint8) % 2
    tx_grid = build_tx_frame(bits, config)
    tx_samples = ofdm_modulate(tx_grid, config)
    scaled, gain = normalize_for_q15(tx_samples)
    i_values, q_values = quantize_complex_q15(scaled)
    recovered_samples = dequantize_complex_q15(i_values, q_values) / gain
    recovered_grid = ofdm_demodulate(recovered_samples, config)
    recovered_bits = extract_data_bits(recovered_grid, config)
    assert bit_error_rate(bits, recovered_bits) == 0.0
    assert complex_evm(tx_samples, recovered_samples) < 1e-3
