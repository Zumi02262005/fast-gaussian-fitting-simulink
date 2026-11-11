function [xc, yc, status] = wcg(roi, p)
% WCG  Weighted centre-of-gravity centroid of a star in the ROI.
%
%   [xc, yc, status] = wcg(roi, p)
%
%   Inputs
%     roi    : N-by-N star signal in DN, background removed (subtract_background)
%     p      : parameter struct from params_baseline
%
%   Outputs
%     xc, yc : estimated centroid in pixel coordinates (pixelCoordRule = 'integer')
%     status : 0 = OK, 1 = failed (sum of weighted values <= 0).
%              On failure, return xc = yc = NaN.
%
%   Same interface and status codes as cg.m.
%
%   Formula ([Wan] Eq. 2):
%     xc = sum(W_i * I_i * x_i) / sum(W_i * I_i),  yc likewise with y_i
%   Weight rule p.centroid.wcgWeightRule:
%     'intensity' : W_i = I_i, the squared gray centroid ([Wan] Sec. 1, citing
%                   its ref. [10]). So W_i * I_i = I_i^2.
%
%   Decisions (params_baseline):
%     negPixelRule = 'clip' : negative pixels set to 0 BEFORE weighting.
%       With W_i = I_i this is required, not optional: squaring a negative
%       noise pixel turns it into a positive weight. 'keep' is rejected here.
%     pixel set    = all N^2 pixels (same as cg)
%
%   References: [Wan] Eq. 2 and Sec. 1.

% ---- Check decisions are made ----------------------------------------------
% TODO: error if p.centroid.wcgWeightRule is empty, or is not 'intensity'
%       (the only rule written so far)
if ~isfield(p.centroid, 'wcgWeightRule') || isempty(p.centroid.wcgWeightRule) || ...
        ~strcmpi(p.centroid.wcgWeightRule, 'intensity')
    error('wcg:InvalidWeightRule', 'wcg requires wcgWeightRule = ''intensity''.');
end
% TODO: error if p.centroid.negPixelRule is empty
if ~isfield(p.centroid, 'negPixelRule') || isempty(p.centroid.negPixelRule) || ...
        ~ismember(lower(p.centroid.negPixelRule), {'clip', 'keep'}) || ...
        strcmpi(p.centroid.negPixelRule, 'keep')
    error('wcg:InvalidNegPixelRule', 'wcg requires negPixelRule = ''clip''.');
end
% TODO: error if p.centroid.negPixelRule is 'keep' (see the note above);
%       anything other than 'clip' or 'keep' is an error too

% ---- Negative pixels -------------------------------------------------------
% TODO: clip negative values of roi to 0 (same line as in cg)
roi = max(roi, 0);

% ---- Weights ---------------------------------------------------------------
% TODO: W = the weight of every pixel under the 'intensity' rule
%       (an N-by-N matrix, element-wise; no loops needed)
W = roi;
% ---- Pixel coordinates -----------------------------------------------------
% TODO: X and Y from meshgrid, exactly as in cg (N from size(roi, 1))
N = size(roi, 1);
[X, Y] = meshgrid(1:N, 1:N);

% ---- Weighted centre of gravity, [Wan] Eq. 2 --------------------------------
% TODO: denominator = sum of W .* roi over all pixels
% TODO: if denominator <= 0: xc = NaN, yc = NaN, status = 1, and return
% TODO: xc = sum of W .* roi .* X over all pixels, divided by the denominator once
% TODO: yc = the same with Y
denominator = sum(W(:) .* roi(:));
if denominator <= 0
    xc = NaN;
    yc = NaN;
    status = 1;
    return;
end
xc = (sum(W(:) .* roi(:) .* X(:)))/denominator;
yc = (sum(W(:) .* roi(:) .* Y(:)))/denominator;
status = 0;
% ---- Self-check ideas (add to tests/test_centroiders.m) ---------------------
% Expected values from an independent calculation (Gaussian PSF, 7x7 ROI):
% - Noise-free centred star: (4, 4) exactly
% - Noise-free max |error| vs sub-pixel offset (compare with CG):
%     sigma 0.3: 0.197 px   (CG 0.054)  <- squaring makes the spot effectively
%     sigma 0.5: 0.071 px   (CG 0.002)     narrower, so the S-curve is WORSE
%     sigma 0.7: 0.011 px   (CG ~0)        for small spots ([Wan] Sec. 1)
%     sigma 1.0: ~0.0001 px (CG 0.005)
%     sigma 1.5: 0.007 px   (CG 0.068)  <- but truncation is 10x smaller
% - Noisy, sigma 0.7, true x offset +0.3 px, clip:
%     S = 5,000 e-: bias x ~ -0.014 px, std ~ 0.026 px  (CG: -0.037, 0.063)
%     S = 1,000 e-: bias x ~ -0.065 px, std ~ 0.155 px  (CG: -0.152, 0.20)
%   Squaring suppresses the faint (mostly noise) border pixels, so WCG beats CG
%   under noise but loses to it on narrow, clean spots.
% - All-zero roi: status = 1, xc = yc = NaN
end