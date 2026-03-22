% =========================================================
% Segment Sweep — Successive Zooming (4 rounds)
% Waypoints at t = 0, 0.75, 1.5, 2.25, 3
% 4th-order polynomial, 5 coefficients
% 5 waypoints = 5 equations, fully determined (no extra constraint)
% p0-p4 all swept, maximizing v_final
% =========================================================

A = [0^4,      0^3,      0^2,     0,     1;
     0.75^4,   0.75^3,   0.75^2,  0.75,  1;
     1.5^4,    1.5^3,    1.5^2,   1.5,   1;
     2.25^4,   2.25^3,   2.25^2,  2.25,  1;
     3^4,      3^3,      3^2,     3,     1];

% Initial coarse ranges
p0_range = [8,  40];
p1_range = [30, 80];
p2_range = [35, 90];
p3_range = [40, 100];
p4_range = [40, 100];

n_pts    = [7, 5, 5, 4];
n_rounds = 4;

% --- Pre-compute runs per round and grand total ---
runs_per_round = zeros(1, n_rounds);
for r = 1:n_rounds
    runs_per_round(r) = n_pts(r)^5;
end
grand_total = sum(runs_per_round);

fprintf('Total runs across all rounds: %d\n', grand_total);
for r = 1:n_rounds
    fprintf('  Round %d: %d runs (%d pts per param)\n', r, runs_per_round(r), n_pts(r));
end

% Build rounds breakdown string for figure
rounds_str = '';
for r = 1:n_rounds
    rounds_str = [rounds_str, sprintf('R%d: %d  ', r, runs_per_round(r))];
end

% --- Progress figure ---
fig = figure('Name', 'Sweep Progress', 'NumberTitle', 'off', ...
             'Position', [500 400 520 200], 'Resize', 'off');

counter_text = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.62 0.9 0.22], ...
                     'FontSize', 16, 'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'center', ...
                     'String', sprintf('0 / %d', grand_total));

status_text  = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.40 0.9 0.18], ...
                     'FontSize', 11, 'HorizontalAlignment', 'center', ...
                     'String', 'valid: 0  |  failed: 0');

eta_text     = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.22 0.9 0.16], ...
                     'FontSize', 10, 'HorizontalAlignment', 'center', ...
                     'String', 'ETA: calculating...');

rounds_text  = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.04 0.9 0.16], ...
                     'FontSize', 9, 'ForegroundColor', [0.4 0.4 0.4], ...
                     'HorizontalAlignment', 'center', ...
                     'String', rounds_str);
drawnow;

set_param('onlyProportional', 'StartTime', '0');
set_param('onlyProportional', 'StopTime',  '3');

all_round_results = cell(n_rounds, 1);
global_counter    = 0;
global_valid      = 0;
global_failed     = 0;
t_start           = tic;

for round = 1:n_rounds
    n = n_pts(round);

    p0_values = linspace(p0_range(1), p0_range(2), n);
    p1_values = linspace(p1_range(1), p1_range(2), n);
    p2_values = linspace(p2_range(1), p2_range(2), n);
    p3_values = linspace(p3_range(1), p3_range(2), n);
    p4_values = linspace(p4_range(1), p4_range(2), n);

    results      = [];
    valid_count  = 0;
    failed_count = 0;
    counter      = 0;

    fprintf('\n========== ROUND %d ==========\n', round);
    fprintf('p0: [%.2f, %.2f]  p1: [%.2f, %.2f]  p2: [%.2f, %.2f]  p3: [%.2f, %.2f]  p4: [%.2f, %.2f]\n', ...
            p0_range(1), p0_range(2), p1_range(1), p1_range(2), ...
            p2_range(1), p2_range(2), p3_range(1), p3_range(2), ...
            p4_range(1), p4_range(2));

    for i0 = 1:n
        for i1 = 1:n
            for i2 = 1:n
                for i3 = 1:n
                    for i4 = 1:n
                        counter        = counter + 1;
                        global_counter = global_counter + 1;

                        p0 = p0_values(i0);
                        p1 = p1_values(i1);
                        p2 = p2_values(i2);
                        p3 = p3_values(i3);
                        p4 = p4_values(i4);

                        b      = [p0; p1; p2; p3; p4];
                        coeffs = A \ b;

                        coeff_a0 = coeffs(5);
                        coeff_a1 = coeffs(4);
                        coeff_a2 = coeffs(3);
                        coeff_a3 = coeffs(2);
                        coeff_a4 = coeffs(1);

                        set_param('onlyProportional/a0', 'Value', num2str(coeff_a0, '%.10f'));
                        set_param('onlyProportional/a1', 'Value', num2str(coeff_a1, '%.10f'));
                        set_param('onlyProportional/a2', 'Value', num2str(coeff_a2, '%.10f'));
                        set_param('onlyProportional/a3', 'Value', num2str(coeff_a3, '%.10f'));
                        set_param('onlyProportional/a4', 'Value', num2str(coeff_a4, '%.10f'));

                        simOut   = sim('onlyProportional.slx');
                        v_final  = simOut.carVelocity(end);
                        max_slip = max(simOut.maxSlipDuringRun);

                        if max_slip >= 0.5
                            failed_count  = failed_count + 1;
                            global_failed = global_failed + 1;
                        else
                            valid_count  = valid_count + 1;
                            global_valid = global_valid + 1;
                            results(end+1,:) = [coeff_a0, coeff_a1, coeff_a2, coeff_a3, coeff_a4, ...
                                                p0, p1, p2, p3, p4, v_final, max_slip];
                        end

                        if mod(global_counter, 100) == 0 || global_counter == grand_total
                            elapsed = toc(t_start);
                            eta_sec = (elapsed / global_counter) * (grand_total - global_counter);
                            counter_text.String = sprintf('Round %d  —  %d / %d', round, global_counter, grand_total);
                            status_text.String  = sprintf('valid: %d  |  failed: %d', global_valid, global_failed);
                            eta_text.String     = sprintf('Elapsed: %dm %ds    |    ETA: %dm %ds', ...
                                                          floor(elapsed/60), mod(floor(elapsed),60), ...
                                                          floor(eta_sec/60), mod(floor(eta_sec),60));
                            drawnow;
                        end
                    end
                end
            end
        end
    end

    all_round_results{round} = results;

    counter_text.String          = sprintf('Round %d DONE  —  %d / %d', round, global_counter, grand_total);
    counter_text.ForegroundColor = [0.0 0.6 0.0];
    drawnow;

    if isempty(results)
        fprintf('Round %d: no valid results, stopping.\n', round);
        break;
    end

    % Find best and zoom — maximize v_final (col 11)
    [~, best_idx] = max(results(:, 11));
    best    = results(best_idx, :);
    best_p0 = best(6);  best_p1 = best(7);
    best_p2 = best(8);  best_p3 = best(9);
    best_p4 = best(10);

    fprintf('Round %d best: p0=%.3f  p1=%.3f  p2=%.3f  p3=%.3f  p4=%.3f  v=%.4f\n', ...
            round, best_p0, best_p1, best_p2, best_p3, best_p4, best(11));

    step0 = (p0_range(2) - p0_range(1)) / (n - 1);
    step1 = (p1_range(2) - p1_range(1)) / (n - 1);
    step2 = (p2_range(2) - p2_range(1)) / (n - 1);
    step3 = (p3_range(2) - p3_range(1)) / (n - 1);
    step4 = (p4_range(2) - p4_range(1)) / (n - 1);

    p0_range = zoom_range(best_p0, p0_range, step0);
    p1_range = zoom_range(best_p1, p1_range, step1);
    p2_range = zoom_range(best_p2, p2_range, step2);
    p3_range = zoom_range(best_p3, p3_range, step3);
    p4_range = zoom_range(best_p4, p4_range, step4);

    fprintf('New ranges: p0=[%.2f,%.2f]  p1=[%.2f,%.2f]  p2=[%.2f,%.2f]  p3=[%.2f,%.2f]  p4=[%.2f,%.2f]\n', ...
            p0_range(1), p0_range(2), p1_range(1), p1_range(2), ...
            p2_range(1), p2_range(2), p3_range(1), p3_range(2), ...
            p4_range(1), p4_range(2));
end

% Mark fully complete
counter_text.String          = sprintf('DONE  —  %d / %d', grand_total, grand_total);
counter_text.ForegroundColor = [0.0 0.6 0.0];
status_text.String           = sprintf('valid: %d  |  failed: %d', global_valid, global_failed);
eta_text.String              = sprintf('Total time: %dm %ds', floor(toc(t_start)/60), mod(floor(toc(t_start)),60));
drawnow;

% Collect top 100 across all rounds — sorted by v_final
all_results = vertcat(all_round_results{:});
[~, idx]    = sort(all_results(:, 11), 'descend');
top100      = all_results(idx(1:min(100, end)), :);

% Save to Excel — one tab per round + Top100
xlsx_path = 'C:\GITHUB\FB26_Controls\Control Algorithms\Formula_LCS_Competition\sweep_seg_0to3_zooming.xlsx';
headers   = {'a0','a1','a2','a3','a4','p0','p1','p2','p3','p4','v_final','maxSlip'};

for r = 1:n_rounds
    if ~isempty(all_round_results{r})
        writetable(array2table(all_round_results{r}, 'VariableNames', headers), ...
                   xlsx_path, 'Sheet', sprintf('Round%d', r));
    end
end
writetable(array2table(top100, 'VariableNames', headers), xlsx_path, 'Sheet', 'Top100');

fprintf('\nResults saved to:\n  %s\n', xlsx_path);

% Print top 100 to console
fprintf('\n--- TOP 100 ACROSS ALL ROUNDS ---\n');
fprintf('%-10s %-10s %-10s %-10s %-10s %-8s %-8s %-8s %-8s %-8s %-12s %-10s\n', headers{:});
for i = 1:size(top100, 1)
    fprintf('%-10.4f %-10.4f %-10.4f %-10.4f %-10.4f %-8.2f %-8.2f %-8.2f %-8.2f %-8.2f %-12.4f %-10.4f\n', ...
            top100(i,1),  top100(i,2),  top100(i,3),  top100(i,4),  top100(i,5), ...
            top100(i,6),  top100(i,7),  top100(i,8),  top100(i,9),  top100(i,10), ...
            top100(i,11), top100(i,12));
end

% =========================================================
% Helper function — biased zoom
% =========================================================
function new_range = zoom_range(best, old_range, step)
    rel = (best - old_range(1)) / (old_range(2) - old_range(1));

    if rel > 0.85
        % Near upper boundary: 0.75 back, 2 forward
        new_low  = best - 0.75 * step;
        new_high = best + 2.0  * step;
    elseif rel < 0.15
        % Near lower boundary: 2 back, 0.75 forward
        new_low  = best - 2.0  * step;
        new_high = best + 0.75 * step;
    else
        % Symmetric
        new_low  = best - step;
        new_high = best + step;
    end

    % Clamp to never go below 0
    new_range = [max(new_low, 0), new_high];
end