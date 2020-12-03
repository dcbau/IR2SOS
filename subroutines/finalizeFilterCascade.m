%this function is basically doing the same thing as the
%makeNextFilterSection, but applies random changes to all filters in the
%list at once. 

% does it really make sense to do it this way??? shows almost no
% improvement, even though ramos said the finalisation step is crucial

function [param_list] = finalizeFilterCascade(hrtf_ref, frequencies, fs, param_list)

M = size(param_list, 1);

filter_response = getFilterResponseFromParameters(param_list, fs, frequencies);


%% compare and random-improve filter %%%%%%%%%%%%%%%%%%%%%
num_random_trials = 100;

error = mean(abs(hrtf_ref - filter_response));

% define the ranges for the random modulations

% gain modulation
gain_random_range = 5;
g1 = -gain_random_range/2;
g2 = gain_random_range/2;
gain_range = linspace(g1, g2, 51)';

% make frequency range to one octave relative to filter frequency ->
% freq_range is a factor, applied to filter frequency
freq_range = 2.^linspace(-0.5, 0.5, 51)';

%similar to frequency, q_range will be applied as a factor
Q_range = logspace(-0.5,0.5, 51)'; % values between 0.316 and 3.16

% pre-make the random combinations of freq, gain & Q
%combis = round(rand(num_random_trials,3)*49) + 1;

% make a working copy of the list for the random trials
%sos_list_temp = sos_list;
%g_list_temp = g_list;
param_list_temp = param_list;

for i = 1:num_random_trials
    
    % get random filter parameters for every filter of M
    random_idx = round(rand(M, 3)*50)+1;
    param_list_temp(:, 2) = param_list(:, 2)  + gain_range(random_idx(:, 1));
    param_list_temp(:, 3) = param_list(:, 3) .* freq_range(random_idx(:, 2));
    param_list_temp(:, 4) = param_list(:, 4) .* Q_range(random_idx(:, 3));

    f_response_temp = getFilterResponseFromParameters(param_list_temp, fs, frequencies);
    
    % compare
    error_temp = mean(abs(hrtf_ref - f_response_temp));
    if error_temp < error
        error = error_temp;
        param_list = param_list_temp;
    end
    

end

end

