%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filename: RCID_Single_Temp_Model.m                                     %
% Author:   Daniel Seals                                                 %
% Updated:  December 20, 2019                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear all; clc;
addpath('Formatted RCID Data')
addpath('Unformatted RCID Data')
addpath('..')
code_ver = '3.0'

%% Inputs
Model_Type = 1; % 0 - Zero, 1 - First, 2 - Second


%% Import Data & Format

% Load Test Data
Formatted_Directory = dir_custom('Formatted RCID Data');
Unformatted_Directory = dir_custom('Formatted RCID Data');

if length(Formatted_Directory) == 1
    Test_File_Name = Formatted_Directory(1).name;
    load(Test_File_Name)
elseif length(Formatted_Directory) > 1
    disp('Select RCID test file.')
    Test_File_Name = uigetfile;
    fprintf('Test selected: %s \n',Test_File_Name);
    load(Test_File_Name)
end

% If test data is not in formatted folder, identifiy which machine the test
% came from and reformat/save as a .mat file in the Formatted folder

% Assign variables
V = TestData.V;
I = TestData.I;
Time = TestData.Time;
Step = TestData.Step;
deltat = 0.1;

% V=TestData.("Voltage(V)");
% I = TestData.("Current(A)");
% Time = TestData.("Test_Time(s)");
% Step = TestData.Step_Index;
% Find smallest step size out of all tests and index the pulses of every
% test
Smallest_Pulse = 301;    % This is ~30.1 seconds at a .1 second sampling rate


%% Get Test Temperature
% Ask user to manually input the temperature of the test file displayed
Message = sprintf('Please enter the temperature of the selected test in degrees Celcius: \n\n %s \n',...
    Test_File_Name);
Prompt = {Message};
dlgtitle = 'Enter Test Temperature';
dims = [1 50];

Temperature = inputdlg(Prompt,dlgtitle,dims);
Temperature = str2double(Temperature);

if isempty(Temperature)
    error('User did not enter a value for temperature')
end
fprintf('Selected Temperature: %.f degrees Celcius\n',Temperature)
pause(1)


%% Load Datasheet
% Based on the name of the selected test file, load the correct datasheet
File_Name_Parts = split(Test_File_Name,'_');
Datasheet_Filename = strcat(File_Name_Parts(1),'_',File_Name_Parts(2),'.mat');
if isfile(strcat('../Datasheets/',Datasheet_Filename{1}))
    load(strcat('../Datasheets/',Datasheet_Filename{1}))
else
    % No datasheet file found with the correct filename. Warn user, then
    % allow them to create a new datasheet
    
    uiwait(msgbox(strcat('No datasheet found that matches the cell name',...
        ' from the test datafile. Make sure the datasheet is in the',...
        'correct folder, or manually create a new datasheet after',...
        ' pressing OK'),'No Datasheet Found'))
    
    Prompt = {'Enter mass','Enter V_max','Enter V_min','Enter V_nom',...
        'Enter C_nom','Enter Volume [Units]','Enter Chemistry',...
        'Enter I_max_con_dch','Enter I_max_con_ch','Enter I_max_puls_dch'};
    dlgtitle = 'Enter Cell Datasheet Information';
    dims = [1 60];
    
    Datasheet_Values = inputdlg(Prompt,dlgtitle,dims);
    Datasheet_Values = str2double(Datasheet_Values);
    
    Datasheet.m = Datasheet_Values(1)
    Datasheet.V_max = Datasheet_Values(2)
    Datasheet.V_min = Datasheet_Values(3)
    Datasheet.V_nom = Datasheet_Values(4)
    Datasheet.C_nom =Datasheet_Values(5)
    Datasheet.Volume = Datasheet_Values(6)
    Datasheet.chem = Datasheet_Values(7)
    Datasheet.I_max_con_dch = Datasheet_Values(8)
    Datasheet.I_max_con_ch = Datasheet_Values(9)
    Datasheet.I_max_puls_dch = Datasheet_Values(10)
    
    % Save Datasheet
    save(strcat('../Datasheets/',Datasheet_Filename{1}),'Datasheet')
end



%% Detect Current Steps & Identify Pulse Steps
[Pulse_Start_Index,Pulse_Stop_Index,Initial_Pulse_Index,Final_Pulse_Index, ...
    Cap_Start,Cap_End] = RCID_Current_Detection(Time,I,deltat,Smallest_Pulse);

% Plot Identified Current Steps ( Still has Duplicate C-rate Pulses )

figure('Position',[100 100 1000 600])
movegui('center')
plot(Time,I,'LineWidth',1)
hold on
scatter(Time(Pulse_Start_Index),I(Pulse_Start_Index),'go')
scatter(Time(Pulse_Stop_Index),I(Pulse_Stop_Index),'rx')
scatter(Time(Initial_Pulse_Index),I(Initial_Pulse_Index),'b^')
scatter(Time(Final_Pulse_Index),I(Final_Pulse_Index),'k^')
scatter(Time(Cap_Start),I(Cap_Start),'k')
scatter(Time(Cap_End),I(Cap_End),'k')
title('Automatic Detection of Current Pulses of RCID Test')
xlabel('Time [Seconds]')
ylabel('Current [A]')
legend('Current','Start of Every Pulse','Stop of Every Pulse',...
    'Initial Pulse in Set','Final Pulse in Set','Capacity Test Start',...
    'Capacity Test Stop')
hold off



%% Coulomb Counting
C_real = [];

% If a capacity is to be manually chosen, write code here that manually
% changes C_real to the desired value for the desired test(s):
%************* Example Code:
% C_real = 3.5;
%*************
V = TestData.V;
I = TestData.I;
Time = TestData.Time;
Step = TestData.Step;
deltat = 0.1;

if ~isempty(Cap_Start) || ~isempty(C_real)
    % This statement is run if a capacity test is found
    % or if the capacity is being manually overriden
    
    if ~isempty(C_real) == 1
        disp(['C_real is being manually overwritten in the Coulomb'...
            ' Counting section of code.'])
        
        Capacity_Flag = 1; % This will be used when creating the ECM Model
        % Indicates a manual capacity was used, and will be called
        % C_real in the model output
        
    else
        Capacity_Flag = 0; % No C_real manually defined. Used detected capacity test
        C_real = max(abs(cumtrapz(deltat,I(Cap_Start:Cap_End))./(3600)));
    end
    
    SOC_count = 1 + (cumtrapz(deltat,I))./(3600*C_real);
    SOC_count = SOC_count - (SOC_count(Pulse_Start_Index(1)-1)-1);
    if (abs(C_real - Datasheet.C_nom) / Datasheet.C_nom) > 0.25
        disp(['WARNING: Cell capacity found is more than 25% off from'...
            ' the nominal capacity.'])
        warndlg(['WARNING: Cell capacity found is more than 25% off from'...
            ' the nominal capacity. Ensure correct files were selected and' ...
            ' that the code is identifying the capacity test correctly.'])
    end
else
    Capacity_Flag = 2; % No capacity test was found - Using Nominal capacity
    % C_real can be defined at the begenning of the Coulomb Counting
    % section to override at the top of the Coulomb Counting
    
    SOC_count = 1 + (cumtrapz(deltat,I))./(3600*Datasheet.C_nom);
    SOC_count = SOC_count - (SOC_count(Pulse_Start_Index(1)-1)-1);
    
    disp(['WARNING: No capacity test identified with Current Detection'...
        ' code. Nominal capacity from datasheet was used. This can be'...
        'overriden in the Coulomb Counting section of code.'])
    warndlg(['WARNING: No capacity test identified with Current Detection'...
        ' code. Nominal capacity from datasheet was used. This can be'...
        'overriden in the Coulomb Counting section of code.'])
end


%% Determine C-Rates & Remove Duplicate C-Rates
% Find unique C-rates within a tolerance, then average all values
% within tolerance of that C_rate
% C_Rate_Values are the the averages unique values
% C_Rate_Index stores the indices of all values at each C-rate ( These
% values should align with SOC_test value)

% Create vector the contains the average current for each index of
% Pulse_Start_Index (Averaged over at least 20 datapoints). This average
% current will be used to determine C-rate
Smallest_Pulse = 301;
for i = 1:length(Pulse_Start_Index)
    Average_Current_Index_All(i) = mean(I(Pulse_Start_Index(i)+10:Pulse_Start_Index(i)+20));
end

Unfiltered_C_Rates = Average_Current_Index_All ./ Datasheet.C_nom;
[Unfiltered_C_Rate_Values,Unfiltered_C_Rate_Index] = uniquetol(Unfiltered_C_Rates,0.1/Datasheet.C_nom,'OutputAllIndices',true);


% Identify extra pulses in same pulse set that have the same C-Rate
Duplicate_Index{1} = [];
for i = 1:length(Unfiltered_C_Rate_Index)
    Test_Index = Pulse_Start_Index(Unfiltered_C_Rate_Index{i,1});
    
    C_Rate_Duplicates = [];
    for j = 1:length(Initial_Pulse_Index)
        Remove_Pulse = find(Test_Index >= Initial_Pulse_Index(j) & Test_Index <= Final_Pulse_Index(j));
        if length(Remove_Pulse) > 1
            C_Rate_Duplicates = [C_Rate_Duplicates; Unfiltered_C_Rate_Index{i,1}(Remove_Pulse(2:end))];
        end
    end
    
    Duplicate_Index{i} = C_Rate_Duplicates;
    
end

% Remove extra pulses in same pulse set that have the same C-Rate
Remove_Array = [];
for i = 1:length(Unfiltered_C_Rate_Index)
    if ~isempty(Duplicate_Index{i})
        Remove_Array = [Remove_Array Duplicate_Index{i}];
    end
end
Pulse_Start_Index(Remove_Array) = [];
Pulse_Stop_Index(Remove_Array) = [];


% After duplicate pulses are removed, re-find & re-index C-rates
for i = 1:length(Pulse_Start_Index)
    Average_Current_Index(i) = mean(I(Pulse_Start_Index(i)+1:Pulse_Start_Index(i)+20));
end

All_C_Rates = Average_Current_Index ./ Datasheet.C_nom;
[C_Rate_Values,C_Rate_Index] = uniquetol(All_C_Rates,0.1/Datasheet.C_nom,'OutputAllIndices',true);


% Once C-rate & C-C evaluation is finished, move 'end of pulse' index to the
% start index + the smallest pulse length
Pulse_Stop_Index = Pulse_Start_Index + Smallest_Pulse - 1;


%% Parameter Calculations

for SOC_test = 1:length(Pulse_Start_Index)

    SOC(SOC_test) = SOC_count(Pulse_Start_Index(SOC_test));
    V_init(SOC_test) = V(Pulse_Start_Index(SOC_test));
    if length(Initial_Pulse_Index)>1
            OCV_est(SOC_test) = interp1(SOC_count(Initial_Pulse_Index), V(Initial_Pulse_Index), SOC(SOC_test), 'linear', 'extrap');
        else
            OCV_est(SOC_test) =V(Pulse_Start_Index(SOC_test));
        end
    R_full(SOC_test) = abs((V(Pulse_Start_Index(SOC_test)) - V(Pulse_Stop_Index(SOC_test)))...
        /(I(Pulse_Stop_Index(SOC_test)) - I(Pulse_Start_Index(SOC_test))));
    R_0(SOC_test) = abs(V(Pulse_Start_Index(SOC_test)+1)-V(Pulse_Start_Index(SOC_test)))...
        /abs(I(Pulse_Start_Index(SOC_test)+1)-I(Pulse_Start_Index(SOC_test)));
    if I(Pulse_Start_Index(SOC_test) + 1) < 0
        P_lim(SOC_test) = Datasheet.V_min * (OCV_est(SOC_test) - Datasheet.V_min) / R_full(SOC_test);
    else
        P_lim(SOC_test) = Datasheet.V_max * (Datasheet.V_max - OCV_est(SOC_test)) / R_full(SOC_test);
    end
end


%% Model Optimization/Fault Check/Verification
if Model_Type == 0 % Zero-Order Model Fault Check & Verification
    for SOC_test = 1:length(Pulse_Start_Index)
        global V_new I_new Time_new
        V_new = V(Pulse_Start_Index(SOC_test)-5:Pulse_Start_Index(SOC_test)+Smallest_Pulse-1);
        I_new = -1*I(Pulse_Start_Index(SOC_test)-5:Pulse_Start_Index(SOC_test)+Smallest_Pulse-1);
        Time_new = Time(Pulse_Start_Index(SOC_test)-5:Pulse_Start_Index(SOC_test)+Smallest_Pulse-1);
        
        % Zero-Order Response
        Vest_zero = V_init(SOC_test) - R_full(SOC_test).*I_new ;
        
        if(nonzeros(V_new>Datasheet.V_max-0.0001 | V_new<Datasheet.V_min+0.0001))
            fault_V(SOC_test) = 1;
            R_full(SOC_test) = NaN;
        else
            fault_V(SOC_test) = 0;
        end
        
        %% Plot Model Voltage Response for Verification
        % % Model Verification Plots
        %     figure;
        %     set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
        %     subplot(2,1,1);
        %     plot(Time_new,V_new,'r',Time_new,Vest_first,'g')
        %     grid on
        %
        %     title({
        %     ['er.:' num2str(err_min,2)], ...
        %     ['SOC:' num2str(SOC(SOC_test),2) ' OCV:' num2str(Param(1),2)], ...
        %     ['R0: ' num2str(Param(2),2) ' R1: ' num2str(Xopt_test(2),1)], ...
        %     ['C1: ' num2str(Xopt_test(1),2)]})
        %
        %
        %     legend('Data','Model opt','Location','best')
        %     xlabel('Time (sec)')
        %     ylabel('Battery voltage (volt)')
        %     subplot(2,1,2);
        %     plot(Time_new,I_new/3.24,'r')
        %     xlabel('Time (sec)')
        %     ylabel('Battery current (C-Rate)')
    end
elseif Model_Type == 1 % First-Order Model Optimization, Fault Check, and Verification
    for SOC_test = 1:length(Pulse_Start_Index)
        global V_new I_new Time_new
        
        % Assign pulse data to variables
        V_new = V(Pulse_Start_Index(SOC_test)-5:Pulse_Start_Index(SOC_test)+Smallest_Pulse-1);
        I_new = -1*I(Pulse_Start_Index(SOC_test)-5:Pulse_Start_Index(SOC_test)+Smallest_Pulse-1);
        Time_new = Time(Pulse_Start_Index(SOC_test)-5:Pulse_Start_Index(SOC_test)+Smallest_Pulse-1);
        
        % Extract parameter estimates from data
        E0_est(SOC_test) = V_init(SOC_test);                                   % Estimate of E0
        R0_est(SOC_test) = R_0(SOC_test);                                   % Estimate of R0
        R1_est(SOC_test) = R_full(SOC_test) - R0_est(SOC_test);             % Estimate of R1
        
        % Estimate 4 Tau
        Tau_Response = V(Pulse_Start_Index(SOC_test)) + (V(Pulse_Stop_Index(SOC_test)-1) - V(Pulse_Start_Index(SOC_test)))*.9812;
        % Calculate 95% change in voltage
        [~,index] = min(abs(V_new - Tau_Response));                         % Find index of 98% change
        tau_est(SOC_test) = Time_new(index) - Time_new(1);                  % Find Time of 98% change (4 tau)
        C1_est(SOC_test) = (tau_est(SOC_test)/4)/R1_est(SOC_test);          % C1 Estimate
%         C1_est(SOC_test) = 1200;
        % First-Order Optimization of C1, R1
        Param = [E0_est(SOC_test) R0_est(SOC_test)];                        % Load Paramaters (Not optimized)
        X0 = [C1_est(SOC_test) R1_est(SOC_test)];                           % Load initial guesses (To be optimized)
        [Xopt_test,err_min] = fminsearch(@(Coef)Param_Opt(Coef,Param), X0);    % Minimize error with model coefs
        
        % Display results
        fprintf(1,'X = [C1, R1]\n')
        fprintf(1,'Initial guess (automatically generated from data):\n')
        fprintf(1,'X0 = [%f %f] ',X0)
        fprintf(1,'X_found = [%.2f %.6f]\n',Xopt_test)
        fprintf(1,'Err_min (RMS) = %f volts\n\n',err_min)
        
        % Optimized First-Order Response
        Vc = zeros(size(Time_new));                                         % Initialize voltage and capacitor arrays
        deltat = Time_new(3) - Time_new(2);                                 % Generate estimated response with fitted parameters
        for k = 2:length(I_new)
            Vc(k) = Vc(k-1)*exp(-deltat/(Xopt_test(1)*Xopt_test(2)))+ ...
                Xopt_test(2)*I_new(k-1)*(1-exp(-deltat/(Xopt_test(1)*Xopt_test(2))));
        end
        Vest_first = Param(1) - Param(2).*I_new - Vc;
        
        if(nonzeros(V_new>Datasheet.V_max-0.0001 | V_new<Datasheet.V_min+0.0001))
            fault_V(SOC_test) = 1;
            R_full(SOC_test) = NaN;
            Param = [NaN, NaN];
            Xopt_test = [NaN, NaN];
        else
            fault_V(SOC_test) = 0;
        end
        
        Xopt_final(SOC_test,:) = [Param,Xopt_test,err_min];
        
        
        %% Plot Model Voltage Response for Verification
        % Model Verification Plots
        if err_min>0.007
            figure;
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
            subplot(2,1,1);
            plot(Time_new,V_new,'r',Time_new,Vest_first,'g')
            grid on
            
            title({
                ['er.:' num2str(err_min,2)], ...
                ['SOC:' num2str(SOC(SOC_test),2) ' OCV:' num2str(Param(1),2)], ...
                ['R0: ' num2str(Param(2),2) ' R1: ' num2str(Xopt_test(2),1)], ...
                ['C1: ' num2str(Xopt_test(1),2)]})
            
            
            legend('Data','Model opt','Location','best')
            xlabel('Time (sec)')
            ylabel('Battery voltage (volt)')
            subplot(2,1,2);
            plot(Time_new,I_new,'r')
            xlabel('Time (sec)')
            ylabel('Battery current')
        end
    end

elseif Model_Type == 2
    
% Creating model
SOC = SOC_count(Initial_Pulse_Index);
OCV = V(Initial_Pulse_Index);
ECM.C_Rate_Value = C_Rate_Values;
ECM.Temp_Value = Temperature;
ECM.SOC = SOC;
ECM.OCV = OCV;

for i = 1:length(C_Rate_Values)
    ECM.C_Rate(i).Data.Data_for_C_rate = C_Rate_Values(i);
    ECM.C_Rate(i).Data.SOC = [];
    ECM.C_Rate(i).Data.V_init = [];
    ECM.C_Rate(i).Data. R0 = [];

%     ECM.C_Rate(i).Data.R1_est = [];
%     ECM.C_Rate(i).Data.C1_est = [];
%     ECM.C_Rate(i).Data.R2_est = [];
%     ECM.C_Rate(i).Data.C2_est = [];

    ECM.C_Rate(i).Data.R1_calib = [];
    ECM.C_Rate(i).Data.C1_calib = [];
    ECM.C_Rate(i).Data.R2_calib = [];
    ECM.C_Rate(i).Data.C2_calib = [];
    
    %ECM.C_Rate(i).Data.RMSE_mV = [];
end
errors.count = 0;
%% Optimizing 
tic 
for i = 1:length(Pulse_Start_Index)
i
     try 
        ini_SOC_opt = SOC_count(Pulse_Start_Index(i));
 
        V_new = TestData.V(Pulse_Start_Index(i) : Pulse_Stop_Index(i));
        I_new = TestData.I(Pulse_Start_Index(i) : Pulse_Stop_Index(i));
        Time_new = TestData.Time(Pulse_Start_Index(i) : Pulse_Stop_Index(i))...
                - TestData.Time(Pulse_Start_Index(i)); 
            
        R0 = (abs((V_new(1) - V_new(2)) ./ (I_new(1) - I_new(end))));
        
        
        R1_step = 281;
        r1_opt = (abs(((TestData.V(Pulse_Start_Index(i) + 1) - TestData.V(Pulse_Start_Index(i) + R1_step)) ./ ...
                (TestData.I(Pulse_Start_Index(i) ) - TestData.I(Pulse_Start_Index(i)+1)))));
        
        tau_1 = abs((TestData.Time(Pulse_Start_Index(i)+R1_step) - TestData.Time(Pulse_Start_Index(i) + 1)));           
        c1_opt = tau_1./ (r1_opt/1000);  
        
        R2_step = 181;
        r2_opt = (abs((TestData.V(Pulse_Start_Index(i) + R2_step) - TestData.V(Pulse_Stop_Index(i))) ./ ...
            (TestData.I(Pulse_Start_Index(i) ) - TestData.I(Pulse_Start_Index(i)+1))));
        
        tau_2 = abs((TestData.Time(Pulse_Start_Index(i) + R2_step) - TestData.Time(Pulse_Stop_Index(i))));           
        c2_opt = tau_2./ (r2_opt/1000);
    
        X0 = [ c1_opt; r1_opt; c2_opt; r2_opt];
   
        [xopt, err] = fmincon(@(X)ECM_call_second(X,R0,ini_SOC_opt, V_new, I_new, Time_new, OCV, SOC), ...
               X0,[],[],[],[],[0 0.000001 0 0.00001],[inf inf inf inf]);
    
        c1_calib = xopt(1);
        r1_calib = xopt(2);
        c2_calib = xopt(3);
        r2_calib = xopt(4); 
%%       
        opt_C_rate = (I_new(end) - I_new(1)) / Datasheet.C_nom;
        for j = 1:length(C_Rate_Values)
            
            if round(ECM.C_Rate(j).Data.Data_for_C_rate,1) == round(opt_C_rate,1)
                
                jj = j;
                ECM.C_Rate(j).Data.SOC = [ECM.C_Rate(j).Data.SOC, ini_SOC_opt];
                ECM.C_Rate(j).Data.V_init = [ECM.C_Rate(j).Data.V_init, V_new(1)];
                
                ECM.C_Rate(j).Data.R0 = [ECM.C_Rate(j).Data.R0, R0];
                
%                 ECM.C_Rate(j).Data.R1_est = [ECM.C_Rate(j).Data.R1_est, r1_opt];
%                 ECM.C_Rate(j).Data.C1_est = [ECM.C_Rate(j).Data.C1_est, c1_opt];
%                 ECM.C_Rate(j).Data.R2_est = [ECM.C_Rate(j).Data.R2_est, r2_opt];
%                 ECM.C_Rate(j).Data.C2_est = [ECM.C_Rate(j).Data.C2_est, c2_opt];
                
                ECM.C_Rate(j).Data.R1_calib = [ECM.C_Rate(j).Data.R1_calib, r1_calib];
                ECM.C_Rate(j).Data.C1_calib = [ECM.C_Rate(j).Data.C1_calib, c1_calib];
                ECM.C_Rate(j).Data.R2_calib = [ECM.C_Rate(j).Data.R2_calib, r2_calib];
                ECM.C_Rate(j).Data.C2_calib = [ECM.C_Rate(j).Data.C2_calib, c2_calib];

            end
        end
  %% Running the simulation for error
  if err > 0.002
        V_new = TestData.V(Pulse_Start_Index(i) : Pulse_Stop_Index(i)+300);
        I_new = TestData.I(Pulse_Start_Index(i) : Pulse_Stop_Index(i)+300);
        Time_new = TestData.Time(Pulse_Start_Index(i) : Pulse_Stop_Index(i)+300)...
                - TestData.Time(Pulse_Start_Index(i)); 
          

            Tend = max(Time_new); % Set simulation end time
            out = sim('ECM_second_plot',[Tend]);
            
            % Plotting and comparing the resposne
            figure
            plot(Time_new, V_new, 'LineWidth', 1.5)
            hold
            plot(out.T_sim, out.V_sim_data, 'LineWidth', 1.5)
            legend('Experimental Data', 'Sim Response')
            err_rmse = sqrt(sum((out.V_opt_data - out.V_sim_data).^2)/(length(I_new)-1));
            title(['Model Response at ' num2str(opt_C_rate) 'C at ' num2str(ini_SOC_opt * 100) '%SOC' ' and RMSE = ' num2str(round(err_rmse,5)*1000) 'mV' ])
            set(gca,'fontsize',18)
            xlabel('Time [s]')
            ylabel('Voltage [V]')
            grid on
               

  end
        
    catch
     disp(['An error occurred while Optimizing the parameters for pulse number ' num2str(i)]);
     pause(1)
     disp('Optimization will continue');
     errors.count = errors.count +1;
     kk = 1;
     errors.indx_val(kk) = i;
     kk = kk + 1;
    
    end 
%         clearvars V_new I_new Time_new R0 r1_opt c1_opt r2_opt c2_opt...
%             r1_calib c1_calib r2_calib c2_calib opt_C_rate

    end    

timeexp = toc;
timeexp/60
    
else
    error('Model type (Zero or First Order) not specified correctly.')
end


%% Create Model Output

% Save calculated parameters & OCV/SOC/faults/etc.
for ndx1 = 1:length(C_Rate_Index)
    Pulse_Numbers = C_Rate_Index{ndx1,1};
    % Create Structure
    ECM_Model.C_Rate_Value = C_Rate_Values;
    ECM_Model.Temp_Value = Temperature;
    ECM_Model.C_Rate(ndx1).Temp.SOC = SOC(Pulse_Numbers);
    ECM_Model.C_Rate(ndx1).Temp.V_init = V_init(Pulse_Numbers);
    ECM_Model.C_Rate(ndx1).Temp.R_full = R_full(Pulse_Numbers);
    ECM_Model.C_Rate(ndx1).Temp.R_0 = R_0(Pulse_Numbers);
    ECM_Model.C_Rate(ndx1).Temp.P_lim = P_lim(Pulse_Numbers);
    if Model_Type == 1
        ECM_Model.C_Rate(ndx1).Temp.R_1 = Xopt_final(Pulse_Numbers,4)';
        ECM_Model.C_Rate(ndx1).Temp.C_1 = Xopt_final(Pulse_Numbers,3)';
    end
    ECM_Model.C_Rate(ndx1).Temp.fault_V = fault_V(Pulse_Numbers);
    
    if Capacity_Flag == 0 || Capacity_Flag == 1
        ECM_Model.C_Rate(ndx1).Temp.C_real = C_real;
    else
        ECM_Model.C_Rate(ndx1).Temp.C_nom = Datasheet.C_nom;
    end
end

ECM_Model.OCV = V(Initial_Pulse_Index);
ECM_Model.SOC_OCV = SOC_count(Initial_Pulse_Index);
ECM_Model.Date_Processed = date; % Adds current date to ECM Model Structure
ECM_Model.Version = code_ver;

%% Prompt user to enter the filename for the model
Prompt = sprintf('Please enter the filename for the ECM Model: \n\n\n');

dlgtitle = 'Enter ''Manufacturer_Cellname''';
dims = [1 50];

Model_Name = inputdlg(Prompt,dlgtitle,dims);

if isempty(Model_Name)
    error('User did not enter a filename')
end

Model_Name = strcat(Model_Name,'_RCID');

if Model_Type == 0
    Model_Name = strcat(Model_Name,'_Zero_Order_ECM');
else
    Model_Name = strcat(Model_Name,'_First_Order_ECM');
end

save(Model_Name{1},'ECM_Model')


%% Plot Pulse Power Capability

figure('Position', [100 100 1000 600])
movegui('center')

style = {'-' '--' ':' '-.'};
marker = {'o' '+' 'x' '*' 's' 'd' '^'};
hold on
for k = 1:length(C_Rate_Index)
    plot(ECM_Model.C_Rate(k).Temp.SOC * 100, ECM_Model.C_Rate(k).Temp.P_lim, [style{1} marker{1}], 'LineWidth', 1)
    style = circshift(style, 1);
    marker = circshift(marker, 1);
end
set(gca, 'xdir', 'reverse')

title('Pulse Power Capability vs %-Remaining of Operating Capacity')

for k = 1:length(C_Rate_Index)
    Legend_Array(k) = strcat(string(abs(round(I(Pulse_Start_Index(C_Rate_Index{k, 1}(1)) + 10)))),...
        '[A]');
    if I(Pulse_Start_Index(C_Rate_Index{k, 1}(1)) + 1) < 0
        Legend_Array(k) = strcat(Legend_Array(k), ' Discharge');
    else
        Legend_Array(k) = strcat(Legend_Array(k), ' Regen');
    end
end

legend(Legend_Array)
xlabel('State of Charge [%]')
ylabel('Power [W]')
xlim([0 101])

% Clear all variables except model
clearvars -except 'ECM_Model'
