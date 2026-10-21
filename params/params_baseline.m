function p = params_baseline()
% PARAMS_BASELINE  Baseline (default) simulation parameters

%% Sensor
p.sensor.pixel_pitch_um     = 5.5;    % source: Tang et al.; Wei et al. (same value)
p.sensor.roi_size_px        = 7;      % N for an NxN ROI, source: assumed
% NOTE: 7x7 truncates the star at sigma = 1.5 px (+/-3 sigma spans ~9 px).
% Rule of thumb N >= 6*sigma + 1; Wan et al. used a 31x31 window.
p.sensor.adc_bits           = 10;     % source: CMV4000 datasheet (10-bit mode; 12-bit also available)
% Wei et al. and Tang et al. simulate 8 bits, but the real CMV4000 has no 8-bit mode.
p.sensor.full_well_e        = 13500;  % sets saturation, source: Wei et al.; CMV4000 datasheet
p.sensor.gain_e_per_DN      = p.sensor.full_well_e / 2^p.sensor.adc_bits;  % ~13.18 e-/DN at 10 bits
% Assumes full well maps to the top of the ADC range (our assumption, not stated by Wei et al.).
% Quantization noise = gain / sqrt(12) ~ 3.8 e- rms at 10 bits.
p.sensor.adc_max_DN         = 2^p.sensor.adc_bits - 1;  % 1023 DN; ADC clips at ~13,487 e-
p.sensor.black_level_DN     = NaN;    % decision; noise floor is ~1 DN at 10 bits, so ~5-10 DN is enough
p.sensor.qe                 = 0.6;    % quantum efficiency x fill factor (0 to 1), source: Wei et al.
% qe is used only to convert star magnitudes to electrons; signal_e is already in electrons.
p.sensor.roundRule          = '';     % decision: 'round' or 'floor'

%% Optics
p.optics.focal_length_mm    = 42;     % source: Tang et al. (Wei et al. uses 44.16 mm)
% Our sensor combines Tang et al.'s optics with Wei et al.'s detector.
p.optics.aperture_dia_mm    = 40;     % source: Wei et al.
p.optics.transmittance      = 0.85;   % optical transmittance (0 to 1), source: Wei et al.
p.optics.plate_scale_arcsec = (p.sensor.pixel_pitch_um * 1e-3 / p.optics.focal_length_mm) * 206265;  % ~27.0 arcsec/px

%% PSF
p.psf.modelRule             = 'gaussian';  % 'gaussian', 'moffat' or 'airy'
p.psf.sigma_px              = 0.7;    % PSF width (Gaussian radius = sigma), source: Wei et al.
p.psf.moffat_beta           = 2.5;    % source: Trujillo et al.
p.psf.fwhm_factor           = 2.355;  % FWHM = fwhm_factor * sigma, used to match PSF shapes; source: Trujillo et al.
p.psf.airy_width            = NaN;    % TBD: matched by FWHM, or from wavelength and f-number
p.psf.subpixel_grid_n       = NaN;    % decision; sub-points per pixel side (e.g. 10 for 10x10), Moffat and Airy only

%% Star
p.star.signal_e             = 5000;   % total electrons per star (sweep this to vary SNR)
% Baseline stays below full well for every PSF in params_sweeps.
% Centered star at sigma = 0.5 px puts ~46.6% of S in the peak pixel.
% At 10 bits the ADC clips at ~13,487 e-, so S must stay below ~28,900 e-
% without offset, or ~28,700 e- with a 10 DN black level.
% True centroid is drawn per trial, uniform within the central pixel
% (see generate_spot), source: Wan et al.

%% Noise
p.noise.dark_current_e_per_s = 125;   % electrons per pixel per second at 25 C, source: Wei et al.; CMV4000 datasheet
p.noise.exposure_ms          = 100;   % source: Tang et al.; must not exceed the frame period (see update_rate_Hz)
p.noise.read_noise_e         = 13;    % electrons rms ("temporal noise"), source: Wei et al.; CMV4000 datasheet
p.noise.fpn_e                = 35;    % fixed pattern noise rms, source: Wei et al. (worst case;
                                      % CMV4000 datasheet bound is < 1 LSB, ~13.5 e-). Set to 0 to turn off.
p.noise.prnu                 = 0.01;  % photo-response non-uniformity (fraction), source: Wei et al. Set to 0 to turn off.
p.noise.bg_level_e           = NaN;   % decision; baseline background electrons per pixel
p.noise.bgSubtractionRule    = '';    % decision: 'known' (mean given) or 'border' (estimated from ROI border pixels)
% Switches for validation tests (FPN and PRNU are turned off by setting their value to 0)
p.noise.enableShot           = true;
p.noise.enableRead           = true;
p.noise.enableDark           = true;
p.noise.enableQuant          = true;

%% Detection
p.detect.snrRule             = '';    % decision: 'wei_eq8', 'liebe' or 'integrated'
p.detect.detect_threshold    = 5;     % minimum SNR to count as a star, source: Wei et al. (Liebe uses 5 sigma)

%% Centroiding
p.centroid.fgf_T             = 3;     % Fast GF keeps pixels with estimated SNR > T, source: Wan et al.
p.centroid.fgf_min_px        = 5;     % Fast GF needs at least this many pixels, source: Wan et al.
p.centroid.gfInitGuessRule   = '';    % decision: e.g. 'cg' (use the CG result)
p.centroid.gf_tol_px         = NaN;   % decision; standard GF stopping tolerance (e.g. 1e-6 px)
p.centroid.gf_max_iter       = NaN;   % decision; standard GF iteration limit (e.g. 50)
p.centroid.negPixelRule      = '';    % decision: 'clip' or 'keep', same for CG and WCG

%% Supervisor (thresholds tuned from Stage 5 results)
p.supervisor.snr_switch      = NaN;   % SNR below which the supervisor falls back from Fast GF
p.supervisor.valid_px_min    = NaN;   % minimum valid pixels before falling back
p.supervisor.saturation_e    = NaN;   % pixel level treated as saturated
p.supervisor.outlierRule     = '';    % decision: outlier test method

%% Simulation
p.sim.n_trials               = 10000; % Monte Carlo trials per setting, source: Wan et al.
p.sim.seed                   = 123;   % base seed, fixed for reproducibility
% Per-setting seed = base seed + setting index, so any setting can be rerun alone.
p.sim.tuning_seed            = NaN;   % decision; seed set used to tune supervisor thresholds
p.sim.test_seed              = NaN;   % decision; separate seed set used to report results

%% Processor
p.proc.coreRule              = 'STM32F401CCU6 (Cortex-M4F)';
p.proc.clock_MHz             = 84;    % source: STM32F401xC datasheet
p.proc.update_rate_Hz        = 1;     % default; frame period = 1000/rate ms. 1 Hz so the
                                      % 100 ms exposure fits; 1, 5 and 10 Hz are swept in params_sweeps.

%% Timing
p.timing.stars_per_frame     = NaN;   % compute from Wei et al. Eq. 10
p.timing.cpu_share           = 0.5;   % fraction of CPU time allowed for centroiding (0 to 1)
end