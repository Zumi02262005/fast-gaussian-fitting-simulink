p = params_baseline();  rng(1);
img_e = zeros(7);
DN = zeros(7, 7, 2000);
for k = 1:2000, DN(:,:,k) = apply_noise_chain(img_e, p); end
mean(DN(:))      % expect ~10.9 DN
std(DN(:))       % expect ~2.9 DN