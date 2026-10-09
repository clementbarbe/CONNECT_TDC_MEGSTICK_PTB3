function test_protocol()
%TEST_PROTOCOL Can run in MATLAB without joystick/PTB/StimTemplate.
for order = 1:4
    base = MEG.BuildParadigm(1,order,'Acquisition',300);
    adapt = MEG.BuildParadigm(2,order,'Acquisition',300);
    assert(isequal(cell2mat(base(:,6))',[0 1 2]));
    assert(isequal(cell2mat(adapt(:,6))',[3 4 5 6 7 8]));
    assert(isequal(cell2mat(base(:,3))',[4 48 48]));
    assert(isequal(cell2mat(adapt(:,3))',[48 48 48 48 48 48]));
    assert(all(cell2mat(base(:,2))==0));
    assert(isequal(cell2mat(base(:,5))',[1 1 0]));
    assert(isequal(cell2mat(adapt([3 6],2))',[0 0]));
    assert(isequal(cell2mat(adapt([3 6],5))',[1 1]));
    assert(isequal(cell2mat(adapt([1 2],2)),repmat(adapt{1,2},2,1)));
    assert(isequal(cell2mat(adapt([4 5],2)),repmat(-adapt{1,2},2,1)));
    assert(all(cell2mat(adapt([1 2],5))==adapt{1,5}));
    assert(all(cell2mat(adapt([4 5],5))==1-adapt{1,5}));
    assert(adapt{1,8}==300 && adapt{4,8}==300);
    assert(sum(cell2mat(base(:,3)))+sum(cell2mat(adapt(:,3)))==388);
end
% Counterbalance variants from the four experimental diagrams.
rot = [30 -30 -30 30];
vis = [1 1 0 0];
for order=1:4
    p = MEG.BuildParadigm(2,order,'Acquisition',300);
    assert(p{1,2}==rot(order) && p{4,2}==-rot(order));
    assert(p{1,5}==vis(order) && p{4,5}==1-vis(order));
end
for phase=1:2
    p=MEG.BuildParadigm(phase,1,'FastDebug',300);
    assert(all(cell2mat(p(:,3))==4));
    assert(~any(cell2mat(p(:,8))>=300));
end
% Mathematical +30 is clockwise in right/up coordinates.
[dx,dy]=ADAPT.ApplyDeviation(0,0,1,0,30);
assert(abs(dx-cosd(30))<1e-10 && abs(dy+sind(30))<1e-10);
% Intersection works even for a perfectly vertical segment (old fsolve
% formulation could be undefined for equal X coordinates).
p0=struct('X',0,'Y',0); p1=struct('X',0,'Y',150);
circle=struct('diameter',202,'thickness',2);
[x,y]=ADAPT.estimate_intersection(p0,p1,circle);
assert(x==0 && y==100);
disp('All protocol assertions passed.');
end
