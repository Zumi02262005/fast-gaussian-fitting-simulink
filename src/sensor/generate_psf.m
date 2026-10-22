function I = generate_psf(dx, dy, p)
% GENERATE_PSF  PSF intensity at offsets (dx, dy) from the true centroid.
%
%   I = generate_psf(dx, dy, p)
%
%   Inputs
%     dx, dy : arrays of the same size, offsets from the star centre in pixels
%              (dx = x - xc, dy = y - yc)
%     p      : parameter struct from params_baseline (uses p.psf.*)
%
%   Output
%     I      : PSF intensity at each point, same size as dx. Normalized so the
%              integral over the WHOLE plane is 1 (not over the ROI), so light
%              falling outside the ROI is genuinely lost.
%
%   Supported models (p.psf.modelRule): 'gaussian', 'moffat', 'airy'
%   All three are matched by FWHM = p.psf.fwhm_factor * p.psf.sigma_px, so
%   "sigma = 0.7" means the same blob width for every shape.
%
%   References: [Wan] Eq. 22 (Gaussian spot), [Trujillo] Eq. A1 (Moffat),
%   [Nahlik] (Airy disk). Tags are listed in params_baseline.

% ---- Input checks ----------------------------------------------------------
% TODO: check that dx and dy have the same size (error if not)
% TODO: check that p.psf.sigma_px is positive

% ---- Shared width ----------------------------------------------------------
% TODO: compute the target FWHM in pixels from p.psf.fwhm_factor and p.psf.sigma_px
fwhm_px = NaN;

% Radial distance from the centre (all three models are circularly symmetric)
% TODO: compute r (same size as dx) from dx and dy
r = NaN(size(dx));

% ---- Model-specific intensity ----------------------------------------------
switch lower(p.psf.modelRule)
    case 'gaussian'
        % TODO: 2D circular Gaussian with standard deviation p.psf.sigma_px
        % TODO: choose the normalization constant so the plane integral = 1
        %       (hint: work out the integral of exp(-r^2 / (2 sigma^2)) over the plane)
        I = NaN(size(dx));

    case 'moffat'
        % TODO: read beta from p.psf.moffat_beta
        % TODO: convert the target FWHM into Moffat's width parameter alpha
        %       ([Trujillo] Eq. A1 gives FWHM in terms of alpha and beta - invert it)
        % TODO: write the Moffat profile and its normalization for the plane
        % NOTE: normalization only converges for beta > 1; error if beta <= 1
        I = NaN(size(dx));

    case 'airy'
        % TODO: error with a clear message if p.psf.airy_width is still NaN (decision open)
        % TODO: convert the target FWHM into the Airy scale (first-zero radius
        %       or lambda*N) using the FWHM of the Airy pattern ([Nahlik])
        % TODO: write the Airy intensity using the Bessel function besselj(1, .)
        % TODO: handle r = 0 separately (0/0 at the centre; use the limit value)
        % TODO: normalize so the plane integral = 1
        I = NaN(size(dx));

    otherwise
        error('generate_psf:unknownModel', ...
              'Unknown PSF model "%s". Use gaussian, moffat or airy.', p.psf.modelRule);
end

% ---- Self-check ideas (put these in tests/test_psf.m, not here) -------------
% - Numerically integrate I over a large grid (e.g. +/-20 px, fine spacing):
%   result should be ~1 for every model
% - Measure the FWHM of I along one axis: should equal fwhm_px for every model
% - I should be largest at r = 0 and never negative
end