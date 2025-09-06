clear;
clc;
close all;

SIM_FILE = "\\coeit.osu.edu\home\b\banko.8\Documents\FORMULA\Final Capstone TV\Final Capstone TV\no_connections_stacey.slx";

%% Vehicle Parameters
m = 450/2.2;    %Total mass kg
m_e = m*2.2;
W_e = m*2.2;
g = 9.81;   %Gravity m/s^2
W = m*g;    %Weight of vehicle N
Wquart = W/4;   %Quarter weight of the car
m_wheel = 4.536;    %kg
I_wheel = 0.127576; %kgm^2
I_wheel_yaw_roll = 0.086978;    %yaw/roll moment of inertia
Rr_c = 0.015;   %rolling resistance moment
L = 1.582;  %wheelbase m
Lf = 0.9255;    %CG to front axle m
Lr = L-Lf;  %CG to rear axle m
h = 0.28931;    %CG height m
Rw = 0.1993;   %wheel radius m
m_sprung = 172; %kg
Ixx = 27.116;   %roll inertia kgm^2
Iyy = 82.7038;  %Pitch inertia kgm^2
Izz = 71.888;   %Yw inertia kgm^2
GR = 11;    %Gear ratio
mu_factor = 1;  %Friction coefficient adjuster
J_m = 2.74;   %Inertia kgcm^2 (of motor? i don't remember)
b = 1;
kt = 0.26;

%% Aerodynamics
rho = 1.225;    %air density kg/m^3
Af = 1.153; %frontal area m^2

%% Cornering tire data loading and processing
Tire_Fy = load('TireFy_LC0.csv');   %Lateral tire forces
slip_angle_tire = Tire_Fy(:,1); %deg
Fy50lbf = Tire_Fy(:,2);     %N
Fy100lbf = Tire_Fy(:,3);    %N
Fy150lbf = Tire_Fy(:,4);    %N
Fy200lbf = Tire_Fy(:,5);    %N
Fy250lbf = Tire_Fy(:,6);    %N

    % Visualizing Tire Fy vs Slip Angle to find linear range
    % plot(slip_angle_tire,Fy250lbf);
    % title('F_y vs Slip Angle for LC0 250lbf Load');
    % ylabel('F_y, N');
    % xlabel('Absolute Slip Angle, deg');

%Line fitting 50lb load stiffness
slip_curve = slip_angle_tire(3:20,1);
Fy_curve50 = Fy50lbf(3:20,1);
Cornering_Tire50 = polyfit(slip_curve,Fy_curve50,1);
Cf(1) = Cornering_Tire50(1); %cornering stiffness of "front" which is the same as "rear"
%Line fitting 100lb load stiffness
Fy_curve100 = Fy100lbf(3:20,1);
Cornering_Tire100 = polyfit(slip_curve,Fy_curve100,1);
Cf(2) = Cornering_Tire100(1); %cornering stiffness of "front" which is the same as "rear"
%Line fitting 150lb load stiffness
Fy_curve150 = Fy150lbf(3:20,1);
Cornering_Tire150 = polyfit(slip_curve,Fy_curve150,1);
Cf(3) = Cornering_Tire150(1); %cornering stiffness of "front" which is the same as "rear"
%Line fitting 200lb load stiffness
Fy_curve200 = Fy200lbf(3:20,1);
Cornering_Tire200 = polyfit(slip_curve,Fy_curve200,1);
Cf(4) = Cornering_Tire200(1); %cornering stiffness of "front" which is the same as "rear"
%Line fitting 250lb load stiffness
Fy_curve250 = Fy250lbf(3:20,1);
Cornering_Tire250 = polyfit(slip_curve,Fy_curve250,1);
Cf(5) = Cornering_Tire250(1); %cornering stiffness of "front" which is the same as "rear"

% Cornering stiffness vs load data fitting (quadratic)
load_ = [50*4.448 100*4.448 150*4.448 200*4.448 250*4.448];
stiffness_load = polyfit(load_,Cf,2);

    %Visualizing relationship between Fz and cornering stiffness
    % figure;
    % plot(load_,Cf);
    % xlabel('Load, N');
    % ylabel('Cornering Stiffness, idk');

% Equation for cornering stiffness given load (per wheel) in N
corner_stiffness_fnc = @(x) stiffness_load(1)*x^2+stiffness_load(2)*x+stiffness_load(3);
%% Calculate front and rear cornering stiffness
Fzf = Lr*W/(2*(Lf+Lr));
Fzr = Fzf*Lf/Lr;
Cf = corner_stiffness_fnc(Fzf);
Cr = corner_stiffness_fnc(Fzr);

%% Longitudinal tire data
Tire_Fx = load('TireFx_LC0.csv');   %Longitudinal tire forces
s = Tire_Fx(:,1); %unitless
Fx200lbf = Tire_Fx(:,5);    %N
    % Visualizing Tire Fx vs Slip Ratio to find linear range
    % figure;
    % plot(s,Fx200lbf);
    % title('F_x vs Slip Ratio for LC0 Max Load');
    % ylabel('F_x, N');
    % xlabel('Slip Ratio');
[fx_max s_max] = max(Fx200lbf);
s_desired = s(s_max);

%% Motor Data
we = [0, 2000, 4000, 6000, 8000, 10000, 12000, 14000, 16000, 18000, 20000, 20001, 22000];    % motor speed in rpm
power_max = [0, 4.5, 9, 13.5, 18, 22.5, 27, 31.5, 36, 34.5, 29.5,0,0]*1000;    % max power in W
power_rated = [0, 2.5, 5, 7.5, 9.5, 11, 12, 14, 15, 15.5, 15, 0, 0]*1000;    % rated power in W
T_rated = [14, 13, 12, 11.5, 11, 10.5, 9.5, 9,8,7.5,6.5,0,0];
T_max = [21 21 21 21 21 21 21 20 17.5 15.5 13.5 0 0];

%% Calculating r_desired 
J = Izz;
%Linear Parameters Calculation
a11 = -(Cr+Cf)/(m);
a12 = -1-((Cf*Lf-Cr*Lr)/(m));
a21 = (Lr*Cr-Lf*Cf)/J;
a22 = -((Cf*Lf^2)+(Cr*Lr^2))/(J);
b11 = Cf/(m);
b12 = Cr/(m); %delta_r parameter
b21 = Cf*Lf/J;
b22 = Cr*Lr/J; %delta_r parameter

e2 = 1/J; % For yaw moment term
r_d_term = (m*(Lr*Cr-Lf*Cf))/(2*Cr*Cf*(Lf+Lr));

%% Simulations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Delta f = 35 deg         T_request = 150Nm/231
fprintf('delta_f = 35 degrees and T_r = 150 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 150;
FF_gain =1.049*20*0.1;
TV_vel_trig = 1;
Kp = 590*0.1;
Ki = 125*0.1;
Kd = 0;
T_up = T_request*0.75;
T_down = -T_request*0.75;

delta_f = 35;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;
r_d = r_desired;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--',t_noTV,r_d,'b--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');

%% Delta f = 35 deg         T_request = 100Nm/231
fprintf('delta_f = 35 degrees and T_r = 100 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 100;
FF_gain =1.049*20*1.15;
TV_vel_trig = 1;
Kp = 590*1.15;
Ki = 125*1.15;
Kd = 0;
T_up = T_request*0.85;
T_down = -T_request*0.85;

delta_f = 35;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');

%% Delta f = 35 deg         T_request = 50Nm/231
fprintf('delta_f = 35 degrees and T_r = 50 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 50;
scale = 1.5;
FF_gain =1.049*20*scale;
TV_vel_trig = 1;
Kp = 590*scale;
Ki = 125*scale;
Kd = 0;
T_up = T_request*0.75;
T_down = -T_request*0.75;

delta_f = 35;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');

%% Delta f = 20 deg         T_request = 150Nm/231
fprintf('delta_f = 20 degrees and T_r = 150 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 150;
FF_gain =1.049*20*0.2;
TV_vel_trig = 1;
Kp = 590*0.2;
Ki = 125*0.2;
Kd = 0;
T_up = T_request*0.75;
T_down = -T_request*0.75;

delta_f = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');

%% Delta f = 20 deg         T_request = 100Nm/231
fprintf('delta_f = 20 degrees and T_r = 100 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 100;
FF_gain =1.049*20*0.008;
TV_vel_trig = 1;
Kp = -590*0.008;
Ki = -125*0.008;
Kd = 0;
T_up = T_request*0.75;
T_down = -T_request*0.75;

delta_f = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');

%% Delta f = 20 deg         T_request = 50Nm/231
fprintf('delta_f = 20 degrees and T_r = 50 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 50;
scale = 0.05;
FF_gain =1.049*20*scale;
TV_vel_trig = 1;
Kp = -590*scale;
Ki = -125*scale;
Kd = 0;
T_up = T_request*0.95;
T_down = -T_request*0.95;

delta_f = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');

%% Delta f = 5 deg         T_request = 150Nm/231
fprintf('delta_f = 5 degrees and T_r = 150 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 150;
scale = 0.01;
FF_gain =1.049*20*scale;
TV_vel_trig = 1;
Kp = 590*scale;
Ki = 125*scale;
Kd = 0;
T_up = T_request*0.75;
T_down = -T_request*0.75;

delta_f = 5;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');

%% Delta f = 5 deg         T_request = 100Nm/231
fprintf('delta_f = 5 degrees and T_r = 100 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 100;
FF_gain =1.049*20*0.008;
TV_vel_trig = 1;
Kp = 590*0.008;
Ki = 125*0.008;
Kd = 0;
T_up = T_request*0.75;
T_down = -T_request*0.75;

delta_f = 5;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');

%% Delta f = 5 deg         T_request = 50Nm/231
fprintf('delta_f = 5 degrees and T_r = 100 Nm');
% No TV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time = 10;
TV_switch = 0;  % 1 - TV on, 0 - TV off
T_switch = 0;   % 1 - traction on, 0 - traction off
Tm_max = 231;
T_request = 50;
scale = 0.05;
FF_gain =1.049*20*scale;
TV_vel_trig = 1;
Kp = 590*scale;
Ki = 125*scale;
Kd = 0;
T_up = T_request*0.95;
T_down = -T_request*0.95;

delta_f = 5;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_noTV_5 = V;
r_noTV_5 = r;
ax_noTV_5 = ax;
ay_noTV_5 = ay;
Vx_mps_noTV_5 = Vx_mps;
yv_gain_noTV_5 = yaw_vel_gain;
r_error_noTV_5 = r_error;
t_noTV = tout;
x_noTV = x;
y_noTV = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TV_switch = 1;  % 1 - TV on, 0 - TV off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sim(SIM_FILE);

V_TV_5 = V;
r_TV_5 = r;
ax_TV_5 = ax;
ay_TV_5 = ay;
Vx_mps_TV_5 = Vx_mps;
yv_gain_TV_5 = yaw_vel_gain;
r_error_TV_5 = r_error;
t_TV = tout;
x_TV = x;
y_TV = y;

% Plotting
% Velocity
figure(1)
plot(t_noTV,V_noTV_5,t_TV,V_TV_5);
title('Velocity of the Vehicle');
ylabel('Velocity, km/h');
xlabel('Time, s');
legend('no TV','TV');

V_avg_noTV = mean(V_noTV_5)
V_avg_TV = mean(V_TV_5)

% Yaw Rate
figure(2)
plot(t_noTV,r_noTV_5,t_TV,r_TV_5,t_TV,r_desired,'k--');
title('Yaw Rate of the Vehicle');
ylabel('Yaw Rate, deg/s');
xlabel('Time, s');
legend('no TV','TV','desired');

figure(22)
plot(t_noTV,r_error_noTV_5,t_TV,r_error_TV_5);
title('Yaw Rate Error of the Vehicle');
ylabel('Yaw Rate Error, deg/s');
xlabel('Time, s');
legend('no TV','TV');

r_avg_noTV = mean(r_noTV_5);
r_avg_TV = mean(r_TV_5);
R_error_noTV = mean(abs(r_error_noTV_5))
R_error_TV = mean(abs(r_error_TV_5))

% Accelerations
time_noTV = linspace(0,10,length(ay_noTV_5));
time_TV = linspace(0,10,length(ay_TV_5));
% figure(3)
% plot(tout,ax);
% title('ax');
% ax_avg = mean(ax)

figure(4)
plot(time_noTV',ay_noTV_5,time_TV',ay_TV_5);
title('a_y of the Vehicle');
ylabel('a_y, m/s^2');
xlabel('Time, s');
legend('no TV','TV');
ay_avg_noTV = mean(ay_noTV_5)
ay_avg_TV = mean(ay_TV_5)

% Steering Gradient
figure(5)
plot(Vx_mps_noTV_5,yv_gain_noTV_5,'r-');
hold on
plot(Vx_mps,yaw_vel_gain_ideal,'k-');
hold on
plot(Vx_mps_TV_5,yv_gain_TV_5,'b-');
% P = polyfit(Vx_mps,yaw_vel_gain,1);
% yfit = P(1).*Vx_mps+P(2);
% plot(Vx_mps,yfit,'g--');
title('Steering Gradient');
xlabel('Velocity, m/s');
ylabel('r/\delta_f, rad/s/rad');
legend('no TV','ideal','TV');
hold off

figure(6)
plot(x_noTV,y_noTV,x_TV,y_TV);
title('Path of Vehicle')
ylabel('Y position, m');
xlabel('X position, m');
legend('no TV','TV');