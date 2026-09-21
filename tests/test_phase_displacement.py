import numpy as np
from model.phase_displacement import WAVELENGTH_M, dominant_frequency, displacement_from_phase, phase_from_displacement, recover_incremental_displacement

def test_phase_displacement_round_trip():
    displacement = np.array([-2e-4, 0.0, 2e-4])
    assert np.allclose(displacement_from_phase(phase_from_displacement(displacement)), displacement)

def test_incremental_recovery_has_expected_sign_and_scale():
    displacement = np.linspace(0.0, 0.0005, 100)
    z = np.exp(1j * phase_from_displacement(displacement))
    recovered = recover_incremental_displacement(z)
    assert np.max(np.abs((recovered - recovered[0]) - displacement)) < 5e-7
    assert WAVELENGTH_M > 0.05

def test_frequency_estimate():
    fs = 100.0
    n = 4096
    t = np.arange(n) / fs
    estimate = dominant_frequency(np.sin(2 * np.pi * 2.4 * t), fs)
    assert abs(estimate - 2.4) < 0.05
