EEG-ISC 
============
This is a Matlab toolkit for calculating inter-subject correlations (ISC) in EEG data.
It also contains utility functions for manipulating BrainVision(BV) files in batch.
This project is built on top of [EEGLAB](https://sccn.ucsd.edu/eeglab/).

Featues:
- Utilities for batch manipulation of BV files including: Loading, aligning to same start/end point. 
- Internal intermidate result caching. This allows the continuation of stopped runs.
- Optimized code for multiple processors (parfor)
- Calculates the significance of the data using a bootstap method. Details in the code.

### Usage
See [example.m](example.m) for a documented example run.

### Citing
EEG-ISC is freely available under the GUN General Public License. 
Please cite the following publication if using:  
> ...
> ...
> ...

