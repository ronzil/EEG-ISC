% return a timedata object with the power of the events i.e number of events per step
function timedata = sliderpower(filename, step)
% debate1-events_data.csv, 1000

allevents = readtable(filename);

events = allevents(find(strcmp(allevents.question_id,'slider')),:);

start_time = min(events.TS);
end_time = max(events.TS);

%step = 5000;

times = [];
values = [];

lastt = start_time;
for t = start_time:step:end_time

	inds = find(events.TS>lastt & events.TS<t);
%	values = str2double(events(inds),:).value;
	
%	res = [res;[t, length(inds)]];
    times = [times t];
    values = [values length(inds)];


	lastt = t;
end

timedata = struct;
timedata.startTS = start_time;
timedata.data = values;
timedata.step = step;