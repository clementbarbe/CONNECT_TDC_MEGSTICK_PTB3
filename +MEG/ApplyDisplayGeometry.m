function S = ApplyDisplayGeometry(S)
%APPLYDISPLAYGEOMETRY Configure relative MEG stimulus sizes.
% No monitor width measurement is required: the outer circle diameter is
% 80% of the PTB window height. Other stimuli preserve their relative
% proportions from the MEG document (20/320 for targets/cross, 16/320
% for cursor). Actual sizes in millimetres are NOT guaranteed.
S.MEG.GeometryMode = 'relative_to_window_height';
S.MEG.RequestedSamplingHz = 140;
outerRatio = S.Parameters.ADAPT.Circle.DimensionRatio;
S.Parameters.ADAPT.Target.DimensionRatio = outerRatio * 20/320;
S.Parameters.ADAPT.Cursor.DimensionRatio = outerRatio * 16/320;
S.Parameters.ADAPT.Cross.ScreenRatio = outerRatio * 20/320;
S.Parameters.ADAPT.Circle.FrameColor = [255 255 255];
S.Parameters.ADAPT.Cross.Color = [255 255 255];
if S.PTB.FPS < S.MEG.RequestedSamplingHz
    warning('MEG:SamplingRate', ...
        'Trajectory capture follows screen flips (nominal %.1f Hz), not assured 140 Hz.',S.PTB.FPS);
end
end
