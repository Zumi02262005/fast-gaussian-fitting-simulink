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
p.sensor.bl_offset         = Nan;   % a few DN e.g. DN = 10
p.sensor.roundRule         = Nan;   % round or floor
p.sensor.adcMaxCode        = 255;   % in DN, clips at 13440 e-


%% Optics
p.optics.focalLength_mm    = 42;    % source: Tang et al. (Wei et al. uses 44.16 mm)
p.optics.aperture_dia      = 40;    % source: Wei et al.
p.optics.opt_transmittance = 0.85;  % source: Wei et al.
p.optics.plateScale        = 27;    % in arcseconds; derived

% PSF
p.psf.model                = 'gaussian';
p.psf.sigma_px             = 0.7;   % PSF width (Gaussian radius = sigma), source: Wei et al.
p.psf.moffat_beta          = 2.5;   % source: Trujillo et al.
p.psf.fwhmFactor           = 2.355; % 2.355 * sigma; source: Trujillo et al.
p.psf.airyWidthParameter   = Nan;   %TBD
p.psf.subPixelGrid         = Nan;   % own decision; e.g 10x10

%% Star
p.star.signal_e            = 5000;  % total electrons per star (sweep this to vary SNR)
% Baseline stays below full well for every PSF in params_sweeps.
% Centered star at sigma = 0.5 px puts ~46.6% of S in the peak pixel,
% so S must stay below ~29,000 e- without offset; ~27,000 e- with 10 DN offset to avoid saturation.
% True centroid is drawn per trial, uniform within the central pixel
% (see generate_spot), source: Wan et al.

%% Noise
p.noise.darkCurrent_eps    = 125;   % electrons per pixel per second, source: Wei et al.
p.noise.exposure_ms        = 100;   % source: Tang et al.
p.noise.readNoise_e        = 13;    % electrons rms ("temporal noise"), source: Wei et al.
p.noise.enableShot         = true;  % switches for validation tests
p.noise.fpn                = 35;    % source: Wei et al.
p.noise.prnu               = 0.01;  % source: Wei et al.
p.noise.bg_level           = NaN;   % baseline e-/pixel; decision
p.noise.bg_subtraction     = NaN;   % known or border; decision
p.noise.enableRead         = true;
p.noise.enableDark         = true;
p.noise.enableQuant        = true;

%% Detection
p.detect.SNRdefinition     = NaN;   % wei eq 8, liebe, or integrated
p.detect.detect_threshold  = 5;     % source: Wei et al.

%% Centroiding
p.centroid.FGF_T           = 3;     % source: Wan et al.
p.centroid.FGF_minpx       = 5;     % source: Wan et al.
p.centroid.GF_initguess    = NaN;
p.centroid.GF_tol          = NaN;
p.centroid.negpxRule       = NaN;

%% Supervisor
p.svisor.snrSwitch         = NaN;
p.svisor.valid_px_min      = NaN;
p.svisor.saturation        = NaN;
p.svisor.outlierTest       = NaN;

%% Simulation
p.sim.nTrials              = 10000; % Monte Carlo trials per setting, source: Wan et al.
p.sim.seed                 = 123;   % fixed for reproducibility
p.sim.tuning               = Nan;
p.sim.perSettingRule       = Nan;

%% Processor (cost estimates, fill in later)
p.proc.coreName            = 'STM32F401CCU6 (Cortex-M4F)';
p.proc.clock_MHz           = 84;    % in MHz; source: Datasheet
p.proc.updateRate_Hz       = 10;    % in Hz; real-time budget; ms per frame = 1000/rate

%% Timing
p.timing.starsPerFrame     = Nan;   % compute from wei eq. 10
p.timing.CPUshare          = 50;    % in %;
end