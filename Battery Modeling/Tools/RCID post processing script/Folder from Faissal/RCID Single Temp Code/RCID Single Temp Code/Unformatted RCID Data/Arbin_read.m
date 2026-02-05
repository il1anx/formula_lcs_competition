clear all; close all; clc;

%% ask user for folder that contains all of the files which need to be imported and combined
dname = uigetdir;
files = dir(fullfile(dname, '*.xlsx'));

%% Import the data, extracting spreadsheet dates in Excel serial date format
% Create table
Test_Times = [];
Step_Times = [];
Step_Index = [];
Cycle_Index = [];
VoltageV = [];
CurrentA = [];
Charge_CapacityAh = [];
Discharge_CapacityAh = [];
Charge_EnergyWh = [];
Discharge_EnergyWh = [];
%InternalResistanceOhm = stringVectors(:,1);
% dVdtVs = [];
% Aux_VoltageV_1 = [];
% Aux_VoltageV_2 = [];
% Aux_Temperature_1 = [];
% Aux_Temperature_2 = [];
% Aux_Temperature_3 = [];
%%
tic;
for i=1:length(files);
    filepath=[files(i).folder, '\', files(i).name];
    n = num2str(length(xlsread(filepath, 2, 'C:C')));
    [~, ~, raw] = xlsread(filepath,2,['B2:R' n]);
    raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
    stringVectors = string(raw(:,11));
    stringVectors(ismissing(stringVectors)) = '';
    raw = raw(:,[1,2,3,4,5,6,7,8,9,10,12,13,14,15,16,17]);
    
    % Replace non-numeric cells with NaN
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells
    
    % Create output variable
    data = reshape([raw{:}],size(raw));
    
    % Allocate imported array to column variable names
    Test_Times = [Test_Times; data(:,2)];
    Step_Times = [Step_Times; data(:,3)];
    Step_Index = [Step_Index; data(:,5)];
    Cycle_Index = [Cycle_Index; data(:,4)];
    VoltageV = [VoltageV; data(:,7)];
    CurrentA = [CurrentA; data(:,6)];
    Charge_CapacityAh = [Charge_CapacityAh; data(:,9)];
    Discharge_CapacityAh = [Discharge_CapacityAh; data(:,10)];
    Charge_EnergyWh = [Charge_EnergyWh; data(:,11)];
    Discharge_EnergyWh = [Discharge_EnergyWh; data(:,12)];
    %InternalResistanceOhm = stringVectors(:,1);
%     dVdtVs = [dVdtVs; data(:,11)];
%     Aux_VoltageV_1 = [Aux_VoltageV_1; data(:,12)];
%     Aux_VoltageV_2 = [Aux_VoltageV_2; data(:,13)];
%     Aux_Temperature_1 = [Aux_Temperature_1; data(:,14)];
%     Aux_Temperature_2 = [Aux_Temperature_2; data(:,15)];
%     Aux_Temperature_3 = [Aux_Temperature_3; data(:,16)];
end
toc
%% Clear temporary variables
clearvars data raw stringVectors R files dname i n filepath;