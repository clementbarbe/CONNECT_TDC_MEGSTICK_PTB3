function [ reward ] = Reward
global S

ratio = S.Parameters.ADAPT.Reward.ScreenRatio;
color = S.Parameters.ADAPT.Reward.NoRewardColor;

filename = fullfile(setup_AMEDYST(),'assets','images','50centsEURO.png');

reward = Image(filename, [], [], color);
reward.map = 0; % no need for these pictures

reward.LinkToWindowPtr(S.PTB.wPtr);
reward.MakeTexture;

reward.Move( [S.PTB.CenterH S.PTB.CenterV] );
reward.Rescale( (ratio*S.PTB.wRect(4)) / reward.baseRect(4) );

reward.AssertReady % just to check

end % function
