function [sos, g] = makeBiquadCoeffs(filter_params, samplerate, plot)

type = filter_params(1);
gain = filter_params(2);
frequency = filter_params(3);
Q = filter_params(4);

omega = 2*pi*(frequency / samplerate);
alpha = sin(omega)/(2*Q);
g = 10^(gain/40);
    
if type == 1 % 1=peak
   
    b0 = 1 + g*alpha;
    b1 = -2*cos(omega);
    b2 = 1 - g * alpha;

    a0 = 1 + (alpha / g);
    a1 = -2*cos(omega);
    a2 = 1 - (alpha/g);
    
elseif type == 0 % 0=lowshelf
    
    b0 = g*((g+1) - (g-1)*cos(omega) + 2*sqrt(g)*alpha);
    b1 = 2*g*((g-1) - (g+1)*cos(omega));
    b2 = g*((g+1) - (g-1)*cos(omega) - 2*sqrt(g)*alpha);
    
    a0 = (g+1) + (g-1)*cos(omega) + 2*sqrt(g)*alpha;
    a1 = -2*((g-1) + (g+1)*cos(omega));
    a2 = (g+1) + (g-1)*cos(omega) - 2*sqrt(g)*alpha; 
    
    
end
    
[sos, g ] = tf2sos([b0, b1, b2], [a0, a1, a2]);

if plot==true
    biquad = dsp.BiquadFilter(sos, g);
    [h, w] = freqz(biquad, 2048);
    w = w*samplerate/(2*pi);
    plotTF(w, abs(h));
end
