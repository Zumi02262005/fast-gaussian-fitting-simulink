function [xc, yc, status, info] = gauss_fit_std(roi, p)
% GAUSS_FIT_STD  Standard Gaussian fitting centroid (nonlinear least squares, [Wan] Eq. 4-5).
%
%   [xc, yc, status]       = gauss_fit_std(roi, p)
%   [xc, yc, status, info] = gauss_fit_std(roi, p)   % also returns fit details
%
%   Inputs
%     roi    : N-by-N star signal in DN, background removed (subtract_background)
%     p      : parameter struct from params_baseline
%
%   Outputs
%     xc, yc : estimated centroid in pixel coordinates (pixelCoordRule = 'integer')
%     status : 0 = OK
%              1 = no signal          (the initial-guess method failed)
%              3 = invalid fit        (sigma <= 0 that damping can't fix, or a singular step)
%              4 = not converged      (gf_max_iter reached)
%              On any failure, xc = yc = NaN.
%     info   : info.iterations - iterations used, including rejected LM steps
%                                (cycle cost on the MCU scales with this)
%              info.A, info.sigma - fitted amplitude and [sigma_x sigma_y]
%
%   Same first three outputs as cg / wcg / fast_gf; codes 1 and 3 mean the same.
%
%   Model ([Wan] Eq. 4), 5 parameters t = [A, xc, yc, sx, sy]:
%     S_i = A * exp( -(x_i - xc)^2 / (2 sx^2) - (y_i - yc)^2 / (2 sy^2) )
%   Objective ([Wan] Eq. 5): minimise sum over all N^2 pixels of (I_i - S_i)^2
%   No background term: the background is 'known' and already subtracted.
%
%   Decisions (params_baseline):
%     gfSolverRule     = 'lm'    Levenberg-Marquardt ([Wan] Sec. 2.2 cites it, ref. [18])
%     gfInitGuessRule  = 'wcg'   centre from wcg, A = brightest pixel, sigma = gf_sigma0_px
%     gf_tol_px        = 1e-6    stop when the centroid step is below this (both axes)
%     gf_max_iter      = 50      runaway guard; typical fits take ~4-13 iterations
%     gf_lambda0       = 1e-3    starting LM damping
%     gf_lambda_factor = 10      damping is divided by this after a good step, multiplied after a bad one
%     gf_sigma0_px     = 1       starting width (the processor does not know the true sigma)
%     negPixelRule     = 'clip'  required: the initial guess (wcg) only accepts 'clip'
%
%   Why LM and not plain Gauss-Newton: with lambda -> 0 the step IS Gauss-Newton
%   (fast near the answer); with large lambda it becomes a small, safe gradient
%   step (robust far from it). Rejecting steps that raise the cost is what keeps
%   it from diverging.
%
%   References: [Wan] Eq. 4-5 and Sec. 2.2; LM: Moré (1978), cited by [Wan] as ref. [18].

% ---- Check decisions are made ----------------------------------------------
centroidP = p.centroid;

numericFields = [ ...
    centroidP.gf_tol_px, ...
    centroidP.gf_max_iter, ...
    centroidP.gf_lambda0, ...
    centroidP.gf_lambda_factor, ...
    centroidP.gf_sigma0_px];

if any(isnan(numericFields))
    error('gauss_fit_std:InvalidParameter', 'Centroid Gaussian-fit parameters must not be NaN.');
end

if isempty(centroidP.gfSolverRule) || ~strcmpi(centroidP.gfSolverRule, 'lm')
    error('gauss_fit_std:InvalidParameter', 'gfSolverRule must be ''lm''.');
end

if isempty(centroidP.gfInitGuessRule) || ~strcmpi(centroidP.gfInitGuessRule, 'wcg')
    error('gauss_fit_std:InvalidParameter', 'gfInitGuessRule must be ''wcg''.');
end

if isempty(centroidP.negPixelRule) || ~strcmpi(centroidP.negPixelRule, 'clip')
    error('gauss_fit_std:InvalidParameter', ...
          'negPixelRule must be ''clip'' (the wcg initial guess does not accept ''keep'').');
end

if centroidP.gf_tol_px <= 0 || centroidP.gf_max_iter < 1 || centroidP.gf_lambda0 <= 0 || ...
        centroidP.gf_lambda_factor <= 1 || centroidP.gf_sigma0_px <= 0
    error('gauss_fit_std:InvalidParameter', 'Gaussian-fit parameters must be positive and valid.');
end

xc = NaN;
yc = NaN;
status = 1;
info = struct('iterations', 0, 'A', NaN, 'sigma', [NaN NaN]);

% ---- Pixels as column vectors ----------------------------------------------
roi = double(roi);
roi(roi < 0) = 0;                       % negPixelRule = 'clip'

[nRows, nCols] = size(roi);
[X, Y] = meshgrid(1:nCols, 1:nRows);

I = roi(:);
x = X(:);
y = Y(:);

% ---- Initial guess ----------------------------------------------------------
[x0, y0, st0] = wcg(roi, p);
if st0 ~= 0
    return
end

t = [max(I); x0; y0; centroidP.gf_sigma0_px; centroidP.gf_sigma0_px];
S = gaussModel(t, x, y);                % model only; no Jacobian needed here
cost = sum((I - S).^2);
lambda = centroidP.gf_lambda0;
lambdaFactor = centroidP.gf_lambda_factor;
tol = centroidP.gf_tol_px;

% ---- Levenberg-Marquardt loop ----------------------------------------------
for it = 1:centroidP.gf_max_iter
    [S, J] = gaussModel(t, x, y);
    r = I - S;

    H = J' * J;
    grad = J' * r;

    dampedH = H + lambda * diag(diag(H));
    if rcond(dampedH) < 1e-12
        info.iterations = it;
        info.A = t(1);
        info.sigma = t(4:5).';
        status = 3;
        return
    end

    d = dampedH \ grad;
    tNew = t + d;

    if tNew(4) <= 0 || tNew(5) <= 0     % sigma must stay positive
        lambda = lambda * lambdaFactor;
        continue
    end

    Snew = gaussModel(tNew, x, y);
    costNew = sum((I - Snew).^2);
    tinyStep = abs(d(2)) < tol && abs(d(3)) < tol;

    if costNew < cost                   % good step: accept it
        t = tNew;
        cost = costNew;
        lambda = lambda / lambdaFactor;
        converged = tinyStep;
    else                                % bad step: reject it, damp more
        lambda = lambda * lambdaFactor;
        % At the optimum, rounding can make a tiny step look "not better".
        % Treat that as converged only if the cost is unchanged to rounding
        % level - a tiny step from heavy damping far from the optimum would
        % raise the cost noticeably, so it is not mistaken for convergence.
        converged = tinyStep && (costNew - cost) <= 1e-12 * max(cost, eps);
    end

    if converged
        xc = t(2);
        yc = t(3);
        status = 0;
        info.iterations = it;
        info.A = t(1);
        info.sigma = t(4:5).';
        return
    end
end

info.iterations = centroidP.gf_max_iter;
info.A = t(1);
info.sigma = t(4:5).';
status = 4;

% ---- Self-check ideas (in tests/test_centroiders.m) -------------------------
% Expected values from an independent calculation (Gaussian PSF, 7x7 ROI,
% LM, WCG start, clip):
% - Noise-free centred star: (4, 4) to ~1e-9
% - Noise-free error at +0.3 px, sigma 0.7: ~ +0.0008 px (same as Fast GF:
%   both fit a point-sampled Gaussian to pixel-integrated values)
% - Noise-free max |error|: sigma 0.3: 0.031, sigma 1.5: ~0.00001 px
% - Iterations, noise-free: ~3-8
% - Noisy, sigma 0.7, true x offset +0.3 px:
%     S = 5,000 e-: bias ~0.000, std ~0.026 px, failures 0, ~6 iterations
%     S = 1,000 e-: bias ~0.00, std ~0.12 px, median |error| ~0.08 px,
%                   ~0.1% not converged (status 4), ~12 iterations
%   -> the most accurate method at low signal, at the highest cost
% - All-zero roi: status = 1 (wcg fails first)
end

% ==== Local function ========================================================
function [S, J] = gaussModel(t, x, y)
% GAUSSMODEL  Model intensity S (column) and its Jacobian J (N^2-by-5) at t.
%   t = [A; xc; yc; sx; sy]. Column k of J is dS/dt(k).
%   J is only built when the caller asks for it (nargout > 1).
A = t(1);
xc = t(2);
yc = t(3);
sx = t(4);
sy = t(5);

e = exp(-((x - xc).^2 ./ (2 * sx^2) + (y - yc).^2 ./ (2 * sy^2)));
S = A * e;

if nargout > 1
    dSdA = e;
    dSdxc = S .* (x - xc) ./ (sx^2);
    dSdyc = S .* (y - yc) ./ (sy^2);
    dSdsx = S .* (x - xc).^2 ./ (sx^3);
    dSdsy = S .* (y - yc).^2 ./ (sy^3);

    J = [dSdA, dSdxc, dSdyc, dSdsx, dSdsy];
end
end