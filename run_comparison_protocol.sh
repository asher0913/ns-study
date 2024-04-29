#!/bin/bash

# Set the output CSV file path
output_csv="comparison.csv"

# Initialize the CSV file with headers
echo "No. of run,Protocol,Delay(ms),Throughput(bps),Drop Rate(%)" > "$output_csv"

# Variables for TCP and UDP accumulation
tcp_delay_sum=0
tcp_throughput_sum=0
tcp_drop_sum=0
tcp_count=0

udp_delay_sum=0
udp_throughput_sum=0
udp_drop_sum=0
udp_count=0

# Counter for the number of runs
run_number=1

# Process each .tr file in the traces directory
for file in traces/*.tr; do
    while IFS=, read -r protocol delay throughput drop_rate; do
        # Append the formatted output to the CSV file
        echo "$run_number,$protocol,$delay,$throughput,$drop_rate" >> "$output_csv"
        # Accumulate values for averages based on protocol
        if [[ "$protocol" == "TCP" ]]; then
            tcp_delay_sum=$(echo "$tcp_delay_sum + $delay" | bc)
            tcp_throughput_sum=$(echo "$tcp_throughput_sum + $throughput" | bc)
            tcp_drop_sum=$(echo "$tcp_drop_sum + $drop_rate" | bc)
            ((tcp_count++))
        elif [[ "$protocol" == "UDP" ]]; then
            udp_delay_sum=$(echo "$udp_delay_sum + $delay" | bc)
            udp_throughput_sum=$(echo "$udp_throughput_sum + $throughput" | bc)
            udp_drop_sum=$(echo "$udp_drop_sum + $drop_rate" | bc)
            ((udp_count++))
        fi
    done < <(awk -f comparison.awk "$file")
    # Increment the run number
    ((run_number++))
done

# Calculate and append averages to the CSV, check for divide by zero
if [ "$tcp_count" -gt 0 ]; then
    tcp_avg_delay=$(echo "$tcp_delay_sum / $tcp_count" | bc -l)
    tcp_avg_throughput=$(echo "$tcp_throughput_sum / $tcp_count" | bc -l)
    tcp_avg_drop=$(echo "$tcp_drop_sum / $tcp_count" | bc -l)
    printf "Average,TCP,%.6f,%.8f,%.2f\n" $tcp_avg_delay $tcp_avg_throughput $tcp_avg_drop >> "$output_csv"
else
    echo "Average,TCP,0.000000,0.00000000,0.00" >> "$output_csv"
fi

if [ "$udp_count" -gt 0 ]; then
    udp_avg_delay=$(echo "$udp_delay_sum / $udp_count" | bc -l)
    udp_avg_throughput=$(echo "$udp_throughput_sum / $udp_count" | bc -l)
    udp_avg_drop=$(echo "$udp_drop_sum / $udp_count" | bc -l)
    printf "Average,UDP,%.6f,%.8f,%.2f\n" $udp_avg_delay $udp_avg_throughput $udp_avg_drop >> "$output_csv"
else
    echo "Average,UDP,0.000000,0.00000000,0.00" >> "$output_csv"
fi
