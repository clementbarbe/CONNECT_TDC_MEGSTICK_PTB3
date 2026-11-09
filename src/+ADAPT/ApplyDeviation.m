function [ dXc, dYc ] = ApplyDeviation( prevX, prevY, newX, newY, deviation )

dX = newX - prevX; % pixels
dY = newY - prevY; % pixels

% dR     = sqrt(dX*dX + dY*dY); % pixels
% dTheta = atan2(dY,dX);        % rad
[dTheta,dR] = cart2pol(dX,dY); % built-in (probably faster, but surely more elegent)

% dXc = dR * cos(dTheta + deviation*pi/180); % pixels
% dYc = dR * sin(dTheta + deviation*pi/180); % pixels
% Screen uses an upward-positive Y axis. The protocol defines +30 deg as
% CLOCKWISE: use a negative mathematical rotation on the raw displacement.
[dXc,dYc] = pol2cart(dTheta - deviation*pi/180,dR);

end % function
