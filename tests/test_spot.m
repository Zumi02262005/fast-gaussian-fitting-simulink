% TEST_SPOT  Checks for generate_spot (noise-free spot in the ROI).
%
% Run from the project root (with src/ and params/ on the path):
%   >> test_spot
%
% Uses S = 1 so img shows the fraction of the star's light on each pixel.
% Expected values come from the erf calculation and from check_psf_shapes
% (in-ROI share for a centred star, sigma = 0.7 px, 7x7 ROI).

p = params_baseline();
p.star.signal_e = 1;
c   = (p.sensor.roi_size_px + 1) / 2;   % central pixel centre (4 for a 7x7 ROI)
tol = 1e-12;                            % floating-point tolerance for symmetry

if isnan(p.psf.subpixel_grid_n)
    error('test_spot:noGrid', 'Set p.psf.subpixel_grid_n in params_baseline first (e.g. 20).');
end

fprintf('\n---- Gaussian (erf branch) ----\n');
p.psf.modelRule = 'gaussian';

% 1. Peak share, sigma = 0.5, centred
p.psf.sigma_px = 0.5;
img = generate_spot(p, c, c);
fprintf('sigma 0.5 peak pixel      : %.4f (expect ~0.466)\n', img(c, c));
assert(abs(img(c, c) - 0.466) < 0.001, 'Peak share wrong at sigma 0.5');

% 2. Side neighbour, sigma = 0.7, centred
p.psf.sigma_px = 0.7;
img = generate_spot(p, c, c);
fprintf('sigma 0.7 side neighbour  : %.4f (expect ~0.116)\n', img(c, c-1));
assert(abs(img(c, c-1) - 0.116) < 0.001, 'Side neighbour share wrong at sigma 0.7');

% 3. Symmetry when centred
lr = max(abs(img - fliplr(img)), [], 'all');
ud = max(abs(img - flipud(img)), [], 'all');
fprintf('symmetry (LR, UD)         : %.1e, %.1e (expect < 1e-12)\n', lr, ud);
assert(lr < tol && ud < tol, 'Centred spot is not symmetric');

% 4. Total light inside the ROI
fprintf('sum in ROI                : %.4f (expect ~1.000)\n', sum(img(:)));
assert(abs(sum(img(:)) - 1) < 0.001, 'Gaussian in-ROI share should be ~1');

% 5. Shift +0.3 px in x only: right neighbour grows, left shrinks, up/down stay equal
img = generate_spot(p, c + 0.3, c);
fprintf('x shift +0.3: left, right : %.4f, %.4f (right should be larger)\n', ...
    img(c, c-1), img(c, c+1));
assert(img(c, c+1) > img(c, c-1), 'x shift did not move light to the right');
assert(abs(img(c-1, c) - img(c+1, c)) < tol, 'x shift changed the y balance');

fprintf('\n---- Moffat / Airy (sub-grid branch, M = %d) ----\n', p.psf.subpixel_grid_n);
% In-ROI share for a centred star; compare with check_psf_shapes
cases = { 'moffat', 1.5, 0.734;
    'moffat', 2.5, 0.956;
    'moffat', 5,   0.997;
    'airy',   NaN, 0.916 };
for k = 1:size(cases, 1)
    p.psf.modelRule = cases{k, 1};
    if ~isnan(cases{k, 2})
        p.psf.moffat_beta = cases{k, 2};
        label = sprintf('%s beta=%g', cases{k, 1}, cases{k, 2});
    else
        label = cases{k, 1};
    end
    img = generate_spot(p, c, c);
    fprintf('%-16s sum in ROI : %.4f (expect ~%.3f)\n', label, sum(img(:)), cases{k, 3});
    assert(abs(sum(img(:)) - cases{k, 3}) < 0.005, 'In-ROI share wrong for %s', label);
end

fprintf('\nAll generate_spot checks passed.\n');