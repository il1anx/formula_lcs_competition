% Define parameter ranges to test
slip_ratios = linspace(0.02, 1, 20);  % Different slip ratio thresholds
p_gains = linspace(0,500,50);           % Different traction power cut percentages

% Initialize results storage
results = [];

% Calculate total number of combinations
total_combinations = length(slip_ratios) * length(p_gains);
current_combo = 0;

fprintf('Starting parameter sweep: %d total combinations\n', total_combinations);

% Loop through all parameter combinations
for i = 1:length(slip_ratios)
    for j = 1:length(p_gains)
        
        % Update progress counter
        current_combo = current_combo + 1;
        percent_complete = (current_combo / total_combinations) * 100;
        
        % Set parameters in base workspace (so Simulink can access them)
        assignin('base', 'kappa_thresh', slip_ratios(i));
        assignin('base', 'TC_CUT', p_gains(j));
        
        % Run simulation
        simOut = sim('cbuildv3p0.slx'); % Adjust stop time as needed
        
        % Extract simulation results
        % Assuming you have a signal that tracks distance or acceleration time
        time_to_complete = simOut.tout(end);
        
        % Store results
        results(i,j).slip_ratio = slip_ratios(i);
        results(i,j).cut_percent = p_gains(j);
        results(i,j).acceleration_time = time_to_complete;
        results(i,j).simulation_data = simOut;
        
        % Display progress with percentage
        fprintf('Completed: %d/%d (%.1f%%) - Slip Ratio=%.3f, Cut Percent=%.3f, Time=%.3fs\n', ...
                current_combo, total_combinations, percent_complete, ...
                slip_ratios(i), p_gains(j), time_to_complete);
    end
end

fprintf('Parameter sweep complete! 100%% done.\n');

% Save results
save('traction_control_analysis.mat', 'results');

% Create 3D mesh plot
figure('Position', [100, 100, 1200, 800]);

% Extract data for plotting
X = p_gains;  % TC_CUT as x-axis
Y = slip_ratios;   % kappa_thresh as y-axis
Z = zeros(length(slip_ratios), length(p_gains));

% Populate Z matrix with acceleration times
for i = 1:length(slip_ratios)
    for j = 1:length(p_gains)
        Z(i,j) = results(i,j).acceleration_time;
    end
end

% Create mesh plot
mesh(X, Y, Z);
xlabel('TC Cut Percent');
ylabel('Slip Ratio Threshold (\kappa_{thresh})');
zlabel('Acceleration Time (s)');
title('Traction Control Optimization: Acceleration Time vs Parameters');
grid on;

% Add colorbar for better interpretation
colorbar;
colormap('jet'); % Use jet colormap for better visibility

% Optional: Add contour plot on the bottom
hold on;
contour3(X, Y, Z, 20, 'k-', 'LineWidth', 0.5);

% Optional: Find and mark the optimal point (minimum acceleration time)
[min_time, min_idx] = min(Z(:));
[min_row, min_col] = ind2sub(size(Z), min_idx);
optimal_x = X(min_col);
optimal_y = Y(min_row);

% Mark optimal point with a red star
plot3(optimal_x, optimal_y, min_time, 'r*', 'MarkerSize', 15, 'LineWidth', 3);

% Add annotation for optimal point
text(optimal_x, optimal_y, min_time, ...
     sprintf('Optimal: \kappa=%.3f, TC=%.2f\ Time=%.3fs', ...
             optimal_y, optimal_x, min_time), ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
     'BackgroundColor', 'white', 'FontSize', 10);

% Set nice viewing angle
view(45, 30);

% Improve appearance
set(gca, 'FontSize', 12);
grid on;

fprintf('\nOptimal Parameters Found:\n');
fprintf('Slip Ratio (kappa_thresh): %.3f\n', optimal_y);
fprintf('TC Cut Percent: %.3f\n', optimal_x);
fprintf('Best Acceleration Time: %.3f seconds\n', min_time);