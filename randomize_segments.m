function rsegments = randomize_segments(segments, timedata)
    % get the random segments
    % get the total time value of all the 
    durs = segments.data(:,2);
    totaldurlen = sum(durs);
    totaltime = length(timedata.data)*timedata.step;
    rval = totaltime - totaldurlen;
   
    randts = timedata.startTS + sort(randperm(rval, length(durs)))';
    randts = randts + cumsum([0;durs(1:end-1)]);
        
    randseg = [randts , durs];
    
    rsegments = segments;
    rsegments.data = randseg;
        

end
    