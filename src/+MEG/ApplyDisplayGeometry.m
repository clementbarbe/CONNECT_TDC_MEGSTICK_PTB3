function S = ApplyDisplayGeometry(S)
%APPLYDISPLAYGEOMETRY Configure relative MEG stimulus sizes.
% No monitor width measurement is required: the outer circle diameter is
% 80% of the PTB window height. The central/peripheral target diameter uses
% the document's 20/320 ratio times DiameterMultiplier; cross = 20/320,
% cursor = 16/320. Actual sizes in millimetres are NOT guaranteed.
S.MEG.GeometryMode = 'relative_to_window_height';
S.MEG.RequestedSamplingHz = 140;
outerRatio = S.Parameters.ADAPT.Circle.DimensionRatio;
S.Parameters.ADAPT.Target.DimensionRatio = outerRatio * 20/320 * ...
    S.Parameters.ADAPT.Target.DiameterMultiplier;
S.Parameters.ADAPT.Cursor.DimensionRatio = outerRatio * 16/320;
S.Parameters.ADAPT.Cross.ScreenRatio = outerRatio * 20/320;
S.Parameters.ADAPT.Circle.FrameColor = [255 255 255];
S.Parameters.ADAPT.Cross.Color = [255 255 255];
if S.PTB.FPS < S.MEG.RequestedSamplingHz
    warning('MEG:SamplingRate', ...
        'Trajectory capture follows screen flips (nominal %.1f Hz), not assured 140 Hz.',S.PTB.FPS);
end
end
