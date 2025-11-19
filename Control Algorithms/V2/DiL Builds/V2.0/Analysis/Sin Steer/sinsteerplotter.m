%% Plotter tool for Step Steer Tests by Mehmet Kara %%

%% Obtain the time and target yaw rate matrices from the V2 run
load("V2/targetyawrate.mat");  % Load without assignment - goes to ans
r_target_mat = ans;
time = r_target_mat(1, :);
r_target = r_target_mat(2, :);
clear ans

%% Obtain the yaw rates from each run

% V2
load("V2/yawrate.mat");  % Load without assignment - goes to ans
r_v2_mat = ans;
r_v2 = r_v2_mat(2, :);
clear ans
load("V2/yawrateerror.mat");  % Load without assignment - goes to ans
r_v2error_mat = ans;
r_v2error = r_v2error_mat(2,  1:667);
r_v2errormedian = median(abs(r_v2error));
clear ans

% V1
load("V1/yawrate.mat");  % Load without assignment - goes to ans
r_v1_mat = ans;
r_v1 = r_0p025_mat(2, :);
clear ans
load("V1/yawrateerror.mat");  % Load without assignment - goes to ans
r_v1error_mat = ans;
r_v1error = r_v1error_mat(2, 1:667);
r_v1errormedian = median(abs(r_v1error));
clear ans

%% Plot data

figure
plot(time, r_target, 'k--', 'LineWidth', 2, 'DisplayName', 'Target Yaw Rate');
hold on
plot(time, r_v1, 'b', 'DisplayName', 'V1');
plot(time, r_v2, 'r', 'DisplayName', 'V2');
hold off

xlabel('Time (s)');
ylabel('Yaw Rate (rad/s)');
title('Step Steer Test - Yaw Rate Response');
legend('show');
grid on;

figure
plot(time, r_v2error, 'b', 'DisplayName', 'V2');
hold on
plot(time, r_v1error, 'r', 'DisplayName', 'V1');
hold off

xlabel('Time (s)');
ylabel('Yaw Rate (rad/s)');
title('Sin Steer Test - Yaw Rate Error');
legend('show');
grid on;