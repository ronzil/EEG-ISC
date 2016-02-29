% return the mean value from timedata of the matching segments.
%
% also creates <randnum> random segments with the same duration but random
% starting points and calculates the real values difference from the
% random's mean in random's stds.
%
% timedata. is a struct with the following properties
%   .data - vector of values
%   .startTS - timestamp of first value in unix time
%   .step - time step between samples in miliseconds. (1/srate)
%
% segments. a cell array contains a struct with fields
% name - name of the segment group
% data - 2D array [startTS, duration]
%
% second parameter can also be just one segment struct, or just the segment
% data.
function [res, significance, meanr, stdr] = segment_by_timedata(timedata, segments, randnum)
    if (strcmp(class(segments), 'cell'))
        segments = segments;
    elseif (strcmp(class(segments), 'struct'))
        segments = {segments};
    else
        segments = {struct('data',segments)};
    end
    
    for i=1:length(segments)
        [v,s,mr,sr] = do_segment_by_timedata_with_random(timedata, segments{i}.data, randnum);
        res(i) = v;
        significance(i) = s;
        meanr(i) = mr;
        stdr(i) = sr;
    end

end


function [res, significance, meanr, stdr] = do_segment_by_timedata_with_random(timedata, segment_data, randnum)
    % get the random segments
    % get the total time value of all the 
    durs = segment_data(:,2);
    totaldurlen = sum(durs);
    totaltime = length(timedata.data)*timedata.step;
    rval = totaltime - totaldurlen;
   
    for i=1:randnum
        randts = timedata.startTS + sort(randperm(rval, length(durs)))';
        randts = randts + cumsum([0;durs(1:end-1)]);
        
        randseg = [randts , durs];
        
        vec = vector_from_timedata_by_segments(timedata, randseg);
        val(i)= mean(vec);
    end
    
    meanr = mean(val);
    stdr = std(val);
    
    vec = vector_from_timedata_by_segments(timedata, segment_data);
    res = mean(vec);
    
    significance = (res-meanr)/stdr;

end

