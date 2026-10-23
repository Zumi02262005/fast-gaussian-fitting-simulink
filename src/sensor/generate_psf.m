function I = generate_psf(dx, dy, p)
%% GENERATE_PSF  PSF intensity at offsets (dx, dy) from the true centroid.
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

%% ---- Input checks ----------------------------------------------------------
if ~isequal(size(dx), size(dy))
    error('generate_psf:sizeMismatch', 'dx and dy must have the same size.');
end
if ~isfield(p.psf, 'sigma_px') || ~isscalar(p.psf.sigma_px) || ~(p.psf.sigma_px > 0)
    error('generate_psf:invalidSigma', 'p.psf.sigma_px must be a positive scalar.');
end

% ---- Shared width ----------------------------------------------------------
fwhm_px = p.psf.fwhm_factor * p.psf.sigma_px;

r = hypot(dx, dy);

% ---- Model-specific intensity ----------------------------------------------
switch lower(p.psf.modelRule)
    case 'gaussian'
        sigma_px = p.psf.sigma_px;
        I = exp(-r.^2/(2*sigma_px^2))/(2*pi*sigma_px^2);

    case 'moffat'
        moffat_beta = p.psf.moffat_beta;
        if ~isscalar(moffat_beta) || ~(moffat_beta > 1)
            error('generate_psf:invalidMoffatBeta', ...
                'p.psf.moffat_beta must be a scalar greater than 1.');
        end
        moffat_alpha = fwhm_px / (2 * sqrt(2^(1/moffat_beta) - 1));   % [Trujillo] Eq. A1, solved for alpha
        I = (moffat_beta - 1) / (pi * moffat_alpha^2) .* ...
            (1 + (r ./ moffat_alpha).^2).^(-moffat_beta);

    case 'airy'
        % FWHM-matched Airy: [2 J1(x)/x]^2 is half its peak at x = 1.6163 (Profile is from [Nahlik]
        % Eq. 1 and that 1.6163 is the half max of [2J, (x)/x]^2 which can be verified with fzero),
        % and that x sits at r = FWHM/2.
        airy_k = 2 * 1.616339948310703 / fwhm_px;     % 1/px
        x = airy_k * r;
        I = ones(size(r));                            % limit of [2 J1(x)/x]^2 at x = 0 is 1
        nz = x ~= 0;
        I(nz) = (2 * besselj(1, x(nz)) ./ x(nz)).^2;
        I = I * airy_k^2 / (4 * pi);                  % plane integral = 1

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