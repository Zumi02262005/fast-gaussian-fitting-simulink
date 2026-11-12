% TEST_CENTROIDERS  Checks and figures for subtract_background and the centroiders.
%
% Run from the project root (with src/ and params/ on the path):
%   >> test_centroiders
%
% Pipeline under test:
%   generate_spot -> apply_noise_chain -> subtract_background -> centroider
%
% Methods are passed as function handles (@cg, @wcg, ...) so one helper,
% runMethod, runs the full pipeline for any of them. To add GF or Fast GF,
% add a row to the centroiders table below with its expected values.
%
% Expected values come from an independent calculation (Gaussian PSF, 7x7 ROI,
% sigma 0.7 unless stated, true offset +0.3 px in x, negPixelRule = 'clip'):
%                              CG        WCG (W = I, [Wan] Eq. 2)
%   x shift +0.3, noise-free   ~0        -0.011 px
%   max |err|, sigma 0.3       0.054     0.197 px  (S-curve: squaring sharpens the spot)
%   max |err|, sigma 1.5       0.068     0.007 px  (truncation: squaring suppresses the edge)
%   noisy, S = 5,000 e-        bias -0.04, std 0.06   bias -0.014, std 0.026
%   noisy, S = 1,000 e-        bias -0.14, std 0.20   bias -0.065, std 0.155
%
% Figures
%   1. Noise-free error vs true x offset, for several PSF widths
%      (CG solid, WCG dashed, same colour per sigma)
%   2. One ROI (noise-free and noisy) with the true and estimated centroids
%   3. Noisy Monte Carlo scatter at a fixed true position, per method and signal level

p0 = params_baseline();
p0.psf.modelRule = 'gaussian';
p0.psf.sigma_px  = 0.7;
p0.star.signal_e = 5000;
N  = p0.sensor.roi_size_px;
c  = (N + 1) / 2;
rng(p0.sim.seed);

% ---- Methods under test and their expected noise-free values ---------------
%            handle  name   x-shift error  max|err| s0.3  max|err| s1.5  line
centroiders = { @cg,      'CG',  0,       0.054,  0.068,   '-';
                @wcg,     'WCG', -0.011,  0.197,  0.007,   '--';
                @fast_gf, 'FGF', 0.0008,  0.031,  0.00001, ':' };
nM = size(centroiders, 1);

fprintf('\n==== Stage 4: subtract_background and centroiders ====\n');

%% 1. subtract_background: dark frame mean ~ 0 DN
nFrames = 2000;
R = zeros(N, N, nFrames);
for k = 1:nFrames
    R(:, :, k) = subtract_background(apply_noise_chain(zeros(N), p0), p0);
end
fprintf('%-34s %9.4f DN (expect ~0)\n', 'Dark frame mean after subtraction', mean(R, 'all'));
assert(abs(mean(R, 'all')) < 0.02, 'Background not removed correctly');

%% 2. Noise-free checks, every method
q = noiseOff(p0);
for m = 1:nM
    f = centroiders{m, 1};  name = centroiders{m, 2};  expShift = centroiders{m, 3};
    fprintf('\n-- %s --\n', name);

    [xc, yc, s] = runMethod(f, q, c, c);
    fprintf('%-34s (%.6f, %.6f), status %d (expect (%g, %g), 0)\n', 'Centred star', xc, yc, s, c, c);
    assert(s == 0 && abs(xc - c) < 1e-9 && abs(yc - c) < 1e-9, '%s: centred star not at the centre', name);

    [xc, yc, s] = runMethod(f, q, c + 0.3, c);
    fprintf('%-34s %.4f px (expect ~%.3f)\n', 'x shift +0.3 error, sigma 0.7', xc - (c + 0.3), expShift);
    assert(s == 0 && abs((xc - (c + 0.3)) - expShift) < 0.002, '%s: x estimate off for a shifted star', name);
    assert(abs(yc - c) < 1e-9, '%s: x shift moved the y estimate', name);

    [xc, yc, s] = f(zeros(N), q);
    fprintf('%-34s (%g, %g), status %d (expect (NaN, NaN), 1)\n', 'All-zero ROI', xc, yc, s);
    assert(isnan(xc) && isnan(yc) && s == 1, '%s: zero ROI not flagged as failed', name);
end

%% Figure 1: noise-free error vs true x offset
sigmas  = [0.3 0.5 0.7 1.0 1.5];
offsets = linspace(-0.5, 0.5, 101);
colours = lines(numel(sigmas));
fprintf('\n');

fig1 = figure('Name', 'Centroider noise-free bias', 'Color', 'w', 'Position', [100 100 900 550]);
setLightTheme(fig1);
hold on;
hLeg = gobjects(0);  legText = {};
for m = 1:nM
    f = centroiders{m, 1};  name = centroiders{m, 2};
    err = zeros(numel(sigmas), numel(offsets));
    for i = 1:numel(sigmas)
        q.psf.sigma_px = sigmas(i);
        for k = 1:numel(offsets)
            xc = runMethod(f, q, c + offsets(k), c);
            err(i, k) = xc - (c + offsets(k));
        end
    end
    q.psf.sigma_px = p0.psf.sigma_px;

    % Antisymmetry: error(-d) = -error(d) for a symmetric PSF in a symmetric ROI
    asym = max(abs(err + fliplr(err)), [], 'all');
    fprintf('%-34s %.1e (expect < 1e-9)\n', sprintf('%s antisymmetry', name), asym);
    assert(asym < 1e-9, '%s error is not antisymmetric', name);
    fprintf('%-34s %.4f px (expect ~%.3f)\n', sprintf('%s max |error|, sigma 0.3', name), ...
            max(abs(err(1, :))), centroiders{m, 4});
    fprintf('%-34s %.4f px (expect ~%.3f)\n', sprintf('%s max |error|, sigma 1.5', name), ...
            max(abs(err(end, :))), centroiders{m, 5});

    for i = 1:numel(sigmas)
        h = plot(offsets, err(i, :), centroiders{m, 6}, 'Color', colours(i, :), 'LineWidth', 1.2);
        hLeg(end + 1) = h;                                         %#ok<SAGROW>
        legText{end + 1} = sprintf('%s, \\sigma = %.1f px', name, sigmas(i)); %#ok<SAGROW>
    end
end
yline(0, ':');
hold off; grid on;
xlabel('True x offset from pixel centre (px)');
ylabel('Error, estimate - true (px)');
title('Noise-free bias vs sub-pixel position (Gaussian PSF, 7x7 ROI): CG solid, WCG dashed');
legend(hLeg, legText, 'Location', 'eastoutside');

%% Figure 2: one ROI, noise-free and noisy, with true and estimated centroids
xt = c + 0.3;  yt = c - 0.2;
img_e = generate_spot(p0, xt, yt);
roiClean = subtract_background(apply_noise_chain(img_e, q), q);
roiNoisy = subtract_background(apply_noise_chain(img_e, p0), p0);
rois    = {roiClean, roiNoisy};
names2  = {'Noise-free', 'Noisy'};
markers = {'rx', 'co', 'ms', 'y^'};          % one marker per method

fig2 = figure('Name', 'Centroiders on one ROI', 'Color', 'w', 'Position', [100 100 1000 450]);
setLightTheme(fig2);
tl = tiledlayout(1, 2, 'TileSpacing', 'compact');
title(tl, sprintf('One star (\\sigma = %.1f px, S = %d e^-), true centroid (%.1f, %.1f)', ...
      p0.psf.sigma_px, p0.star.signal_e, xt, yt));
for k = 1:2
    nexttile;
    imagesc(1:N, 1:N, rois{k});
    axis image; colormap(gca, gray); cb = colorbar; cb.Label.String = 'DN';
    hold on;
    plot(xt, yt, 'g+', 'MarkerSize', 14, 'LineWidth', 2);
    errText = {};
    for m = 1:nM
        [xe, ye] = centroiders{m, 1}(rois{k}, p0);
        plot(xe, ye, markers{m}, 'MarkerSize', 12, 'LineWidth', 2);
        errText{end + 1} = sprintf('%s (%.3f, %.3f)', centroiders{m, 2}, xe - xt, ye - yt); %#ok<SAGROW>
    end
    hold off;
    title({names2{k}, ['error: ' strjoin(errText, ', ')]});
    xlabel('x (column, px)'); ylabel('y (row, px)');
    legend([{'True'}, centroiders(:, 2)'], 'Location', 'southoutside', 'Orientation', 'horizontal');
end

%% Figure 3: noisy Monte Carlo scatter at a fixed true position
nTrials = 500;
levels  = [5000 1000];
xt = c + 0.3;  yt = c;
fig3 = figure('Name', 'Centroiders noisy scatter', 'Color', 'w', 'Position', [100 100 1000 850]);
setLightTheme(fig3);
tl3 = tiledlayout(nM, numel(levels), 'TileSpacing', 'compact');
title(tl3, sprintf('Estimates over %d noisy trials (true centroid +0.3 px in x, negPixelRule = %s)', ...
      nTrials, p0.centroid.negPixelRule));
fprintf('\nNoisy trials (true x offset +0.3 px, sigma %.1f)\n', p0.psf.sigma_px);
for m = 1:nM
    f = centroiders{m, 1};  name = centroiders{m, 2};
    for j = 1:numel(levels)
        pj = p0;  pj.star.signal_e = levels(j);
        est = zeros(nTrials, 2);  st = zeros(nTrials, 1);
        for k = 1:nTrials
            [est(k, 1), est(k, 2), st(k)] = runMethod(f, pj, xt, yt);
        end
        ok   = st == 0;
        bias = mean(est(ok, :) - [xt yt], 1);
        sd   = std(est(ok, :), 0, 1);
        fprintf('  %-4s S = %5d e-: bias (%.3f, %.3f) px, std (%.3f, %.3f) px, failures %d\n', ...
                name, levels(j), bias, sd, sum(~ok));

        nexttile;
        plot(est(ok, 1), est(ok, 2), '.', 'MarkerSize', 6); hold on;
        plot(xt, yt, 'g+', 'MarkerSize', 16, 'LineWidth', 2);
        plot(mean(est(ok, 1)), mean(est(ok, 2)), 'rx', 'MarkerSize', 16, 'LineWidth', 2);
        plot(c, c, 'ko', 'MarkerSize', 8);
        hold off; axis equal; grid on;
        xlim(xt + [-0.6 0.6]); ylim(yt + [-0.6 0.6]);
        xlabel('x (px)'); ylabel('y (px)');
        title(sprintf('%s, S = %d e^-: bias x = %.3f, std x = %.3f px', name, levels(j), bias(1), sd(1)));
    end
end
lg = legend('Estimates', 'True', 'Mean estimate', 'ROI centre', 'Orientation', 'horizontal');
lg.Layout.Tile = 'south';

fprintf('\nAll subtract_background and centroider checks passed.\n');

%% ---- Local functions ------------------------------------------------------
function q = noiseOff(q)
% Switch every noise source off (flags false, FPN and PRNU values 0).
q.noise.enableShot  = false;
q.noise.enableRead  = false;
q.noise.enableDark  = false;
q.noise.enableQuant = false;
q.noise.fpn_e       = 0;
q.noise.prnu        = 0;
q.noise.bg_level_e  = 0;
end

function [xc, yc, status] = runMethod(method, p, xt, yt)
% Full pipeline for one star at (xt, yt), using the given centroider (e.g. @cg, @wcg).
img_e = generate_spot(p, xt, yt);
roi   = subtract_background(apply_noise_chain(img_e, p), p);
[xc, yc, status] = method(roi, p);
end

function setLightTheme(fig)
% Force a white figure for the report even when MATLAB is in dark mode.
if exist('theme', 'file') || exist('theme', 'builtin')
    theme(fig, 'light');
end
end