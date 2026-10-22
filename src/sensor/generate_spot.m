function [img_e, xc, yc] = generate_spot(p, xc, yc)
% GENERATE_SPOT  Expected (noise-free) signal electrons per pixel for one star in the ROI.
%
%   [img_e, xc, yc] = generate_spot(p)          % random true centroid
%   [img_e, xc, yc] = generate_spot(p, xc, yc)  % fixed centroid (for tests)
%
%   Inputs
%     p      : parameter struct from params_baseline
%     xc, yc : (optional) true centroid in pixel coordinates
%
%   Outputs
%     img_e  : N-by-N expected signal electrons (no dark, no background, no noise)
%     xc, yc : true centroid used, in pixel coordinates
%
%   Coordinate convention is set by p.sensor.pixelCoordRule. The TODOs below
%   assume 'integer' (pixel centres at whole numbers):
%     - Pixel (i, j) has its centre at x = j, y = i (column = x, row = y)
%     - Pixel (i, j) covers x in [j - 0.5, j + 0.5], y in [i - 0.5, i + 0.5]
%     - The central pixel of an N-by-N ROI is at ((N+1)/2, (N+1)/2)
%   If you choose a different convention, change every edge and centre below to match.
%
%   The random draw uses MATLAB's global RNG. Seed it in the caller with
%   rng(seed) so the same seed reproduces the same spot.
%
%   References: [Wei] Eq. 6 (integrate the PSF over each pixel),
%   [Wan] Sec. 3.3 (centroid uniform within the central pixel).

N = p.sensor.roi_size_px;
S = p.star.signal_e;

% ---- Check decisions are made ----------------------------------------------
% TODO: error with a clear message if p.sensor.pixelCoordRule is empty

% ---- True centroid ---------------------------------------------------------
if nargin < 3
    % TODO: compute the centre coordinate of the central pixel
    % TODO: draw xc and yc uniformly within that pixel (+/- 0.5 px), [Wan] Sec. 3.3
    xc = NaN;
    yc = NaN;
end

% ---- Pixel edges -----------------------------------------------------------
% TODO: build vectors of left/right x edges and lower/upper y edges for all N pixels
%       (from the coordinate convention above)

img_e = zeros(N, N);

% ---- Fraction of the PSF falling on each pixel ([Wei] Eq. 6) ----------------
switch lower(p.psf.modelRule)
    case 'gaussian'
        % Exact method: the 2D Gaussian separates into x and y parts, so the
        % fraction on a pixel = (fraction in its x range) * (fraction in its y range).
        % TODO: write the 1D fraction between two edges using erf
        %       (the Gaussian CDF; offsets are measured from xc or yc)
        % TODO: form the N-by-N fraction matrix from the x and y fractions
        %       (hint: an outer product of two vectors; rows = y, columns = x)
        % TODO: img_e = S * fraction matrix

    case {'moffat', 'airy'}
        % No closed form, so average generate_psf over a fine sub-grid in each pixel.
        g = p.psf.subpixel_grid_n;   % sub-points per pixel side (M)
        % TODO: error if g is NaN (decision not made yet)
        % TODO: build sub-point offsets inside one pixel (g points per side,
        %       centred in g equal sub-cells, not on the pixel edges)
        % TODO: for each pixel, evaluate generate_psf at its sub-points
        %       (dx = x_sub - xc, dy = y_sub - yc), average, and multiply by
        %       the pixel area (1 px^2) to get the fraction on that pixel
        % TODO: img_e = S * fraction matrix
        % NOTE: loops over the N^2 pixels are fine here; vectorize later only if slow

    otherwise
        error('generate_spot:unknownModel', 'Unknown PSF model "%s".', p.psf.modelRule);
end

% ---- Self-check ideas (tests/test_psf.m or a new test) ---------------------
% - sum(img_e(:)) should equal S times the PSF fraction inside the ROI
%   (slightly less than S, more so at sigma = 1.5)
% - With xc, yc exactly at the central pixel centre, img_e should be symmetric
%   (img_e == fliplr(img_e) and == flipud(img_e))
% - Centred, sigma = 0.5 Gaussian: peak pixel should hold ~46.6% of S
% - Centred, sigma = 0.7 Gaussian: each side neighbour holds ~11.6% of S
%   (the 4-neighbour average used by compute_snr)
% - For Gaussian, compare the erf result with the sub-grid method: they should
%   agree closely, which also chooses M for Moffat/Airy
end