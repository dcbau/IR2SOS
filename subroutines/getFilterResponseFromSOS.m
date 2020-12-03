function [filter_response, phase_response] = getFilterResponseFromSOS(sos_list, gain, fs, freq_ref)
%GETFILTERRESPONSEFROMSOS Get magnitude response with logarithmic frquency
%distribution
%   Takes sos and gain lists to make a filter response out of it. From that
%   response, calculates the db magnitude and resample it to logarithmic
%   frequency distribution
% Input:
% sos_list - Mx6 SOS cascade
% g_list   - Mx1 filter gain list for SOS cascade
% fs       - samplerate
% freq_ref - (Logarithmic) Frequency values to resample the magnitude
%            response to

biquad = dsp.BiquadFilter(sos_list, gain);
[h, f] = freqz(biquad, 8192);
filter_response = mag2db(abs(h))';
phase_response = angle(h)';
frequencies_filter_lin = f'*fs/(2*pi);

% resample to logarithmic frequency distribution
filter_response = interp1(frequencies_filter_lin, filter_response, freq_ref);
phase_response = interp1(frequencies_filter_lin, phase_response, freq_ref);

end

