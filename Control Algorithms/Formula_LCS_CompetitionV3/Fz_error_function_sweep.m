clear
clc
torqueSweep = 7:0.5:100;
all_timeseries = cell(1, length(torqueSweep));

for i = 1:length(torqueSweep)
    simIn = Simulink.SimulationInput('Demo');
    simIn = simIn.setVariable('constTorqueSweep', torqueSweep(i));
    out = sim(simIn);
    t               = out.tout(:);
    Fz_error_signal = out.Fz_error_graph.Data(:);
    all_timeseries{i} = [t, Fz_error_signal];
    fprintf('Done: Torque %d%%\n', torqueSweep(i));
end

% --- common grid + interpolation ---
t_max    = min(cellfun(@(x) x(end,1), all_timeseries));
t_common = linspace(1, t_max, 1000);

Fz_matrix = zeros(length(torqueSweep), length(t_common));
for i = 1:length(torqueSweep)
    t_i  = all_timeseries{i}(:,1);
    Fz_i = all_timeseries{i}(:,2);
    Fz_matrix(i,:) = interp1(t_i, Fz_i, t_common, 'linear');
end

Fz_mean = mean(Fz_matrix, 1);

% --- steady state error per torque (mean of last 20% of each run) ---
ss_error = zeros(1, length(torqueSweep));
for i = 1:length(torqueSweep)
    t_i  = all_timeseries{i}(:,1);
    Fz_i = all_timeseries{i}(:,2);
    idx  = t_i > 0.8 * t_i(end);
    ss_error(i) = mean(Fz_i(idx));
end

% --- fits ---
deg_time   = 8;
p_time     = polyfit(t_common, Fz_mean, deg_time);
Fz_fit     = polyval(p_time, t_common);

deg_torque = 3;
p_torque   = polyfit(torqueSweep, ss_error, deg_torque);
ss_fit     = polyval(p_torque, torqueSweep);

% ================================================================
figure('Position', [100 100 1400 900]);
tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
colors = jet(length(torqueSweep));

% --- Plot 1: all timeseries ---
nexttile;
hold on;
for i = 1:length(torqueSweep)
    plot(all_timeseries{i}(:,1), all_timeseries{i}(:,2), ...
        'Color', colors(i,:), 'LineWidth', 0.8);
end
colormap(jet);
cb = colorbar;
cb.Label.String = 'Torque Input (%)';
clim([torqueSweep(1), torqueSweep(end)]);
xlabel('Time (s)'); ylabel('Fz Error (N)');
title('All Timeseries');
grid on; hold off;

% --- Plot 2: mean error vs time + poly fit ---
nexttile;
plot(t_common, Fz_mean, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mean Error');
hold on;
plot(t_common, Fz_fit, 'r--', 'LineWidth', 2, 'DisplayName', sprintf('Poly fit deg %d', deg_time));
xlabel('Time (s)'); ylabel('Fz Error (N)');
title('Mean Error vs Time');
legend; grid on; hold off;

% --- Plot 3: steady state error vs torque + poly fit ---
nexttile;
plot(torqueSweep, ss_error, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'SS Error');
hold on;
plot(torqueSweep, ss_fit, 'r--', 'LineWidth', 2, 'DisplayName', sprintf('Poly fit deg %d', deg_torque));
xlabel('Torque Input (%)'); ylabel('Fz Error (N)');
title('Steady State Error vs Torque');
legend; grid on; hold off;

% --- Plot 4: 2D surface error vs time and torque ---
nexttile;
[T_grid, Torq_grid] = meshgrid(t_common, torqueSweep);
surf(T_grid, Torq_grid, Fz_matrix, 'EdgeColor', 'none');
colormap(jet); colorbar;
xlabel('Time (s)'); ylabel('Torque Input (%)'); zlabel('Fz Error (N)');
title('Error vs Time and Torque (Surface)');
view(45, 30); grid on;