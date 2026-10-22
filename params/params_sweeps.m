function s = params_sweeps()
% PARAMS_SWEEPS  Values to vary in each experiment.
%
% Reference tags ([Wei], [Wan], ...) are listed at the top of params_baseline.

%% Objective 2: accuracy vs SNR and PSF shape (main sweep)
s.snr.signal_e             = [1000 2000 5000 10000 20000 25000];   % total signal levels (e-)
% Fully unsaturated for every sigma: top level capped at 25,000 because sigma = 0.5 px
% saturates at ~28,700 e- (10-bit ADC, 10 DN black level).
% Detection limit is ~2,430 e- ([Wei] Eq. 9, see params_baseline), so S = 1,000 is below
% the detection threshold: a stress case. Expect Fast GF failures there; record the failure rate.
% Magnitude labels ([Wei] Eq. 2, 100 ms): 25,000 e- ~ 5.8, 5,000 e- ~ 7.6, 1,000 e- ~ 9.3.
s.psf.sigma_px             = [0.5 0.7 1.0 1.5];                    % PSF widths; [Wan] Sec. 3.3.2 (0.5-2 range)
s.psf.modelRule            = {'gaussian', 'moffat', 'airy'};       % [Wan] Eq. 22; [Trujillo] Eq. A1; [Nahlik]
s.psf.moffat_beta          = [1.5 2.5 5];                          % [Trujillo]
% Moffat is expanded by beta: 5 shapes (Gaussian, Moffat x3, Airy)
% -> 6 signals x 4 widths x 5 shapes = 120 settings.

%% Update rates (project framework: at least three)
s.timing.update_rate_Hz    = [1 5 10];                             % frame period = 1000 / rate ms
s.timing.exposure_ms       = [NaN NaN NaN];                        % decision; one per rate, must fit the frame
                                                                   % period minus readout (100 ms fills the 10 Hz frame)
% Recompute Mv ([Wei] Eq. 9) and N_star ([Wei] Eq. 10) for each exposure; shorter exposures
% detect fewer stars, which partly relaxes the faster-rate budget.
s.timing.stars_per_frame_check = 33;                               % sensitivity check: Mv ~ 6.3 at 1 deg/s,
                                                                   % [Wei] Fig. 4a-b; report deadline margins at both

%% Disturbance: raised background (stray light)
% Goal: show where CG collapses and where GF / Fast GF deteriorate under raised noise.
% Background defined relative to the noise floor (sigma_0 = noise_floor_e, [Wei] Eq. 7):
%   B = (k^2 - 1) * sigma_0^2,  so total background noise = k * sigma_0
% k = 1 is the baseline (B = 0).
s.bg.k_range               = [1.0 2.5];                            % decided range of k
s.bg.k                     = [];                                   % decision; discrete k steps within k_range
s.bg.signal_max_e          = 10000;                                % decided; S <= 10,000 keeps k = 2.5 unsaturated for every sigma
s.bg.signal_e              = [];                                   % decision; S levels to run at (<= signal_max_e)
% At k = 2.5 (B ~ 7,460 e-), the 10-bit ADC (10 DN black level, 3-sigma margin) saturates
% above S ~ 11,800 at sigma = 0.5 and ~19,900 at sigma = 0.7.

%% Abnormal: saturation scenario
s.sat.sigma_px             = 0.7;                                  % decided
s.sat.signal_e             = 50000;                                % decided (~magnitude 5.0, [Wei] Eq. 2)
s.sat.positionRule         = '';                                   % decision: 'centre' (star fixed at the pixel centre)
                                                                   % or 'uniform' (random within the pixel)
% At S = 50,000 with uniform positions only ~11% of trials saturate (10-bit ADC);
% every position saturates above ~74,600 e-. A centred star hides CG's S-curve.
% GF and Fast GF exclude saturated pixels before fitting: [Wan] Sec. 2.4 step 1, Sec. 3.3.4.

%% Abnormal: other faults
s.fault.hot_pixel_e        = NaN;                                  % decision; hot pixel / cosmic-ray amplitude (e.g. near full well)
s.fault.edge_offset_px     = NaN;                                  % decision; star distance from the ROI centre (e.g. 2-3 px)

%% Objective 4: precision study
s.precision.formatRule     = {'double', 'single', 'fixed'};        % double first: it is the reference
s.precision.fixed_point_Q  = [16 8; 16 12; 32 16; 32 24];          % [word length, fraction length] pairs
% Expect Q16.12 (range ~ +/-8) to overflow in the least-squares sums ([Wan] Eq. 5-12): a finding, not a bug.

%% Optional extra sweeps
s.noise.read_noise_e       = [];
s.sensor.roi_size_px       = [];
end