%% 3D Map Visualization Script
% Author: Mehmet Kara
% Description: Creates a 3D surface plot from 2D table data in a .mat file

%% Load data from .mat file
load('map_data.mat');

% Display variable information
whos

%% Extract axes and data values from the 16x12 double matrix
% Assuming:
% - Row 1 (except first element) contains Y-axis values
% - Column 1 (except first element) contains X-axis values  
% - The remaining 15x11 block contains Z = f(X,Y) data

% Extract X values (first column, rows 2-16)
X = map_data(2:end, 1);

% Extract Y values (first row, columns 2-12)
Y = map_data(1, 2:end)';

% Extract Z values (the main data matrix - rows 2-16, columns 2-12)
Z = map_data(2:end, 2:end);

% Display dimensions to verify
fprintf('X dimensions: %dx%d\n', size(X));
fprintf('Y dimensions: %dx%d\n', size(Y));
fprintf('Z dimensions: %dx%d\n', size(Z));

%% Create meshgrid for 3D plotting
[X_grid, Y_grid] = meshgrid(X, Y);
Z_matrix = Z';  % Transpose to match meshgrid orientation

%% Get axis labels from user
x_label = input('Enter label for X-axis: ', 's');
y_label = input('Enter label for Y-axis: ', 's'); 
z_label = input('Enter label for Z-axis: ', 's');

%% Create 3D surface plot
figure;
surf(X_grid, Y_grid, Z_matrix);
xlabel(x_label);
ylabel(y_label); 
zlabel(z_label);
title('3D Surface Map');
colorbar;
grid on;

%% Alternative visualization options

% Mesh plot
figure;
mesh(X_grid, Y_grid, Z_matrix);
xlabel(x_label);
ylabel(y_label);
zlabel(z_label);
title('3D Mesh Plot');
colorbar;
grid on;

% Contour plot
figure;
contour(X_grid, Y_grid, Z_matrix);
xlabel(x_label);
ylabel(y_label);
title('2D Contour Plot');
colorbar;

fprintf('All plots created successfully!\n');