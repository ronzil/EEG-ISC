% align all the EEG data to start and end at the same time by trimming 
% down to the largest continious region shared by all recordings. Optional
% parameters are extra trim time in seconds
function EEGcell = eeg_multi_align(EEGcell, extraSecondsStart, extraSecondsEnd)

% optional params
if (~exist('extraSecondsStart'))
    extraSecondsStart = 0;
end
if (~exist('extraSecondsEnd'))
    extraSecondsEnd = 0;
end

% go over all EEG recordings and if there is more than one segment (due to
% an error in the recording most likely. Keep only the longest continious segment).
EEGcell = eeg_multi_apply(@(eeg) eeg_keeplongestsegment(eeg), EEGcell);

EEGcell = eeg_multi_alignstart(EEGcell, extraSecondsStart);
EEGcell = eeg_multi_alignend(EEGcell, extraSecondsEnd);

end
