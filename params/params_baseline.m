function p = params_baseline()
% PARAMS_BASELINE  Baseline (default) simulation parameters.
%
% References (equation and table numbers used in the comments below):
%   [Wei]      Wei et al. 2014, Exposure Time Optimization for Highly Dynamic Star Trackers
%              Eq. 2 (star signal from magnitude), Eq. 6 (PSF integrated over a pixel),
%              Eq. 7 (noise sum), Eq. 8 (SNR of second-type pixels), Eq. 9 (detection
%              magnitude Mv), Eq. 10 (stars per frame), Eq. 13 (gain), Table 2 (eta), Table 3
%   [Wan]      Wan et al. 2018, Star Centroiding Based on Fast Gaussian Fitting
%              Eq. 11 (phi(r)), Eq. 19-21 (pixel SNR and selection), Sec. 3.1-3.3
%   [Tang]     Tang et al. 2025, Multi-Centroid Extraction ... Star Trail, Sec. 4.1
%   [Trujillo] Trujillo et al., The effects of seeing on Sersic profiles II (Moffat), Eq. A1
%   [Nahlik]   Nahlik & Stys, Microscope point spread function ... (Airy disk)
%   [Liebe]    Liebe 2002, Accuracy Performance of Star Trackers - A Tutorial
%   [CMV4000]  ams CMV4000 image sensor datasheet

%% Sensor
p.sensor.pixel_pitch_um     = 5.5;    % [Tang] Sec. 4.1; [Wei] Table 3
p.sensor.array_px           = 2048;   % pixels per side (2048 x 2048); [Wei] Table 3; [CMV4000]
p.sensor.roi_size_px        = 7;      % N for an NxN ROI; assumed
% NOTE: 7x7 truncates the star at sigma = 1.5 px (+/-3 sigma spans ~9 px).
% Rule of thumb N >= 6*sigma + 1; [Wan] Sec. 3.1 used a 31x31 window.
p.sensor.adc_bits           = 10;     % [CMV4000] (10-bit mode; 12-bit also available)
% [Wei] Table 3 and [Tang] Sec. 4.1 simulate 8 bits, but the real CMV4000 has no 8-bit mode.
p.sensor.full_well_e        = 13500;  % sets saturation; [Wei] Table 3; [CMV4000]
p.sensor.gain_e_per_DN      = p.sensor.full_well_e / 2^p.sensor.adc_bits;  % ~13.18 e-/DN
% Full well maps to the top of the ADC range: [Wei] Eq. 13 (I_k = 2^q / N_well * S_k).
% Quantization noise = gain / sqrt(12) ~ 3.8 e- rms ([Wei] Table 1, n_ADC).
p.sensor.adc_max_DN         = 2^p.sensor.adc_bits - 1;  % 1023 DN; ADC clips at ~13,487 e-
p.sensor.black_level_DN     = 10;    % decision; noise floor is ~1-3 DN at 10 bits, so ~10 DN is enough
% With a 10 DN black level the ADC ceiling is (1023 - 10) x gain ~ 13,355 e-.
p.sensor.qe                 = 0.6;    % quantum efficiency x fill factor (0 to 1); [Wei] Table 3
% qe enters only the magnitude-to-electron conversion ([Wei] Eq. 2); signal_e is already in electrons.
p.sensor.roundRule          = 'round';     % decision: 'round' or 'floor'
p.sensor.pixelCoordRule     = 'integer';     % decision: pixel-centre convention (papers differ); keep one everywhere

%% Optics
p.optics.focal_length_mm    = 42;     % [Tang] Sec. 4.1 ([Wei] Table 3 uses 44.16 mm)
% Our sensor combines [Tang]'s optics with [Wei]'s detector.
p.optics.aperture_dia_mm    = 40;     % [Wei] Table 3
p.optics.transmittance      = 0.85;   % optical transmittance (0 to 1); [Wei] Table 3
p.optics.plate_scale_arcsec = (p.sensor.pixel_pitch_um * 1e-3 / p.optics.focal_length_mm) * 206265;  % ~27.0 arcsec/px
p.optics.fov_deg            = 2 * atand(p.sensor.array_px * p.sensor.pixel_pitch_um * 1e-3 / 2 ...
                                        / p.optics.focal_length_mm);  % ~15.3 deg (square FOV side)

%% PSF
p.psf.modelRule             = 'gaussian';  % 'gaussian', 'moffat' or 'airy'
p.psf.sigma_px              = 0.7;    % PSF width (Gaussian radius = sigma); [Wei] Table 3
p.psf.moffat_beta           = 2.5;    % [Trujillo]
p.psf.fwhm_factor           = 2.355;  % FWHM = fwhm_factor * sigma, used to match PSF shapes; [Trujillo] Eq. A1
p.psf.airy_width            = 'fwhm';    % TBD: matched by FWHM, or from wavelength and f-number; [Nahlik]
p.psf.subpixel_grid_n       = NaN;    % decision; sub-points per pixel side (M), Moffat and Airy only
% Pixel integration follows [Wei] Eq. 6. Choose M by comparing Gaussian sub-grid
% integration against the exact erf values.

%% Star
p.star.signal_e             = 5000;   % total electrons per star (sweep this to vary SNR)
% Baseline stays below full well for every PSF in params_sweeps.
% Centered star at sigma = 0.5 px puts ~46.6% of S in the peak pixel.
% At 10 bits the ADC clips at ~13,487 e-, so S must stay below ~28,900 e-
% without offset, or ~28,700 e- with a 10 DN black level.
% True centroid is drawn per trial, uniform within the central pixel
% (see generate_spot); [Wan] Sec. 3.3.

%% Noise
p.noise.dark_current_e_per_s = 125;   % electrons per pixel per second at 25 C; [Wei] Table 3; [CMV4000]
p.noise.exposure_ms          = 100;   % [Tang] Sec. 4.1; must not exceed the frame period (see update_rate_Hz)
p.noise.read_noise_e         = 13;    % electrons rms ("temporal noise"); [Wei] Table 3; [CMV4000]
p.noise.fpn_e                = 35;    % fixed pattern noise rms; [Wei] Table 3 (worst case;
                                      % [CMV4000] bound is < 1 LSB, ~13.5 e-). Set to 0 to turn off.
p.noise.fpnRule              = 'random';  % decided: new random FPN map every trial ([Wei] Eq. 7 treatment)
p.noise.prnu                 = 0.01;  % photo-response non-uniformity (fraction); [Wei] Table 3. Set to 0 to turn off.
p.noise.prnuRule             = 'random';    % decision: 'random' (per trial) or 'fixed' (one map for all trials)
p.noise.bg_level_e           = 0;   % decision; nominal background electrons per pixel per frame
% Options: 0, or zodiacal light ~1-4 e-/px per 100 ms (cite Leinert et al. 1998).
% Raised background for the disturbance sweep is set in params_sweeps (k multiples).
p.noise.bgSubtractionRule    = 'known';   % decided: processor is given the true mean; subtraction failure is out of scope
% Switches for validation tests (FPN and PRNU are turned off by setting their value to 0)
p.noise.enableShot           = true;
p.noise.enableRead           = true;
p.noise.enableDark           = true;
p.noise.enableQuant          = true;
% Chain order (apply_noise_chain): dark + background -> PRNU -> Poisson -> full-well clip
%   -> FPN + read noise -> gain, black level, rounding -> ADC clip

% Noise floor (no star, no background): [Wei] Eq. 7 without the signal terms.
% Used for the background sweep (sigma_0) and the detection limit below.
p.noise.dark_e               = p.noise.dark_current_e_per_s * p.noise.exposure_ms / 1000;  % 12.5 e-
p.noise.noise_floor_e        = sqrt(p.noise.dark_e + p.noise.read_noise_e^2 + p.noise.fpn_e^2 ...
                                    + p.sensor.gain_e_per_DN^2 / 12);  % ~37.7 e- (n_DC, n_TN, n_FPN, n_ADC)

%% Detection
p.detect.snrRule             = 'wei_eq8';    % decision: 'wei_eq8', 'liebe' or 'integrated' (truth SNR for plots)
p.detect.neighbourRule       = 'four';  % second-type pixels for a static star: 'four' (side neighbours) or 'eight'
% Note: [Wei] Eq. 8 uses the second-type pixels next to the brightest, not the peak pixel.
p.detect.detect_threshold    = 5;     % V_sn, minimum SNR to count as a star; [Wei] Table 3 ([Liebe] uses 5 sigma)

% Star brightness model, [Wei] Eq. 2:
%   mu_0 = tau_A * tau_0 * E_0 * 2.512^(-Mv) * (pi D^2 / 4) * T_e * QE * K_fill / E_ph
p.detect.e0_W_per_mm2        = 2.96e-14;  % flux of a magnitude-0 star; [Wei] after Eq. 2
p.detect.tau_atm             = 1.0;   % atmospheric transmissivity; 1 in orbit ([Wei] Table 3 uses 0.9 for ground tests)
p.detect.wavelength_nm       = 550;   % assumption: mean photon wavelength for E_ph ([Wei] does not state E_ph)
p.detect.photon_energy_J     = 6.626e-34 * 2.998e8 / (p.detect.wavelength_nm * 1e-9);  % E_ph ~ 3.6e-19 J
p.detect.mag0_e              = p.detect.tau_atm * p.optics.transmittance * p.detect.e0_W_per_mm2 ...
                               * (pi * p.optics.aperture_dia_mm^2 / 4) * (p.noise.exposure_ms / 1000) ...
                               * p.sensor.qe / p.detect.photon_energy_J;  % ~5.2e6 e- for a magnitude-0 star
% Label any signal S with a magnitude: Mv = -2.5 * log10(S / mag0_e).

% Detection magnitude, [Wei] Eq. 9 (solves [Wei] Eq. 8 for the faintest detectable star):
p.detect.eta                 = 0.0831;  % second-type pixel share of mu_0 for a static star (trail length 0); [Wei] Table 2
V  = p.detect.detect_threshold;
P  = p.noise.prnu;
R2 = p.noise.noise_floor_e^2;           % n_DC^2 + n_TN^2 + n_FPN^2 + n_ADC^2
s2nd_e = (V^2 + sqrt(V^4 + 4 * (1 - V^2 * P^2) * V^2 * R2)) / (2 * (1 - V^2 * P^2));  % ~202 e- per second-type pixel
p.detect.mv_limit            = log(p.detect.mag0_e * p.detect.eta / s2nd_e) / log(2.512);  % ~8.3
p.detect.min_signal_e        = s2nd_e / p.detect.eta;  % ~2,430 e-: faintest detectable star (total signal)
% Stars below min_signal_e (e.g. S = 1,000 in the main sweep) are below the detection threshold:
% treat them as a stress case, not a normal faint star.

%% Centroiding
p.centroid.fgf_T             = 3;     % Fast GF keeps pixels with estimated SNR > T; [Wan] Eq. 21, Sec. 3.2
% phi(r) stays within (0.81, 1.15) for SNR > 3; [Wan] Eq. 11, Fig. 2.
p.centroid.fgf_min_px        = 5;     % Fast GF needs at least this many pixels; [Wan] Sec. 2.4, Sec. 3.2
p.centroid.gfInitGuessRule   = '';    % decision: e.g. 'cg' (use the CG result)
p.centroid.gf_tol_px         = NaN;   % decision; standard GF stopping tolerance (e.g. 1e-6 px)
p.centroid.gf_max_iter       = NaN;   % decision; standard GF iteration limit (e.g. 50)
p.centroid.negPixelRule      = '';    % decision: 'clip' or 'keep', same for CG and WCG

%% Supervisor (thresholds tuned from Stage 5 results)
p.supervisor.snr_switch      = NaN;   % estimated SNR below which the supervisor falls back from Fast GF ([Wan] Eq. 19-20)
p.supervisor.valid_px_min    = NaN;   % minimum valid pixels before falling back
p.supervisor.saturation_DN   = NaN;   % pixel code treated as saturated (e.g. adc_max_DN)
p.supervisor.outlierRule     = '';    % decision: outlier test method

%% Metrics
p.metrics.errorRule          = 'both';  % RMS radial error (proposal) and mean Euclidean error ([Wan] Sec. 3.3)

%% Simulation
p.sim.n_trials               = 10000; % Monte Carlo trials per setting; [Wan] Sec. 3.3
p.sim.seed                   = 123;   % base seed, fixed for reproducibility
% Per-setting seed = base seed + setting index, so any setting can be rerun alone.
p.sim.tuning_seed            = NaN;   % decision; seed set used to tune supervisor thresholds
p.sim.test_seed              = NaN;   % decision; separate seed set used to report results

%% Processor
p.proc.coreRule              = 'STM32F401CCU6 (Cortex-M4F)';  % two boards used; document the split
p.proc.clock_MHz             = 84;    % STM32F401xC datasheet
p.proc.update_rate_Hz        = 1;     % default; frame period = 1000/rate ms. 1 Hz so the
                                      % 100 ms exposure fits; 1, 5 and 10 Hz are swept in params_sweeps.

%% Timing
% Stars per frame, [Wei] Eq. 10: N_star = 6.57 * e^(1.08 Mv) * (1 - cos(A / sqrt(pi))) / 2
% A in degrees here (cosd). Static sensor, consistent with the stationary spot model.
p.timing.stars_per_frame     = 6.57 * exp(1.08 * p.detect.mv_limit) ...
                               * (1 - cosd(p.optics.fov_deg / sqrt(pi))) / 2;  % ~290-300
% Mv depends on exposure, so recompute N_star for each update rate's exposure.
% Sensitivity check: ~33 stars at Mv ~ 6.3 ([Wei] Fig. 4a-b, 1 deg/s), see params_sweeps.
p.timing.cpu_share           = 0.5;   % fraction of CPU time allowed for centroiding (0 to 1); assumed
p.timing.budget_cycles       = (1 / p.proc.update_rate_Hz) * p.timing.cpu_share ...
                               * p.proc.clock_MHz * 1e6 / p.timing.stars_per_frame;  % per centroid
% Computed: Mv ~ 8.34 and N_star ~ 302 (291 if Mv is rounded to 8.3 and A to 15.3 deg).
% At ~300 stars: ~139 k / 28 k / 14 k cycles at 1 / 5 / 10 Hz.
end