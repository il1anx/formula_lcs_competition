%% Description
% Plots battery constant data at different temperatures

clear all; clc;

%% Load Data

batterydata = load('batterydata.mat');

SoC = batterydata.batterydata(1,1:7);
R0_60 = batterydata.batterydata(2,1:7);
R0_40 = batterydata.batterydata(3,1:7);
R0_25 = batterydata.batterydata(4,1:7);

%% Plot Data
figure
plot(SoC, R0_25, SoC, R0_40, SoC, R0_60, 'LineWidth', 3)
legend('R_0 @ 25 Degrees C', 'R_0 @ 40 Degrees C', 'R_0 @ 60 Degrees C')
title('Sony VTC6 R_0 Values Over SoC and Temperature @ 9 C-rate')
ylabel('Resistance [ohms]')
xlabel('SoC [-]')