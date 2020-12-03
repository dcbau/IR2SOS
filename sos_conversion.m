
clearvars;
close all;

%% Get the dataset

load('HRIRs_sfd_N35.mat');
fs = HRIRs_sfd_N35.f(end) * 2;
az = 0:35;
az = az*10;
el = 90*ones(length(az), 1);
grid = [az', el];

[hrirs_l, hrirs_r] = supdeq_getArbHRIR(HRIRs_sfd_N35, grid);

N = size(hrirs_l, 1);
M = size(hrirs_l, 2);

hrirs_modeled = zeros(N*2, M, 2);
mean_errors = zeros(M, 2);

nSOS = 12;

fprintf('Making Filters...');
for m=1:M
    fprintf('|');
    hrir_ref = [hrirs_l(:, m), hrirs_r(:, m)];
    [sos_list, gain, delay, hrir_modeled, mean_errors(m, :)] = hrir2sos(hrir_ref, fs, nSOS, [], false, true);
    
    SOS_dataset(m).sos_list = sos_list;
    SOS_dataset(m).gain = gain;
    SOS_dataset(m).delay = delay;
    
    hrirs_modeled(:, m, 1) = hrir_modeled(:, 1);
    hrirs_modeled(:, m, 2) = hrir_modeled(:, 2);
    
end

fprintf('  Done!\n');

    
