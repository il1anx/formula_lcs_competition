%% Plotter tool for Step Steer Tests by Mehmet Kara %%

clear
clc

%% Obtain the time and target yaw rate matrices from the 0 gain run
load("0/targetyawrate.mat");  % Load without assignment - goes to ans
r_target_mat = ans;
time = r_target_mat(1, 1:4001);
r_target = r_target_mat(2, 1:4001);
clear ans

%% Obtain the yaw rates from each run

% 0 gain
load("0/yawrate.mat");  % Load without assignment - goes to ans
r_0_mat = ans;
r_0 = r_0_mat(2, :);
clear ans

% 0.025 gain
load("0.025/yawrate.mat");  % Load without assignment - goes to ans
r_0p025_mat = ans;
r_0p025 = r_0p025_mat(2, :);
clear ans

% 0.05 gain
load("0.05/yawrate.mat");  % Load without assignment - goes to ans
r_0p05_mat = ans;
r_0p05 = r_0p05_mat(2, :);
clear ans

% 0.1 gain
load("0.1/yawrate.mat");  % Load without assignment - goes to ans
r_0p1_mat = ans;
r_0p1 = r_0p1_mat(2, :);
clear ans

%% Plot data

figure
plot(time, r_target, 'k--', 'LineWidth', 2, 'DisplayName', 'Target Yaw Rate');
hold on
plot(time, r_0, 'b', 'DisplayName', '0 Gain');
plot(time, r_0p025, 'r', 'DisplayName', '0.025 Gain');
plot(time, r_0p05, 'g', 'DisplayName', '0.05 Gain');
plot(time, r_0p1, 'm', 'DisplayName', '0.1 Gain');
hold off

xlabel('Time (s)');
ylabel('Yaw Rate (deg/s)');
title('Step Steer Test - Yaw Rate Response');
legend('show');
grid on;
