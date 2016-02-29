function res = corr_timedatas_by_segments(td1, td2, segments)

    vec1 = vector_from_timedata_by_segments(td1, segments.data);
    vec2 = vector_from_timedata_by_segments(td2, segments.data);
    
    res = corr(vec1', vec2');
    
    
end
