% =========================================================
% Successive Zooming PD Gain Sweep — ~11,746 runs
% Rounds: 1920 (coarse) + 4913 (medium) + 4913 (fine)
% Primary sort: fastest run time (car reaches 75m)
% Runs that hit 4.5s timeout are excluded entirely
% =========================================================

MODEL_NAME = 'Demo';
SAVE_PATH  = 'C:\GITHUB\FB26_Controls\Control Algorithms\Formula_LCS_Competition\sweep_results_top100.xlsx';
TIMEOUT    = 4.5;

all_results  = [];
total        = 1920 + 4913 + 4913;  % ~11746
counter      = 0;
valid_count  = 0;
failed_count = 0;
t_start      = tic;

% =========================================================
% PROGRESS FIGURE
% =========================================================
fig = figure('Name', 'Sweep Progress', 'NumberTitle', 'off', ...
             'Position', [500 400 520 160], 'Resize', 'off');
counter_text = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.55 0.9 0.25], ...
                     'FontSize', 16, 'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'center', ...
                     'String', sprintf('0 / %d', total));
status_text  = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.28 0.9 0.2], ...
                     'FontSize', 11, ...
                     'HorizontalAlignment', 'center', ...
                     'String', 'valid: 0  |  failed: 0');
eta_text     = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.05 0.9 0.2], ...
                     'FontSize', 10, ...
                     'HorizontalAlignment', 'center', ...
                     'String', 'ETA: calculating...');
drawnow;

% =========================================================
% HELPER FUNCTION
% =========================================================
function row = run_sim(model, kpu, kpd, kd, run_num, timeout)
    assignin('base', 'kP_up',   kpu);
    assignin('base', 'kP_down', kpd);
    assignin('base', 'kD',      kd);
    row = [];
    try
        simOut   = sim(model, 'StopTime', num2str(timeout));
        run_time = simOut.runTime.Time(end);
        if run_time >= timeout - 0.1
            return;
        end
        slip_data   = evalin('base', 'slipRatio');
        t_slip      = slip_data(:, 1);
        slip        = slip_data(:, 2);
        mask        = t_slip >= 0.2 & t_slip <= run_time;
        slip_window = slip(mask);
        rms_error   = sqrt(mean((slip_window - 0.11).^2));
        peak_slip   = max(abs(slip_window));
        osc_amp     = std(slip_window);
        row = [run_num, kpu, kpd, kd, run_time, rms_error, peak_slip, osc_amp];
    catch
        return;
    end
end

% =========================================================
% INLINE UPDATE HELPER
% =========================================================
function update_display(counter_text, status_text, eta_text, ...
                         counter, total, valid_count, failed_count, t_start)
    if mod(counter, 10) == 0 || counter == total
        elapsed = toc(t_start);
        if counter > 0
            eta_sec = (elapsed / counter) * (total - counter);
        else
            eta_sec = 0;
        end
        counter_text.String = sprintf('%d / %d', counter, total);
        status_text.String  = sprintf('valid: %d  |  failed: %d', valid_count, failed_count);
        eta_text.String     = sprintf('Elapsed: %dm %ds    |    ETA: %dm %ds', ...
                                      floor(elapsed/60), mod(floor(elapsed),60), ...
                                      floor(eta_sec/60), mod(floor(eta_sec),60));
        drawnow;
    end
end

% =========================================================
% ROUND 1 — Coarse grid 1920 runs
% kP_up:   0.5:0.2:3.0  (14 values)
% kP_down: 1.5:0.5:8.0  (14 values)
% kD:      0.0:0.2:1.4  ( 8 values)
% =========================================================
fprintf('===== ROUND 1: Coarse grid =====\n');
kpu_r1 = 0.5 : 0.2 : 3.0;
kpd_r1 = 1.5 : 0.5 : 8.0;
kd_r1  = 0.0 : 0.2 : 1.4;
run_num = 1; r1_results = [];

for kpu = kpu_r1
    for kpd = kpd_r1
        for kd = kd_r1
            row = run_sim(MODEL_NAME, kpu, kpd, kd, run_num, TIMEOUT);
            counter = counter + 1;
            if ~isempty(row)
                all_results(end+1,:) = row;
                r1_results(end+1,:)  = row;
                valid_count = valid_count + 1;
            else
                failed_count = failed_count + 1;
            end
            update_display(counter_text, status_text, eta_text, ...
                           counter, total, valid_count, failed_count, t_start);
            run_num = run_num + 1;
        end
    end
end

[~,idx1] = min(r1_results(:,5));
best_r1  = r1_results(idx1,:);
fprintf('Round 1 best: kP_up=%.2f kP_down=%.2f kD=%.2f  time=%.4fs\n', ...
        best_r1(2),best_r1(3),best_r1(4),best_r1(5));

% =========================================================
% ROUND 2 — Medium zoom 17x17x17 = 4913 runs
% =========================================================
fprintf('\n===== ROUND 2: Medium zoom =====\n');
step2_kpu = 0.2/5;  step2_kpd = 0.5/5;  step2_kd = 0.2/5;
kpu_r2 = max(0.01, best_r1(2)-8*step2_kpu) : step2_kpu : best_r1(2)+8*step2_kpu;
kpd_r2 = max(0.10, best_r1(3)-8*step2_kpd) : step2_kpd : best_r1(3)+8*step2_kpd;
kd_r2  = max(0.00, best_r1(4)-8*step2_kd)  : step2_kd  : best_r1(4)+8*step2_kd;
run_num = 1; r2_results = [];

for kpu = kpu_r2
    for kpd = kpd_r2
        for kd = kd_r2
            row = run_sim(MODEL_NAME, kpu, kpd, kd, run_num, TIMEOUT);
            counter = counter + 1;
            if ~isempty(row)
                all_results(end+1,:) = row;
                r2_results(end+1,:)  = row;
                valid_count = valid_count + 1;
            else
                failed_count = failed_count + 1;
            end
            update_display(counter_text, status_text, eta_text, ...
                           counter, total, valid_count, failed_count, t_start);
            run_num = run_num + 1;
        end
    end
end

[~,idx2] = min(r2_results(:,5));
best_r2  = r2_results(idx2,:);
fprintf('Round 2 best: kP_up=%.3f kP_down=%.3f kD=%.3f  time=%.4fs\n', ...
        best_r2(2),best_r2(3),best_r2(4),best_r2(5));

% =========================================================
% ROUND 3 — Fine zoom 17x17x17 = 4913 runs
% =========================================================
fprintf('\n===== ROUND 3: Fine zoom =====\n');
step3_kpu = step2_kpu/5;  step3_kpd = step2_kpd/5;  step3_kd = step2_kd/5;
kpu_r3 = max(0.01, best_r2(2)-8*step3_kpu) : step3_kpu : best_r2(2)+8*step3_kpu;
kpd_r3 = max(0.10, best_r2(3)-8*step3_kpd) : step3_kpd : best_r2(3)+8*step3_kpd;
kd_r3  = max(0.00, best_r2(4)-8*step3_kd)  : step3_kd  : best_r2(4)+8*step3_kd;
run_num = 1; r3_results = [];

for kpu = kpu_r3
    for kpd = kpd_r3
        for kd = kd_r3
            row = run_sim(MODEL_NAME, kpu, kpd, kd, run_num, TIMEOUT);
            counter = counter + 1;
            if ~isempty(row)
                all_results(end+1,:) = row;
                r3_results(end+1,:)  = row;
                valid_count = valid_count + 1;
            else
                failed_count = failed_count + 1;
            end
            update_display(counter_text, status_text, eta_text, ...
                           counter, total, valid_count, failed_count, t_start);
            run_num = run_num + 1;
        end
    end
end

% =========================================================
% FINAL — sort by RunTime, save top 100
% =========================================================
fprintf('\n===== FINAL RESULTS =====\n');
fprintf('Total valid runs: %d\n', size(all_results,1));
all_results = sortrows(all_results, 5);

fprintf('\n--- TOP 20 (fastest) ---\n');
fprintf('%-6s %-8s %-10s %-6s %-10s %-10s %-10s %-10s\n', ...
        'Run','kP_up','kP_down','kD','RunTime','RMS_err','Peak','Osc');
for i = 1:min(20, size(all_results,1))
    r = all_results(i,:);
    fprintf('%-6d %-8.4f %-10.4f %-6.4f %-10.4f %-10.4f %-10.4f %-10.4f\n', ...
            r(1),r(2),r(3),r(4),r(5),r(6),r(7),r(8));
end

top100 = all_results(1:min(100,size(all_results,1)),:);
T = array2table(top100, 'VariableNames', ...
    {'Run','kP_up','kP_down','kD','RunTime_s','RMS_error','Peak_slip','Osc_amp'});
writetable(T, SAVE_PATH);




% Final display update
counter_text.String = sprintf('%d / %d  DONE', counter, total);
status_text.String  = sprintf('valid: %d  |  failed: %d', valid_count, failed_count);
eta_text.String     = sprintf('Total time: %dm %ds', ...
                               floor(toc(t_start)/60), mod(floor(toc(t_start)),60));
drawnow;
fprintf('\nTop 100 saved to:\n%s\n', SAVE_PATH);