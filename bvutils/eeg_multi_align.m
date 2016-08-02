% align all the EEG data to start and end at the same time by trimming 
% down to the largest continious region shared by all recordings. Optional
% extra parameters are extra trim time in seconds from begining/end and
% fixMode explained below.
%
% Analysis can only be done on continious data streams.
% Under the default mode, if any of the EEG data contains non continious
% data, the function fails. fixMode can solve this by:
% 'TRIM' - Delete all but the longest continious segment.
% 'REMOVE' - Remove the bad EEG data from the cell array.
function EEGcell = eeg_multi_align(EEGcell, extraSecondsStart, extraSecondsEnd, fixMode)

% optional params
if (~exist('extraSecondsStart'))
    extraSecondsStart = 0;
end
if (~exist('extraSecondsEnd'))
    extraSecondsEnd = 0;
end
if (~exist('fixMode'))
    fixMode = 'ASSERT';
end

% go over all EEG recordings and check if there is more than one segment (due to
% an error in the recording most likely.
keep = 1:length(EEGcell);
for i = 1:length(EEGcell)

    b = find(strcmp('boundary', {EEGcell{i}.event.type})); 
    if (length(b) > 1)
        disp([EEGcell{i}.setname, ': Problem with data. Non continious stream.']);
        if (strcmp(fixMode, 'TRIM'))
            disp('Remove all but the longest segment.'); 
            %Keep only the longest continious segment.
            EEGcell{i} = eeg_keeplongestsegment(EEGcell{i});
        elseif (strcmp(fixMode, 'REMOVE'))
            disp('Removing EEG data from cell array');
            keep = setdiff(keep, i);
        else
            assert(false, 'Aborting. Fix manually or use the fixMode parameter. See documentation.');
        end   
        
    end
end

% remove any data that is marked for removal.
EEGcell = EEGcell(keep);

% trim from both sides.
EEGcell = eeg_multi_alignstart(EEGcell, extraSecondsStart);
EEGcell = eeg_multi_alignend(EEGcell, extraSecondsEnd);

end
