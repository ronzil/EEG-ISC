function vector = vector_from_timedata_by_segments(timedata, seggroup_data)

    step = timedata.step;

	startoffset = round((seggroup_data(:,1) - timedata.startTS)/step) + 1;
    endoffset = round(startoffset + seggroup_data(:,2)/step - 1);
    
    % note. fix this by getting the last chunk of the EEG data
    startoffset = max(startoffset, 1);
    endoffset = min(endoffset, length(timedata.data));
    if (min(startoffset)<=0)
		disp('3');
    end
    if (max(endoffset)>length(timedata.data))
		disp('3');
	end
    
    
	assert(min(startoffset)>0);
	assert(max(endoffset)<=length(timedata.data));

    vector = [];
	% go over all the segments
	for i=1:size(seggroup_data,1)
%        if (endoffset(i) == startoffset(i)) continue; end% note. remove when added chunks 

%		val(i) = mean(timedata.data(startoffset:durationoffset));
		vector = [vector timedata.data(startoffset(i):endoffset(i))];
	end
end