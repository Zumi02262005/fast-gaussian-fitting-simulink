function roi = subtract_background(img_DN, p)
% SUBTRACT_BACKGROUND  Remove the known black level and background from a digitized ROI.
%
%   roi = subtract_background(img_DN, p)
%
%   Inputs
%     img_DN : N-by-N digitized image from apply_noise_chain (black level included)
%     p      : parameter struct from params_baseline
%
%   Output
%     roi    : N-by-N star signal in DN, background removed. Negative values are
%              KEPT here; each centroider applies p.centroid.negPixelRule itself.
%
%   This is the first processing step (the processor side, not the sensor model).
%   bgSubtractionRule = 'known': the processor is given the true mean background,
%   so subtraction errors are out of scope.
%   Shared by all four centroiders, so the comparison stays fair.

% ---- Check decisions are made ----------------------------------------------
% TODO: error if p.noise.bgSubtractionRule is not 'known' (the only mode written so far)
if ~strcmpi(p.noise.bgSubtractionRule, 'known')
    error('subtract_background:UnsupportedRule', ...
        'Only the known background subtraction rule is supported.');
end

% ---- Mean background in DN -------------------------------------------------
% TODO: the mean level a pixel with NO star would read, in DN:
%       black level + (dark charge + sky background) converted to DN
%       - dark charge: p.noise.dark_e, only if p.noise.enableDark
%       - background:  p.noise.bg_level_e
%       - convert e- to DN with p.sensor.gain_e_per_DN
%       (Check: at baseline this is ~10.95 DN, the dark-frame mean from Stage 3 test 6)
meanBackgroundDN = p.sensor.black_level_DN + ...
    (p.noise.bg_level_e + p.noise.enableDark * p.noise.dark_e) / p.sensor.gain_e_per_DN;

% ---- Subtract --------------------------------------------------------------
% TODO: roi = img_DN - mean background (one number, subtracted from every pixel)
roi = img_DN - meanBackgroundDN;

% ---- Self-check --------------------------------------------------------------
% - Dark frame (no star), all noise on, many trials: mean(roi) ~ 0 DN
% - Noise-free spot (all noise off): roi * gain ~ img_e from generate_spot
%   (up to rounding)
end