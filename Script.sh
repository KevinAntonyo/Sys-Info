#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# Clear screen and hide cursor
clear
tput civis

# Trap CTRL+C to restore cursor on exit
trap "tput cnorm; echo; exit" SIGINT

print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ███████╗██╗   ██╗███████╗    ██╗███╗   ██╗███████╗ ██████╗ "
    echo "  ██╔════╝╚██╗ ██╔╝██╔════╝    ██║████╗  ██║██╔════╝██╔═══██╗"
    echo "  ███████╗ ╚████╔╝ ███████╗    ██║██╔██╗ ██║█████╗  ██║   ██║"
    echo "  ╚════██║  ╚██╔╝  ╚════██║    ██║██║╚██╗██║██╔══╝  ██║   ██║"
    echo "  ███████║   ██║   ███████║    ██║██║ ╚████║██║     ╚██████╔╝"
    echo "  ╚══════╝   ╚═╝   ╚══════╝    ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝ "
    echo -e "${RESET}"
}

draw_bar() {
    local val=$1
    local max=$2
    local width=30
    local filled=$(( val * width / max ))
    local empty=$(( width - filled ))
    local bar="${GREEN}["
    for ((i=0; i<filled; i++)); do
        if (( i > width * 7 / 10 )); then bar+="${RED}█"
        elif (( i > width * 4 / 10 )); then bar+="${YELLOW}█"
        else bar+="${GREEN}█"
        fi
    done
    for ((i=0; i<empty; i++)); do bar+="${RESET}░"; done
    bar+="${GREEN}]${RESET}"
    echo -e "$bar"
}

get_cpu_usage() {
    read cpu a b c idle _ < /proc/stat
    sleep 0.3
    read cpu a2 b2 c2 idle2 _ < /proc/stat
    local total=$(( (a2+b2+c2+idle2) - (a+b+c+idle) ))
    local used=$(( (a2+b2+c2) - (a+b+c) ))
    echo $(( used * 100 / total ))
}

while true; do
    clear
    print_banner

    # --- Date & Time ---
    echo -e "${MAGENTA}${BOLD}  🕐  $(date '+%A, %B %d %Y  |  %H:%M:%S')${RESET}"
    echo -e "${CYAN}  ─────────────────────────────────────────────────${RESET}"

    # --- Hostname & User ---
    echo -e "${BOLD}  👤  User:     ${GREEN}$(whoami)${RESET}  ${BOLD}@  ${CYAN}$(hostname)${RESET}"

    # --- OS Info ---
    os=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    kernel=$(uname -r)
    echo -e "${BOLD}  🐧  OS:       ${YELLOW}$os${RESET}"
    echo -e "${BOLD}  ⚙️   Kernel:   ${YELLOW}$kernel${RESET}"

    # --- Uptime ---
    uptime_str=$(uptime -p | sed 's/up //')
    echo -e "${BOLD}  ⏱️   Uptime:   ${GREEN}$uptime_str${RESET}"
    echo -e "${CYAN}  ─────────────────────────────────────────────────${RESET}"

    # --- CPU ---
    cpu_usage=$(get_cpu_usage)
    echo -e "${BOLD}  💻  CPU Usage: ${cpu_usage}%${RESET}"
    echo -n "      "
    draw_bar $cpu_usage 100

    # --- RAM ---
    total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    free_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    used_mem=$(( total_mem - free_mem ))
    mem_pct=$(( used_mem * 100 / total_mem ))
    used_mb=$(( used_mem / 1024 ))
    total_mb=$(( total_mem / 1024 ))
    echo -e "${BOLD}  🧠  RAM:       ${used_mb}MB / ${total_mb}MB  (${mem_pct}%)${RESET}"
    echo -n "      "
    draw_bar $mem_pct 100

    # --- Disk ---
    disk_info=$(df -h / | tail -1)
    disk_used=$(echo $disk_info | awk '{print $3}')
    disk_total=$(echo $disk_info | awk '{print $2}')
    disk_pct=$(echo $disk_info | awk '{print $5}' | tr -d '%')
    echo -e "${BOLD}  💾  Disk:      ${disk_used} / ${disk_total}  (${disk_pct}%)${RESET}"
    echo -n "      "
    draw_bar $disk_pct 100

    echo -e "${CYAN}  ─────────────────────────────────────────────────${RESET}"

    # --- Network ---
    ip_addr=$(hostname -I | awk '{print $1}')
    echo -e "${BOLD}  🌐  Local IP:  ${GREEN}${ip_addr}${RESET}"

    # --- Top Process ---
    top_proc=$(ps -eo comm,%cpu --sort=-%cpu | awk 'NR==2{print $1, $2"%"}')
    echo -e "${BOLD}  🔥  Top CPU:   ${RED}${top_proc}${RESET}"

    echo -e "${CYAN}  ─────────────────────────────────────────────────${RESET}"
    echo -e "${YELLOW}  Press CTRL+C to exit  |  Refreshes every second${RESET}"

    sleep 1
done
