function PLOT_ALL( S )

fprintf('Plotting... \n')

ADAPT.Stats.plot_trajectories     ( S )
% ADAPT.Stats.plot_evolution_inBlock( S )

%ADAPT.Stats.plot_stat_by_reward   ( S )
%ADAPT.Stats.plot_stat_by_target   ( S )

fprintf('... done \n')

end % function
