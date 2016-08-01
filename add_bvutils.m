% add the functions in bvutils to the path.
function add_bvutils()
% One of the purposes of this library is to fix a bug in the default eeglab
% bvio plugin. To achive this we must make sure bvutils is loaded before
% bvio

    % make sure EEGLAB is loaded, as this library is dependent on it
    assert(exist('eeg_checkset', 'file')>0, 'EEGLAB seems not to be loaded.');

    % bvutils path
    bvutils_path = fullfile(fileparts(mfilename('fullpath')), 'bvutils');
  
    % check if we are matched first. pop_loadbv is used both by bvutils
    % and the problematic internal EEGLAB function. This works for both
    % use-cases of (1)nothing loaded (which returns ''), or (2)bad library loaded first.
    if (strcmp(fullfile(bvutils_path, 'pop_loadbv.m'), which('pop_loadbv')))
        return;
    end
        
    % insert path in the top of the search list.
    addpath(bvutils_path, '-BEGIN');

    % make sure it works now.
    assert(strcmp(fullfile(bvutils_path, 'pop_loadbv.m'), which('pop_loadbv')), 'cant get bvutils to take precedence in path.');
    
end
