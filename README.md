# IR2SOS
Matlab function set for estimating a second order section structure from the magnitude of an impulse response. Estimation is done with iterative error optimization.

Roughly based on an algorithm proposed by Ramos & Cobos:

> Ramos, G., & Cobos, M. (2013). Parametric head-related transfer function modeling and interpolation for cost-efficient binaural sound applications. The Journal of > the Acoustical Society of America, 134(3), 1735–1738. https://doi.org/10.1121/1.4817881

See sos_conversion.m for an example how to convert a HRIR dataset (requires the SUpDEq toolbox)

### Dependencies:
- DSP System Toolbox
- AKTools

