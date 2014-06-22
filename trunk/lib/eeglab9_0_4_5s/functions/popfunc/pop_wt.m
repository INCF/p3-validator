function [ EEG, com ] = pop_wt( EEG );
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
com ='';


%sinusova vlna slozena z klid, klid, 8 Hz

tt = (0:0.01:1.6*2*pi); % 628 = 2*pi .... 1005 = 1.6*2*pi
sin_8Hz = 7*sin(50.2*tt); 
s_klid = 4*sin(0*tt); 

s = [s_klid s_klid sin_8Hz];
figure(3)
subplot(3,1,1);
plot(s); title('Sinusova vlna obsahujici frekvenci 8 Hz'); axis ([0 1300 -1.1 1.1]);


%sinusova vlna slozena z ruznych sinu - frekvence 2Hz, 5Hz, 3Hz

sin_mix = 4*sin(12.6*tt) + 2*sin(31.4*tt) + 3*sin(18.8*tt);

s2 = [sin_mix sin_mix sin_mix];
figure(3)
subplot(3,1,2);
plot(s2); title('Sinusova vlna slozena ze sinusovych vln s ruznou frekvenci i amplitudou')
; axis ([0 1300 -10 10]);

%soucet dvou predchozich sinusovych signalu
 
celk = s + s2;
figure (3);
subplot(3,1,3);
plot(celk); title('Sectene predchozi sinusove vlny'); axis ([0 1300 -10 10]);



figure(5) %CWT vytvoreneho signalu

scales = 1:128;
delta = 0.001; %perioda vzorkování (1/1000)
coefs = cwt(celk, scales, 'db7', 'plot');

f = scal2frq(scales,'db7',delta);

per = 1./f;

disp ('Scale Frequency Period')
disp([scales' f' per'])

figure(6)
plot(coefs(86,:)); title('Scale 86 in test signal');

figure(7) %Scalogram vytvoreneho signalu
sc = wscalogram ('image', coefs);

%realna data EEG

figure(8) %jeden z kanalu EEG dat
sig = EEG.data(1,:);
plot(sig)
axis([0 12600 -290 -120])

figure(9) %CWT EEG dat
scales = 1:128;

coefs2 = cwt(sig, scales, 'db7', 'plot');



delta = 0.001; 


f = scal2frq(scales,'db7',delta);

per = 1./f;

disp ('Scale Frequency Period')
disp([scales' f' per'])

figure(10)
plot(coefs2(86,:)); title('Scale 86 in EEG signal');

figure(11) %Scalogram EEG dat
sc2 = wscalogram ('image', coefs2, f);
axis([0 12600 1 32])


%sinusovka
% 
% t =(0:0.01:10);
% t2 =(0:0.01:5);
% prvnis = 4*sin(1*t);
% druhas = 8*sin(8*t2);
% tretis = 4*sin(4*t);
% 
% 
% sig = [prvnis druhas tretis];
% figure (1)
% plot(sig)
% 
% scales = 1:32;
% 
% figure(3)
% coefs = cwt(sig, scales, 'db5', 'plot');
% a = 2.^[1:128];
% f = scal2frq(scales, 'db5', 1000);
% 
% 
% figure(4)
% sc = wscalogram ('image', coefs, 'scales', f);
% 
% 
% 
% 
% figure(5)
% sig = EEG.data(3,:);
% plot(sig)
% axis([0 12600 -290 -120])
% 
% figure(6)
% coefs2 = cwt(sig, 1:32, 'db5', 'plot');
% axis([0 12600 1 32])
% a = 2.^[1:32];
% f = scal2frq(a, 'db5',0.1);
% 
% per = 1./f;
% 
% disp('Scale Frequency Period')
% disp([a' f' per'])
% 
% figure(7)
% sc2 = wscalogram ('image', coefs2);
% a = 2.^[1:32];
% f = scal2frq(a, 'db5',0.1);
% axis([0 12600 1 32])

end

