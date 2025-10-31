%% MATLAB Script by Mehmet Kara %%

% MATLAB program to compare real test data with battery thermal simulation
% Load and plot voltage and temperature data from realout.mat and simout.mat

clear; clc; close all;

% Load data from both files
load('realout.mat', 'realout');
load('simout.mat', 'simout');

% Extract data from real test
time_real = realout(:, 1);
voltage_real = realout(:, 2);
temp_real = realout(:, 3);

% Extract data from simulation
time_sim = simout(:, 1);
voltage_sim = simout(:, 2);
temp_sim = simout(:, 3);

% Display array sizes for debugging
fprintf('Real data size: %d x %d\n', size(realout));
fprintf('Sim data size: %d x %d\n', size(simout));

% Handle different array sizes by interpolating to common time base
if length(time_real) ~= length(time_sim)
    fprintf('Arrays have different sizes. Interpolating to common time base...\n');
    
    % Use the union of both time vectors as common time base
    common_time = union(time_real, time_sim);
    
    % Interpolate both datasets to common time base
    voltage_real_interp = interp1(time_real, voltage_real, common_time, 'linear', 'extrap');
    temp_real_interp = interp1(time_real, temp_real, common_time, 'linear', 'extrap');
    voltage_sim_interp = interp1(time_sim, voltage_sim, common_time, 'linear', 'extrap');
    temp_sim_interp = interp1(time_sim, temp_sim, common_time, 'linear', 'extrap');
    
    % Use interpolated data for comparison
    time_plot = common_time;
    voltage_real_plot = voltage_real_interp;
    temp_real_plot = temp_real_interp;
    voltage_sim_plot = voltage_sim_interp;
    temp_sim_plot = temp_sim_interp;
    
else
    % If arrays are same size, use original data
    time_plot = time_real;
    voltage_real_plot = voltage_real;
    temp_real_plot = temp_real;
    voltage_sim_plot = voltage_sim;
    temp_sim_plot = temp_sim;
end

% Create figure with two subplots
figure('Position', [100, 100, 1200, 800]);

% Subplot 1: Voltage comparison
subplot(2, 1, 1);
plot(time_plot, voltage_real_plot, 'b-', 'LineWidth', 2, 'DisplayName', 'Real Data');
hold on;
plot(time_plot, voltage_sim_plot, 'r-', 'LineWidth', 2, 'DisplayName', 'Simulation');
xlabel('Time (s)');
ylabel('Voltage (V)');
title('Battery Voltage: Real vs Simulation');
legend('Location', 'best');
grid on;
set(gca, 'FontSize', 12);

% Subplot 2: Temperature comparison
subplot(2, 1, 2);
plot(time_plot, temp_real_plot, 'b-', 'LineWidth', 2, 'DisplayName', 'Real Data');
hold on;
plot(time_plot, temp_sim_plot, 'r-', 'LineWidth', 2, 'DisplayName', 'Simulation');
xlabel('Time (s)');
ylabel('Temperature (°C)');
title('Cell Temperature: Real vs Simulation');
legend('Location', 'best');
grid on;
set(gca, 'FontSize', 12);

% Add overall title
sgtitle('Battery Thermal Model Validation', 'FontSize', 16, 'FontWeight', 'bold');

% Calculate and display comparison metrics using the compatible arrays
fprintf('\nComparison Metrics:\n');
fprintf('===================\n');

% Voltage statistics
voltage_rmse = sqrt(mean((voltage_real_plot - voltage_sim_plot).^2));
voltage_max_error = max(abs(voltage_real_plot - voltage_sim_plot));
voltage_mean_error = median(voltage_real_plot - voltage_sim_plot);

fprintf('Voltage Statistics:\n');
fprintf('  RMSE: %.4f V\n', voltage_rmse);
fprintf('  Max Error: %.4f V\n', voltage_max_error);
fprintf('  Mean Error: %.4f V\n', voltage_mean_error);

% Temperature statistics
temp_rmse = sqrt(mean((temp_real_plot - temp_sim_plot).^2));
temp_max_error = max(abs(temp_real_plot - temp_sim_plot));
temp_mean_error = median(abs(temp_real_plot - temp_sim_plot));

fprintf('\nTemperature Statistics:\n');
fprintf('  RMSE: %.4f °C\n', temp_rmse);
fprintf('  Max Error: %.4f °C\n', temp_max_error);
fprintf('  Mean Error: %.4f °C\n', temp_mean_error);

% Optional: Create a separate figure for error analysis
figure('Position', [100, 100, 1000, 600]);

subplot(1, 2, 1);
error_voltage = voltage_real_plot - voltage_sim_plot;
plot(time_plot, error_voltage, 'k-', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Voltage Error (V)');
title('Voltage Error (Real - Simulation)');
grid on;
set(gca, 'FontSize', 12);
% Add zero reference line
hold on;
plot(xlim, [0 0], 'r--', 'LineWidth', 0.5);

subplot(1, 2, 2);
error_temp = temp_real_plot - temp_sim_plot;
plot(time_plot, error_temp, 'k-', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Temperature Error (°C)');
title('Temperature Error (Real - Simulation)');
grid on;
set(gca, 'FontSize', 12);
% Add zero reference line
hold on;
plot(xlim, [0 0], 'r--', 'LineWidth', 0.5);

sgtitle('Error Analysis', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('\nPlot generation complete.\n');
fprintf('Data points used for comparison: %d\n', length(time_plot));