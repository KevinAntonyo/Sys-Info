#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'
WIDTH=70

# Hide cursor, clear ONCE on start
tput civis
clear

# Restore cursor and clear on exit
trap 'tput cnorm; tput sgr0; echo; exit' SIGINT SIGTERM EXIT

# Print a line padded to a fixed width so old text never shows through.
# We pad based on VISIBLE length (strip ANSI codes) not the raw string length.
line() {
    local raw="$1"
    local visible
    visible=$(echo -e "$raw" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$(( WIDTH - ${#visible} ))
    (( pad < 0 )) && pad=0
    printf "%b" "$raw"
    printf '%*s\n' "$pad" ""
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
    echo -n "$bar"
}

get_cpu_usage() {
    read cpu a b c idle _ < /proc/stat
    sleep 0.3
    read cpu a2 b2 c2 idle2 _ < /proc/stat
    local total=$(( (a2+b2+c2+idle2) - (a+b+c+idle) ))
    local used=$(( (a2+b2+c2) - (a+b+c) ))
    (( total <= 0 )) && { echo 0; return; }
    echo $(( used * 100 / total ))
}

print_banner() {
    line "${CYAN}${BOLD}  ███████╗██╗   ██╗███████╗    ██╗███╗   ██╗███████╗ ██████╗ ${RESET}"
    line "${CYAN}${BOLD}  ██╔════╝╚██╗ ██╔╝██╔════╝    ██║████╗  ██║██╔════╝██╔═══██╗${RESET}"
    line "${CYAN}${BOLD}  ███████╗ ╚████╔╝ ███████╗    ██║██╔██╗ ██║█████╗  ██║   ██║${RESET}"
    line "${CYAN}${BOLD}  ╚════██║  ╚██╔╝  ╚════██║    ██║██║╚██╗██║██╔══╝  ██║   ██║${RESET}"
    line "${CYAN}${BOLD}  ███████║   ██║   ███████║    ██║██║ ╚████║██║     ╚██████╔╝${RESET}"
    line "${CYAN}${BOLD}  ╚══════╝   ╚═╝   ╚══════╝    ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝ ${RESET}"
}

while true; do
    tput cup 0 0

    print_banner
    line ""

    # --- Date & Time ---
    line "${MAGENTA}${BOLD}  🕐  $(date '+%A, %B %d %Y  |  %H:%M:%S')${RESET}"
    line "${CYAN}  ─────────────────────────────────────────────────${RESET}"

    # --- Hostname & User ---
    line "${BOLD}  👤  User:     ${GREEN}$(whoami)${RESET}  ${BOLD}@  ${CYAN}$(hostname)${RESET}"

    # --- OS Info ---
    os=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    kernel=$(uname -r)
    line "${BOLD}  🐧  OS:       ${YELLOW}$os${RESET}"
    line "${BOLD}  ⚙️   Kernel:   ${YELLOW}$kernel${RESET}"

    # --- Uptime ---
    uptime_str=$(uptime -p | sed 's/up //')
    line "${BOLD}  ⏱️   Uptime:   ${GREEN}$uptime_str${RESET}"
    line "${CYAN}  ─────────────────────────────────────────────────${RESET}"

    # --- CPU ---
    cpu_usage=$(get_cpu_usage)
    line "${BOLD}  💻  CPU Usage: ${cpu_usage}%${RESET}"
    echo -n "      "
    draw_bar "$cpu_usage" 100
    printf "\033[K\n"

    # --- RAM ---
    total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    free_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    used_mem=$(( total_mem - free_mem ))
    mem_pct=$(( used_mem * 100 / total_mem ))
    used_mb=$(( used_mem / 1024 ))
    total_mb=$(( total_mem / 1024 ))
    line "${BOLD}  🧠  RAM:       ${used_mb}MB / ${total_mb}MB  (${mem_pct}%)${RESET}"
    echo -n "      "
    draw_bar "$mem_pct" 100
    printf "\033[K\n"

    # --- Disk ---
    disk_info=$(df -h / | tail -1)
    disk_used=$(echo $disk_info | awk '{print $3}')
    disk_total=$(echo $disk_info | awk '{print $2}')
    disk_pct=$(echo $disk_info | awk '{print $5}' | tr -d '%')
    line "${BOLD}  💾  Disk:      ${disk_used} / ${disk_total}  (${disk_pct}%)${RESET}"
    echo -n "      "
    draw_bar "$disk_pct" 100
    printf "\033[K\n"

    line "${CYAN}  ─────────────────────────────────────────────────${RESET}"

    # --- Network ---
    ip_addr=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
    if [ -z "$ip_addr" ]; then
        ip_addr=$(ip addr show | awk '/inet / && !/127.0.0.1/ {print $2}' | cut -d/ -f1 | head -1)
    fi
    line "${BOLD}  🌐  Local IP:  ${GREEN}${ip_addr}${RESET}"

    # --- Top Process ---
    top_proc=$(ps -eo comm,%cpu --sort=-%cpu | awk 'NR==2{print $1, $2"%"}')
    line "${BOLD}  🔥  Top CPU:   ${RED}${top_proc}${RESET}"

    line "${CYAN}  ─────────────────────────────────────────────────${RESET}"
    line "${YELLOW}  Press CTRL+C to exit  |  Live updating${RESET}"

    tput ed
    sleep 0.7
done
