%%% EEG analysis

function EEGA_bands(alldata) 

	%set data length as minimial length of EEG data from all people
	datalength = 10000000000;
	for i = 1:length(alldata)
		EEG = alldata{i};
		datalength = min(datalength, EEG.pnts);
	end
	
	%get sample rate
	srate = alldata{1}.srate;
	

	%step1 filter <1Hz and > 50Hz and subtract reference from #17
	alldata = cachefun(@() do_filter(alldata), 'step1_dofilter');

	% iterate all data in 20 minute segments
	segment_length = 20*60*srate; 
    startfrom = 1;
	for start = startfrom:segment_length:datalength-segment_length
        %spectorgrams and correlations require a window of data from the
        %moment we are trying to calculate. Therefore we need extra data to calculate the last second.
        internal_segment_length = segment_length + 1*60*srate; 
		
		%trim EEG to 20 minutes each time	
		alldatatrim = do_trim(alldata, start, start+internal_segment_length-1);
		
		%calculate ica weights
		fname = sprintf('step2_ica_%d_%d', start, internal_segment_length);
		alldatatrim = cachefun(@() do_ica(alldatatrim), fname);

		%store the components data per person/
		%allComponents is a cell array per person. Each cell contains component data array.
		fname = sprintf('step3_components_%d_%d', start, internal_segment_length);		
		componentsPerPerson = cachefun(@() get_components(alldatatrim), fname);
		
		%find number of components by taking the minimum of all people. (sometimes its less than the channel number)
		numComponents = 1000;
		for i = 1:length(alldatatrim)
			numComponents = min(numComponents, length(alldatatrim{i}.icaweights));
		end
		numComponents
		
		%spectogramsPerPerson is a cell array per person. Each cell is: Cell array of components. Each cell is: bands X data (in seconds)
		% spectogramsPerPerson{person_number}{component_number}{band_number, data}
		fname = sprintf('step4_spectograms_%d_%d', start, internal_segment_length);				
		spectogramsPerPerson = cachefun(@() get_spectograms(componentsPerPerson, numComponents), fname);

		fname = sprintf('step5_spectogramBands_%d_%d', start, internal_segment_length);						
		spectogramsBandsPerPerson =  cachefun(@() make_bands(spectogramsPerPerson, numComponents), fname);
		
		fname = sprintf('step6_CorrSpectoTimeBands_%d_%d', start, internal_segment_length);								
		bandcorr = cachefun(@() calc_correlations(spectogramsBandsPerPerson), fname);

		for i= 1:10
			fname = sprintf('step7_RandCorrSpectoTimeBands_%d_%d_%d', i, start, internal_segment_length);								
			result = calc_rand_correlations(spectogramsBandsPerPerson);
			save(fname, 'result');
		end
		
	end	
		

		
		
	
    
	
	



end



function alldata = do_filter(alldata)
	disp('doing filter');
	for i = 1:length(alldata)
		EEG = alldata{i};
		
		EEG = eeg_checkset( EEG );
		EEG = pop_chanedit(EEG, 'load',{'locations.loc' 'filetype' 'autodetect'},'setref',{'17' 'Ref'});
		EEG = eeg_checkset( EEG );
		EEG = pop_eegfiltnew(EEG, [], 1, 826, true, [], 0); %%filter data 1
		EEG = eeg_checkset( EEG );
		EEG = pop_eegfiltnew(EEG, [], 50, 66, 0, [], 0);%% filter data above 50
		EEG = eeg_checkset( EEG );
		EEG = pop_reref( EEG, 17); %reference to channel 17
		EEG = eeg_checkset( EEG );
%		EEG = pop_chanedit(EEG, 'delete', 18, 'delete', 17);
%		EEG = eeg_checkset( EEG );
		
		alldata{i} = EEG;

	end    

end



function alldata = do_trim(alldata, start_sample, end_sample)
	for i = 1:length(alldata)
		EEG = alldata{i};
		
		EEG = eeg_eegrej( EEG, [end_sample+1, EEG.pnts] );
		EEG = eeg_eegrej( EEG, [1, start_sample-1] );
		
		alldata{i} = EEG;
	end


end


function alldata = do_ica(alldata)
	parfor i = 1:length(alldata)
		EEG = alldata{i};
		
		EEG = pop_runica(EEG, 'extended',1,'interupt','on', 'chanind', [1:16]);
		EEG = eeg_checkset( EEG ); 
		
		alldata{i} = EEG;
	end

end

function componentsPerPerson = get_components(alldata)
		componentsPerPerson = {};	
		for i = 1:length(alldata)
		    EEG = alldata{i};
			componentsPerPerson{i} = eeg_getdatact(EEG, 'component', [1:size(EEG.icaweights,1)]);
		end
end		
		

function spectogramsPerPerson = get_spectograms(componentsPerPerson, numcomponents)
	%spectogramsPerPerson is a cell array per person. Each cell is: Cell array of components. Each cell is: bands X data (in seconds)
	% spectogramsPerPerson{i}{compind}[second, frequency]

	data_length = length(componentsPerPerson{1}); %in sample. note add assert that all components are same length
    window = 5; % 5 seconds
    frequencies = 60;
	srate = 250; % note make nicer
	window_in_samples = window*srate;
	
	
	spectogramsPerPerson = {};
	parfor i = 1:length(componentsPerPerson) % going over people
		personspec = {};
		
		for compind = 1:numcomponents % going over components
			compspec = [];
			
			% go over the data in <window> size. and calculate the FFT			
			for step=1:srate:data_length-window_in_samples
				data = componentsPerPerson{i}(compind, step:step+window_in_samples-1);
				fft = freq(data);
				fft = fft(1:frequencies); % cut the unwanted frequencies because they are all zero and take a lot of space

				% accumilate the fft data in columns. each column is one second.
				compspec = [compspec , fft'];
		
			end
			
			personspec{compind} = compspec;
			
		end
		
		spectogramsPerPerson{i} = personspec;
	end
	
end




function spectogramsBandsPerPerson = make_bands(spectogramsPerPerson, numComponents)
	%spectogramsBandsPerPerson{i}{compind}[second, band]
	
	spectogramsBandsPerPerson = {};
	
	for individual = 1:length(spectogramsPerPerson) % going over people
		spectogramsBandsPerPerson{individual} = {};
		
		for compind = 1:numComponents % going over components

			% frequence data for this component
			data = spectogramsPerPerson{individual}{compind}; %frequence data. 2D array frequence X time
			% holds the bands data
			bandsdata = [];

			% make 4Hz band			
			bandsize = 4;
			for i=1:bandsize:size(data,1)-bandsize
				bandsdata = [bandsdata ; mean(data(i:i+bandsize-1, :))]; % average the frequencies from i to i+bandsdata
			end	
			% make 10Hz band			
			bandsize = 10;
			for i=1:bandsize:size(data,1)-bandsize
				bandsdata = [bandsdata ; mean(data(i:i+bandsize-1, :))];
			end	
			
			
			spectogramsBandsPerPerson{individual}{compind} = bandsdata;
		end
	end
end


function allBandsCorr = calc_correlations(spectogramsBandsPerPerson)
	%spectogramsBandsPerPerson{i}{compind}[second, band]
	peoplenum = length(spectogramsBandsPerPerson);
	datalength = size(spectogramsBandsPerPerson{1}{1},2);

    window = 30; % in seconds	
	calclength = datalength;
	
	% all start at begining
	startingTimePerPerson = ones(1,peoplenum);



	allBandsCorr = do_calc_correlations(spectogramsBandsPerPerson, startingTimePerPerson, calclength, window);
end

function allBandsCorr = calc_rand_correlations(spectogramsBandsPerPerson)
	peoplenum = length(spectogramsBandsPerPerson);
	datalength = size(spectogramsBandsPerPerson{1}{1},2);

    window = 30; % in seconds	
	calclength = 100 + window;
	
	% all start at begining
	startingTimePerPerson = randi(datalength-calclength, 1,peoplenum);


	allBandsCorr = do_calc_correlations(spectogramsBandsPerPerson, startingTimePerPerson, calclength, window);
end



function allBandsCorr = do_calc_correlations(spectogramsBandsPerPerson, startingTimePerPerson, datalength, window)

	peoplenum = length(spectogramsBandsPerPerson);
	componentnum = length(spectogramsBandsPerPerson{1});
	bandsnum = size(spectogramsBandsPerPerson{1}{1},1);

	% go over bands
	% calc the corr for the entire time per band
	allBandsCorr = [];
	parfor bandi = 1:bandsnum
		% go over time looking at a window
		% calc the corr
		corrtimevec = [];
		for windowstart=1:datalength-window
%			disp(sprintf('band %d windowstart %d', bandi, windowstart));
			
			% build component matrix
			compmat = [];
			for personi = 1:peoplenum
				for compi = 1:componentnum
					starttimei = startingTimePerPerson(personi)-1+windowstart;				
					compmat = [compmat spectogramsBandsPerPerson{personi}{compi}(bandi, starttimei:starttimei+window-1)'];
				end
			end
			
			%boom
			corrmat = corr(compmat);

			%now go over the person per person blocks in the matrix
			avgvalue = 0;
			for personi = 1:peoplenum-1
				for personj = personi+1:peoplenum
					si = (personi-1)*componentnum+1;
					sj = (personj-1)*componentnum+1;
					
					maxcorr = max(max(corrmat(si:si+componentnum-1,sj:sj+componentnum-1)));
					avgvalue = avgvalue + maxcorr;
				end
			end
			
			avgvalue = avgvalue / (peoplenum*(peoplenum-1)/2); % go from sum to average			
		
			corrtimevec = [corrtimevec, avgvalue]; % create the time series
		end
		
%		allBandsCorr = [allBandsCorr; corrtimevec]; % stack the bands time series
		allBandsCorr(bandi,:) = corrtimevec; % stack the bands time series

	end
end	


	
function allBandsCorr = slow_calc_correlations(spectogramsBandsPerPerson, startingTimePerPerson, calclength, window)

	peoplenum = length(spectogramsBandsPerPerson);
	componentnum = length(spectogramsBandsPerPerson{1});
	bandsnum = size(spectogramsBandsPerPerson{1}{1},1);

	% go over bands
	% calc the corr for the entire time per band
	allBandsCorr = [];
	for bandi = 1:bandsnum
		% go over time looking at a window
		% calc the corr
		corrtimevec = [];
		for windowstart=1:calclength-window
			disp(sprintf('band %d windowstart %d', bandi, windowstart));
			% go over all pairs of people
			% calc AVERAGE max correlation
			avgvalue = 0;
				for personi = 1:peoplenum-1
					for personj = personi+1:peoplenum
						% go over all pairs of componentsPerPerson. 
						% calc the MAX correlation
						maxcorr = -1;
						for compi = 1:componentnum
							for compj = 1:componentnum
								% get correlation between the bands here
								starttimei = startingTimePerPerson(personi)-1+windowstart;
								starttimej = startingTimePerPerson(personj)-1+windowstart;
								
								% get data windows
								datai = spectogramsBandsPerPerson{personi}{compi}(bandi, starttimei:starttimei+window-1);
								dataj = spectogramsBandsPerPerson{personj}{compj}(bandi, starttimej:starttimej+window-1);
								% get correlation
								val = corr(datai', dataj');
								% save the max value			
								maxcorr = max(maxcorr, val);
							end
						end
						% sum up to calculate the average
						avgvalue = avgvalue + maxcorr;
					end
				end
			
			% devide to get the average
			avgvalue = avgvalue / (peoplenum*(peoplenum-1)/2); % go from sum to average
		
			corrtimevec = [corrtimevec, avgvalue]; % create the time series
		end
		
		allBandsCorr = [allBandsCorr; corrtimevec]; % stack the bands time series

	end	

		
	

end





function result = cachefun(func, name)
	
%	if (exist('__cache', 'var')==0)
%		global __cache;
%		__cache = struct;
%	end
	
%	if (isfield(__cache, name))
%		result = getfield(__cache, name);
%	else
		fname = strcat(name, '.mat');
		if (exist(fname, 'file'))
			clear result;
			disp(sprintf('Loading %s...', fname));
			load(fname); % should load a variable named result 
			assert(exist('result', 'var') ~= 0, 'cache load didnt work');
		else
			disp(sprintf('Calculating %s...', fname));
			result = func();
            disp(sprintf('Saving %s...', fname));
			save(fname, 'result', '-v7.3'); 
            disp(sprintf('Saved %s', fname));
		end

		disp(sprintf('Got %s', fname));					
%		setfield(__cache, name, result);
%	end	
	
end

function res = dome()
	disp('dome');
	res = 2;
end



	
