clear
clc
kP = 0;
initialTorq = 0;
maxTorqSweep = 1:1:30;
slipThreshold = 0.11;
figure; hold on;
colors = turbo(length(maxTorqSweep));
for i = 1:length(maxTorqSweep)
    maxTorqNoSlip = maxTorqSweep(i);
    out = sim('Demo');
    slip = out.slipRatio.Data;
    t    = out.slipRatio.Time;
    plot(t, slip, 'Color', colors(i,:), 'DisplayName', sprintf('%d Nm', maxTorqNoSlip));
    fprintf('Run %d / %d | maxTorqNoSlip = %d Nm\n', i, length(maxTorqSweep), maxTorqNoSlip);
end
yline(slipThreshold, 'r--', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Slip Ratio');
title('Slip ratio per initial torque');
legend('Location','eastoutside');
grid on;