%% Plotter tool for Voltage Tests by Mehmet Kara

%% Obtain the voltage data

load("voltage_out.mat");  % Load without assignment - goes to ans
voltage_mat = voltage;
time = voltage_mat(1, :);
voltage_calculated = voltage_mat(2, :);
voltage_ocv = voltage_mat(3, :);
voltage_real = voltage_mat(4, :);
voltage_error = voltage_mat(5, :);
clear ans

%% Plot data

% Plot voltage comparison 

figure
plot(time, voltage_ocv, 'k--', 'LineWidth', 2, 'DisplayName', 'Open Circuit Voltage [V]');
hold on
plot(time, voltage_real, 'b', 'DisplayName', 'Real Voltage [V]');
plot(time, voltage_calculated, 'r', 'DisplayName', 'Simulated Voltage [V]');
hold off

xlabel('Time (s)');
ylabel('Voltage (V)');
title('V8 Lump Cell Voltage Correlation');
legend('show');
grid on;

% Plot voltage error

figure
plot(time, voltage_error, 'k--', 'LineWidth', 2, 'DisplayName', 'Voltage Error [V]');

xlabel('Time (s)');
ylabel('Voltage (V)');
title('V8 Lump Cell Voltage Error');
legend('show');
grid on;

%% Calculate median error

median_error = median(abs(voltage_error));

disp(median_error)