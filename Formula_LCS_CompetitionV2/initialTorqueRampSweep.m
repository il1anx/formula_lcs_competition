a_values = 20:0.5:40;
results = [];
valid_count = 0;
failed_count = 0;

set_param('onlyProportional', 'StopTime', '1');
set_param('onlyProportional/rampType', 'Value', '1');
set_param('onlyProportional/bconst', 'Value', '0');
set_param('onlyProportional/cconst', 'Value', '0');
set_param('onlyProportional/dconst', 'Value', '0');

for ii = 1:length(a_values)
    a_current = a_values(ii);
    set_param('onlyProportional/aconst', 'Value', num2str(a_current));
    simOut = sim('onlyProportional.slx');
    v_final  = simOut.carVelocity(end);
    max_slip = max(simOut.maxSlipDuringRun);

    if max_slip >= 0.11
        failed_count = failed_count + 1;
        fprintf('a=%.2f, v=%.4f, maxSlip=%.4f  FAILED (slip too high)\n', a_current, v_final, max_slip);
    else
        valid_count = valid_count + 1;
        fprintf('a=%.2f, v=%.4f, maxSlip=%.4f  OK\n', a_current, v_final, max_slip);
    end

    results(end+1,:) = [a_current, v_final, max_slip];
end

fprintf('\nValid runs: %d | Failed (slip): %d\n', valid_count, failed_count);

% Best valid run = highest final velocity without slip violation
valid = results(results(:,3) < 0.12, :);
[~, idx] = max(valid(:,2));
best = valid(idx,:)
% columns: [a, v_final, maxSlip]

figure;
plot(results(:,1), results(:,2), 'o-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
plot(best(1), best(2), 'r*', 'MarkerSize', 15, 'LineWidth', 2);
xlabel('a (linear ramp coefficient)');
ylabel('Final velocity at 1s (m/s)');
title('Linear Ramp Sweep — Final Velocity at 1s');
legend('All runs', 'Best valid run');
grid on;