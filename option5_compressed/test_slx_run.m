run('/Users/arkadiyturevskiy/Documents/Claude/SOC_model/option5_compressed/setup_and_open_slx.m');
fprintf('Running sim...\n');
out = sim('soc_opt5_compressed');
yout = out.get('yout');
soc_vals = double(yout{1}.Values.Data(:));
fprintf('SOC = %.6f  (ref: -0.030127)\n', soc_vals(end));
