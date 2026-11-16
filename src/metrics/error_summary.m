function s = error_summary(xEst, yEst, xTrue, yTrue)
% ERROR_SUMMARY  All accuracy metrics for one method at one setting, in one struct.
%
%   s = error_summary(xEst, yEst, xTrue, yTrue)
%
%   The experiments call this once per (method, setting) and store s, so every
%   table and plot is built from the same numbers.
%
%   Inputs  : as in centroid_error (NaN marks a failed trial)
%   Output struct s:
%     s.nTrials     total trials
%     s.nFailed     trials where the method returned NaN (status ~= 0)
%     s.failRate    nFailed / nTrials
%     s.biasX/Y     mean(dx), mean(dy)            (systematic error, e.g. clip pull)
%     s.stdX/Y      std(dx), std(dy)              (random error)
%     s.rmsRadial   from rms_error                (proposal metric)
%     s.meanE       from mean_error               ([Wan] Sec. 3.3 metric)
%     s.medianE     median(e)                     (robust to the few wild FGF fits)
%     s.p95E        95th percentile of e          (worst-case-ish; no toolbox needed)
%   All statistics are over the successful trials only.
%
%   Why so many: FGF at low S showed std x = 0.56 px but median 0.10 px - a few
%   wild fits dominate the std and RMS. Reporting median, p95 and the failure
%   rate alongside RMS keeps that visible.

% TODO: [dx, dy, e] = centroid_error(...); ok = ~isnan(e)
% TODO: counts: nTrials, nFailed, failRate
% TODO: bias and std per axis over ok trials
% TODO: rmsRadial via rms_error, meanE via mean_error (reuse; don't recompute by hand)
% TODO: medianE = median(e(ok))
% TODO: p95E: sort e(ok) and take the value at index ceil(0.95 * nUsed)
%       (prctile would also work but needs the Statistics Toolbox)
% TODO: if no trial succeeded, fill every statistic with NaN (failRate = 1)
s = struct();   % TODO: replace

% Self-check: run on CG output from test_centroiders' Figure 3 (sigma 0.7,
% S = 5,000, true +0.3 px): biasX ~ -0.04, stdX ~ 0.06, failRate 0,
% and rmsX^2 ~ biasX^2 + stdX^2.
end