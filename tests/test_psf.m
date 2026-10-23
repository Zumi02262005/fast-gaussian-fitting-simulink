% CHECK_PSF_SHAPES  Numeric checks and figures for generate_psf.
%
% Run from the project root (with src/ and params/ on the path):
%   >> check_psf_shapes
%    
% Prints peak, plane integral and FWHM for every PSF shape, then draws:
%   Figure 1 - 2D image of each shape, with the 7x7 ROI outlined
%   Figure 2 - radial profiles on a linear scale (core shape and FWHM match)
%   Figure 3 - radial profiles on a log scale (wings: why Moffat/Airy lose light outside the ROI)
%
% Expected at sigma = 0.7 px (FWHM ~ 1.65 px):
%   shape         peak    integral (+/-10 px)   in 7x7 ROI (centred)
%   gaussian      0.325   1.000                 ~100%
%   moffat b=1.5  0.138   ~0.904 (heavy wings)  ~73%
%   moffat b=2.5  0.225   ~0.998                ~96%
%   moffat b=5    0.279   ~1.000                ~99.7%
%   airy          0.306   ~0.971 (rings)        ~92%

p = params_baseline();

% ---- Shapes to compare (Moffat expanded by beta, as in params_sweeps) ------
shapes = { 'gaussian', NaN;
           'moffat',   1.5;
           'moffat',   2.5;
           'moffat',   5;
           'airy',     NaN };
nShapes = size(shapes, 1);
labels  = cell(nShapes, 1);
for k = 1:nShapes
    if isnan(shapes{k, 2})
        labels{k} = shapes{k, 1};
    else
        labels{k} = sprintf('%s \\beta=%g', shapes{k, 1}, shapes{k, 2});
    end
end

% ---- Evaluation grid -------------------------------------------------------
step = 0.01;                          % px
x    = -10:step:10;                   % +/-10 px for the integral and FWHM
[X, Y] = meshgrid(x, x);
iRow = find(abs(x) < step/2);         % row through y = 0
fwhmTarget = p.psf.fwhm_factor * p.psf.sigma_px;
roiHalf    = p.sensor.roi_size_px / 2;

% ---- Numeric checks --------------------------------------------------------
fprintf('\nsigma = %.2f px, target FWHM = %.3f px\n', p.psf.sigma_px, fwhmTarget);
fprintf('%-16s %8s %10s %8s %10s\n', 'shape', 'peak', 'integral', 'FWHM', 'in ROI');
images = cell(nShapes, 1);
for k = 1:nShapes
    q = p;
    q.psf.modelRule = shapes{k, 1};
    if ~isnan(shapes{k, 2})
        q.psf.moffat_beta = shapes{k, 2};
    end
    I = generate_psf(X, Y, q);
    images{k} = I;

    row      = I(iRow, :);
    above    = x(row >= max(row) / 2);
    fwhm     = above(end) - above(1);
    integral = sum(I(:)) * step^2;
    inRoi    = abs(X) <= roiHalf & abs(Y) <= roiHalf;   % centred star
    roiShare = sum(I(inRoi)) * step^2;

    fprintf('%-16s %8.3f %10.4f %8.3f %9.1f%%\n', ...
            labels{k}, max(I(:)), integral, fwhm, 100 * roiShare);

    % Basic sanity checks (stop on a clear failure)
    assert(all(I(:) >= 0), 'Negative intensity in %s', labels{k});
    assert(abs(fwhm - fwhmTarget) < 0.03, 'FWHM mismatch in %s (%.3f vs %.3f)', ...
           labels{k}, fwhm, fwhmTarget);
end
fprintf(['Integral below 1 for Moffat b=1.5 and Airy is light beyond +/-10 px, not an error.\n' ...
         '"in ROI" = share of light inside the %dx%d ROI for a centred star.\n\n'], ...
        p.sensor.roi_size_px, p.sensor.roi_size_px);

% ---- Figure 1: 2D images ---------------------------------------------------
view = abs(x) <= 4;                   % show +/-4 px
figure('Name', 'PSF shapes (2D)', 'Color', 'w');
tl = tiledlayout(1, nShapes, 'TileSpacing', 'compact');
title(tl, sprintf('PSF shapes, \\sigma = %.1f px (FWHM %.2f px), %dx%d ROI outlined', ...
      p.psf.sigma_px, fwhmTarget, p.sensor.roi_size_px, p.sensor.roi_size_px));
for k = 1:nShapes
    nexttile;
    imagesc(x(view), x(view), images{k}(view, view));
    axis image; set(gca, 'YDir', 'normal');
    colorbar;
    hold on;
    rectangle('Position', [-roiHalf, -roiHalf, 2*roiHalf, 2*roiHalf], ...
              'EdgeColor', 'w', 'LineStyle', '--');
    hold off;
    title(labels{k});
    xlabel('x (px)'); ylabel('y (px)');
end

% ---- Figures 2 and 3: radial profiles --------------------------------------
rPos = x(x >= 0);
figure('Name', 'PSF radial profiles', 'Color', 'w');
tl2 = tiledlayout(1, 2, 'TileSpacing', 'compact');
title(tl2, 'Radial profiles through the centre');

nexttile; hold on;
for k = 1:nShapes
    row = images{k}(iRow, :);
    plot(rPos, row(x >= 0), 'LineWidth', 1.2);
end
xline(fwhmTarget / 2, ':', 'HWHM');
xline(roiHalf, '--', 'ROI edge');
hold off; grid on; xlim([0 5]);
xlabel('r (px)'); ylabel('Intensity (1/px^2)');
title('Linear scale: same FWHM');
legend(labels, 'Location', 'northeast');

nexttile;
for k = 1:nShapes
    row = images{k}(iRow, :);
    semilogy(rPos, row(x >= 0), 'LineWidth', 1.2); hold on;
end
xline(roiHalf, '--', 'ROI edge');
hold off; grid on; xlim([0 10]); ylim([1e-7 1]);
xlabel('r (px)'); ylabel('Intensity (1/px^2), log');
title('Log scale: wings and Airy rings');
legend(labels, 'Location', 'northeast');