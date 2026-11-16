function [rmsRadial, rmsX, rmsY, nUsed] = rms_error(xEst, yEst, xTrue, yTrue)
% RMS_ERROR  Root-mean-square centroiding error over the successful trials.
%
%   [rmsRadial, rmsX, rmsY, nUsed] = rms_error(xEst, yEst, xTrue, yTrue)
%
%   Inputs  : as in centroid_error (NaN marks a failed trial)
%   Outputs
%     rmsRadial : sqrt(mean(e.^2)), e from [Wan] Eq. 23   (the proposal's metric)
%     rmsX/rmsY : sqrt(mean(dx.^2)), sqrt(mean(dy.^2)) per axis
%     nUsed     : number of successful trials the RMS is taken over
%
%   Notes
%   - RMS includes BOTH bias and spread: rms^2 = bias^2 + std^2 (per axis).
%     So a biased method (CG with 'clip' at low S) is penalised here even if
%     its spread is small. Report bias and std separately too (error_summary).
%   - Failed trials (NaN) are excluded, so ALWAYS report the failure rate next
%     to the RMS; otherwise a method that fails on the hard trials looks better
%     than it is.
%   - rmsRadial^2 = rmsX^2 + rmsY^2 (a quick self-check).

% TODO: [dx, dy, e] = centroid_error(xEst, yEst, xTrue, yTrue)
% TODO: ok = trials where e is not NaN; nUsed = number of them
% TODO: if nUsed == 0: return NaN for all three RMS values (avoid 0/0 warnings)
% TODO: rmsRadial, rmsX, rmsY over the ok trials only
rmsRadial = NaN;  rmsX = NaN;  rmsY = NaN;  nUsed = 0;   % TODO: replace

% Self-check: errors (0.3, 0) and (0, 0.4), one NaN trial
%   -> rmsX = sqrt(0.045) = 0.2121, rmsY = sqrt(0.08) = 0.2828,
%      rmsRadial = sqrt((0.09 + 0.16)/2) = 0.3536, nUsed = 2
end