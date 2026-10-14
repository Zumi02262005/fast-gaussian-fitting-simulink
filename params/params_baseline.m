function p = params_baseline()
% PARAMS_BASELINE  Baseline (default) simulation parameters.
%% Sensor
p.sensor.pixelPitch_um     = 5.5;   % source: Tang et al.; Wei et al. (same value)
p.sensor.roiSize_px        = 7;     % N for an NxN ROI, source: assumed
% NOTE: 7x7 truncates the star at sigma = 1.5 px (+/-3 sigma spans ~9 px).
% Rule of thumb N >= 6*sigma + 1; Wan et al. used a 31x31 window.
p.sensor.adcBits           = 8;     % source: Tang et al.; Wei et al.
p.sensor.fullWell_e        = 13500; % sets saturation, source: Wei et al.
p.sensor.gain_eperDN       = 52.7;  % electrons per DN, derived: fullWell_e / 2^adcBits (Wei et al. values)
p.sensor.qe                = 0.6;   % quantum efficiency x fill factor (0 to 1), source: Wei et al.
%% Optics
p.optics.focalLength_mm    = 42;    % source: Tang et al. (Wei et al. uses 44.16 mm)
p.psf.model                = 'gaussian';
p.psf.sigma_px             = 0.7;   % PSF width (Gaussian radius = sigma), source: Wei et al.
% p.psf.<extra params for non-Gaussian shapes>
%% Star
p.star.signal_e            = 5000;  % total electrons per star (sweep this to vary SNR)
% Baseline stays below full well for every PSF in params_sweeps.
% Centered star at sigma = 0.5 px puts ~46.6% of S in the peak pixel,
% so S must stay below ~28,000 e- to avoid saturation.
% True centroid is drawn per trial, uniform within the central pixel
% (see generate_spot), source: Wan et al.
%% Noise
p.noise.darkCurrent_eps    = 125;   % electrons per pixel per second, source: Wei et al.
p.noise.exposure_ms        = 100;   % source: Tang et al.
p.noise.readNoise_e        = 13;    % electrons rms ("temporal noise"), source: Wei et al.
p.noise.enableShot         = true;  % switches for validation tests
p.noise.enableRead         = true;
p.noise.enableDark         = true;
p.noise.enableQuant        = true;
%% Simulation
p.sim.nTrials              = 10000; % Monte Carlo trials per setting, source: Wan et al.
p.sim.seed                 = 123;   % fixed for reproducibility
%% Processor (cost estimates, fill in later)
p.proc.coreName            = '';
p.proc.clock_MHz           = NaN;
p.proc.updateRate_Hz       = NaN;   % real-time budget; ms per frame = 1000/rate
end