#!/bin/bash

spinner() {
    local message="$1"
    local duration="${2:-5}"  # Default 5 seconds
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    local end_time=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end_time ]; do
        printf "\r%s %s" "$message" "${chars:$i%${#chars}:1}"
        i=$(((i + 1) % ${#chars}))
        sleep 0.1
    done
    printf "\r%s Done!\n" "$message"
}

# Usage
spinner "Thinking..." 3  # Spins for 3 seconds
