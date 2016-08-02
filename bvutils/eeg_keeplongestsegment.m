% Remove all but the longest segment in the EEG data
function EEGdata = eeg_keeplongestsegment(EEGdata)
    % only needed if more than one segment
    b = eeg_getbounds(EEGdata);
    if (length(b) == 1)
        return ;
    end
        
    % find largest segment
    latencies = [EEGdata.event.latency EEGdata.pnts+1];
    lengths = diff(latencies);
    [~, maxi] = max(lengths);
    
    % save the event
    event = EEGdata.event(maxi);
    
    % mark the segments for rejection
    reject = [];
    for i = 1:length(EEGdata.event)
        if (i ~= maxi)
            reject = [reject ; latencies(i), latencies(i+1)-1];
        end        
    end
    
    % trim the data to keep only 1 segment.
    EEGdata = eeg_eegrej( EEGdata, reject );

    % manually create the single boundary event.
    EEGdata.event = event;
    EEGdata.event.latency = 1;
    
end
