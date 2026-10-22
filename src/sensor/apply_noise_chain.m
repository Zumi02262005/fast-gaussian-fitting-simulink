function [img_DN, img_e_noisy] = apply_noise_chain(img_e, p)
% APPLY_NOISE_CHAIN  Turn expected signal electrons into a digitized ROI in DN.
%
%   [img_DN, img_e_noisy] = apply_noise_chain(img_e, p)
%
%   Inputs
%     img_e        : N-by-N expected signal electrons from generate_spot
%     p            : parameter struct from params_baseline
%
%   Outputs
%     img_DN       : N-by-N digitized image (integers, 0 to p.sensor.adc_max_DN),
%                    black level still included
%     img_e_noisy  : N-by-N electrons just before digitizing (useful for Stage 3
%                    validation tests)
%
%   Apply the steps in exactly this order, each one respecting its switch
%   (enable flag, or value 0 for FPN and PRNU):
%     1. Dark charge + background    (expected values, before Poisson)
%     2. PRNU                        (scales light only, not dark charge)
%     3. Shot noise                  (Poisson draw)
%     4. Full-well clip              (the well caps collected charge, before readout)
%     5. FPN + read noise            (Gaussian, in electrons, added at readout)
%     6. Gain, black level, rounding (to DN)
%     7. ADC clip                    (0 to adc_max_DN)
%
%   Current decisions (params_baseline):
%     fpnRule = 'random', prnuRule = 'random'  -> new maps every call (every trial)
%     bg_level_e = 0, black_level_DN = 10, roundRule = 'round'
%
%   Seed the global RNG in the caller with rng(seed) for reproducibility.
%   References: [Wei] Table 1 and Eq. 7 (noise terms), Eq. 13 (gain); [CMV4000].

N = size(img_e, 1);

% ---- Check decisions are made ----------------------------------------------
% TODO: error with a clear message if any of these are unset (NaN or ''):
%       p.noise.bg_level_e, p.sensor.black_level_DN, p.sensor.roundRule,
%       p.noise.fpnRule, p.noise.prnuRule
% TODO: error if fpnRule or prnuRule is not 'random' (the only mode written so far)

% ---- 1. Dark charge and background (expected electrons per pixel) ----------
% TODO: dark = p.noise.dark_e (already dark current x exposure in params_baseline)
% TODO: apply p.noise.enableDark (dark = 0 if disabled)
% TODO: light = img_e + p.noise.bg_level_e     (light = what PRNU scales)

% ---- 2. PRNU (prnuRule = 'random') -----------------------------------------
% TODO: build a new N-by-N multiplier this call: 1 + p.noise.prnu * (standard normal)
%       (p.noise.prnu = 0 gives all ones, i.e. PRNU off)
% TODO: expected = light .* multiplier + dark  (PRNU scales light, not dark charge)

% ---- 3. Shot noise ---------------------------------------------------------
% TODO: if p.noise.enableShot, replace each expected count with a Poisson draw
%       of that mean (poissrnd); otherwise keep the expected value
% NOTE: poissrnd needs the Statistics and Machine Learning Toolbox; if you don't
%       have it, note this and decide on an alternative

% ---- 4. Full-well clip -----------------------------------------------------
% TODO: clip the collected electrons above p.sensor.full_well_e
%       (physically the well fills before readout, so this comes right after
%       the Poisson draw and before read noise and FPN are added)

% ---- 5. FPN and read noise (fpnRule = 'random') -----------------------------
% TODO: add FPN: a new N-by-N Gaussian offset map this call, std p.noise.fpn_e
%       (p.noise.fpn_e = 0 turns it off)
% TODO: if p.noise.enableRead, add zero-mean Gaussian noise with std
%       p.noise.read_noise_e to every pixel
% NOTE: values can now go slightly above full well or below 0; that is real
%       readout behaviour. The black level and the ADC clip in steps 6-7 handle it.
img_e_noisy = NaN(N, N);   % TODO: replace with the result of steps 1-5

% ---- 6. Gain, black level, rounding ----------------------------------------
% TODO: convert electrons to DN: divide by p.sensor.gain_e_per_DN
% TODO: add p.sensor.black_level_DN
% TODO: if p.noise.enableQuant, round using p.sensor.roundRule ('round' -> round,
%       'floor' -> floor); if disabled, keep the continuous value (validation only)

% ---- 7. ADC clip -----------------------------------------------------------
% TODO: clip to the range 0 to p.sensor.adc_max_DN
img_DN = NaN(N, N);        % TODO: replace with the final image

% ---- Reminder for the processing stage -------------------------------------
% The centroiders expect the black level and background removed. Do that in the
% processing step (bgSubtractionRule = 'known': subtract black_level_DN and the
% known background in DN), not here: this function models the sensor, not the processor.

% ---- Self-check ideas (tests/test_noise_stats.m, Stage 3) ------------------
% - Shot only: variance in electrons ~= mean
% - Read only: std ~= 13 e-
% - Quant only, input varying over several DN: std ~= gain/sqrt(12) ~ 3.8 e-
% - Dark frame, all on: mean ~= dark_e/gain + 10 DN, std ~= noise_floor_e/gain ~ 2.9 DN
% - Photon transfer curve: slope of variance(DN^2) vs mean(DN) ~= 1/gain ~ 0.076
end