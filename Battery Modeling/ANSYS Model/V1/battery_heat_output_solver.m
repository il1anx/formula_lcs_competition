%% Battery Heat Power Output Program By Mehmet Kara

clear
clc

%% Load vehicle data
load('I_map.mat'); % loads the current pull over a lap
load('SOC_map.mat'); % loads the SOC over a lap

%% Define battery resistance as over SOC and C-Rate

