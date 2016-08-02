% Remove all but the longest segment in the EEG data
function EEGdata = eeg_keeplongestsegment(EEGdata)
    % only needed if more than one segment
    if (length(find(strcmp('boundary', {EEGdata.event.type}))) == 1)
        return ;
    end
    
    disp([EEGdata.setname, ': EEG data is not continious. Attempting to remove all but the longest segment.']); 
    
    % get latencies
    latencies = [EEGdata.event.latency EEGdata.pnts+1];
    lengths = diff(latencies);
    [v, maxi] = max(lengths);
    
    event = EEGdata.event(maxi);
    
    reject = [];
    for i = 1:length(EEGdata.event)
        if (i ~= maxi)
            reject = [reject ; latencies(i), latencies(i+1)-1];
        end        
    end
    
    EEGdata = eeg_eegrej( EEGdata, reject );

    EEGdata.event = event;
    EEGdata.event.latency = 1;
    
end
