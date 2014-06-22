function [event]=fetch_event(data)

% FETCH_EVENT mimics the behaviour of FT_READ_EVENT, but for a FieldTrip
% raw data structure instead of a file on disk.
%
% Use as
%   [event] = fetch_event(data)
%
% See also FT_READ_EVENT, FETCH_HEADER, FETCH_DATA

% Copyright (C) 2008, Esther Meeuwissen
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: fetch_event.m 1739 2010-09-21 13:17:59Z sashae $

% check whether input is data
data = checkdata(data, 'datatype', 'raw');

% locate the event structure
event = findcfg(data.cfg, 'event');

