%% MATLAB Script by Mehmet Kara %%

% Used to plot the readings of thermocouples for module temperature tests %

clear; clc; close all;

% Load data from both files
load('thermocouple_readings.mat', 'thermocouple_readings');

% Pull the temperature readings from all 5 thermocouples
cell1_temp = thermocouple_readings(:, 1);
cell2_temp = thermocouple_readings(:, 3);
cell3_temp = thermocouple_readings(:, 5);
cell4_temp = thermocouple_readings(:, 7);
cell5_temp = thermocouple_readings(:, 9);

% Pull the time array for plotting
time = thermocouple_readings(:, 10);

% Ignore values at t = 0
non_zero_indices = time > 0;
time = time(non_zero_indices);
cell1_temp = cell1_temp(non_zero_indices);
cell2_temp = cell2_temp(non_zero_indices);
cell3_temp = cell3_temp(non_zero_indices);
cell4_temp = cell4_temp(non_zero_indices);
cell5_temp = cell5_temp(non_zero_indices);

% Finds the maximum temperature of each cell
cell1_maxtemp = max(cell1_temp);
cell2_maxtemp = max(cell2_temp);
cell3_maxtemp = max(cell3_temp);
cell4_maxtemp = max(cell4_temp);
cell5_maxtemp = max(cell5_temp);

% Display max temps to user
disp("Maximum temperatures for Cells 1-5")
disp(cell1_maxtemp)
disp(cell2_maxtemp)
disp(cell3_maxtemp)
disp(cell4_maxtemp)
disp(cell5_maxtemp)

% Create an array of average cell temperature
averagetemp = zeros(length(time), 1);  % Pre-allocate the array
for j = 1:length(time)
    averagetemp(j) = (cell1_temp(j) + cell2_temp(j) + cell3_temp(j) + cell4_temp(j) + cell5_temp(j)) / 5;
end

disp('Averages found')

% Plot the individual thermocouple temperatures

plot(time, cell1_temp, 'b-', 'LineWidth', 2, 'DisplayName', 'Cell 1');
xlabel("Time (s)")
ylabel("Cell Temperature (c)")
title('Per Cell Thermocouple Measurements');
legend('Location', 'best');
grid on;
hold on
plot(time, cell2_temp, 'r-', 'LineWidth', 2, 'DisplayName', 'Cell 2');
plot(time, cell3_temp, 'g-', 'LineWidth', 2, 'DisplayName', 'Cell 3');
plot(time, cell4_temp, 'y-', 'LineWidth', 2, 'DisplayName', 'Cell 4');
plot(time, cell5_temp, 'm-', 'LineWidth', 2, 'DisplayName', 'Cell 5');
plot(time, averagetemp, 'c-', 'LineWidth', 2, 'DisplayName', 'Average Temperature');