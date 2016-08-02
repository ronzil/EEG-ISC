%Return the indexes of the EEG's events that are boundary events
function b = eeg_getbounds(EEGdata) 
    b = find(strcmp('boundary', {EEGdata.event.type}));
end
