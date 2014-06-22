function vers=eegplugin_save(fig,trystr,catchstr)
submenu = findobj(fig, 'tag', 'export');
vers='save_epochs1.0';
comcnt1 = [ trystr.check_epoch 'LASTCOM=pop_save(EEG);' catchstr.add_to_hist ]; 
uimenu(submenu,'label','Save epochs to text files', 'callback', comcnt1);