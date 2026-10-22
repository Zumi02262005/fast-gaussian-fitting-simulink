function snr = compute_snr(img_e, p)
% COMPUTE_SNR  "Truth" SNR of a star from known model values.
%
%   snr = compute_snr(img_e, p)
%
%   Inputs
%     img_e : N-by-N EXPECTED signal electrons from generate_spot (noise-free)
%     p     : parameter struct from params_baseline
%
%   Output
%     snr   : scalar SNR of the star under the chosen definition
%
%   This is the TRUTH SNR, computed from model values the processor never sees.
%   Use it for plot axes and scenario labels only. The supervisor must use the
%   ESTIMATED SNR it computes from the image itself ([Wan] Eq. 19-20).
%
%   Definition: p.detect.snrRule = 'wei_eq8' ([Wei] Eq. 8): mean signal of the
%   second-type pixels divided by the noise at those pixels. For a static star the
%   second-type pixels are the neighbours of the brightest pixel, chosen by
%   p.detect.neighbourRule ('four' = side neighbours, 'eight' = plus diagonals).

% ---- Check decisions are made ----------------------------------------------
if isempty(p.detect.snrRule)
    error('compute_snr:noRule', 'p.detect.snrRule is not set in params_baseline.');
end

switch lower(p.detect.snrRule)
    case 'wei_eq8'
        % First-type pixel: the brightest expected pixel
        [~, idx] = max(img_e(:));
        [r, c]   = ind2sub(size(img_e), idx);

        % Second-type pixels: neighbours of the brightest pixel
        switch lower(p.detect.neighbourRule)
            case 'four'
                offsets = [-1 0; 1 0; 0 -1; 0 1];            % up, down, left, right
            case 'eight'
                offsets = [-1 0; 1 0; 0 -1; 0 1; ...
                           -1 -1; -1 1; 1 -1; 1 1];          % plus diagonals
            otherwise
                error('compute_snr:neighbourRule', ...
                      'Unknown neighbourRule "%s". Use four or eight.', p.detect.neighbourRule);
        end
        rr = r + offsets(:, 1);
        cc = c + offsets(:, 2);
        inside = rr >= 1 & rr <= size(img_e, 1) & cc >= 1 & cc <= size(img_e, 2);  % star near the ROI edge
        s2nd_e = mean(img_e(sub2ind(size(img_e), rr(inside), cc(inside))));

        % ---- Noise at a second-type pixel, [Wei] Eq. 7 (variances add) ------
        % TODO: shot-noise variance = s2nd_e + p.noise.bg_level_e + p.noise.dark_e
        %       (signal, background and dark charge are all Poisson; apply the enable flags)
        % TODO: PRNU variance = (p.noise.prnu * s2nd_e)^2
        % TODO: remaining variances = read_noise_e^2 + fpn_e^2 + gain_e_per_DN^2 / 12
        %       (or reuse p.noise.noise_floor_e^2, which already holds dark + read + FPN + quant)
        %       Careful not to count dark charge twice if you reuse noise_floor_e.
        % TODO: snr = s2nd_e / sqrt(total variance)
        snr = NaN;

    case 'integrated'
        % TODO: total signal in the ROI divided by sqrt(total noise variance in the ROI)
        % NOTE: this one does not change with sub-pixel position
        snr = NaN;

    otherwise
        error('compute_snr:unknownRule', ...
              'Unknown SNR rule "%s". Use wei_eq8 or integrated.', p.detect.snrRule);
end

% ---- Notes -----------------------------------------------------------------
% - The second-type pixels change with sub-pixel position, so compute SNR per trial
%   (or per setting with the star centred) - pick one and state it.
% - Detection limit consistency: p.detect.eta in params_baseline should be the
%   mean second-type share for the same neighbourRule (~0.113 for 'four',
%   ~0.0835 for 'eight' at sigma = 0.7; [Wei] Table 2 gives 0.0831).
% - Self-check: centred sigma = 0.7 Gaussian, S = 5,000 e-, 'four' ->
%   s2nd_e ~ 581 e-, snr ~ 581 / sqrt(581 + 1421 + (0.01*581)^2) ~ 13.0
end