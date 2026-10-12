function p = params_baseline()
% PARAMS_BASELINE  Baseline (default) simulation parameters.

%% Sensor
p.sensor.pixelPitch_um     = 5.5;   % source: Tang et al.
p.sensor.roiSize_px        = 7;     % N for an NxN ROI, source: assumed
p.sensor.adcBits           = 8;     % source: Tang et al.
p.sensor.fullWell_e        = 13500; % sets saturation, source: Wei et al.
p.sensor.gain_eperDN       = 52.7;  % electrons per digital number, source: derived at Wei et al.
p.sensor.qe                = 0.6;   % quantum efficiency (0 to 1), source: Wei et al.

%% Optics
p.optics.focalLength_mm    = 42;    % source: Tang et al.
p.psf.model                = 'gaussian';
p.psf.sigma_px             = 0.7;   % PSF width, source: Wei et al.
% p.psf.<extra params for non-Gaussian shapes>

%% Star
p.star.signal_e            = 5000;   % total electrons per star (sweep this to vary SNR)
% total electrons per star avoids saturation with given ADC and Dark
% Current specifications
% True centroid is drawn per trial (see generate_spot), not stored here.

%% Noise
p.noise.darkCurrent_eps    = 125;   % electrons per pixel per second, source: Wei et al.
p.noise.exposure_ms        = 100;   % source: Tang et al.
p.noise.readNoise_e        = 13;   % electrons rms, source: Wei et al.
p.noise.enableShot         = true;  % switches for validation tests
p.noise.enableRead         = true;
p.noise.enableDark         = true;
p.noise.enableQuant        = true;

%% Simulation
p.sim.nTrials              = 10000;   % Monte Carlo trials per setting
p.sim.seed                 = 123;   % fixed for reproducibility

%% Processor (cost estimates, fill in later)
p.proc.coreName            = '';
p.proc.clock_MHz           = NaN;
p.proc.updateRate_Hz       = NaN;   % real-time budget; ms per frame = 1000/rate

end