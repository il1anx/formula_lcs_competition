%% Wheel Slip Angle Calculator by Mehmet Kara %%

%% Assumptions: %%
% -no body slip occurs
% -its a single track vehicle model
% -there is no toe in the rear

%% Variable Definitions %%

L = 1.53; % Vehicle wheelbase
a = 0.775; % Distance of the CG from the front axle
R = 9.125; % The cornering radius measured from the center of gravity
b = L - a; % The distance of the CG from the rear axle
delta = deg2rad(15); % steering angle of the front wheel

%% Calculations %%

% Standard bicycle model approximation
alpha_F = delta - atan2(a, R);
alpha_R = atan2(b, R);

disp(rad2deg(alpha_F)) % Display the slip angle of the rear tire in degrees to the user
disp(rad2deg(alpha_R)) % Display the slip angle of the front tire in degrees to the user