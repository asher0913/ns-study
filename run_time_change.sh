#!/bin/bash

# Define the log file for all outputs
log_file="simulation_time_change.csv"

# Assign the first command line argument to a variable
tcl_script=$1

# Create directories for storing trace and NAM files, if they don't already exist
mkdir -p traces
mkdir -p nams

# Loop to run simulations 20 times
for i in {0..19}
do
    # Define the filenames for the trace and NAM files for this iteration
    trace_filename="traces/run_${i}.tr"
    nam_filename="nams/run_${i}.nam"
    simulation_time=$(($i*100 + 100))
    # Run the simulation script with the current trace and NAM filenames as arguments
    ns time.tcl $trace_filename $nam_filename $simulation_time
done


# Initialize total sum variables
total_delay=0.0
total_throughput=0.0
total_drop_rate=0.0
count=0

# Iterate over all .tr files in the traces directory
simulation_time=100
echo "Simulation Time(s),Delay(ms),Throughput(bps),Drop Rate(%)" >> $log_file
for file in traces/*.tr
do
    # Use awk script to analyze each file and read the output
    read delay throughput drop_rate <<< $(awk -f analyze.awk "$file")
    # Accumulate results from each file
    printf "%d,%.6f,%.2f,%.6f\n" $simulation_time $delay $throughput $drop_rate >> $log_file
    total_delay=$(awk "BEGIN{print $total_delay + $delay}")
    total_throughput=$(awk "BEGIN{print $total_throughput + $throughput}")
    total_drop_rate=$(awk "BEGIN{print $total_drop_rate + $drop_rate}")
    ((count++))
    ((simulation_time+=100))
done

# Calculate average values
if [ $count -gt 0 ]; then
    avg_delay=$(awk "BEGIN{print $total_delay / $count}")
    avg_throughput=$(awk "BEGIN{print $total_throughput / $count}")
    avg_drop_rate=$(awk "BEGIN{print $total_drop_rate / $count}")
    
    # Output average values
    printf "Average,%.6f,%.2f,%.6f\n" $avg_delay $avg_throughput $avg_drop_rate >> $log_file
else
    echo "No trace files found for analysis." >> $log_file
fi


