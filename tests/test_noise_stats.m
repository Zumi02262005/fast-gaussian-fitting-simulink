% TEST_NOISE_STATS  Stage 3: validate apply_noise_chain one noise source at a time.
%
% Run from the project root (with src/ and params/ on the path):
%   >> test_noise_stats
%
% Method: switch every noise source off, turn ONE back on, push many flat
% frames through apply_noise_chain, and compare the measured statistic with
% the value theory predicts ([Wei] Table 1 and Eq. 7; [CMV4000]).
%
% Sample size: nFrames x 49 pixels ~ 98,000 samples per test, so a measured
% variance scatters by ~0.5% and a std by ~0.2%. The 2% tolerance below is
% wide enough to pass reliably and tight enough to catch a wrong formula.
%
% Outputs used:
%   img_e_noisy : electrons before digitizing  -> tests 1-4
%   img_DN      : digitized image              -> tests 5-8

p0      = params_baseline();
N       = p0.sensor.roi_size_px;
nFrames = 2000;
tol     = 0.02;                       % relative tolerance
g       = p0.sensor.gain_e_per_DN;    % ~13.18 e-/DN
rng(p0.sim.seed);

fprintf('\n==== Stage 3: noise chain validation (%d frames x %d px) ====\n', nFrames, N^2);

%% 1. Shot noise only: variance = mean (Poisson)
fprintf('\nSHOT NOISE ONLY\n');
p = allOff(p0);  p.noise.enableShot = true;
S = 1000;
[~, E] = runFrames(S * ones(N), p, nFrames);
E_mean     = mean(E, 'all');
E_variance = var(E, 0, 'all');
checkClose('Mean (e-)', E_mean, S, tol);
checkClose('Variance (e-^2)', E_variance, E_mean, tol);

%% 2. Read noise only: std = read_noise_e
fprintf('\nREAD NOISE ONLY\n');
p = allOff(p0);  p.noise.enableRead = true;
[~, E] = runFrames(zeros(N), p, nFrames);
checkClose('Std (e-)', std(E, 0, 'all'), p0.noise.read_noise_e, tol);

%% 3. FPN only: std = fpn_e (fpnRule = 'random', so a new map every frame)
fprintf('\nFPN ONLY\n');
p = allOff(p0);  p.noise.fpn_e = p0.noise.fpn_e;
[~, E] = runFrames(zeros(N), p, nFrames);
checkClose('Std (e-)', std(E, 0, 'all'), p0.noise.fpn_e, tol);

%% 4. PRNU only: std = prnu x signal (it scales with the light)
fprintf('\nPRNU ONLY\n');
p = allOff(p0);  p.noise.prnu = p0.noise.prnu;
for S = [10000 2000]
    [~, E] = runFrames(S * ones(N), p, nFrames);
    checkClose(sprintf('Std at S = %d (e-)', S), std(E, 0, 'all'), p0.noise.prnu * S, tol);
end

%% 5. Quantization only: error std = gain / sqrt(12)
% The input must vary over many DN, or every pixel rounds the same way.
fprintf('\nQUANTIZATION ONLY\n');
p = allOff(p0);  p.noise.enableQuant = true;
D = zeros(N, N, nFrames);
for k = 1:nFrames
    img_e = 1000 * rand(N);
    img_DN = apply_noise_chain(img_e, p);
    D(:, :, k) = (img_DN - p.sensor.black_level_DN) * g - img_e;
end
D_mean = mean(D, 'all');
checkClose('Error std (e-)', std(D, 0, 'all'), g / sqrt(12), tol);
fprintf('%-28s %10.4f   (expect ~0)\n', 'Error mean (e-)', D_mean);
assert(abs(D_mean) < 0.1, 'Quantization mean failed: %.4f (expect ~0)', D_mean);

%% 6. Dark frame, everything on (baseline)
fprintf('\nDARK FRAME, ALL ON\n');
p = p0;
[DN, ~] = runFrames(zeros(N), p, nFrames);
DN_expected_mean = p.noise.dark_e / g + p.sensor.black_level_DN;
DN_expected_std  = sqrt((p.noise.dark_e + p.noise.read_noise_e^2 + p.noise.fpn_e^2) / g^2 + 1/12);
checkClose('Mean (DN)', mean(DN, 'all'), DN_expected_mean, tol);
checkClose('Std (DN)', std(DN, 0, 'all'), DN_expected_std, tol);

%% 7. Clipping: full well and ADC ceiling
fprintf('\nCLIPPING\n');
p = p0;
[DN, ~] = runFrames(20000 * ones(N), p, 200);
assert(max(DN(:)) <= p.sensor.adc_max_DN, 'DN above ADC ceiling: %g', max(DN(:)));
assert(min(DN(:)) >= 0, 'DN below 0: %g', min(DN(:)));
assert(all(DN(:) == round(DN(:))), 'Not all values are whole numbers');
satFraction = mean(DN(:) == p.sensor.adc_max_DN);
fprintf('%-28s %9.2f%%   (expect ~100%%)\n', 'At ADC ceiling', 100 * satFraction);

%% 8. Photon transfer curve (PTC): slope of variance(DN) vs mean(DN) = 1/gain
% Shot + read + quant on; PRNU and FPN off so the curve is a straight line.
% The intercept = read^2 / g^2 + 1/12, the noise floor without signal.
fprintf('\nPHOTON TRANSFER CURVE\n');
p = allOff(p0);  p.noise.enableShot = true;  p.noise.enableRead = true;  p.noise.enableQuant = true;
levels = [0 500 1000 2000 4000 6000 8000 10000];
mDN = zeros(size(levels));  vDN = zeros(size(levels));
for k = 1:numel(levels)
    [DN, ~] = runFrames(levels(k) * ones(N), p, 500);
    mDN(k) = mean(DN, 'all');
    vDN(k) = var(DN, 0, 'all');
end
ptc_fit   = polyfit(mDN, vDN, 1);
ptc_slope = ptc_fit(1);
checkClose('PTC slope (DN^2/DN)', ptc_slope, 1/g, tol);

figure;
plot(mDN, vDN, 'o', mDN, polyval(ptc_fit, mDN), '-');
grid on;
xlabel('Mean (DN)'); ylabel('Variance (DN^2)');
title(sprintf('Photon Transfer Curve (slope = %.4f, expected 1/gain = %.4f)', ptc_slope, 1/g));
legend('Simulated', 'Linear fit', 'Location', 'northwest');

fprintf('\nAll Stage 3 noise checks passed.\n');

%% ---- Local functions ------------------------------------------------------
function p = allOff(p)
% Switch every noise source off (flags false, FPN and PRNU values 0).
p.noise.enableShot  = false;
p.noise.enableRead  = false;
p.noise.enableDark  = false;
p.noise.enableQuant = false;
p.noise.fpn_e       = 0;
p.noise.prnu        = 0;
p.noise.bg_level_e  = 0;
end

function [DN, E] = runFrames(img_e, p, nFrames)
% Run apply_noise_chain nFrames times on the same input.
% DN : N-by-N-by-nFrames digitized images; E : same size, electrons before digitizing.
N  = size(img_e, 1);
DN = zeros(N, N, nFrames);
E  = zeros(N, N, nFrames);
for k = 1:nFrames
    [DN(:, :, k), E(:, :, k)] = apply_noise_chain(img_e, p);
end
end

function checkClose(name, measured, expected, tol)
% Print one result and stop if it is outside the relative tolerance.
fprintf('%-28s %10.4f   (expect %10.4f)\n', name, measured, expected);
assert(abs(measured / expected - 1) < tol, '%s failed: %.4f vs %.4f', name, measured, expected);
end