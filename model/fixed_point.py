"""Q1.15 helpers used to bridge the NumPy model and FPGA arithmetic."""
from __future__ import annotations

from typing import Tuple

import numpy as np

Q15_FRAC_BITS = 15
Q15_SCALE = 1 << Q15_FRAC_BITS
Q15_MIN = -32768
Q15_MAX = 32767


def quantize_q15(values: np.ndarray | float) -> np.ndarray:
    """Round signed real values to saturating Q1.15 int16."""
    x = np.asarray(values, dtype=float)
    return np.clip(np.rint(x * Q15_SCALE), Q15_MIN, Q15_MAX).astype(np.int16)


def dequantize_q15(values: np.ndarray) -> np.ndarray:
    """Convert Q1.15 int16 values back to floating point."""
    return np.asarray(values, dtype=np.int16).astype(np.float64) / Q15_SCALE


def quantize_complex_q15(values: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """Return separate signed Q1.15 I and Q arrays."""
    z = np.asarray(values, dtype=np.complex128)
    return quantize_q15(z.real), quantize_q15(z.imag)


def dequantize_complex_q15(i_values: np.ndarray, q_values: np.ndarray) -> np.ndarray:
    """Recombine separate Q1.15 I/Q arrays into complex floating point."""
    i = dequantize_q15(i_values)
    q = dequantize_q15(q_values)
    if i.shape != q.shape:
        raise ValueError("I and Q arrays must have the same shape")
    return i + 1j * q


def complex_mul_q15(
    a_i: np.ndarray, a_q: np.ndarray, b_i: np.ndarray, b_q: np.ndarray
) -> Tuple[np.ndarray, np.ndarray]:
    """Multiply two Q1.15 complex vectors with rounded saturation."""
    ai = np.asarray(a_i, dtype=np.int64)
    aq = np.asarray(a_q, dtype=np.int64)
    bi = np.asarray(b_i, dtype=np.int64)
    bq = np.asarray(b_q, dtype=np.int64)
    if not (ai.shape == aq.shape == bi.shape == bq.shape):
        raise ValueError("all Q1.15 operands must have the same shape")
    real = (ai * bi - aq * bq + (1 << (Q15_FRAC_BITS - 1))) >> Q15_FRAC_BITS
    imag = (ai * bq + aq * bi + (1 << (Q15_FRAC_BITS - 1))) >> Q15_FRAC_BITS
    return (
        np.clip(real, Q15_MIN, Q15_MAX).astype(np.int16),
        np.clip(imag, Q15_MIN, Q15_MAX).astype(np.int16),
    )


def normalize_for_q15(values: np.ndarray, headroom: float = 0.8) -> Tuple[np.ndarray, float]:
    """Scale a complex waveform below full scale before Q1.15 conversion."""
    if not 0.0 < headroom <= 1.0:
        raise ValueError("headroom must be in (0, 1]")
    z = np.asarray(values, dtype=np.complex128)
    peak = float(np.max(np.abs(z))) if z.size else 0.0
    gain = 1.0 if peak == 0.0 else headroom / peak
    return z * gain, gain


def complex_evm(reference: np.ndarray, estimate: np.ndarray) -> float:
    """Return RMS error divided by RMS reference magnitude."""
    ref = np.asarray(reference, dtype=np.complex128)
    est = np.asarray(estimate, dtype=np.complex128)
    if ref.shape != est.shape:
        raise ValueError("reference and estimate must have the same shape")
    denominator = float(np.sqrt(np.mean(np.abs(ref) ** 2)))
    return 0.0 if denominator == 0.0 else float(np.sqrt(np.mean(np.abs(ref - est) ** 2)) / denominator)
