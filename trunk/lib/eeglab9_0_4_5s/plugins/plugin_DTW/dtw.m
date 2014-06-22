function [ output ] = dtw(model, data, diagonal_drift, point_drift,  smoothing_amount, weights)
%dtw() function for calculation of average using Dynamic Time Warping
% dtw() - Calculates warping path from model and warps data dynamically
% Usage:
%      >> [warped_data] = dtw(model, data, diagonal_drift, point_drift, smoothing_amount, [value_weight 1st_derivative_veight]);
% Inputs:
%   model           - Data tht serves as a basis for warping curve 
%   data            - Data to be warped
%   diagonal_drift  - Maximum allowable deviation of warping function from the digonal
%   point_drift     - Maximum allowable number of steps in one direction before a mandatory diagonal step is taken
%   smoothing_amount- Width of averaging window (in datapoints) for smoothing of input data to achieve better results with noise
%   weights         - Weights of point value(1) and first derivative (2) for calculation of distance matrix
%
% Outputs:
%   channels    - a vector of channel indices.
%
% Example
%    >> [warped_average] = dtw(EEG.data(1,:,1), EEG.data(2,:,1), 50, 1, 20, [0.5 0.5]);
%
% Author: Pavel Petrman, University of West Bohemia, Czech Republic,
% 17.5.2012



% Check input parameters and set default values
if nargin < 6 || length(weights) < 2, weights = [0.5 0.5]; end
if nargin < 5 || smoothing_amount < 1, smoothing_amount = 1; end
if nargin < 4 || point_drift < 0, point_drift = 1; end

weights = weights/(weights(1)+weights(2));

fprintf('Calculating DTW. p: %d\td: %d\ts: %d\t w: %0.2f %0.2f \n',...
    point_drift,diagonal_drift,smoothing_amount,weights(1),weights(2));


weight_value = weights(1);
weight_d = weights(2);
% Check data size
%
% Mathematically the data needn't be same length, but in this algorithm and
% for use in other functions of this plugin we require same length
% nontheless.
if length(model) ~= length(data),
    error('Data must be of same length as model.');
end


data_length = length(data);

data_original = data;

% normalize data
model = model / max (model);
data = data / max (data);

data = smoothing(data,smoothing_amount);
model = smoothing(model,smoothing_amount);

% Calculate first derivative and shrink data
model_d = zeros(data_length,1);
data_d = zeros(data_length,1);
%Let's have a bit of unaccuracy at the start and the end
model_d(1) = (model(2) - model(1))/2;
data_d(1)  = (data(2) - data(1))/2;
model_d(data_length) = (model(data_length) - model(data_length-1))/2;
data_d(data_length)  = (data(data_length) - data(data_length-1))/2;

for iter_i = 2:data_length-1,
    model_d(iter_i) = (model(iter_i+1) - model(iter_i-1))/2;
    data_d(iter_i)  = (data(iter_i+1) - data(iter_i-1))/2;
end

% normalize derivative
model_d = model_d / max (max(model_d),abs(min(model_d)));
data_d = data_d / max (max(data_d),abs(min(data_d)));



% Calculate distance matrix
% Fill fields that are off limits set by diagonal drift to very high value
distances = ones(data_length,data_length) * realmax;
dtw = ones(data_length,data_length) * realmax;
dtw_values = zeros(data_length,1);
data_new = zeros(data_length,1);

tmp_diagonal = zeros(data_length,1);

for iter_i = 1:data_length,
    % Calculate only to a limited distance from the diagonal
    lower_bound = max(1, iter_i - diagonal_drift);
    upper_bound = min(iter_i + diagonal_drift,data_length);
    
    % Compute distance matrix and DTW cost matrix
    for iter_j = lower_bound:upper_bound,
        distance = weight_value * abs(model(iter_i) - data(iter_j)) + ...
            weight_d * abs(model_d(iter_i) - data_d(iter_j));
        distances(iter_i,iter_j) = distance;
        if iter_i > 1 && iter_j > 1,
            dtw(iter_i,iter_j) = distance + min([dtw(iter_i-1, iter_j), ...
                dtw(iter_i, iter_j-1), dtw(iter_i-1, iter_j-1)] );
        else
            dtw(iter_i,iter_j) = distance;
        end
    end
end

% Get warping path
steps_v = 0;    % counters for maximum number of steps in one direction
steps_h = 0;    % |
pos_h = data_length;      % Starting at the end
pos_v = data_length;      % |

while pos_h > 1 && pos_v > 1,
    
    dtw_values(pos_h) = pos_v; 
    
    % If limit is reached, all we need is a diagonal step and counter reset
    if steps_h >= point_drift || steps_v >= point_drift,
        pos_h = pos_h - 1;
        pos_v = pos_v - 1;
        steps_h = 0;
        steps_v = 0;
    else
        if distances(pos_h - 1, pos_v) < distances(pos_h - 1, pos_v - 1) ...
                && distances(pos_h - 1, pos_v) < distances(pos_h, pos_v - 1),
            % Horizontal step            
            pos_h = pos_h - 1;
            steps_h = steps_h + 1;
        elseif distances(pos_h, pos_v - 1) < distances(pos_h - 1, pos_v - 1) ...
                && distances(pos_h, pos_v - 1) < distances(pos_h - 1, pos_v),
            % Vertical step            
            pos_v = pos_v - 1;
            steps_v = steps_v + 1;
        else
            % Diagonal step otherwise
            % even if two other scores are equal (which happens rarely)            
            pos_h = pos_h - 1;
            pos_v = pos_v - 1;
            steps_v = 0;
            steps_h = 0;
        end
    end
end

% Last step
dtw_values(pos_h) = pos_v;


% Warp according to the calculated warping function
for iter_i = 1:length(dtw_values),
    tmp_diagonal(iter_i) = iter_i;
    new_position = dtw_values(iter_i);
    if new_position < 1, new_position = 1; end % TODO poøešit
    
    data_new(iter_i) = data_original(max(1,dtw_values(iter_i)));
end
output = transpose(data_new);
end

