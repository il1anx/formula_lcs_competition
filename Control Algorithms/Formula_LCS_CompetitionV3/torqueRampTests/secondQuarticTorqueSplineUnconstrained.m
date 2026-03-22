% =========================================================
% Successive Zooming Sweep — Two Chains
% Chain 1: zooms on best v_final
% Chain 2: zooms on best distance
% p1_range = [8,  30]
% p2_range = [10, 70]
% p3_range = [20, 90]
% p4_range = [30, 100]
% n_pts = [5, 5, 4, 3]  ->  4 rounds each chain
% Slip threshold: 0.7 (ignored for first 0.1s via Simulink gate)
% Outputs: top100_vel and top100_dist across both chains
% =========================================================

% Constraint matrix
A = [0^4,      0^3,      0^2,     0,    1;
     (1/3)^4,  (1/3)^3,  (1/3)^2, 1/3,  1;
     (2/3)^4,  (2/3)^3,  (2/3)^2, 2/3,  1;
     1^4,      1^3,      1^2,     1,    1;
     4*1^3,    3*1^2,    2*1,     1,    0];

% Initial ranges (reset at start of each chain)
p1_init = [8,  30];
p2_init = [10, 70];
p3_init = [20, 90];
p4_init = [30, 100];

n_pts    = [5, 5, 4, 3];
n_rounds = 4;

% Pre-compute total runs (same for each chain)
runs_per_round = n_pts .^ 4;
total_per_chain = sum(runs_per_round);
grand_total     = total_per_chain * 2;   % two chains

fprintf('Total runs (both chains): %d\n', grand_total);
for r = 1:n_rounds
    fprintf('  Round %d: %d runs (%d pts per param)\n', r, runs_per_round(r), n_pts(r));
end

rounds_str = '';
for r = 1:n_rounds
    rounds_str = [rounds_str, sprintf('R%d:%d  ', r, runs_per_round(r))];
end

% --- Progress figure ---
fig = figure('Name', 'Sweep Progress', 'NumberTitle', 'off', ...
             'Position', [500 350 560 220], 'Resize', 'off');

counter_text = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.65 0.9 0.22], ...
                     'FontSize', 15, 'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'center', ...
                     'String', sprintf('0 / %d', grand_total));

chain_text   = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.48 0.9 0.16], ...
                     'FontSize', 11, 'ForegroundColor', [0.1 0.4 0.8], ...
                     'HorizontalAlignment', 'center', ...
                     'String', 'Chain 1 of 2: zooming on v_final');

status_text  = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.31 0.9 0.16], ...
                     'FontSize', 11, 'HorizontalAlignment', 'center', ...
                     'String', 'valid: 0  |  failed: 0');

eta_text     = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.15 0.9 0.14], ...
                     'FontSize', 10, 'HorizontalAlignment', 'center', ...
                     'String', 'ETA: calculating...');

rounds_text  = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.02 0.9 0.12], ...
                     'FontSize', 9, 'ForegroundColor', [0.4 0.4 0.4], ...
                     'HorizontalAlignment', 'center', ...
                     'String', rounds_str);
drawnow;

set_param('onlyProportional', 'StopTime', '1');

% Storage for both chains
chain_round_results = cell(2, n_rounds);   % chain x round
chain_names         = {'v_final', 'distance'};
zoom_col            = [10, 12];            % col 10 = v_final, col 12 = distance

global_counter = 0;
global_valid   = 0;
global_failed  = 0;
t_start        = tic;

% =========================================================
% OUTER LOOP: two chains
% =========================================================
for chain = 1:2

    % Reset ranges for each chain
    p1_range = p1_init;
    p2_range = p2_init;
    p3_range = p3_init;
    p4_range = p4_init;

    chain_text.String = sprintf('Chain %d of 2: zooming on %s', chain, chain_names{chain});
    chain_text.ForegroundColor = [0.1 0.4 0.8];
    drawnow;

    fprintf('\n\n========== CHAIN %d: zoom on %s ==========\n', chain, chain_names{chain});

    % =====================================================
    % INNER LOOP: rounds within this chain
    % =====================================================
    for round = 1:n_rounds
        n = n_pts(round);

        p1_values = linspace(p1_range(1), p1_range(2), n);
        p2_values = linspace(p2_range(1), p2_range(2), n);
        p3_values = linspace(p3_range(1), p3_range(2), n);
        p4_values = linspace(p4_range(1), p4_range(2), n);

        results      = [];   % only valid runs stored
        valid_count  = 0;
        failed_count = 0;

        fprintf('\n--- Chain %d | Round %d ---\n', chain, round);
        fprintf('p1:[%.2f,%.2f]  p2:[%.2f,%.2f]  p3:[%.2f,%.2f]  p4:[%.2f,%.2f]\n', ...
                p1_range(1), p1_range(2), p2_range(1), p2_range(2), ...
                p3_range(1), p3_range(2), p4_range(1), p4_range(2));

        for i1 = 1:n
            for i2 = 1:n
                for i3 = 1:n
                    for i4 = 1:n
                        global_counter = global_counter + 1;

                        p1 = p1_values(i1);
                        p2 = p2_values(i2);
                        p3 = p3_values(i3);
                        p4 = p4_values(i4);

                        b      = [p1; p2; p3; p4; 0];
                        coeffs = A \ b;

                        coeff_a0 = coeffs(5); coeff_a1 = coeffs(4);
                        coeff_a2 = coeffs(3); coeff_a3 = coeffs(2);
                        coeff_a4 = coeffs(1);

                        assignin('base', 'a0', coeff_a0);
                        assignin('base', 'a1', coeff_a1);
                        assignin('base', 'a2', coeff_a2);
                        assignin('base', 'a3', coeff_a3);
                        assignin('base', 'a4', coeff_a4);

                        simOut   = sim('onlyProportional.slx');
                        v_final  = simOut.carVelocity.Data(end);
                        d_final  = simOut.distance.Data(end);
                        max_slip = max(simOut.maxSlipDuringRun.Data);

                        % Columns: [a0,a1,a2,a3,a4, p1,p2,p3,p4, v_final, max_slip, d_final]
                        if max_slip >= 0.7
                            failed_count  = failed_count + 1;
                            global_failed = global_failed + 1;
                        else
                            valid_count  = valid_count + 1;
                            global_valid = global_valid + 1;
                            results(end+1,:) = [coeff_a0, coeff_a1, coeff_a2, coeff_a3, coeff_a4, ...
                                                p1, p2, p3, p4, v_final, max_slip, d_final];
                        end

                        % Update progress every 100 runs
                        if mod(global_counter, 100) == 0 || global_counter == grand_total
                            elapsed = toc(t_start);
                            eta_sec = (elapsed / global_counter) * (grand_total - global_counter);
                            counter_text.String = sprintf('Chain %d | Round %d  —  %d / %d', ...
                                                          chain, round, global_counter, grand_total);
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

        chain_round_results{chain, round} = results;

        fprintf('Round %d done: valid=%d  failed=%d\n', round, valid_count, failed_count);

        if isempty(results)
            fprintf('Chain %d Round %d: no valid results, stopping chain.\n', chain, round);
            break;
        end

        % Find best run for this chain's zoom target
        [~, best_idx] = max(results(:, zoom_col(chain)));
        best    = results(best_idx, :);
        best_p1 = best(6); best_p2 = best(7);
        best_p3 = best(8); best_p4 = best(9);

        fprintf('Best: p1=%.3f  p2=%.3f  p3=%.3f  p4=%.3f  v=%.4f  dist=%.4f  slip=%.4f\n', ...
                best_p1, best_p2, best_p3, best_p4, best(10), best(12), best(11));

        % Zoom ranges to ±1 step around best
        step1 = (p1_range(2) - p1_range(1)) / (n - 1);
        step2 = (p2_range(2) - p2_range(1)) / (n - 1);
        step3 = (p3_range(2) - p3_range(1)) / (n - 1);
        step4 = (p4_range(2) - p4_range(1)) / (n - 1);

        p1_range = [best_p1 - step1, best_p1 + step1];
        p2_range = [best_p2 - step2, best_p2 + step2];
        p3_range = [best_p3 - step3, best_p3 + step3];
        p4_range = [best_p4 - step4, best_p4 + step4];
    end
end

% Mark complete
counter_text.String          = sprintf('DONE  —  %d / %d', grand_total, grand_total);
counter_text.ForegroundColor = [0.0 0.6 0.0];
chain_text.String            = 'Both chains complete';
chain_text.ForegroundColor   = [0.0 0.6 0.0];
status_text.String           = sprintf('valid: %d  |  failed: %d', global_valid, global_failed);
eta_text.String              = sprintf('Total time: %dm %ds', ...
                                       floor(toc(t_start)/60), mod(floor(toc(t_start)),60));
drawnow;

% =========================================================
% POST-PROCESSING
% =========================================================

% Collect all valid results across both chains and all rounds
all_results = vertcat(chain_round_results{:});

headers = {'a0','a1','a2','a3','a4','p1','p2','p3','p4','v_final','maxSlip','distance'};

% Top 100 by v_final
[~, idx_vel] = sort(all_results(:,10), 'descend');
top100_vel   = all_results(idx_vel(1:min(100,end)), :);

% Top 100 by distance
[~, idx_dist] = sort(all_results(:,12), 'descend');
top100_dist   = all_results(idx_dist(1:min(100,end)), :);

% --- Print top 100 by velocity ---
fprintf('\n--- TOP 100 BY FINAL VELOCITY ---\n');
fprintf('%-10s %-10s %-10s %-10s %-10s %-8s %-8s %-8s %-8s %-12s %-12s %-10s\n', headers{:});
for i = 1:size(top100_vel, 1)
    fprintf('%-10.4f %-10.4f %-10.4f %-10.4f %-10.4f %-8.2f %-8.2f %-8.2f %-8.2f %-12.4f %-10.4f %-12.4f\n', ...
            top100_vel(i,1), top100_vel(i,2), top100_vel(i,3), top100_vel(i,4), top100_vel(i,5), ...
            top100_vel(i,6), top100_vel(i,7), top100_vel(i,8), top100_vel(i,9), ...
            top100_vel(i,10), top100_vel(i,11), top100_vel(i,12));
end

% --- Print top 100 by distance ---
fprintf('\n--- TOP 100 BY DISTANCE ---\n');
fprintf('%-10s %-10s %-10s %-10s %-10s %-8s %-8s %-8s %-8s %-12s %-12s %-10s\n', headers{:});
for i = 1:size(top100_dist, 1)
    fprintf('%-10.4f %-10.4f %-10.4f %-10.4f %-10.4f %-8.2f %-8.2f %-8.2f %-8.2f %-12.4f %-10.4f %-12.4f\n', ...
            top100_dist(i,1), top100_dist(i,2), top100_dist(i,3), top100_dist(i,4), top100_dist(i,5), ...
            top100_dist(i,6), top100_dist(i,7), top100_dist(i,8), top100_dist(i,9), ...
            top100_dist(i,10), top100_dist(i,11), top100_dist(i,12));
end

% --- Save ---
base_path = 'C:\GITHUB\FB26_Controls\Control Algorithms\Formula_LCS_Competition\';

% .mat
save([base_path, 'sweepResults_zooming.mat'], 'chain_round_results', 'all_results', 'top100_vel', 'top100_dist');

% Excel — one sheet per chain/round + two top100 sheets
xlsx_path = [base_path, 'sweep_zooming.xlsx'];
for chain = 1:2
    for r = 1:n_rounds
        if ~isempty(chain_round_results{chain, r})
            writetable(array2table(chain_round_results{chain, r}, 'VariableNames', headers), ...
                       xlsx_path, 'Sheet', sprintf('C%d_Round%d', chain, r));
        end
    end
end
writetable(array2table(top100_vel,  'VariableNames', headers), xlsx_path, 'Sheet', 'Top100_Vel');
writetable(array2table(top100_dist, 'VariableNames', headers), xlsx_path, 'Sheet', 'Top100_Dist');

% CSVs
writetable(array2table(top100_vel,  'VariableNames', headers), [base_path, 'top100_vel_zooming.csv']);
writetable(array2table(top100_dist, 'VariableNames', headers), [base_path, 'top100_dist_zooming.csv']);

fprintf('\nResults saved to:\n  %s\n  %s\n', [base_path, 'sweep_zooming.xlsx'], [base_path, 'sweepResults_zooming.mat']);