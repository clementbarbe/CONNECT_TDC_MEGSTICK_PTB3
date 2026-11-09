function [X, Y, rawAxes] = QueryJoystickData( ScreenWidth, ScreenHeight ) %#ok<INUSD>
global S

rawAxes = ADAPT.ReadJoystickAxes();
[X,Y] = ADAPT.JoystickPosition(rawAxes,S.Joystick.Center, ...
    S.xmin_ymin_xmax_ymax,ScreenHeight,S.Parameters.ADAPT.Joystick);

end % function
