% eegplugin_advanced_averaging() - Plugin for calculating Grand Average
% without ERPlab andcalculating averages using Dynamic Time Warping
function vers = eegplugin_advanced_averaging( fig, try_strings, catch_strings) 

    vers = 'Advanced Averaging 1.0';
    if nargin < 3
        error('eegplugin_advanced_averaging requires 3 arguments');
    end;
    
    % add folder to path
    % ------------------
    if exist('rozruch', 'file')
        p = which('eegplugin_advanced_averaging.m');
        p = p(1:findstr(p,'eegplugin_advanced_averaging.m')-1);
        addpath(p);
    end;
    
    % find import data menu
    % ---------------------
    menu = findobj(fig, 'tag', 'plot');
    
    % menu callbacks
    % --------------
    calls_grand_average = [ try_strings.no_check '[EEG LASTCOM] = pop_grand_average(EEG);' catch_strings.new_and_hist ];
    calls_time_warping = [ try_strings.no_check '[EEG LASTCOM] = pop_dtw(EEG);' catch_strings.new_and_hist ];
    
    % create menus
    % ------------
    my_menu = uimenu( menu, 'label', 'Averaging', 'separator', 'on');
    uimenu( my_menu, 'label', 'Grand Average', 'callback', calls_grand_average);
    uimenu( my_menu, 'label', 'Dynamic Time Warping', 'callback', calls_time_warping);
          
end 

