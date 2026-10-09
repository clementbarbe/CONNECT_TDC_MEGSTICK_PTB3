function S = ApplyDisplayGeometry(S)
%APPLYDISPLAYGEOMETRY Convert physical stimulus dimensions to screen pixels.
% The operator must MEASURE the visible display width in millimetres.
% Relative positions and original PTB shape classes are left unchanged.
fullRect = Screen('Rect',S.ScreenID);
fullWidth = fullRect(3)-fullRect(1);
pxPerMm = fullWidth/S.MEG.DisplayWidthMm;
windowHeight = S.PTB.wRect(4)-S.PTB.wRect(2);
outerPx = 320*pxPerMm;
if outerPx + 20*pxPerMm > windowHeight
    if strcmp(S.OperationMode,'Acquisition')
        error('MEG:DisplayTooSmall', ...
            '320 mm circle + margin will not fit the selected window. Use a larger display or adjust geometry.');
    else
        warning('MEG:DebugGeometry','Screen too small for 320 mm diameter in debug.');
    end
end
S.MEG.PixelsPerMm = pxPerMm;
S.MEG.ViewingDistanceMm = 800; % Physical setup must be verified by operator.
S.MEG.RequestedSamplingHz = 140;
S.Parameters.ADAPT.Circle.DimensionRatio = outerPx/windowHeight;
S.Parameters.ADAPT.Circle.FrameColor = [255 255 255];
S.Parameters.ADAPT.Target.DimensionRatio = 20*pxPerMm/windowHeight;
S.Parameters.ADAPT.Cursor.DimensionRatio = 16*pxPerMm/windowHeight;
S.Parameters.ADAPT.Cross.ScreenRatio = 20*pxPerMm/windowHeight;
S.Parameters.ADAPT.Cross.Color = [255 255 255];
S.Parameters.ADAPT.Cross.lineWidthRatio = 0.05;
if S.PTB.FPS < S.MEG.RequestedSamplingHz
    warning('MEG:SamplingRate', ...
        'Original sampler records one cursor sample per flip (nominal %.1f Hz), not 140 Hz. Validate MEG acquisition rate.', S.PTB.FPS);
end
end
