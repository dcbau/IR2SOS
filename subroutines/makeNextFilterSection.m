function [param_list] = makeNextFilterSection(N, hrtf_ref, frequencies, fs, param_list, limit_bandwith, plotting)
% Funtion to be used in a context of modeling an HRTF to a SOS filter
% cascade
% Output:
% sos_list,g_list   - Updated filter list
%
% Input:
% N                 - Current order, number of the filter stage
% hrtf_ref          - the hrtf that is currently modeled
% frequencies       - the frequency values at which the hrtf is sampled and
%                     therefore where the error should be evaluated
% fs .              - samplerate
% param_list	    - current parameter list
% plot              - plots the filter for this stage

if nargin < 6
    plotting = false;
end
%disp(['Making Filter: ', N])

%sanity check that order N does not exeed length of sos-list
if N > size(param_list, 1)
    print("Error: N exceeds filter list");
end

if N == 1
    filtertype = 0; %lowshelf
else
    filtertype = 1; %peak
end

if limit_bandwith
    lf_limit = limit_bandwith(1);
    hf_limit = limit_bandwith(2);
else
    lf_limit = 0;
    hf_limit = fs/2;
end
    
ids = find(frequencies < hf_limit & frequencies > lf_limit);



%% define the current error segment %%

%filter_response = getFilterResponseFromSOS(sos_list, g_list, fs, frequencies);
filter_response = getFilterResponseFromParameters(param_list, fs, frequencies);
if N == 1
    % get first error area (from DC to first intersection)
    intersections = findIntersections(hrtf_ref, filter_response);
    error_area_start = 1;
    error_area_end = intersections(1);
else
    % find next error area 
    [error_area_start,error_area_end] = findLargestErrorSegment(filter_response(ids), hrtf_ref(ids));
    error_area_start = error_area_start + (ids(1)-1);
    error_area_end = error_area_end + (ids(1)-1);
end


if plotting == true
    
    % plot first guess
    figure;
    subplot(3, 1, 1);
    title('Current error segment');
    semilogx(frequencies, hrtf_ref);
    xlim([0, 20000]); ylim([-36, 6]);
    xticks([20, 100, 200, 1000, 2000, 10000, 20000]);
    yticks([-36, -24, -18, -12, -6, -3, 0, 3, 6, 12]);
    hold on;
    semilogx(frequencies, filter_response);

    % also plot bounds for current segment
    x1 = frequencies(error_area_start);
    x2 = frequencies(error_area_end);
    yl = ylim;
    xbox = [x1 x1 x2 x2];
    ybox = [yl(1) yl(2) yl(2) yl(1)];
    patch(xbox,ybox,'black', 'FaceColor', 'green', 'FaceAlpha', 0.1)
    drawnow;
end


%% make first guess for filter  %%

% find center of area
error_area_center = round((error_area_start + error_area_end)/2);

% get center frequency and gain
centerfrequency = frequencies(error_area_center);
gain = hrtf_ref(error_area_center) - filter_response(error_area_center);

% make filter stage and append to filter list
param_list(N, :) = [filtertype, gain, centerfrequency, 1];
filter_response = getFilterResponseFromParameters(param_list, fs, frequencies);
%[sos_list(N, :), g_list(N)] = makeBiquadCoeffs(filtertype, fs, centerfrequency, gain, 1, false);
%filter_response = getFilterResponseFromSOS(sos_list, g_list, fs, frequencies);

if plotting == true
    % plot first guess
    subplot(3, 1, 2);
    title('First guess of filter');
    semilogx(frequencies, hrtf_ref);
    xlim([0, 20000]); ylim([-36, 6]);
    xticks([20, 100, 200, 1000, 2000, 10000, 20000]);
    yticks([-36, -24, -18, -12, -6, -3, 0, 3, 6, 12]);
    hold on;
    semilogx(frequencies, filter_response);

    % also plot bounds for current segment
    x1 = frequencies(error_area_start);
    x2 = frequencies(error_area_end);
    yl = ylim;
    xbox = [x1 x1 x2 x2];
    ybox = [yl(1) yl(2) yl(2) yl(1)];
    patch(xbox,ybox,'black', 'FaceColor', 'green', 'FaceAlpha', 0.1)
    drawnow;
end




%% compare and random-improve filter %%%%%%%%%%%%%%%%%%%%%
num_random_trials = 100;

error = mean(abs(hrtf_ref - filter_response));

% define the ranges for the random modulations
gain_random_range = 10;
g1 = gain - gain_random_range/2;
g2 = gain + gain_random_range/2;
gain_range = linspace(g1, g2, 50);
f1 = frequencies(error_area_start);
if f1 == 0
    f1 = 1;
end
f2 = frequencies(error_area_end);
freq_range = exp(linspace(log(f1), log(f2), 50));
Q_range = exp(linspace(log(0.1), log(20), 50));

% pre-make the random combinations of freq, gain & Q
combis = round(rand(num_random_trials,3)*49) + 1;

% make a working copy of the list for the random trials
%sos_list_temp = sos_list;
%g_list_temp = g_list;
param_list_temp = param_list;

for i = 1:num_random_trials
    % get random filter parameters
    gain = gain_range(combis(i, 1));
    frequency = freq_range(combis(i, 2));
    Q = Q_range(combis(i, 3));
    
    % make filter
    %[sos_list_temp(N, :), g_list_temp(N)] = makeBiquadCoeffs(filtertype, fs, frequency, gain, Q, false);
    %f_response_temp = getFilterResponseFromSOS(sos_list_temp, g_list_temp, fs, frequencies);
    param_list_temp(N, :) = [filtertype, gain, frequency, Q];
    f_response_temp = getFilterResponseFromParameters(param_list_temp, fs, frequencies);
    
    % compare
    error_temp = mean(abs(hrtf_ref - f_response_temp));
    if error_temp < error
        error = error_temp;
        filter_response = f_response_temp;
        param_list = param_list_temp;
        %sos_list = sos_list_temp;
        %g_list = g_list_temp;
    end
    

end

if plotting == true
      
    subplot(3, 1, 3);
    title('Random Improved Filter');
    semilogx(frequencies, hrtf_ref);
    xlim([0, 20000]); ylim([-36, 6]);
    xticks([20, 100, 200, 1000, 2000, 10000, 20000]);
    yticks([-36, -24, -18, -12, -6, -3, 0, 3, 6, 12]);
    hold on;
    semilogx(frequencies, filter_response);

    x1 = frequencies(error_area_start);
    x2 = frequencies(error_area_end);
    yl = ylim;
    xbox = [x1 x1 x2 x2];
    ybox = [yl(1) yl(2) yl(2) yl(1)];
    patch(xbox,ybox,'black', 'FaceColor', 'green', 'FaceAlpha', 0.1)
    drawnow;
end

end

