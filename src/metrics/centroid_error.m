function [dx, dy, e] = centroid_error(xEst, yEst, xTrue, yTrue)
% CENTROID_ERROR  Per-trial centroiding error ([Wan] Eq. 23).
%
%   [dx, dy, e] = centroid_error(xEst, yEst, xTrue, yTrue)
%
%   Inputs  (vectors of the same length, one entry per trial)
%     xEst, yEst   : estimated centroids (NaN where the method failed)
%     xTrue, yTrue : true centroids
%
%   Outputs (same length as the inputs; NaN where the method failed)
%     dx, dy : signed error per axis, estimate - true (px)
%     e      : Euclidean (radial) error, [Wan] Eq. 23:
%              e = sqrt((xEst - xTrue)^2 + (yEst - yTrue)^2)
%
%   This is the building block for every other metric. It does NOT drop
%   failures: NaN stays NaN, so the caller can still count them.

% TODO: check that all four inputs have the same number of elements
%       (error with a clear message if not)
% TODO: make all four column vectors (x(:)) so row/column inputs both work
% TODO: dx = estimate - true, dy likewise
% TODO: e  = Euclidean distance, Eq. 23 (hint: hypot, which also passes NaN through)
if ~isequal(numel(xEst), numel(yEst), numel(xTrue), numel(yTrue))
    error('centroid_error:SizeMismatch', 'All inputs must have the same number of elements.');
end
xEst = xEst(:); yEst = yEst(:); xTrue = xTrue(:); yTrue = yTrue(:);
dx = xEst - xTrue; dy = yEst - yTrue; e = hypot(dx, dy);

% Self-check: centroid_error([4.3 NaN], [4 4], [4 4], [4 4])
%   -> dx = [0.3; NaN], dy = [0; NaN], e = [0.3; NaN]
end