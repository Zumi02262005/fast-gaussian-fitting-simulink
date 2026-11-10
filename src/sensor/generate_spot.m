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

% ---- Error Detection ----------------------------------------------
if isempty(p.sensor.pixelCoordRule)
    error('generate_spot:pixelCoordRuleEmpty', 'pixelCoordRule should not be empty');
end

% ---- True centroid ---------------------------------------------------------

if nargin < 3
    % DN = symsum(symsum(image(x, y), x, N/N, N), y, N/N, N);
    % xc = symsum(symsum(((x * image(x, y))/(DN)), x, N/N, N), y, N/N, N);
    % yc = symsum(symsum(((y * image(x, y))/(DN)), y, N/N, N), x, N/N, N);
    xc = (N + 1) / 2;
    yc = (N + 1) / 2;
end

% ---- Pixel edges -----------------------------------------------------------

img_e = zeros(N, N);
v_center = 1:N;
x_left = v_center - 0.5;
x_right = v_center + 0.5;
y_low = v_center - 0.5;
y_high = v_center + 0.5;

% ---- Fraction of the PSF falling on each pixel ([Wei] Eq. 6) ----------------
switch lower(p.psf.modelRule)
    case 'gaussian'
        % Exact method: the 2D Gaussian separates into x and y parts, so the
        % fraction on a pixel = (fraction in its x range) * (fraction in its y range).
        sigma = p.psf.sigma_px;
        xFraction = 0.5 * (erf((x_right - xc)/(sigma*sqrt(2))) - erf((x_left - xc)/(sigma*sqrt(2))));
        yFraction = 0.5 * (erf((y_high - yc)/(sigma*sqrt(2))) - erf((y_low - yc)/(sigma*sqrt(2))));
        fraction = yFraction(:) * xFraction;
        img_e = S * fraction;

    case {'moffat', 'airy'}
        % No closed form, so average generate_psf over a fine sub-grid in each pixel.
        g = p.psf.subpixel_grid_n;   % sub-points per pixel side (M)
        if ~isscalar(g) || isnan(g) || g < 1 || g ~= floor(g)
            error('generate_spot:invalidSubpixelGrid', ...
                'subpixel_grid_n must be a positive integer.');
        end
        offsets = ((1:g) - 0.5) / g - 0.5;
        fraction = zeros(N, N);
        for row = 1:N
            for col = 1:N
                [dx, dy] = meshgrid((v_center(col) - xc) + offsets, (row - yc) + offsets);
                fraction(row, col) = mean(generate_psf(dx, dy, p), 'all');
            end
        end
        img_e = S * fraction;
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