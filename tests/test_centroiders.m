% TEST_CENTROIDERS  Checks and figures for subtract_background and cg.
%
% Run from the project root (with src/ and params/ on the path):
%   >> test_centroiders
%
% Pipeline under test:
%   generate_spot -> apply_noise_chain -> subtract_background -> cg
%
% Figures
%   1. Noise-free CG error vs true x offset, for several PSF widths
%      - sigma 0.3 (narrower than the sweep, shown for reference): classic
%        pixelation S-curve, +/-0.054 px, peaks at +/-0.25 px, zero at 0 and +/-0.5
%      - sigma 0.5 to 1.0: almost no bias (< 0.005 px)
%      - sigma 1.5: ROI truncation, pulls toward the ROI centre (up to 0.068 px)
%   2. One ROI image (noise-free and noisy) with true and estimated centroids
%   3. Noisy Monte Carlo scatter at a fixed true position, two signal levels:
%      the spread grows at low signal, and negPixelRule = 'clip' pulls the cloud
%      toward the ROI centre. Expected for a true offset of +0.3 px in x:
%        S = 5,000 e-: bias x ~ -0.04 px, std ~ 0.06 px per axis
%        S = 1,000 e-: bias x ~ -0.14 px, std ~ 0.20 px per axis
%      (bias y ~ 0 in both, since the true y is at the centre)

p0 = params_baseline();
p0.psf.modelRule = 'gaussian';
p0.psf.sigma_px  = 0.7;
p0.star.signal_e = 5000;
N  = p0.sensor.roi_size_px;
c  = (N + 1) / 2;
rng(p0.sim.seed);

fprintf('\n==== Stage 4: subtract_background and cg ====\n');

%% 1. subtract_background: dark frame mean ~ 0 DN
nFrames = 2000;
R = zeros(N, N, nFrames);
for k = 1:nFrames
    R(:, :, k) = subtract_background(apply_noise_chain(zeros(N), p0), p0);
end
fprintf('%-34s %9.4f DN (expect ~0)\n', 'Dark frame mean after subtraction', mean(R, 'all'));
assert(abs(mean(R, 'all')) < 0.02, 'Background not removed correctly');

%% 2. Noise-free checks
q = noiseOff(p0);

[xc, yc, s] = runCG(q, c, c);
fprintf('%-34s (%.6f, %.6f), status %d (expect (%g, %g), 0)\n', 'Centred star', xc, yc, s, c, c);
assert(s == 0 && abs(xc - c) < 1e-9 && abs(yc - c) < 1e-9, 'Centred star not at the centre');

[xc, yc, s] = runCG(q, c + 0.3, c);
fprintf('%-34s (%.6f, %.6f), status %d (expect (~%.1f, %g), 0)\n', 'x shift +0.3, sigma 0.7', xc, yc, s, c + 0.3, c);
assert(abs(xc - (c + 0.3)) < 0.001, 'x estimate off for a shifted star');
assert(abs(yc - c) < 1e-9, 'x shift moved the y estimate');

[xc, yc, s] = cg(zeros(N), q);
fprintf('%-34s (%g, %g), status %d (expect (NaN, NaN), 1)\n', 'All-zero ROI', xc, yc, s);
assert(isnan(xc) && isnan(yc) && s == 1, 'Zero ROI not flagged as failed');

%% Figure 1: noise-free error vs true x offset
sigmas  = [0.3 0.5 0.7 1.0 1.5];
offsets = linspace(-0.5, 0.5, 101);
err     = zeros(numel(sigmas), numel(offsets));
for i = 1:numel(sigmas)
    q.psf.sigma_px = sigmas(i);
    for k = 1:numel(offsets)
        xc = runCG(q, c + offsets(k), c);
        err(i, k) = xc - (c + offsets(k));
    end
end
q.psf.sigma_px = p0.psf.sigma_px;

% Antisymmetry: error(-d) = -error(d) for a symmetric PSF in a symmetric ROI
asym = max(abs(err + fliplr(err)), [], 'all');
fprintf('%-34s %.1e (expect < 1e-9)\n', 'S-curve antisymmetry', asym);
assert(asym < 1e-9, 'CG error is not antisymmetric');
fprintf('%-34s %.4f px (expect ~0.054)\n', 'Max |error|, sigma 0.3', max(abs(err(1, :))));
fprintf('%-34s %.4f px (expect ~0.068)\n', 'Max |error|, sigma 1.5', max(abs(err(end, :))));

fig1 = figure('Name', 'CG noise-free bias', 'Color', 'w');
setLightTheme(fig1);
plot(offsets, err, 'LineWidth', 1.2);
yline(0, ':');
grid on;
xlabel('True x offset from pixel centre (px)');
ylabel('CG error, estimate - true (px)');
title('Noise-free CG bias vs sub-pixel position (Gaussian PSF, 7x7 ROI)');
legend(compose('\\sigma = %.1f px', sigmas), 'Location', 'best');

%% Figure 2: one ROI, noise-free and noisy, with true and estimated centroids
xt = c + 0.3;  yt = c - 0.2;
img_e = generate_spot(p0, xt, yt);
roiClean = subtract_background(apply_noise_chain(img_e, q), q);
roiNoisy = subtract_background(apply_noise_chain(img_e, p0), p0);
[xcC, ycC] = cg(roiClean, p0);
[xcN, ycN] = cg(roiNoisy, p0);

fig2 = figure('Name', 'CG on one ROI', 'Color', 'w', 'Position', [100 100 1000 420]);
setLightTheme(fig2);
tl = tiledlayout(1, 2, 'TileSpacing', 'compact');
title(tl, sprintf('CG on one star (\\sigma = %.1f px, S = %d e^-)', p0.psf.sigma_px, p0.star.signal_e));
rois = {roiClean, roiNoisy};  ests = [xcC ycC; xcN ycN];  names = {'Noise-free', 'Noisy'};
for k = 1:2
    nexttile;
    imagesc(1:N, 1:N, rois{k});
    axis image; colormap(gca, gray); cb = colorbar; cb.Label.String = 'DN';
    hold on;
    plot(xt, yt, 'g+', 'MarkerSize', 14, 'LineWidth', 2);
    plot(ests(k, 1), ests(k, 2), 'rx', 'MarkerSize', 14, 'LineWidth', 2);
    hold off;
    title(sprintf('%s: error (%.3f, %.3f) px', names{k}, ests(k, 1) - xt, ests(k, 2) - yt));
    xlabel('x (column, px)'); ylabel('y (row, px)');
    legend('True', 'CG', 'Location', 'southoutside', 'Orientation', 'horizontal');
end

%% Figure 3: noisy Monte Carlo scatter at a fixed true position
nTrials = 500;
levels  = [5000 1000];
xt = c + 0.3;  yt = c;
fig3 = figure('Name', 'CG noisy scatter', 'Color', 'w', 'Position', [100 100 1000 420]);
setLightTheme(fig3);
tl3 = tiledlayout(1, numel(levels), 'TileSpacing', 'compact');
title(tl3, sprintf('CG estimates over %d noisy trials (true centroid +0.3 px in x)', nTrials));
fprintf('\nNoisy trials (true x offset +0.3 px, sigma %.1f, negPixelRule = %s)\n', ...
        p0.psf.sigma_px, p0.centroid.negPixelRule);
for j = 1:numel(levels)
    pj = p0;  pj.star.signal_e = levels(j);
    est = zeros(nTrials, 2);  st = zeros(nTrials, 1);
    for k = 1:nTrials
        [est(k, 1), est(k, 2), st(k)] = runCG(pj, xt, yt);
    end
    ok   = st == 0;
    bias = mean(est(ok, :) - [xt yt], 1);
    sd   = std(est(ok, :), 0, 1);
    fprintf('  S = %5d e-: bias (%.3f, %.3f) px, std (%.3f, %.3f) px, failures %d\n', ...
            levels(j), bias, sd, sum(~ok));

    nexttile;
    plot(est(ok, 1), est(ok, 2), '.', 'MarkerSize', 6); hold on;
    plot(xt, yt, 'g+', 'MarkerSize', 16, 'LineWidth', 2);
    plot(mean(est(ok, 1)), mean(est(ok, 2)), 'rx', 'MarkerSize', 16, 'LineWidth', 2);
    plot(c, c, 'ko', 'MarkerSize', 8);
    hold off; axis equal; grid on;
    xlim(xt + [-0.6 0.6]); ylim(yt + [-0.6 0.6]);
    xlabel('x (px)'); ylabel('y (px)');
    title(sprintf('S = %d e^-: bias x = %.3f px', levels(j), bias(1)));
    legend('Estimates', 'True', 'Mean estimate', 'ROI centre', 'Location', 'southoutside', ...
           'Orientation', 'horizontal');
end

fprintf('\nAll subtract_background and cg checks passed.\n');

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

function [xc, yc, status] = runCG(p, xt, yt)
% Full pipeline for one star at the true position (xt, yt).
img_e = generate_spot(p, xt, yt);
roi   = subtract_background(apply_noise_chain(img_e, p), p);
[xc, yc, status] = cg(roi, p);
end

function setLightTheme(fig)
% Force a white figure for the report even when MATLAB is in dark mode.
if exist('theme', 'file') || exist('theme', 'builtin')
    theme(fig, 'light');
end
end