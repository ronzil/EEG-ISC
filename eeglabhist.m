% EEGLAB history file generated on the 10-Feb-2016
% ------------------------------------------------
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadbv('C:\bigdata\debates\rep\', 'GOPDebate_Andrea_0001.vhdr', [1 2677765], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18]);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
EEG = eeg_checkset( EEG );
pop_eegplot( EEG, 1, 1, 1);
EEG = eeg_eegrej( EEG, [43 309] );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
eeglab redraw;
