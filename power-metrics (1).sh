#!/bin/bash

# Set up output file with timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")
output_file="$HOME/Desktop/power_metrics_${timestamp}.csv"

# Create CSV header
echo "Timestamp,CPU_Power,GPU_Power,ANE_Power,Package_Power" > "$output_file"
echo "Created output file: $output_file"

# Function to clean up on exit
cleanup() {
    echo -e "\nCleaning up and stopping logging..."
    pkill -f "powermetrics"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Initialize variables for metrics
cpu_power=0
gpu_power=0
ane_power=0
package_power=0

# Function to write metrics
write_metrics() {
    local ts=$(date +%s%N)
    echo "$ts,$cpu_power,$gpu_power,$ane_power,$package_power" >> "$output_file"
    echo "Logged metrics - CPU: ${cpu_power}mW, GPU: ${gpu_power}mW, ANE: ${ane_power}mW, Package: ${package_power}mW"
}

# Function to continuously log metrics
log_metrics() {
    echo "Starting power metrics logging with continuous sampling..."
    echo "Press Ctrl+C to stop logging."

    # Run powermetrics with minimal samplers needed for power
    powermetrics \
        --samplers cpu_power,gpu_power,ane_power \
        -i 100 \
        2>&1 | while IFS= read -r line; do
        if [[ $line =~ CPU\ Power:\ ([0-9]+)\ mW ]]; then
            cpu_power=${BASH_REMATCH[1]}
        elif [[ $line =~ GPU\ Power:\ ([0-9]+)\ mW ]]; then
            gpu_power=${BASH_REMATCH[1]}
        elif [[ $line =~ ANE\ Power:\ ([0-9]+)\ mW ]]; then
            ane_power=${BASH_REMATCH[1]}
        elif [[ $line =~ Combined\ Power\ \(CPU\ \+\ GPU\ \+\ ANE\):\ ([0-9]+)\ mW ]]; then
            package_power=${BASH_REMATCH[1]}
            write_metrics
        fi
    done
}

# Start logging
log_metrics