p = params_baseline();  p.star.signal_e = 5000;  p.psf.sigma_px = 0.7;
img = generate_spot(p, 4, 4);
p.detect.snrRule = 'wei_eq8';    compute_snr(img, p)   % ~12.9
p.detect.snrRule = 'integrated'; compute_snr(img, p)   % ~18