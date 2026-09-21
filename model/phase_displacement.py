"""Reference equations for incremental phase displacement recovery."""
from __future__ import annotations
import numpy as np

CARRIER_HZ = 5.8e9
C_LIGHT = 299_792_458.0
WAVELENGTH_M = C_LIGHT / CARRIER_HZ

def phase_from_displacement(displacement_m: np.ndarray | float) -> np.ndarray:
    """Round-trip phase; away from radar is positive displacement."""
    return -4.0 * np.pi * np.asarray(displacement_m) / WAVELENGTH_M

def displacement_from_phase(phase_rad: np.ndarray | float) -> np.ndarray:
    """Inverse mapping for the same convention."""
    return -WAVELENGTH_M * np.asarray(phase_rad) / (4.0 * np.pi)

def recover_incremental_displacement(z: np.ndarray, reference_m: float = 0.0) -> np.ndarray:
    """Recover relative displacement from target-gate complex samples."""
    z = np.asarray(z, dtype=np.complex128)
    if z.ndim != 1 or z.size == 0:
        raise ValueError("z must be a non-empty one-dimensional complex array")
    increments = np.angle(z[1:] * np.conj(z[:-1]))
    phase = np.concatenate(([0.0], np.cumsum(increments)))
    return reference_m + displacement_from_phase(phase)

def dominant_frequency(signal: np.ndarray, sample_rate_hz: float = 100.0) -> float:
    """Estimate a dominant non-DC frequency using an rFFT peak bin."""
    x = np.asarray(signal, dtype=float)
    if x.ndim != 1 or x.size < 4:
        raise ValueError("signal must be a one-dimensional array with at least 4 samples")
    x = x - np.mean(x)
    window = np.hanning(x.size)
    spectrum = np.abs(np.fft.rfft(x * window)) ** 2
    spectrum[0] = 0.0
    idx = int(np.argmax(spectrum))
    return float(np.fft.rfftfreq(x.size, 1.0 / sample_rate_hz)[idx])
