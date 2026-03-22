clear
clc

% Define your sweep values (0 to 1 since it's a percent)
%kPsweepValues = 0.03 : 0.005 : 0.13;
%initialTorqSweep = 45 : 1 : 70;

kPsweepValues = .1 : .005 : .2;
initialTorqSweep = 45:2:65;


endTimes = zeros(length(kPsweepValues), length(initialTorqSweep));
totalRuns = length(kPsweepValues) * length(initialTorqSweep);
runCount = 0;

for i = 1:length(kPsweepValues)
    for j = 1:length(initialTorqSweep)
        kP = kPsweepValues(i);
        initialTorq = initialTorqSweep(j);
        out = sim('Demo');
        
        runCount = runCount + 1;
        fprintf('Run %d / %d | kP = %.3f | initTorq = %d\n', ...
                runCount, totalRuns, kP, initialTorq);
        
        endTimes(i,j) = out.runTime(end);
    end
end

% 3D surface plot
figure;
[KP, IT] = meshgrid(kPsweepValues, initialTorqSweep);
surf(KP', IT', endTimes);
xlabel('kP');
ylabel('Initial Torque');
zlabel('Run Time (s)');
title('kP vs Initial Torque vs Run Time');
colorbar;
grid on;