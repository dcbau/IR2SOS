% Takes a pair of impulse reponses and finds a matching
% Second-Order-Section cascade (DF2 Transposed Biquads) that models the frequency responses. Also
% gives the broadband delay for each filter to fit the original TOA

% Requirements: - DSP System Toolbox
%               - AKtools

% INPUT: 
%   - hrtf_ref:     Reference HRIR, given as [Nx2] matrix, where N is the length
%                   of the IR
%   - fs:           Sample rate (default=48000)
% . - nSOS:         Number of second order sections. (default=12)
% . - limit_bandw:  [lf_limit hf_limit] Sets a high- and low-frequency limit for the modelling.
%                   The magnitude above hf_limit and below lf_limit will
%                   not be considered in the modelling process.(default=[],
%                   no limit)
% . - plot_steps    For every new SOS, the current step is shown (only left 
%                   channel). It shows:
%                   1. the current error segment
%                   2. the inital filter guess
%                   3. the optimated filter after the error minimization
%                   search.
%   - plot_result   Plots the final filters for L/R, including an error
%                   plot for the magnitude error
% OUTPUT:
%   - sos_list:     The resulting SOS matrix with shape [Mx6x2] (M=nSOS)
%                   Every SOS has the coefficients for a transposed DF2
%                   biquad filter [b0, b1, b2, 1, -a1, -a2]
% . - gain:         Scaling factor for the SOS matrix
%   - delay:        [delay_l delay_r] Broadband delay in samples for left and right channel
% . - hrir_modeled  Two channel impulse resonse from the SOS
%   - mean_error    Two channel error frequency vector
% 

function [sos_list, gain, delay, hrir_modeled, mean_error] = hrir2sos(hrir_ref, fs, nSOS, limit_bandw, plot_steps, plot_result)

if nargin < 6; plot_result = false; end
if nargin < 5; plot_steps = false; end
if nargin < 4; limit_bandw = []; end
if nargin < 3; nSOS = 12; end
if nargin < 2; fs = 12; end


% transform to frequency domain with quad length
n = size(hrir_ref, 1) * 2;
hrtf_ref_l = fft(hrir_ref(:, 1), 2*n);
hrtf_ref_r = fft(hrir_ref(:, 2), 2*n);

%get db magnitude and remove nyqist frequency since it is not represented in
%the freqz() evaluation of biquads
hrtf_ref_l= mag2db(abs(hrtf_ref_l(1:n)));
hrtf_ref_r= mag2db(abs(hrtf_ref_r(1:n)));

frequencies_ref_lin = linspace(0, fs/2, n+1);
frequencies_ref_lin= frequencies_ref_lin(1:n);

% make a logarithmic frequency distribution with a resolution of 48steps/octave as proposed by Ramos
% range 20Hz to 20480Hz is 10 octaves and covers hearing spectrum well
% enough
frequencies_ref = exp(linspace(log(20), log(20480), 480));
% get the values at those frequencies by stupid interpolation of the linear
% frequency bins
hrtf_ref_l = interp1(frequencies_ref_lin, hrtf_ref_l, frequencies_ref);
hrtf_ref_r = interp1(frequencies_ref_lin, hrtf_ref_r, frequencies_ref);



% initalize filter parameter list [type, gain, frequency, Q ]
% type: 0=lowshelf, 1=peak
% default=[peak, 0dB, 1000Hz, Q=1]
param_list_l = repmat([1, 0, 1000, 1], nSOS, 1);
param_list_r = repmat([1, 0, 1000, 1], nSOS, 1);



% CORE ALGORITHM: 
% turn on plotting to see the effect of every new filter 

for i = 1:nSOS
    param_list_l = makeNextFilterSection(i, hrtf_ref_l, frequencies_ref, fs, param_list_l, limit_bandw, plot_steps);
    param_list_r = makeNextFilterSection(i, hrtf_ref_r, frequencies_ref, fs, param_list_r, limit_bandw, false);
end

filter_response_l = getFilterResponseFromParameters(param_list_l, fs, frequencies_ref);
filter_response_r = getFilterResponseFromParameters(param_list_r, fs, frequencies_ref);



if plot_result
    
   figure;
    subplot(2, 2, 1);
    semilogx(frequencies_ref, hrtf_ref_l);
    xlim([0, 20000]); ylim([-48, 12]);
    xticks([20, 100, 200, 1000, 2000, 10000, 20000]);
    yticks([-36, -24, -18, -12, -6, -3, 0, 3, 6, 12]);
    hold on;
    semilogx(frequencies_ref, filter_response_l);
    hold off;
    title('HRTF L');
    legend('Original HRTF', 'Modeled HRTF', 'location', 'southwest');

    subplot(2, 2, 2);
    title('HRTF R');
    semilogx(frequencies_ref, hrtf_ref_r);
    xlim([0, 20000]); ylim([-48, 12]);
    xticks([20, 100, 200, 1000, 2000, 10000, 20000]);
    yticks([-36, -24, -18, -12, -6, -3, 0, 3, 6, 12]);
    hold on;
    semilogx(frequencies_ref, filter_response_r);
    hold off;
    title('HRTF L');
    legend('Original HRTF', 'Modeled HRTF', 'location', 'southwest');


end

%% get ITD from onset detection %%%%%%%%

toa_l = AKonsetDetect(hrir_ref(:, 1), 10, -20, 'rel', [4000, fs]);
toa_r = AKonsetDetect(hrir_ref(:, 2), 10, -20, 'rel', [4000, fs]);
itd_samples = toa_r - toa_l;
itd_sec = itd_samples / fs;

delay = [toa_l, toa_r];




%% make the final filters 
sos_list_l = ones(nSOS, 6);
sos_list_r = ones(nSOS, 6);
gain_l = 1;
gain_r = 1;

for i = 1:nSOS
    [sos_list_l(i, :), g] = makeBiquadCoeffs(param_list_l(i, :), fs, false);
    gain_l = gain_l * g;

    [sos_list_r(i, :), g] = makeBiquadCoeffs(param_list_r(i, :), fs, false);
    gain_r = gain_r * g;

end

filter_l = dsp.BiquadFilter(sos_list_l, gain_l);
filter_r = dsp.BiquadFilter(sos_list_r, gain_r);

hrir_length = n;

% make HRIR filter by filtering a dirac
hrir_l = filter_l(AKdirac(hrir_length, 1, 0));
hrir_r = filter_r(AKdirac(hrir_length, 1, 0));

% apply delay
hrir_l = AKfractionalDelay(hrir_l, toa_l);
hrir_r = AKfractionalDelay(hrir_r, toa_r);


% pack return values
hrir_modeled = [hrir_l, hrir_r];
sos_list = cat(3, sos_list_l, sos_list_r);
gain = [gain_l, gain_r];

    

%% magnitude error

magnitude_error_l = abs(filter_response_l - hrtf_ref_l);
magnitude_error_r = abs(filter_response_r - hrtf_ref_r);

if plot_result
    subplot(2, 2, 3);
    semilogx(frequencies_ref, magnitude_error_l);
    xlim([0, 20000]); ylim([0, 12]);
    xticks([20, 100, 200, 1000, 2000, 10000, 20000]);
    yticks([-36, -24, -18, -12, -6, -3, 0, 3, 6, 12]);
    title('Magnitude Error L');
    
    subplot(2, 2, 4);
    semilogx(frequencies_ref, magnitude_error_r);
    xlim([0, 20000]); ylim([0, 12]);
    xticks([20, 100, 200, 1000, 2000, 10000, 20000]);
    yticks([-36, -24, -18, -12, -6, -3, 0, 3, 6, 12]);
    title('Magnitude Error R');
end

mean_error = [mean(magnitude_error_l),  mean(magnitude_error_r)];



end

