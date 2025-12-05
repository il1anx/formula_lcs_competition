% BUTTERWORTH_BENCHMARK.M
%
% Measures single-core CPU performance by repeatedly applying an 8th-order
% Butterworth filter to a large signal array. This simulates the kind of
% computational load common in real-time signal processing and guidance systems.

function run_butterworth_benchmark()
    % --- Configuration ---
    TARGET_DURATION_MIN = 3;            % Target duration for the benchmark in minutes
    SAMPLE_INTERVAL_SEC = 5;            % How often to record a performance sample (in seconds)
    SIGNAL_LENGTH = 100000;             % Length of the dummy signal array (number of data points)
    
    % --- Filter Design (8th-Order Butterworth Bandpass) ---
    % Designing a complex filter ensures a substantial workload during the 'filter' call.
    Fs = 1000; % Sampling frequency (Hz)
    Fpass1 = 100; % First passband frequency
    Fpass2 = 200; % Second passband frequency
    FilterOrder = 8;
    
    % Use designfilt to create the digital filter structure (single-core operation)
    D = designfilt('bandpassiir', ...
        'FilterOrder', FilterOrder, ...
        'PassbandFrequency1', Fpass1, ...
        'PassbandFrequency2', Fpass2, ...
        'PassbandRipple', 0.5, ...
        'SampleRate', Fs);
    
    % Pre-generate the dummy signal data (single-core operation)
    % This represents raw sensor input that needs filtering.
    x = randn(SIGNAL_LENGTH, 1);
    
    % --- Benchmark Setup ---
    target_duration_sec = TARGET_DURATION_MIN * 60;
    time_points = []; 
    filter_ops_per_sec = []; 
    
    total_time_elapsed = 0;
    total_filter_operations = 0;
    last_sample_time = 0;
    
    % --- Benchmark Start ---
    fprintf('Starting Butterworth Filter benchmark for %.0f minutes.\n', TARGET_DURATION_MIN);
    fprintf('Signal Length: %d samples. Filter Order: %d.\n', SIGNAL_LENGTH, FilterOrder);
    
    start_time = tic; % Start the overall timer

    % Main loop that runs until the target duration is reached
    while total_time_elapsed < target_duration_sec
        
        % --- Core Single-Core Workload ---
        % The 'filter' function call is the computationally intensive part.
        % It is generally highly optimized but runs on a single core for this task.
        
        % The variable 'y' stores the filtered output (the result is discarded 
        % to keep the benchmark focused purely on the calculation speed).
        y = filter(D, x); 
        
        % --- Update Metrics ---
        total_filter_operations = total_filter_operations + 1;
        total_time_elapsed = toc(start_time);
        
        % --- Sample Logging ---
        if (total_time_elapsed - last_sample_time) >= SAMPLE_INTERVAL_SEC
            
            % Calculate performance: number of full filter operations per second
            current_filter_ops_per_sec = total_filter_operations / total_time_elapsed;
            
            % Store results
            time_points(end+1) = total_time_elapsed;
            filter_ops_per_sec(end+1) = current_filter_ops_per_sec;
            
            % Display status update
            fprintf('  Time: %s / %s (%.1f%%) | Performance: %.2f filter ops/sec\n', ...
                    datestr(seconds(total_time_elapsed), 'MM:SS'), ...
                    datestr(seconds(target_duration_sec), 'MM:SS'), ...
                    (total_time_elapsed / target_duration_sec) * 100, ...
                    current_filter_ops_per_sec);
            
            last_sample_time = total_time_elapsed;
        end
    end
    
    % --- Final Results and Plotting ---
    
    final_avg_performance = total_filter_operations / total_time_elapsed;
    fprintf('\n--- Benchmark Complete ---\n');
    fprintf('Total duration: %.2f seconds (%.2f minutes)\n', total_time_elapsed, total_time_elapsed / 60);
    fprintf('Final Average Single-Core Performance (Butterworth): %.2f filter ops/sec\n', final_avg_performance);
    
    % Plotting the results
    figure('Name', 'Single-Core CPU Performance (Butterworth Filter)');
    plot(time_points, filter_ops_per_sec, '-o', 'LineWidth', 2, 'MarkerSize', 6, 'Color', [0 0.447 0.741]); % Blue color
    grid on;
    title('Single-Core CPU Performance Over Time (Filter Operations/Second)');
    xlabel('Time Elapsed (seconds)');
    ylabel('Performance (Filter Operations/sec)');
    
    % Add lines for context
    hold on;
    yline(final_avg_performance, '--r', sprintf('Final Avg: %.2f ops/sec', final_avg_performance));
    
    % Highlight the peak performance 
    [peak_perf, peak_idx] = max(filter_ops_per_sec);
    plot(time_points(peak_idx), peak_perf, 'p', 'MarkerSize', 12, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
    legend('Performance Samples', 'Final Average', 'Peak Performance', 'Location', 'southeast');
    
    hold off;
    
    disp(' ');
    disp('The plot shows how many full filter calculations your CPU can sustain per second.');
    disp('This type of calculation is common in guidance systems for noise reduction and state estimation.');
end

% Execute the function
run_butterworth_benchmark();