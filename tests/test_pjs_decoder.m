function test_pjs_decoder()
%TEST_PJS_DECODER Binary fixtures, signed extrema, noise and all split points.
setup_AMEDYST();
packets = uint8([128 0 0 0; 136 127 0 7; 135 0 127 8; ...
    143 127 127 15; 240 10 13 0]);
expected = [0 0; 1023 -1024; -1024 1023; -1 -1; 10 13];
stream = reshape(packets',1,[]);
[frames,tail] = ADAPT.DecodePJS(stream);
assert(isequal(frames.Axes,expected) && isempty(tail));
assert(isequal(frames.Buttons,[false(4,2); true(1,2)]));
assert(isequal(frames.Trigger,[false(4,1);true]));
for split = 0:numel(stream)
    [first,tail] = ADAPT.DecodePJS(stream(1:split));
    [second,tail] = ADAPT.DecodePJS(stream(split+1:end),tail);
    assert(isequal([first.Axes;second.Axes],expected) && isempty(tail));
end
tail = uint8([]);
decoded = zeros(0,2);
for byte = stream
    [frames,tail] = ADAPT.DecodePJS(byte,tail);
    decoded = [decoded;frames.Axes];
    assert(numel(tail)<=3);
end
assert(isequal(decoded,expected));

% Connecting to a running stream can begin in the middle of any packet.
repeated = repmat(stream,1,3);
for offset = 0:3
    [frames,tail] = ADAPT.DecodePJS(repeated(1+offset:end));
    if offset==0, wanted = repmat(expected,3,1);
    else, wanted = [expected(2:end,:);repmat(expected,2,1)]; end
    assert(isequal(frames.Axes,wanted) && isempty(tail));
end
[frames,~,info] = ADAPT.DecodePJS([uint8([1 2 3 128 255 99 99 32 20]) stream]);
assert(isequal(frames.Axes,expected) && info.DiscardedBytes==9);

% A missing byte must not shift all subsequent positions permanently.
damaged = [stream(1:5),stream(7:end),stream];
[frames,~] = ADAPT.DecodePJS(damaged);
assert(isequal(frames.Axes(end-4:end,:),expected));

% Exhaustive signed 11-bit decoding, independently reconstructed fixtures.
values = (-1024:1023)';
unsigned = mod(values,2048);
data = uint8([128+floor(unsigned/128),mod(unsigned,128), ...
    mod(unsigned,128),floor(unsigned/128)]);
frames = ADAPT.DecodePJS(reshape(data',1,[]));
assert(isequal(frames.Axes,[values values]));
disp('All PJS decoder assertions passed.');
end
