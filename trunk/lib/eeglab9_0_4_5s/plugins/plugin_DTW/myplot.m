function myplot(figure_name, times, zero_axes, invert_polarity, data1, data2, data1_name, data2_name)
%myplot() just a simplification for displaying of time series

figure('name', '', 'NumberTitle', 'off');
hold on;
axis on;
title(figure_name);

if nargin > 5,
    x_span = [floor(min(min(data1), min(data2))) ceil(max(max(data1), max(data2)))];
else
    x_span = [floor(min(data1)) ceil(max(data1))];
end

if zero_axes == 1,
    plot([times(1) times(length(times))],[0 0],...
        'Color','green','LineWidth',1); % draw horizontal axis at time 0
    plot([0 0],x_span,...
        'Color','green','LineWidth',1); % draw vertical axis at time 0
end

clear xlabel ylabel;
xlabel('Time (ms)');
ylabel('Potential (\muV)');

if invert_polarity == 1,set(gca,'YDir','reverse'); end

if nargin < 6,
    data1_handle = plot(times, data1 ,'Color','blue','LineWidth',2);
    
elseif nargin > 6,
    data1_handle = plot(times, data1 ,'Color','red','LineWidth',1);
    data2_handle = plot(times, data2 ,'Color','blue','LineWidth',2);
end;


if nargin == 8, legend([data1_handle data2_handle], data1_name, data2_name,'Location','SouthEastOutside'); end



end

