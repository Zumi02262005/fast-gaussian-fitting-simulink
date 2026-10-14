function s = params_sweeps()
% PARAMS_SWEEPS  Values to vary in each experiment.
%% Objective 2: accuracy vs SNR and PSF shape
s.snr.signal_e             = [1000 2000 5000 10000 20000 25000];    % total signal levels (e-); top level capped at 25,000 so no PSF model saturates at sigma = 0.5 px
% Low end (S = 1000 at sigma >= 1.0) gives peak pixels of only 1-2 DN:
% expected Fast Gaussian Fitting failures, so record failure rate.
s.psf.sigma_px             = [0.5 0.7 1.0 1.5];                     % PSF widths, within the 0.5-2 range used by Wan et al.
s.psf.model                = {'airy disk', 'moffat', 'gaussian'};   % sources in order: Nahlik & Stys; Trujillo et al.; Wan et al. (Gaussian spot model)
s.psf.moffatBeta           = [1.5 2.5 5];                           % Moffat beta values, source: Trujillo et al.
%% Objective 4: precision study
s.precision.formats        = {'single', 'double', 'fixed'};         % numeric formats tested
s.precision.fixedPointQ    = [16 8; 16 12; 32 16; 32 24];           % [word length, fraction length] pairs
%% Optional extra sweeps
s.noise.readNoise_e        = [];
s.noise.background_e       = [];
s.sensor.roiSize_px        = [];
end