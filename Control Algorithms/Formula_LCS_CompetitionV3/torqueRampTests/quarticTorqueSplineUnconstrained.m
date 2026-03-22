% Constraint matrix — 5 waypoints at t = 0, 0.25, 0.5, 0.75, 1 (fully unconstrained)
A = [0^4,      0^3,      0^2,     0,    1;
     0.25^4,   0.25^3,   0.25^2,  0.25, 1;
     0.5^4,    0.5^3,    0.5^2,   0.5,  1;
     0.75^4,   0.75^3,   0.75^2,  0.75, 1;
     1^4,      1^3,      1^2,     1,    1];

% Sweep ranges
p0_values = linspace(31, 35, 4);
p1_values = linspace(78, 90, 4);
p2_values = linspace(70, 80, 4);
p3_values = linspace(78, 85, 4);
p4_values = linspace(70, 80, 4);

results      = [];
valid_count  = 0;
failed_count = 0;
total        = length(p0_values) * length(p1_values) * length(p2_values) * length(p3_values) * length(p4_values);
counter      = 0;

% --- Progress figure setup ---
fig = figure('Name', 'Sweep Progress', 'NumberTitle', 'off', ...
             'Position', [500 400 520 160], 'Resize', 'off');

counter_text = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.55 0.9 0.25], ...
                     'FontSize', 16, 'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'center', ...
                     'String', sprintf('0 / %d', total));

status_text = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.28 0.9 0.2], ...
                     'FontSize', 11, ...
                     'HorizontalAlignment', 'center', ...
                     'String', 'valid: 0  |  failed: 0');

eta_text = uicontrol(fig, 'Style','text', 'Units','normalized', ...
                     'Position',[0.05 0.05 0.9 0.2], ...
                     'FontSize', 10, ...
                     'HorizontalAlignment', 'center', ...
                     'String', 'ETA: calculating...');
drawnow;

t_start = tic;
set_param('onlyProportional', 'StopTime', '1');

for i0 = 1:length(p0_values)
    for i1 = 1:length(p1_values)
        for i2 = 1:length(p2_values)
            for i3 = 1:length(p3_values)
                for i4 = 1:length(p4_values)
                    counter = counter + 1;

                    p0 = p0_values(i0);
                    p1 = p1_values(i1);
                    p2 = p2_values(i2);
                    p3 = p3_values(i3);
                    p4 = p4_values(i4);

                    b      = [p0; p1; p2; p3; p4];
                    coeffs = A \ b;

                    coeff_a0 = coeffs(5); coeff_a1 = coeffs(4);
                    coeff_a2 = coeffs(3); coeff_a3 = coeffs(2);
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
                        failed_count = failed_count + 1;
                        % skip — do not save failed runs
                    else
                        valid_count = valid_count + 1;
                        results(end+1,:) = [coeff_a0, coeff_a1, coeff_a2, coeff_a3, coeff_a4, ...
                                            p0, p1, p2, p3, p4, v_final, max_slip];
                    end

                    if mod(counter, 100) == 0 || counter == total
                        elapsed = toc(t_start);
                        eta_sec = (elapsed / counter) * (total - counter);
                        counter_text.String = sprintf('%d / %d', counter, total);
                        status_text.String  = sprintf('valid: %d  |  failed: %d', valid_count, failed_count);
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

% Mark complete
counter_text.String = sprintf('DONE  —  %d / %d', total, total);
status_text.String  = sprintf('valid: %d  |  failed: %d', valid_count, failed_count);
eta_text.String     = sprintf('Total time: %dm %ds', floor(toc(t_start)/60), mod(floor(toc(t_start)),60));
counter_text.ForegroundColor = [0.0 0.6 0.0];
drawnow;

% All entries in results are already valid — no filtering needed
[~, idx] = sort(results(:,11), 'descend');
top100   = results(idx(1:min(100,end)), :);

% Display top 100
fprintf('\n--- TOP 100 RUNS ---\n');
fprintf('%-10s %-10s %-10s %-10s %-10s %-8s %-8s %-8s %-8s %-8s %-12s %-10s\n', ...
        'a0','a1','a2','a3','a4','p0','p1','p2','p3','p4','v_final','maxSlip');
for i = 1:size(top100, 1)
    fprintf('%-10.4f %-10.4f %-10.4f %-10.4f %-10.4f %-8.2f %-8.2f %-8.2f %-8.2f %-8.2f %-12.4f %-10.4f\n', ...
            top100(i,1), top100(i,2), top100(i,3), top100(i,4), top100(i,5), ...
            top100(i,6), top100(i,7), top100(i,8), top100(i,9), top100(i,10), ...
            top100(i,11), top100(i,12));
end

% Save results
save_path = 'C:\GITHUB\FB26_Controls\Control Algorithms\Formula_LCS_Competition\sweepResults_seg1_unconstrained_v3.mat';
save(save_path, 'results', 'top100');

csv_path  = 'C:\GITHUB\FB26_Controls\Control Algorithms\Formula_LCS_Competition\top100_seg1_unconstrained_v3.csv';
headers   = {'a0','a1','a2','a3','a4','p0','p1','p2','p3','p4','v_final','maxSlip'};
top100_table = array2table(top100, 'VariableNames', headers);
writetable(top100_table, csv_path);

fprintf('\nResults saved to:\n  %s\n  %s\n', save_path, csv_path);