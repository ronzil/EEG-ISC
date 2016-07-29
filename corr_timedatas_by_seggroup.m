function res = corr_timedatas_by_seggroup(td1, td2, seggroup)

    vec1 = cut_timedata_by_seggroup(td1, seggroup);
    vec2 = cut_timedata_by_seggroup(td2, seggroup);
    
    res = corr(vec1', vec2');
    
    
end
