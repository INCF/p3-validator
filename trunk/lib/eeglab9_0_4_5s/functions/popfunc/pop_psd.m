function [ EEG, com ] = pop_psd( EEG );

com = '';

klid = pop_fileio('signal_klid.set'); %nacteni klidoveho signalu
stimul = pop_fileio('signal_stimul.set'); %nacteni simulovaneho signalu

win = hamming(2048);
[pxx1, f] = pwelch((klid.data(:,:)), win, [], [], 1000);
[pxx2, g] = pwelch((stimul.data(:,:)), win, [], [], 1000);

y1 = 10*log10(pxx1);
x1 = f;

y2 = 10*log10(pxx2);
x2 = g;

%klidovy signal
hodnota_klid = [x1, y1]


h5_5 = hodnota_klid (12, :)
h6 = hodnota_klid (13, :)
h6_5 = hodnota_klid (14, :)
h7 = hodnota_klid (15, :)

h7_5 = hodnota_klid (16, :)
h8 = hodnota_klid (17, :)
h8_5 = hodnota_klid (18, :)

h9 = hodnota_klid (19, :)
h9_5 = hodnota_klid (20, :)
h10 = hodnota_klid (21, :)
h10_5 = hodnota_klid (22, :)



i5_5 = h5_5(1, 2)
i6 = h6(1, 2)
i6_5 = h6_5(1, 2)
i7 = h7(1, 2)

i7_5 = h7_5(1, 2)
i8 = h8(1, 2)
i8_5 = h8_5(1, 2)

i9 = h9(1, 2)
i9_5 = h9_5(1, 2)
i10 = h10(1, 2)
i10_5 = h10_5(1, 2)

avg8 = (i7_5 + i8 + i8_5) / 3

avg = (i5_5 + i6 + i6_5 + i7 + i9 + i9_5 + i10 + i10_5) / 8 %prumer hodnot v okoli 8 Hz

pomer_klid = avg8/avg %pomer v 8 Hz a okoli v klidovem stavu

disp(pomer_klid);


%stimulovan signal
hodnota_stimul = [x2, y2];



h5_5 = hodnota_stimul (12, :)
h6 = hodnota_stimul (13, :)
h6_5 = hodnota_stimul (14, :)
h7 = hodnota_stimul (15, :)

h7_5 = hodnota_stimul (16, :)
h8 = hodnota_stimul (17, :)
h8_5 = hodnota_stimul (18, :)

h9 = hodnota_stimul (19, :)
h9_5 = hodnota_stimul (20, :)
h10 = hodnota_stimul (21, :)
h10_5 = hodnota_stimul (22, :)




i5_5 = h5_5(1, 2)
i6 = h6(1, 2)
i6_5 = h6_5(1, 2)
i7 = h7(1, 2)

i7_5 = h7_5(1, 2)
i8 = h8(1, 2)
i8_5 = h8_5(1, 2)

i9 = h9(1, 2)
i9_5 = h9_5(1, 2)
i10 = h10(1, 2)
i10_5 = h10_5(1, 2)



avg8 = (i7_5 + i8 + i8_5) / 3

avg = (i5_5 + i6 + i6_5 + i7 + i9 + i9_5 + i10 + i10_5) / 8 %prumer hodnot v okoli 8 Hz

pomer_stimul = avg8/avg %pomer v 8 Hz a okoli v klidovem stavu

disp('pomer stimul:');
disp(pomer_stimul)
disp('pomer_klid:');
disp(pomer_klid)

%klid
 figure(11);
 plot(f,10*log10(pxx1))
 axis ([0 20 -10 15]);
 xlabel ( 'Hz');
 ylabel ( 'dB' );
 grid on; %møížky
 title ( 'Welch Power Spectral Density Estimate - resting signal');

 %stimul
 figure(12);
 plot(g,10*log10(pxx2))
 axis ([0 20 -10 15]);
 xlabel ( 'Hz');
 ylabel ( 'dB' );
 grid on; %møížky
 title ( 'Welch Power Spectral Density Estimate - stimulated signal');
 
 %klid i stimul
 figure (13);
 

 plot(f,10*log10(pxx1), 'b-', g,10*log10(pxx2), 'r-' );
 axis ([0 20 -10 15]);
 xlabel ( 'Hz');
 ylabel ( 'dB' );
 legend('resting signal', 'stimulated signal')
 grid on; %møížky
 title ( 'Welch Power Spectral Density Estimate');
 

 
end

