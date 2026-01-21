%% Description:

% This is a tool to convert a CarSim output .CSV file
% It truncates the file so that only the relevant coloumns/signals are used
% This one specifically only keeps current, voltage, temp, SoC and time!
    % Meant for module testing and comparison!


%% Code start

% Initialization

clc; clear all; close all;

% Define the cols to keep

colsToKeep = [1, 819, 64, 712, 751];

% If making a current profile for arbin: use only 1 and 64 cols!!!

% Load the .CSV

carsimdata = readtable("carsimdata");

% Truncate the data
outputdata = carsimdata(:, colsToKeep);

% Write the data to a CSV output
writetable(outputdata, 'outputdata.csv');

fprintf('File saved successfully as outputdata.csv\n');


