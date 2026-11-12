function [frames, pending, info] = DecodePJS(bytes, pending)
%DECODEPJS Decode the four-byte Current Designs programmer's joystick stream.
% Native signed 11-bit axes, before direction correction or scaling.
% Layout: 1 L T R yyyy | 0xxxxxxx | 0yyyyyyy | 0000xxxx.
% Format reference: https://icm-institute.atlassian.net/wiki/spaces/CENIR/pages/360560
% This implementation intentionally uses two's complement modulo 2048.
if nargin<2, pending = uint8([]); end
data = [uint8(pending(:)') uint8(bytes(:)')];
frames = struct('Axes',zeros(0,2),'Buttons',false(0,2),'Trigger',false(0,1));
info = struct('DiscardedBytes',0,'LeadingDiscarded',0,'Continuous',true,'LastRunLength',0);
count = numel(data);
if count<4, pending = data; return; end
starts = find(data(1:end-3)>=128 & data(2:end-2)<128 & ...
    data(3:end-1)<128 & data(4:end)<16);
if isempty(starts)
    pending = data(max(1,count-2):end);
    info.DiscardedBytes = count-numel(pending);
    return
end
x = double(bitand(data(starts+3),15))*128+double(data(starts+1));
y = double(bitand(data(starts),15))*128+double(data(starts+2));
x(x>=1024) = x(x>=1024)-2048;
y(y>=1024) = y(y>=1024)-2048;
frames.Axes = [x(:) y(:)];
frames.Buttons = [bitand(data(starts),64)'~=0 bitand(data(starts),16)'~=0];
frames.Trigger = bitand(data(starts),32)'~=0;
trailing = data(starts(end)+4:end);
pending = trailing(max(1,numel(trailing)-2):end);
info.DiscardedBytes = count-4*numel(starts)-numel(pending);
info.LeadingDiscarded = starts(1)-1;
gaps = find(diff(starts)~=4);
info.Continuous = isempty(gaps);
if isempty(gaps), info.LastRunLength = numel(starts);
else, info.LastRunLength = numel(starts)-gaps(end); end
end
