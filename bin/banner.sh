#!/usr/bin/env zsh

ESC="\033"
# Polar Night (nord0 - nord3: Dark grays/blues for backgrounds##  #)

RED="${ESC}[38;2;191;97;106m"   # #bf616a - Red (errors)
ORG="${ESC}[38;2;208;135;112m"  # #d08770 - Orange (advanced/danger)
YLW="${ESC}[38;2;235;203;139m"  # #ebcb8b - Yellow (warnings)
GRN="${ESC}[38;2;163;190;140m"  # #a3be8c - Green (success)
BLU="${ESC}[38;2;94;129;172m"   # #5e81ac - Deep blue
PUR="${ESC}[38;2;180;142;173m"  # #b48ead - Purple (numbers/uncommon)


RST="${ESC}[0m"
  
printf '%b%s%b\n' "$RED" "░█▀▄░█▀▀░█▄█░▀█▀░█▀█░█▀█" "$RST"
printf '%b%s%b\n' "$GRN" "░█░█░█▀▀░█░█░░█░░█▀█░█░█" "$RST"
printf '%b%s%b\n' "$BLU" "░▀▀░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀░▀" "$RST"

# printf '%b%s%b\n' "$BLU" "░█▀▄░█▀▀░█▄█░▀█▀░█▀█░█▀█" "$RST"
# printf '%b%s%b\n' "$GRN" "░█░█░█▀▀░█░█░░█░░█▀█░█░█" "$RST"
# printf '%b%s%b\n' "$PUR" "░▀▀░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀░▀" "$RST"
# 
# printf '%b%s%b\n' "$RED" "░█▀▄░█▀▀░█▄█░▀█▀░█▀█░█▀█" "$RST"
# printf '%b%s%b\n' "$ORG" "░█░█░█▀▀░█░█░░█░░█▀█░█░█" "$RST"
# printf '%b%s%b\n' "$YLW" "░▀▀░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀░▀" "$RST"

printf '\n'
