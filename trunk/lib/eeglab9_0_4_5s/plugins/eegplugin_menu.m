% eegplugin_menu() 
function eegplugin_metody( fig, try_strings, catch_strings);
 
% vytvoreni menu Methods of analysis v nabidce Plot
plotmenu = findobj(fig, 'tag', 'plot');
submenu = uimenu( plotmenu, 'label', 'Methods of analysis');


psd_welch = [ 'EEG = pop_psd(EEG)' ]; 
wavelet = [ 'EEG = pop_wt(EEG)' ];

% add new submenu
uimenu( submenu, 'label', 'Power spectral density - Welch', 'callback', psd_welch);
uimenu( submenu, 'label', 'Wavelet transform', 'callback', wavelet);

