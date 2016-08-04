%%% EEG analysis

function EEG_ISC_run(config)
    assert(isfield(config, 'data'), 'Must provide data in the form a cell array of EEGLAB''s EEG objects');
    assert(isfield(config, 'run_name'), 'Must provide run_name string.');
    
	% store the config object
    global config__global__;
    config__global__ = config;
	
    % store the config's hash for the cache
    calc_hash_config();
    
    cache_log('Starting...');

    alldata = config_param('data');
        
	%step1 filter <1Hz and > 50Hz and subtract reference from #17
	alldata = cachefun(@() do_filter(alldata), 'step1_dofilter');
    
	%set data length as minimial length of EEG data from all people
	datalength = intmax;
	for i = 1:length(alldata)
		EEG = alldata{i};
		datalength = min(datalength, EEG.pnts);
	end
	
	%get sample rate
	srate = alldata{1}.srate;
	

    CorrSpectoTimeBands = [];
%    CorrSpectoTimeBands_oneremoved = [];
	RandCorrSpectoTimeBands = [];
	corrSig = [];
    
	% iterate all data in segments
	set_segment_length = config_param('segment_length')*srate;
	for start = 1:set_segment_length:datalength
	
		segment_length = min(set_segment_length, datalength-start+1-1*60*srate-1);
	
        %spectorgrams and correlations require a window of data from the
        %moment we are trying to calculate. Therefore we need extra data to calculate the last second.
        internal_segment_length = segment_length + 1*60*srate; 
		
		%trim EEG to segment length each time	
		alldatatrim = do_trim(alldata, start, start+internal_segment_length-1);
		
		%calculate ica weights
		alldatatrim = cachefun(@() do_ica(alldatatrim), 'step2_ica', start);

		%store the components data per person/
		%allComponents is a cell array per person. Each cell contains component data array.
		componentsPerPerson = cachefun(@() get_components(alldatatrim), 'step3_components', start);
		
		%find number of components by taking the minimum of all people. (sometimes its less than the channel number)
		numComponents = intmax;
		for i = 1:length(alldatatrim)
			numComponents = min(numComponents, size(componentsPerPerson{i},1));
		end
		numComponents
		
		%spectogramsPerPerson is a cell array per person. Each cell is: Cell array of components. Each cell is: bands X data (in seconds)
		% spectogramsPerPerson{person_number}{component_number}{band_number, data}
		spectogramsPerPerson = cachefun(@() get_spectograms(componentsPerPerson, numComponents), 'step4_spectograms', start);

		% make average bands of specific sizes from the spectograms.
		spectogramsBandsPerPerson =  cachefun(@() make_bands(spectogramsPerPerson, numComponents), 'step5_spectogramBands', start);

		% add a band which is just a sliding windo average of the component data.
		spectogramsBandsPerPerson =  cachefun(@() addAverageWindow(spectogramsBandsPerPerson, componentsPerPerson, numComponents), 'step5a_averageWindow', start);

		% calcluate the correlation of each band 	
		realbandcorr = cachefun(@() calc_correlations(spectogramsBandsPerPerson, segment_length/srate), 'step6_CorrSpectoTimeBands', start);

%		fname = sprintf('step6a_CorrSpectoTimeBands_one_removed_%d_%d', start, internal_segment_length);								
%		realbandcorr_oneremoved = cachefun(@() calc_correlations_one_removed(spectogramsBandsPerPerson, segment_length/srate), fname);
		
        
        % accumilate all correlations.
        CorrSpectoTimeBands = [CorrSpectoTimeBands, realbandcorr];
%		CorrSpectoTimeBands_oneremoved = cat(2, CorrSpectoTimeBands_oneremoved, realbandcorr_oneremoved);

		% calculate the random correlation of each band
		randbandcorrMulti = cachefun(@() calc_rand_correlations(spectogramsBandsPerPerson, segment_length/srate), 'step7_RandCorrSpectoTimeBands_really_100_', start);
		
        % accumilate all rand correlations.
        RandCorrSpectoTimeBands = cat(3, RandCorrSpectoTimeBands, randbandcorrMulti);

		% calculate the significance for each band	        
		segBand = cachefun(@() calc_significance(realbandcorr, randbandcorrMulti), 'step8_SignificanceVec', start);
		
		corrSig = [corrSig; segBand(1,:)];
		
    end	
		
    % save correltion for entire time span.
	cache_save(CorrSpectoTimeBands, 'step6_CorrSpectoTimeBands');
%	cache_save(CorrSpectoTimeBands_oneremoved, 'step6a_CorrSpectoTimeBands_oneremoved');	
	cache_save(RandCorrSpectoTimeBands, 'step7_RandCorrSpectoTimeBands');
	cache_save(corrSig, 'step8_SignificanceVec_accumilated');
				        
	segBand = cachefun(@() calc_significance(CorrSpectoTimeBands, RandCorrSpectoTimeBands), 'step8a_SignificanceVec_all');

end



function alldata = do_filter(alldata)
	disp('doing filter');
	for i = 1:length(alldata)
		EEG = alldata{i};
		
		EEG = eeg_checkset( EEG );
		EEG = pop_chanedit(EEG, 'load',{'locations.loc' 'filetype' 'autodetect'},'setref',{'17' 'Ref'});
		EEG = eeg_checkset( EEG );
		EEG = pop_eegfiltnew(EEG, [], 1, 826, true, [], 0); %%filter data 1
%		EEG = pop_eegfiltnew(EEG, [], 20, 166, true, [], 1);		%%filter below 20
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
%			componentsPerPerson{i} = EEG.data(1:16,:);
		end
end		
		

function spectogramsBandsPerPerson = addAverageWindow(spectogramsBandsPerPerson, componentsPerPerson, numComponents)
	data_length = length(componentsPerPerson{1}); %in sample. note add assert that all components are same length
    window = config_param('spectogram_window_size'); % 5 seconds
	data = config_param('data');
    srate = data{1}.srate;
	window_in_samples = window*srate;
	
	
	avgWindowPerPerson = {};
	for i = 1:length(componentsPerPerson) % going over people
		personspec = {};
		
		for compind = 1:numComponents % going over components
			compspec = [];
			
			% go over the data in <window> size. and calculate the FFT			
			for step=1:srate:data_length-window_in_samples
				data = componentsPerPerson{i}(compind, step:step+window_in_samples-1);

				% accumilate the window. each point is one second
				compspec = [compspec , mean(data)];
		
			end
			
%			personspec{compind} = compspec;
            spectogramsBandsPerPerson{i}{compind} = [spectogramsBandsPerPerson{i}{compind} ; compspec];
			
		end
		
	end	



end

function spectogramsPerPerson = get_spectograms(componentsPerPerson, numcomponents)
	%spectogramsPerPerson is a cell array per person. Each cell is: Cell array of components. Each cell is: bands X data (in seconds)
	% spectogramsPerPerson{i}{compind}[second, frequency]

	data_length = length(componentsPerPerson{1}); %in sample. note add assert that all components are same length
    window = config_param('spectogram_window_size'); % 5 seconds
	data = config_param('data');
    srate = data{1}.srate;
    frequencies = config_param('spectogram_max_frequency');

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
				fft = fft(1:frequencies); % cut the unwanted frequencies because they are all zero and take a lot of space. NOTE CHECK THIS

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

			% make bands			
			bandsize = config_param('spectogram_band_size');
			for i=1:bandsize:size(data,1)-bandsize+1
				bandsdata = [bandsdata ; mean(data(i:i+bandsize-1, :))];
			end	
			
			spectogramsBandsPerPerson{individual}{compind} = bandsdata;
		end
	end
end

function allBandsCorr_one_removed = calc_correlations_one_removed(spectogramsBandsPerPerson, segment_length)
% do calc for one person removed each time
	allBandsCorr_one_removed = [];
	peoplenum = length(spectogramsBandsPerPerson);	
	for i=1:peoplenum
		
		partial = spectogramsBandsPerPerson(setdiff(1:peoplenum,i));
		allBandsCorr = calc_correlations(partial, segment_length);

		allBandsCorr_one_removed(:,:,i) = allBandsCorr;
	end

end



function allBandsCorr = calc_correlations(spectogramsBandsPerPerson, segment_length)
	%spectogramsBandsPerPerson{i}{compind}[second, band]
	peoplenum = length(spectogramsBandsPerPerson);
	datalength = size(spectogramsBandsPerPerson{1}{1},2);
    
    window = config_param('correlation_window_size'); % 30 seconds
    assert (segment_length + window <= datalength);
    
	calclength = segment_length;

	% all start at begining
	startingTimePerPerson = ones(1,peoplenum);

	allBandsCorr = do_calc_correlations(spectogramsBandsPerPerson, startingTimePerPerson, calclength, window);
end

function allBandsCorrMulti = calc_rand_correlations(spectogramsBandsPerPerson, segment_length)
	peoplenum = length(spectogramsBandsPerPerson);
	datalength = size(spectogramsBandsPerPerson{1}{1},2);

    window = config_param('correlation_window_size'); % 30 seconds
    calclength = config_param('correlation_random_length');
	
	randnum = config_param('correlation_random_iterations');
	allBandsCorrMulti=[];
	for i=1:randnum
		i	
		% all start at begining
		startingTimePerPerson = randi(round(segment_length-calclength), 1,peoplenum);
	
		allBandsCorr = do_calc_correlations(spectogramsBandsPerPerson, startingTimePerPerson, calclength, window);
		allBandsCorrMulti(:,:,i) = allBandsCorr;
	end
	
		
end



function allBandsCorr = do_calc_correlations(spectogramsBandsPerPerson, startingTimePerPerson, datalength, window)

	peoplenum = length(spectogramsBandsPerPerson);
	componentnum = length(spectogramsBandsPerPerson{1});
	bandsnum = size(spectogramsBandsPerPerson{1}{1},1);

	% go over bands
	% calc the corr for the entire time per band
	allBandsCorr = [];
	parfor bandi = 1:bandsnum
	
        % build component matrix
        compmat = [];
        for personi = 1:peoplenum
    		for compi = 1:componentnum
    			starttimei = startingTimePerPerson(personi);				
        		compmat = [compmat spectogramsBandsPerPerson{personi}{compi}(bandi, starttimei:starttimei+datalength+window-1)'];
            end
        end
        
		% go over time looking at a window
		% calc the corr
		corrtimevec = [];

		for windowstart=1:datalength
%			disp(sprintf('band %d windowstart %d', bandi, windowstart));
			
			%boom
			corrmat = corr(compmat(windowstart:windowstart+window-1,:));

			%now go over the person per person blocks in the matrix
			avgvalue = 0;
			for personi = 1:peoplenum-1
				for personj = personi+1:peoplenum
					si = (personi-1)*componentnum+1;
					sj = (personj-1)*componentnum+1;
					
%					maxcorr = max(max(corrmat3(si:si+componentnum-1,sj:sj+componentnum-1)));
                    b = corrmat(si:si+componentnum-1,sj:sj+componentnum-1);
					maxcorr = max(b(:));
					avgvalue = avgvalue + maxcorr;
				end
			end
			
			avgvalue = avgvalue / (peoplenum*(peoplenum-1)/2); % go from sum to average			

            %% tryied these optimiztions that werent faster.
            %mb = max(im2col(corrmat3, [componentnum componentnum], 'distinct'));
            %mb(1:peoplenum+1:peoplenum^2) = [];
            %avg3 = mean(mb);
            
            %b = blockproc(corrmat3, [16 16],  @(block_struct) max(block_struct.data(:)));
            %avg4 = (sum(b(:))-10)/90;
            avgvalue= gather(avgvalue);
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



function segBand = calc_significance(realbandcorr, randbandcorrMulti)
	%realbandcorr is a matrix of bands,time
	%randbandcorrMulti is matrix of bands,time,interations
	
	significance = config_param('significance_threshold'); % 2 standard devs
	
	bandsnum = size(realbandcorr,1);

	segBand = [];
	% go over bands
	% calc the corr for the entire time per band
	allBandsCorr = [];
	for bandi = 1:bandsnum
		%calc 
		randdata = randbandcorrMulti(bandi, :, :);
		randdata = randdata(:);
		randm = mean(randdata);
		rands = std(randdata);
		
		limit = randm + rands*significance;
		
		realcount = sum(realbandcorr(bandi,:) > limit);
		randcount = sum(randdata > limit);
        
		segBand(1,bandi) = realcount/length(realbandcorr);
		segBand(2,bandi) = randcount/length(randdata);
		segBand(3,bandi) = limit;
		
	end



end

%-----------------------------------------------------------------------------
% Utility functions

% convert to frequency domain
function res = freq(x)
	L=length(x);	 	 
	NFFT=256;
	X=fft(x,NFFT);	 	 
	Px=X.*conj(X)/(NFFT*L); %Power of each freq components	 	 
	res = Px(1:NFFT/2);

end

% calculate hash of string.
% from here: http://au.mathworks.com/matlabcentral/answers/45323-how-to-calculate-hash-sum-of-a-string-using-java
function hash = string2hash(string)
    persistent md
    if isempty(md)
        md = java.security.MessageDigest.getInstance('MD5');
    end
    hash = sprintf('%2.2x', typecast(md.digest(uint8(string)), 'uint8')');
end

function res = tostring(v)
   res = evalc('disp(v)');
end

% return the configuration parameter under name. 
% if it doesn't exist, look at the default values.
% abort if not found.
function res = config_param(name) 
	global config__global__;
    if (isfield(config__global__, name))
        res = config__global__.(name);
        return
    end

    defaults = EEG_ISC_defaults();
    if (isfield(defaults, name))
        res = defaults.(name);
        return
    end
    
    assert(false, ['Configuration parameter not defined: ', name]);
    
end

% calculate a hash of the current config struct. Including the data file
% names
function calc_hash_config()
    global config__global__;

    % add the names of the data files to the hashed data
    t = config__global__;
    t.names = strjoin(cellfun(@(EEG) EEG.filename, t.data, 'UniformOutput', false));
    
    config__global__.config_hash = string2hash(tostring(t));
end

% Cache wrapper for function call. If the given key exists in the cache,
% return it's value, otherwise run the function and store the result in the
% cache.
% Optionally, additional parts of the key can be provided as extra
% parameters.
function result = cachefun(func, key, varargin)

        % add optional key parts to main key name
        for k = 1:length(varargin)
            key = [key, '_', num2str(varargin{k})];
        end

		fname = cache_get_filename(key);
		if (exist(fname, 'file'))
			clear result;
			cache_log(sprintf('Loading %s...', fname));
			load(fname); % should load a variable named result 
			assert(exist('result', 'var') ~= 0, 'cache load didn''t work');
		else
			cache_log(sprintf('Calculating %s...', fname));
            timerrun = tic;
			result = func();
            cache_log(sprintf('Saving %s... (elapsed %f)', fname, toc(timerrun)));
			cache_save(result, key)
            cache_log(sprintf('Saved %s', fname));
		end
end

% get the full path to the file in the cache directory for the given file
% name
function fname = cache_get_filename(key)
	% cache dir contains the run_name and the hash or the parameters.
    cache_dir__ = fullfile(config_param('cache_base_directory'), 'cache', [config_param('run_name'), '_', config_param('config_hash')]);
    
    % create it if it doesn't exist
	if (~exist(cache_dir__, 'dir'))
        mkdir(cache_dir__);
    end    
	
    % add a .mat extension if there is none
    if (isempty(strfind(key, '.')))
        key = [key, '.mat'];
    end
    
	fname = fullfile(cache_dir__, key);
end

% save given result in cache under given name.
function cache_save(result, key)
	fname = cache_get_filename(key);
	save(fname, 'result', '-v7.3'); 
end

% append a log message to the run log in the cache folder
function cache_log(msg)
	fname = cache_get_filename('runlog.txt');
	f = fopen(fname, 'a');
	disp(msg);
	fprintf(f,'%s: %s\n',datestr(datetime), msg);
	fclose(f);
end
	
