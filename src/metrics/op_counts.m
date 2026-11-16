function [ops, cycles] = op_counts(method, N, info, p)
% OP_COUNTS  Analytic operation count (and estimated cycles) for one centroid.
%
%   ops           = op_counts(method, N, info)
%   [ops, cycles] = op_counts(method, N, info, p)
%
%   Inputs
%     method : 'cg', 'wcg', 'fast_gf', 'gauss_fit_std' (or 'supervisor' later)
%     N      : ROI side (7), so n = N^2 pixels
%     info   : run details that change the count (from the method's 4th output):
%                fast_gf       -> info.nPixels (|U| in step 2); step 1 uses 9 (box3)
%                gauss_fit_std -> info.iterations
%              pass struct() for cg / wcg
%     p      : parameter struct (only needed for cycles; uses p.proc.cyclesPerOp)
%
%   Outputs
%     ops    : struct with counts of each operation class:
%                add (incl. subtract), mul, div, sqrt, exp, log, cmp (compare/abs/max)
%     cycles : estimated cycles = sum over classes of count * cyclesPerOp
%
%   Why this exists: Stage 8 measures cycles on the board. This gives the
%   PREDICTION to compare against. The gap between predicted and measured
%   cycles is itself a result - it is how you "estimate model accuracy"
%   (rubric, Complex problem solving, Exemplary). It also lets you explain WHY a
%   method costs what it costs (e.g. GF's exp calls per iteration).
%
%   Counting rules (state these in the report):
%   - Count what the C code on the MCU will do, not what MATLAB does
%     internally (e.g. Fast GF in MATLAB uses QR via '\'; if the C code solves
%     the 5x5 normal equations, count that).
%   - Pixel coordinates X, Y and x^2, y^2 are constants (precomputed tables),
%     so building them costs nothing per star.
%   - A sum of n values is n - 1 adds; a dot product of length n is n mul + n - 1 add.
%   - Ignore loop overhead and memory loads here; they show up as the gap to
%     the measured cycles.

if nargin < 3 || isempty(info), info = struct(); end
n = N^2;
ops = struct('add', 0, 'mul', 0, 'div', 0, 'sqrt', 0, 'exp', 0, 'log', 0, 'cmp', 0);

switch lower(method)
    case 'cg'
        % Worked example - use it as the pattern for the others.
        % clip:            n compares (max with 0)
        % DN = sum(roi):   n - 1 adds                              ([Liebe] Eq. 9)
        % sum(X .* roi):   n mul + (n - 1) add; same for Y          (Eq. 10-11)
        % two divisions by DN; one compare for the DN <= 0 guard
        ops.cmp = n + 1;
        ops.add = 3 * (n - 1);
        ops.mul = 2 * n;
        ops.div = 2;

    case 'wcg'
        % TODO: same structure as cg, plus the cost of the weights.
        %       With W = I, W .* I is one extra multiply per pixel (I^2).
        %       Then the three sums run over I^2 instead of I.

    case 'fast_gf'
        % TODO: count step 1 (fit on the 9 box3 pixels) and step 2 (fit on
        %       u = info.nPixels pixels) with ONE helper count for "a fit on m
        %       pixels", called twice. For a fit on m pixels:
        %       - log: m (ln I)
        %       - design matrix D (m x 5): I*x^2, I*y^2, I*x, I*y -> 4m mul
        %       - b = -I .* ln I: m mul
        %       - normal equations M = D'*D: 15 unique entries (symmetric 5x5),
        %         each a length-m dot product; D'*b: 5 dot products
        %       - 5x5 solve: e.g. Cholesky ~ n^3/6 multiply-adds for n = 5 plus
        %         5 sqrt or divides - pick the solver your C code uses and count it
        %       - Eq. 17: a few mul/div, 2 sqrt (sigmas), 1 exp (A)
        %       Between the fits (step 1 -> step 2), over all n pixels:
        %       - S_hat (Eq. 18): n exp plus ~6 mul/add per pixel
        %       - N_hat = I - S_hat: n add; SNR = |S_hat ./ N_hat|: n div, n cmp
        %       - threshold (Eq. 21): n cmp; brightest-pixel search: n cmp
        %       Check: exp and log should dominate the cycles on the MCU.

    case 'gauss_fit_std'
        % TODO: initial guess = the wcg count, plus a max search (n cmp).
        %       Then, PER ITERATION (k = info.iterations):
        %       - model + Jacobian at n pixels: n exp, ~10 mul/add per pixel
        %       - residuals r = I - S: n add
        %       - H = J'*J (15 unique entries) and J'*r (5): dot products of length n
        %       - damped 5x5 solve (as above)
        %       - cost of the trial step: model again at n pixels (n exp, ...)
        %         plus sum of squares (n mul, n - 1 add)
        %       Total = init + k * (per-iteration count).
        %       Rejected LM steps also cost an iteration - info.iterations
        %       should count them (check your loop).

    otherwise
        error('op_counts:unknownMethod', 'Unknown method "%s".', method);
end

% ---- Estimated cycles ------------------------------------------------------
if nargout > 1
    % TODO: error if p is missing or p.proc.cyclesPerOp is not set
    % TODO: cycles = sum over the field names of ops.(f) * p.proc.cyclesPerOp.(f)
    %       (hint: fieldnames(ops) and a loop)
    cycles = NaN;   % TODO: replace
end

% ---- Decisions to add to params_baseline (board-dependent) -----------------
% p.proc.cyclesPerOp = struct('add', ?, 'mul', ?, 'div', ?, 'sqrt', ?, ...
%                             'exp', ?, 'log', ?, 'cmp', ?);
% - add/mul/div/sqrt: from the core's Technical Reference Manual (FPU
%   instruction timing). Single vs double precision differ, and on a core
%   without a double-precision FPU, double ops are software (much slower).
%   Look these up for the exact board once you have its part number.
% - exp/log: library calls, not single instructions - no fixed number in the
%   manual. Measure them on the board (time 1,000 calls with the cycle
%   counter) and put the measured value here.
%
% Self-check: op_counts('cg', 7, struct()) -> add 144, mul 98, div 2, cmp 50
end