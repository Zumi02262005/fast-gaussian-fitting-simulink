function [meanE, nUsed] = mean_error(xEst, yEst, xTrue, yTrue)
% MEAN_ERROR  Mean Euclidean centroiding error, as [Wan] reports it.
%
%   [meanE, nUsed] = mean_error(xEst, yEst, xTrue, yTrue)
%
%   [Wan] Sec. 3.3: "the mean centroiding error of the 10,000 images is used as
%   the centroiding error", with the per-image error from Eq. 23. Use this
%   metric when comparing your numbers with Wan's figures.
%
%   Inputs  : as in centroid_error (NaN marks a failed trial)
%   Outputs
%     meanE : mean of e over the successful trials (px)
%     nUsed : number of successful trials
%
%   Note: for the same data meanE < rmsRadial (the mean of a positive quantity
%   is below its RMS). Don't compare one paper's mean with another's RMS.

% TODO: e from centroid_error; keep the non-NaN trials; nUsed = their count
% TODO: meanE = mean of those (NaN if nUsed == 0)
meanE = NaN;  nUsed = 0;   % TODO: replace

% Self-check: errors 0.3 and 0.4 (one NaN trial) -> meanE = 0.35, nUsed = 2
end