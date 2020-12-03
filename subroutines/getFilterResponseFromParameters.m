function [filter_response, phase_response] = getFilterResponseFromParameters(param_list, fs, freq_ref)
%GETFILTERRESPONSEFROMSOS Get magnitude response with logarithmic frquency
%distribution
%   Takes a Mx4 matrix of filter parameters to make a filter response out of it. From that
%   response, calculates the db magnitude and resample it to logarithmic
%   frequency distribution
% Input:
% param_list - Mx4 filter parameters [type, gain, frequency, Q] for M
%              second order sections
% fs       - samplerate
% freq_ref - (Logarithmic) Frequency values to resample the magnitude
%            response to

M = size(param_list, 1);
sos_list = ones(M, 6);
gain = 1;
g_temp = 1;

for i = 1:M
    [sos_list(i, :), g_temp] = makeBiquadCoeffs(param_list(i, :), fs, false);
    gain = gain * g_temp;
end
    
[filter_response, phase_response] = getFilterResponseFromSOS(sos_list, gain, fs, freq_ref);

end

