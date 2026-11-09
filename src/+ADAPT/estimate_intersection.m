function [x,y] = estimate_intersection(preDot, endDot, circle)
%ESTIMATE_INTERSECTION Intersection between movement segment and outer ring.
% Geometrically equivalent intent to the original fsolve approximation, but
% handles vertical paths, needs no Optimization Toolbox, and avoids fitting.
R = (circle.diameter - circle.thickness)/2;
p0 = [preDot.X preDot.Y];
p1 = [endDot.X endDot.Y];
d = p1 - p0;
a = dot(d,d);
if a == 0
    x = round(p1(1));
    y = round(p1(2));
    return
end
b = 2*dot(p0,d);
c = dot(p0,p0)-R^2;
discriminant = b*b-4*a*c;
if discriminant >= 0
    rootsT = [(-b-sqrt(discriminant))/(2*a), (-b+sqrt(discriminant))/(2*a)];
    onSegment = rootsT(rootsT>=0 & rootsT<=1);
    if ~isempty(onSegment)
        t = min(onSegment);
        hit = p0 + t*d;
        x = round(hit(1));
        y = round(hit(2));
        return
    end
end
% Edge case: a hardware polling step did not bracket the circumference.
if abs(norm(p0)-R) <= abs(norm(p1)-R)
    hit = p0;
else
    hit = p1;
end
x = round(hit(1));
y = round(hit(2));
end
