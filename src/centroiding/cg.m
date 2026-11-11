function [xc, yc, status] = cg(roi, p)
% CG  Centre-of-gravity centroid of a star in the ROI.
%
%   [xc, yc, status] = cg(roi, p)
%
%   Inputs
%     roi    : N-by-N star signal in DN, background removed (subtract_background)
%     p      : parameter struct from params_baseline
%
%   Outputs
%     xc, yc : estimated centroid in pixel coordinates
%              (pixelCoordRule = 'integer': pixel (i, j) centred at x = j, y = i)
%     status : 0 = OK, 1 = failed (no positive signal, DN <= 0).
%              On failure, return xc = yc = NaN.
%
%   Shared interface for all four centroiders (cg, wcg, gf, fast_gf):
%   same inputs, same outputs, same status codes, so the supervisor and the
%   Monte Carlo loop can call any of them the same way.
%
%   Decisions (params_baseline):
%     negPixelRule = 'clip' : negative pixels set to 0 before summing
%     pixel set    = all N^2 pixels (background is 'known', so the border is
%                    not needed for background estimation as in [Liebe])
%
%   References: [Liebe] Eq. 9-11 (DN = sum of pixel values; xcm, ycm =
%   coordinate-weighted sums divided by DN).

% ---- Check decisions are made ----------------------------------------------
% TODO: error if p.centroid.negPixelRule is empty
% TODO: error if it is neither 'clip' nor 'keep'
if isempty(p.centroid.negPixelRule)
    error('cg:noNegPixelRule', 'Set p.centroid.negPixelRule in params_baseline (''clip'' or ''keep'').');
end
if ~ismember(p.centroid.negPixelRule, {'clip', 'keep'})
    error('cg:InvalidNegPixelRule', 'negPixelRule must be ''clip'' or ''keep''.');
end

% ---- Negative pixels -------------------------------------------------------
% TODO: if negPixelRule is 'clip', set negative values of roi to 0
%       (hint: max with 0, element-wise)
if strcmp(p.centroid.negPixelRule, 'clip')
    roi = max(roi, 0);
end

% ---- Pixel coordinates -----------------------------------------------------
% TODO: build X and Y matrices the size of roi holding each pixel's x (column)
%       and y (row) coordinate, from the 'integer' convention (meshgrid)
N = size(roi, 1);
[X, Y] = meshgrid(1:N, 1:N);

% ---- Centre of gravity, [Liebe] Eq. 9-11 ------------------------------------
% TODO: DN = sum of all roi values                                   (Eq. 9)
DN = sum(roi(:));
% TODO: if DN <= 0: xc = NaN, yc = NaN, status = 1, and return       (guard)
if DN <= 0
    xc = NaN; yc = NaN; status = 1;
    return;
end
% TODO: xc = sum of X .* roi over all pixels, divided by DN once      (Eq. 10)
xc = sum(X(:) .* roi(:)) / DN;
yc = sum(Y(:) .* roi(:)) / DN;
status = 0;
% TODO: yc = the same with Y                                          (Eq. 11)
% ---- Self-check ideas (tests/test_cg.m) -------------------------------------
% - Noise-free centred star (generate_spot(p, 4, 4), all noise off): (4, 4) exactly
% - Noise-free star at (4.3, 4): xc moves toward 4.3 but falls short (S-curve,
%   pulled toward the pixel centre); yc stays 4
% - Sweep the true x from 3.5 to 4.5 (noise off) and plot error vs true x:
%   an S-shaped curve, near zero at 3.5, 4 and 4.5 - a report figure
% - All-zero roi: status = 1, xc = yc = NaN
end