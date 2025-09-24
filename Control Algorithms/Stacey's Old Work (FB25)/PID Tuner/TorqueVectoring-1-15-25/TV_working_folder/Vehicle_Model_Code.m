%% Author: Stacey Savchenko Email: anastasiya.forte@gmail.com
% This script initializes vehicle parameters and runs Simulink models for
% torque vectoring and traction control design and simulation.
clear;
clc;
close all;

%% Parameters
% Vehicle
x = 0;          % placeholder for unknowns
m = 450/2.2;  % vehicle mass, kg
Iz = 71.888; % vehicle moment of inertia about z, kg*m^2
L = 1.530;  % wheelbase, m
a = 0.783;  % CG from front axle, m
b = L-a;  % CG from rear axle, m
L = 1.530;  % wheelbase, m
h = 0.225;  % height of CG
t = 1.175;  % track, m
GR = 12.63;    % gear ratio (final drive)
Tmax = 9.8;      % max motor torque, Nm
Tnom = 9.8;     % nominal motor torque, Nm
s_desired = 0.11;   % desired slip ratio

% Tire and Road
C_alpha_f = 288.35;  % cornering stiffness (front)
C_alpha_r = 375.91;  % cornering stiffness (rear)
Cr = 0.015; % rolling resistance
mu = 1.4; % tire-road COF
Rw = 0.1993; % wheel radius, m

% Inputs
time = linspace(0,10,100);   % time (array), s

% Aerodynamic
rho_air = 1.225;    % air density, kg/m^3
Af = 1.153; % effective vehicle front area, m^2
Cd = x; % drag coefficient

% Other
g = 9.81;   % gravity, m/s^2
Mz_dTm_convertion = Rw/2/GR/t;   % Convert Mz at the wheels to the necessary difference in motor torques to achieve said Mz

%% Cornering Stiffness Curve Fitting

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

%% Formulas
% vy = v*delta/L; % lateral velocity, m/s
% u = sqrt(v.^2-vy.^2);   % longitudinal velocity, m/s
% ax = diff(u,time); % longitudinal accel, m/s^2
% ay = diff(vy,time); % lateral accel, m/s^2
% Fz_FL = (m*g*b/(2*L))+(m*h*ax/(2*L))-(m*h*ay*b/(2*t*L));    % normal force FL, N
% Fz_FR = (m*g*b/(2*L))+(m*h*ax/(2*L))+(m*h*ay*b/(2*t*L));    % normal force FR, N
% Fz_RL = (m*g*a/(2*L))-(m*h*ax/(2*L))-(m*h*ay*b/(2*t*L));    % normal force RL, N
% Fz_RR = (m*g*a/(2*L))-(m*h*ax/(2*L))+(m*h*ay*b/(2*t*L));    % normal force RR, N
% r = vy/L;   % yaw rate, rad/s
% alpha_f = delta - atan((vy+a*r)./u);  % slip angle (front), rad
% alpha_r = - atan((vy-b*r)./u);  % slip angle (rear), rad
% Fy_f = C_alpha_f*alpha_f;   % lateral force (front), N
% Fy_r = C_alpha_r*alpha_r;   % lateral force (rear), N
% Mz = (Tm_rl-Tm_rr)*GR*t/(2*Rw); % corrective yaw moment, Nm
% r_d_driver = u*tan(delta)/L;    % desired yaw based on driver steering input
% r_d_car = u/rho_road;           % desired yaw based on the desired drive line curvature input 
% 
% r_dot = (a*Fy_f - b*Fy_r)/Iz;   % yaw acceleration, rad/s^2

%% Study Settings
% type
study = 2;

% time
t_end = 50;
ts = 0.01;
time = 0:ts:t_end;

% steering and velocity index
v_i =2;    % 1-15
delta_i = 15;    % 1-15

%% Yaw Dynamics SS - constant speed and steering input study
if study == 1 
    % speed setting (m/s)
    vx_vector = linspace(0,45,15)';
    vx = vx_vector(v_i);
    
    % steering ramp up
    delta_vector = linspace(0,30,15)*(2*pi/180);
    delta = delta_vector(delta_i);
    
    % lateral acceleration
    ay = vx^2/L*tan(delta);
    
    % normal force f/r
    Fz_RR = (m*g*a/(2*L)+m*h*ay*b/(2*t*L))*0.225;
    Fz_RL = (m*g*a/(2*L)-m*h*ay*b/(2*t*L))*0.225;
    Fz_R = mean([Fz_RL Fz_RR]);
    Fz_FL = (m*g*b/(2*L)-m*h*ay*b/(2*t*L))*0.225;
    Fz_FR = (m*g*b/(2*L)+m*h*ay*b/(2*t*L))*0.225;
    Fz_F = mean([Fz_FR Fz_FL]);
    
    % cornering stiffness
    C_yf = polyval(stiffness_load,Fz_F);
    C_yr = polyval(stiffness_load,Fz_R);
    
    % desired yaw rate
    r_d = vx*tan(delta)/L;
    
    % road curvature (radius)
    R = L/tan(delta);

    % initial vy and yaw rate
    vy_0 = vx*delta/L;
    r_0 = vy_0/L;

    % state space model
    a11 = -(C_yf+C_yr)/(m*vx);
    a12 = (-a*C_yf+b*C_yr)/(m*vx)-vx;
    a21 = (-a*C_yf+b*C_yr)/(Iz*vx);
    a22 = -(C_yf*a^2+C_yr*b^2)/(Iz*vx);
    
    A = [a11 a12;a21 a22];
    
    b11 = 0;
    b12 = C_yf/m;
    b21 = 1/Iz;
    b22 = a*C_yf/Iz;
    
    B = [b11 b12;b21 b22];
    C = [1 0;0 1];
    D = [0 0;0 0];
end

%% Yaw Dynamics SS - constant speed and ramping steering input (average cornering stiffness)
if study == 2
    % speed setting (m/s)
    vx_vector = linspace(0,45,15);
    vx = vx_vector(v_i);
    
    % steering ramp up
    delta = (30/t_end)*time*(2*pi/180);
    
    % lateral acceleration
    ay = vx^2/L*tan(delta);
    
    % normal force f/r
    Fz_RR = (m*g*a/(2*L)+m*h*ay*b/(2*t*L))*0.225;
    Fz_RL = (m*g*a/(2*L)-m*h*ay*b/(2*t*L))*0.225;
    Fz_R = mean([Fz_RL Fz_RR]);
    Fz_FL = (m*g*b/(2*L)-m*h*ay*b/(2*t*L))*0.225;
    Fz_FR = (m*g*b/(2*L)+m*h*ay*b/(2*t*L))*0.225;
    Fz_F = mean([Fz_FR Fz_FL]);
    
    % cornering stiffness
    C_yf = polyval(stiffness_load,Fz_F);
    C_yr = polyval(stiffness_load,Fz_R);
    
    % desired yaw rate
    r_d = vx*tan(delta)/L;
    
    % road curvature (radius)
    R = L./tan(delta);
    
    % initial vy and yaw rate
    vy_0 = 0;
    r_0 = 0;

    % state space model
    a11 = -(C_yf+C_yr)/(m*vx);
    a12 = (-a*C_yf+b*C_yr)/(m*vx)-vx;
    a21 = (-a*C_yf+b*C_yr)/(Iz*vx);
    a22 = -(C_yf*a^2+C_yr*b^2)/(Iz*vx);
    
    A = [a11 a12;a21 a22];
    
    b11 = 0;
    b12 = C_yf/m;
    b21 = 1/Iz;
    b22 = a*C_yf/Iz;
    
    B = [b11 b12;b21 b22];
    C = [1 0;0 1];
    D = [0 0;0 0];
end

%% Full Sim
% time
t_end = 50;
ts = 0.01;
time = 0:ts:t_end;

% speed setting (m/s)
vx_drive = linspace(0,25,length(time));

% steering ramp up
delta = linspace(0,30*pi/180,length(time));

% normal force f/r
Fz_f_static = m*g*b/(2*L);
Fz_r_static = m*g*a/(2*L);
WT_right = m*h*b/(2*t*L);
WT_left = -m*h*b/(2*t*L);
N_to_lb = 0.225;

% desired yaw rate
r_d = vx*tan(delta)/L;

% initial vy and yaw rate
vy_0 = 0;
r_0 = 0;

% Gain Scheduling  
vx_vector = linspace(0,45,15);

NGain = [2.84450804,2.84450804,4.245826716,5.412937893,3.440885499,2,...
2,14.58729627,14.58729627,14.58729627,14.58729627,14.58729627,...
14.58729627,14.58729627,14.58729627];

PGain=  [130.03354,130.03354,132.2979663,135.8088906,130.4448578,...
122.5111241,121.680406,275.8117795,275.6454267,275.5160406,...
275.4125314,275.3278419,275.2572671,275.1975499,275.1463636];

IGain = [117.4799242,117.4799242,87.54143949,87.54143949,65.86609231,...
58.19090765,57.39102046,195.6414284,195.4270634,195.2603347,...
195.1269515,195.0178196,194.9268763,194.8499242,194.7839652];

DGain = [16.29965735,16.29965735,15.46224499,15.46224499,15.85491435,...
21.71073697,22.54158281,11.7271646,11.89023926,12.01707508,...
12.11854371,12.20156349,12.27074664,12.32928621,12.37946299];

%% Tuning
FFgain = 0.3;         % Feedforward gain
FBgain = 20;       % Feedback gain
Kp = 0.1;
Ki = 10;
Kd = 2;
Kn = 1;
Kb = 5;             % Back-calculation coefficient
TV_switch = 1;
TC_switch = 0;

% %% Run CarSIM-Simulink model
% TV_switch = 0;
% sim("TV_full_CARSIM");
% X_OL = X_sim;
% Y_OL = Y_sim;
% r_OL = r_sim;
% tout_OL = tout;
% r_error_OL = abs(r_error_sim);
% TV_switch = 1;
% avg_error_OL = mean(r_error_OL);
% disp(avg_error_OL)
% sim("TV_full_CARSIM");
% X_CL = X_sim;
% Y_CL = Y_sim;
% r_CL = r_sim;
% rd = r_d_sim;
% r_error_CL = abs(r_error_sim);
% tout_CL = tout;
% avg_error_CL = mean(r_error_CL);
% disp(avg_error_CL)
% 
% figure;
% plot(X_OL,Y_OL,X_CL,Y_CL,'--');
% title("Vehicle Path");
% xlabel("X (m)");
% ylabel("Y (m)");
% legend("Open Loop","Closed Loop")
% 
% figure;
% plot(tout_OL,r_OL,tout_CL,r_CL,'--',tout_CL,rd);
% title('Yaw Rate Analysis');
% xlabel('Time (s)');
% ylabel('Yaw Rate (rad/s)')
% legend('Open Loop','Closed Loop','Desired')
% 
% figure;
% plot(tout_OL,r_error_OL,tout_CL,r_error_CL,'--');
% title("Yaw Rate Error");
% xlabel("time (s)");
% ylabel("yaw rate error (deg/s)");
% legend("Open Loop","Closed Loop")