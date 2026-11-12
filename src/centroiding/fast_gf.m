function [xc, yc, status, info] = fast_gf(roi, p)
% FAST_GF  Fast Gaussian fitting centroid of a star in the ROI ([Wan] Sec. 2.3-2.4).
%
%   [xc, yc, status]       = fast_gf(roi, p)
%   [xc, yc, status, info] = fast_gf(roi, p)   % also returns fit details
%
%   Inputs
%     roi    : N-by-N star signal in DN, background removed (subtract_background)
%     p      : parameter struct from params_baseline
%
%   Outputs
%     xc, yc : estimated centroid in pixel coordinates (pixelCoordRule = 'integer')
%     status : 0 = OK
%              1 = no signal          (fewer than fgf_min_px positive pixels at the start)
%              2 = too few pixels     (fewer than fgf_min_px pixels pass SNR > T, Eq. 21)
%              3 = invalid fit        (singular system, or m <= 0 / n <= 0: not a peak)
%              On any failure, xc = yc = NaN.
%     info   : struct for the supervisor and tests:
%              info.nPixels  - pixels used in the final fit (size of U)
%              info.snr      - N-by-N estimated pixel SNR from step 1 (Eq. 20)
%              info.sigma    - [sigma_x sigma_y] of the final fit (Eq. 17)
%
%   Same first three outputs as cg/wcg (status 1 means the same thing).
%
%   Algorithm ([Wan] Sec. 2.4, Fig. 3):
%     0. Candidate pixels: positive (log needs I > 0), not saturated.
%     1. First step  - initial pixel set U0 (p.centroid.fgfInitRule)
%                    - fit (Eq. 15-17) -> rough A', xc', yc', sx', sy'
%                    - model S_i (Eq. 18), noise N_i = I_i - S_i (Eq. 19),
%                      SNR_i = |S_i / N_i| (Eq. 20)
%     2. Second step - U = candidates with SNR_i > T (Eq. 21), need >= fgf_min_px
%                    - fit again on U -> xc, yc (Eq. 17)
%
%   The fit (local function fgfFit below), [Wan] Eq. 15-17:
%     minimise sum over U of (m*I*x^2 + n*I*y^2 + p*I*x + q*I*y + k*I + I*ln I)^2
%     -> linear least squares in (m, n, p, q, k)
%     xc = -p/(2m), yc = -q/(2n), sx = sqrt(1/(2m)), sy = sqrt(1/(2n)),
%     A  = exp(p^2/(4m) + q^2/(4n) - k)
%
%   Decisions (params_baseline):
%     fgf_T = 3, fgf_min_px = 5           ([Wan] Sec. 3.2)
%     fgfInitRule                         DECISION, see below
%     negPixelRule = 'clip'               negatives are excluded anyway (log)
%
%   fgfInitRule - how to choose the first-step pixels U0:
%     'top5' : the 5 brightest pixels, exactly as [Wan] Sec. 2.4 step 2(i).
%              Singular whenever those 5 pixels span only 2 columns or 2 rows
%              (then x^2 = (a+b)x - ab, so the x^2, x and 1 columns are
%              dependent). For compact spots this happens for ~half of all
%              sub-pixel positions. A finding for the report.
%     'box3' : the 3x3 block centred on the brightest pixel (shifted inward if
%              the brightest pixel is on the ROI edge). Always 3 distinct
%              columns and rows, so never singular. A documented deviation
%              from [Wan]; justify it with the 'top5' failure rate.
%
%   References: [Wan] Eq. 4, 12-21, Sec. 2.4 and 3.2.

% ---- Check decisions are made ----------------------------------------------
if ~isfinite(p.centroid.fgf_T) || ~isfinite(p.centroid.fgf_min_px)
    error('fast_gf:InvalidParameter', 'fgf_T and fgf_min_px must be finite.');
end
if isempty(p.centroid.fgfInitRule) || ~ismember(lower(p.centroid.fgfInitRule), {'top5', 'box3'})
    error('fast_gf:InvalidParameter', 'fgfInitRule must be ''top5'' or ''box3''.');
end

xc = NaN;  yc = NaN;  status = 1;
info = struct('nPixels', 0, 'snr', NaN(size(roi)), 'sigma', [NaN NaN]);

% ---- Pixel coordinates -----------------------------------------------------
N = size(roi, 1);
[X, Y] = meshgrid(1:N, 1:N);

% ---- 0. Candidate pixels ---------------------------------------------------
cand = roi > 0;
if nnz(cand) < p.centroid.fgf_min_px
    return
end
% ---- 1. First step: rough fit and pixel-wise SNR ----------------------------
if strcmpi(p.centroid.fgfInitRule, 'top5')
    candidateIndices = find(cand);
    [~, order] = sort(roi(candidateIndices), 'descend');
    U0 = false(size(cand));
    U0(candidateIndices(order(1:min(5, numel(order))))) = true;
else
    [~, brightestIndex] = max(roi(cand));
    candidateIndices = find(cand);
    brightestIndex = candidateIndices(brightestIndex);
    [row, col] = ind2sub([N N], brightestIndex);
    row = min(max(row, 2), N - 1);
    col = min(max(col, 2), N - 1);
    U0 = false(size(cand));
    U0(row-1:row+1, col-1:col+1) = true;
    U0 = U0 & cand;
end
[A1, xc1, yc1, sx1, sy1, ok] = fgfFit(roi(U0), X(U0), Y(U0));
if ~ok, status = 3; return; end
S_hat = A1 * exp(-((X - xc1).^2/(2*sx1^2) + (Y - yc1).^2/(2*sy1^2)));

N_hat = roi - S_hat;
info.snr = abs(S_hat ./ N_hat);

% ---- 2. Second step: reselect pixels and fit again
U = cand & (info.snr > p.centroid.fgf_T);
if nnz(U) < p.centroid.fgf_min_px
    status = 2;
    return
end
[~, xc, yc, sx, sy, ok] = fgfFit(roi(U), X(U), Y(U));
if ~ok
    status = 3;
    return
end
info.nPixels = nnz(U);
info.sigma = [sx, sy];
status = 0;

% ---- Self-check ideas (add to tests/test_centroiders.m) ---------------------
% Expected values from an independent calculation (Gaussian PSF, 7x7 ROI,
% 'box3', T = 3, clip):
% - Noise-free centred star: (4, 4) to ~1e-9
% - Noise-free max |error| vs sub-pixel offset:
%     sigma 0.3: 0.031 px   sigma 0.5: 0.005 px   sigma 0.7: 0.0008 px
%     sigma 1.0 and 1.5: ~0.00001 px (no truncation bias: the fit models the
%     whole Gaussian, unlike CG)
% - Noise-free failures: none with 'box3'; ~52% of offsets with 'top5'
%   (all offsets with |d| > ~0.25 px)
% - Noisy, sigma 0.7, true x offset +0.3 px:
%     S = 5,000 e-: bias ~0.000 px, std ~0.028 px, failures 0, |U| ~ 11.6
%     S = 1,000 e-: failures ~6% (status 2 and 3), median |error| ~0.10 px,
%                   std inflated by occasional wild fits -> report the median
%                   or trim outliers, and count failures separately
%   With 'top5': ~94% failures at 5,000 e-.
% - All-zero roi: status = 1
end

% ==== Local function ========================================================
function [A, xc, yc, sx, sy, ok] = fgfFit(I, x, y)
% FGFFIT  Solve [Wan] Eq. 15-17 for the pixels given (column vectors I, x, y).
%   ok = false if the system is singular or the result is not a peak.

A = NaN;  xc = NaN;  yc = NaN;  sx = NaN;  sy = NaN;  ok = false;

D = [I .* x.^2, I .* y.^2, I .* x, I .* y, I];
b = -I .* log(I);
if rank(D) < 5
    return
end
theta = D \ b;
[m, n, p, q, k] = deal(theta(1), theta(2), theta(3), theta(4), theta(5));
if m <= 0 || n <= 0
    return
end
xc = -p/(2*m);
yc = -q/(2*n);
sx = sqrt(1/(2*m));
sy = sqrt(1/(2*n));
A = exp(p^2/(4*m) + q^2/(4*n) - k);
ok = true;
%
% NOTE (precision study, Stage 7): x and y up to 7 make x^2 up to 49, and
% D'*D squares that again. Measuring x and y from the ROI centre (x - c) keeps
% the numbers small and helps single and fixed-point a lot. If you do that,
% add c back to xc and yc at the end.
end