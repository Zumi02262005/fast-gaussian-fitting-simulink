function s = params_sweeps()
% PARAMS_SWEEPS  Values to vary in each experiment.

%% Objective 2: accuracy vs SNR and PSF shape
s.snr.signal_e             = [1000 2000 5000 10000 20000 30000];    % list of signal levels (gives SNR range) source: derived from Wan et al.
s.psf.sigma_px             = [0.5 0.7 1.0 1.5];    % list of PSF widths source: Wan et al.
s.psf.model                = {'airy disk', 'moffat', 'gaussian'};    % list of PSF shape names source: Nahlik & Stys, Trujillo et al., Hagiwara & Kuwatani
s.psf.moffatBeta           = [];

%% Objective 4: precision study
s.precision.formats        = {'single', 'double', 'fixed'};    % e.g. names of the numeric formats you test
s.precision.fixedPointQ    = [16 8; 16 12; 32 16; 32 24];    % word/fraction lengths to test

%% Optional extra sweeps
s.noise.readNoise_e        = [];
s.noise.background_e       = [];
s.sensor.roiSize_px        = [];

end