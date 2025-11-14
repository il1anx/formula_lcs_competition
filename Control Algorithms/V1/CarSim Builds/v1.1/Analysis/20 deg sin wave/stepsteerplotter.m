%% Plotter tool for Step Steer Tests by Mehmet Kara %%

%% Obtain the time and target yaw rate matrices from the 0 gain run
load("0/targetyawrate.mat");  % Load without assignment - goes to ans
r_target_mat = ans;
time = r_target_mat(1, 1:667);
r_target = r_target_mat(2, 1:667);
clear ans

%% Obtain the yaw rates from each run

% 0 gain
load("0/yawrate.mat");  % Load without assignment - goes to ans
r_0_mat = ans;
r_0 = r_0_mat(2, :);
clear ans
load("0/yawrateerror.mat");  % Load without assignment - goes to ans
r_0error_mat = ans;
r_0error = r_0error_mat(2, 1:667);
r_0errormedian = median(abs(r_0error));
clear ans

% 0.025 gain
load("0.025/yawrate.mat");  % Load without assignment - goes to ans
r_0p025_mat = ans;
r_0p025 = r_0p025_mat(2, :);
clear ans
load("0.025/yawrateerror.mat");  % Load without assignment - goes to ans
r_0p025error_mat = ans;
r_0p025error = r_0p025error_mat(2, 1:667);
r_0p025errormedian = median(abs(r_0p025error));
clear ans

% 0.05 gain
load("0.05/yawrate.mat");  % Load without assignment - goes to ans
r_0p05_mat = ans;
r_0p05 = r_0p05_mat(2, 1:667);
clear ans
load("0.05/yawrateerror.mat");  % Load without assignment - goes to ans
r_0p05error_mat = ans;
r_0p05error = r_0p05error_mat(2, 1:667);
r_0p05errormedian = median(abs(r_0p05error));
clear ans

% 0.1 gain
load("0.1/yawrate.mat");  % Load without assignment - goes to ans
r_0p1_mat = ans;
r_0p1 = r_0p1_mat(2, 1:667);
clear ans
load("0.1/yawrateerror.mat");  % Load without assignment - goes to ans
r_0p1error_mat = ans;
r_0p1error = r_0p1error_mat(2, 1:667);
r_0p1errormedian = median(abs(r_0p1error));
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
ylabel('Yaw Rate (rad/s)');
title('Step Steer Test - Yaw Rate Response');
legend('show');
grid on;

figure
plot(time, r_0error, 'b', 'DisplayName', '0 Gain');
hold on
plot(time, r_0p025error, 'r', 'DisplayName', '0.025 Gain');
plot(time, r_0p05error, 'g', 'DisplayName', '0.05 Gain');
plot(time, r_0p1error, 'm', 'DisplayName', '0.1 Gain');
hold off

xlabel('Time (s)');
ylabel('Yaw Rate (rad/s)');
title('Step Steer Test - Yaw Rate Error');
legend('show');
grid on;