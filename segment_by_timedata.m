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
function [res, segnificance] = segment_by_timedata(timedata, segments, randnum)
    if (strcmp(class(segments), 'cell'))
        segments = segments;
    elseif (strcmp(class(segments), 'struct'))
        segments = {segments};
    else
        segments = {struct('data',segments)};
    end
    
    for i=1:length(segments)
        [v,s] = do_segment_by_timedata_with_random(timedata, segments{i}.data, randnum);
        res(i) = v;
        segnificance(i) = s;
    end

end


function [res, segnificance] = do_segment_by_timedata_with_random(timedata, segment_data, randnum)
    % get the random segments
    % get the total time value of all the 
    durs = segment_data(:,2);
    totaldurlen = sum(durs);
    totaltime = length(timedata.data)*timedata.step;
    rval = totaltime - totaldurlen;
   
    for i=1:randnum
        randts = timedata.startTS + int64(sort(randperm(rval, length(durs))))';
        randts = randts + cumsum([0;durs(1:end-1)]);
        
        randseg = [randts , durs];
        
        val(i)= do_segment_by_timedata(timedata, randseg);
    end
    
    mr = mean(val);
    sr = std(val);
    
    res = do_segment_by_timedata(timedata, segment_data);
    
    segnificance = (res-mr)/sr;

end



function res = do_segment_by_timedata(timedata, segment_data)

    step = timedata.step;

	startoffset = round((segment_data(:,1) - timedata.startTS)/step) + 1;
    endoffset = startoffset + segment_data(:,2)/step - 1;
    
    % note. fix this by getting the last chunk of the EEG data
    startoffset = max(startoffset, 1);
    endoffset = min(endoffset, length(timedata.data));
    
    
	assert(min(startoffset)>0);
	assert(max(endoffset)<=length(timedata.data));
    
	
	% go over all the segments
	for i=1:length(segment_data)
%        if (endoffset(i) == startoffset(i)) continue; end% note. remove when added chunks 

%		val(i) = mean(timedata.data(startoffset:durationoffset));
		val(i) = mean(timedata.data(startoffset(i):endoffset(i)));
	end

	res = mean(val(~isnan(val)));

end