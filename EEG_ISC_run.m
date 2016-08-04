%% EEG analysis
function results = EEG_ISC_run(config)    
	% store the config object
    global config__global__;
    config__global__ = config;
	
    % verify the configuration and data is as expected
    verify_config();
    
    % store the config's hash for the cache
    calc_hash_config();
    
    cache_log(['Starting EEG ISC calculation. Using the following configuration: ', tostring(config)]);
    
    alldata = config_param('data');            
	srate = alldata{1}.srate; %verified to be all equal
	datalength = alldata{1}.pnts; %verified to be all equal

	%step1 band pass filter.
	alldata = cachefun(@() do_filter(alldata), 'step1_dofilter');
    
   
    CorrSpectoTimeBands = [];
%    CorrSpectoTimeBands_oneremoved = [];
	RandCorrSpectoTimeBands = [];
	corrSig = [];
    
	% iterate all data in segments
	set_segment_length = config_param('segment_length')*srate;
	for start = 1:set_segment_length:datalength
	
        %spectorgrams and correlations require a window of data from the
        %moment we are trying to calculate. Therefore we need extra data to calculate the last second.
        %some padding to be on the safe side
        extra_length = srate*(10+max([config_param('spectogram_window_size'), config_param('correlation_window_size')]));
               
		segment_length = min(set_segment_length, datalength-start+1-extra_length-1);
        internal_segment_length = segment_length + extra_length; 
	
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
%		numComponents
		
		%spectogramsPerPerson is a cell array per person. Each cell is: Cell array of components. Each cell is: bands X data (in seconds)
		% spectogramsPerPerson{person_number}{component_number}{band_number, data}
		spectogramsPerPerson = cachefun(@() get_spectograms(componentsPerPerson, numComponents), 'step4_spectograms', start);

		% make average bands of specific sizes from the spectograms.
		spectogramsBandsPerPerson =  cachefun(@() make_bands(spectogramsPerPerson, numComponents), 'step5_spectogramBands', start);

		% add a band which is just a sliding window average of the component data.
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
		
        % accumulate all rand correlations.
        RandCorrSpectoTimeBands = cat(3, RandCorrSpectoTimeBands, randbandcorrMulti);

		% calculate the significance for each band	        
		sigBand = cachefun(@() calc_significance(realbandcorr, randbandcorrMulti), 'step8_SignificanceVec', start);
		
		corrSig = [corrSig, sigBand];
		
    end	

    % calculate the significance for each band for the entire span
    sigBandAll = cachefun(@() calc_significance(CorrSpectoTimeBands, RandCorrSpectoTimeBands), 'step8_SignificanceVec');
    
    % save calculations for entire time span.
	cache_save(CorrSpectoTimeBands, 'step6_CorrSpectoTimeBands');
%	cache_save(CorrSpectoTimeBands_oneremoved, 'step6a_CorrSpectoTimeBands_oneremoved');	
	cache_save(RandCorrSpectoTimeBands, 'step7_RandCorrSpectoTimeBands');
	cache_save(corrSig, 'step8a_SignificanceVec_accumulated_per_segment');
				        
    % make band labels.
    band_labels = {};
    bandsize = config_param('spectogram_band_size');    
    frequencies = size(spectogramsPerPerson{1}{1},1);
    %this for loop recreates the loop in make_bands() which is a bit ugly
    for i=1:bandsize:frequencies-bandsize+1
        band_labels = [band_labels; sprintf('%dhz-%dhz', i, i+bandsize-1)];
    end	
    % add the 'Raw' label to the end just like addAverageWindow()
    band_labels = [band_labels; 'Raw'];
    
    % Create results object
    results = {};
    results.band_labels = band_labels;
    results.correlations_per_band = CorrSpectoTimeBands;
    results.significance_per_band = sigBandAll';
    
end



function alldata = do_filter(alldata)
	for i = 1:length(alldata)
		EEG = alldata{i};
		
		EEG = pop_eegfiltnew(EEG, [], config_param('filter_low_edge'), [], true, [], 0); % high pass
		EEG = pop_eegfiltnew(EEG, [], config_param('filter_high_edge'), [], 0, [], 0);%% low pass
		EEG = eeg_checkset( EEG );
		
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
    data_channels = config_param('data_channels');
	parfor i = 1:length(alldata)
		EEG = alldata{i};
		
		EEG = pop_runica(EEG, 'extended',1,'interupt','on', 'chanind', data_channels);
		EEG = eeg_checkset( EEG ); 
		
		alldata{i} = EEG;
	end

end

function componentsPerPerson = get_components(alldata)
		componentsPerPerson = {};	
		for i = 1:length(alldata)
		    EEG = alldata{i};
			componentsPerPerson{i} = eeg_getdatact(EEG, 'component', [1:size(EEG.icaweights,1)]);
	%		componentsPerPerson{i} = EEG.data(1:16,:);
		end
end		
		

function spectogramsBandsPerPerson = addAverageWindow(spectogramsBandsPerPerson, componentsPerPerson, numComponents)
	data_length = length(componentsPerPerson{1}); %in samples.
    window = config_param('spectogram_window_size'); % in seconds
	data = config_param('data');
    srate = data{1}.srate;
	window_in_samples = window*srate;
	
	
	avgWindowPerPerson = {};
	for i = 1:length(componentsPerPerson) % going over people
		personspec = {};
		
		for compind = 1:numComponents % going over components
			compspec = [];
			
			% go over the data in <window> size. and calculate the mean			
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

	data_length = length(componentsPerPerson{1}); %in samples.
    window = config_param('spectogram_window_size'); % 5 seconds
	data = config_param('data');
    srate = data{1}.srate;
    frequencies = config_param('filter_high_edge');

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
				fft = fft(1:frequencies); % cut the unwanted frequencies because they are all zero and take a lot of space.

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
	
    bandsize = config_param('spectogram_band_size');    
    
	spectogramsBandsPerPerson = {};	
	for individual = 1:length(spectogramsPerPerson) % going over people
		spectogramsBandsPerPerson{individual} = {};
		
		for compind = 1:numComponents % going over components

			% frequence data for this component
			data = spectogramsPerPerson{individual}{compind}; %frequence data. 2D array frequence X time
			% holds the bands data
			bandsdata = [];

			% make bands			
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

    realval = mean(realbandcorr, 2)';
    randdist = mean(randbandcorrMulti, 3)';
    
    segBand = (realval - mean(randdist))./std(randdist);

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

% set a config parameter
function config_param_set(name, value) 
	global config__global__;
    config__global__.(name) = value;

end


% verify the configuration and data is as expected
function verify_config()
    % existance asserted in getter function
    alldata = config_param('data');
    config_param('run_name');
    config_param('data_channels');
  
    srate = alldata{1}.srate;
    datalength = alldata{1}.pnts;
    for i = 1:length(alldata)
        assert(alldata{i}.srate == srate, 'srate mismatch');
        assert(alldata{i}.pnts == datalength, 'data length mismatch');
    end
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
	
