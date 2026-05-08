@echo off
setlocal EnableDelayedExpansion

:: Enable ANSI colors (Windows 10+)
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: Colors
set "CYAN=[36m"
set "GREEN=[32m"
set "YELLOW=[33m"
set "RED=[31m"
set "MAGENTA=[35m"
set "WHITE=[97m"
set "GRAY=[90m"
set "BOLD=[1m"
set "RESET=[0m"

:loop
cls

:: Banner
echo %CYAN%
echo   ███████╗██╗   ██╗███████╗    ██╗███╗   ██╗███████╗ ██████╗
echo   ██╔════╝╚██╗ ██╔╝██╔════╝    ██║████╗  ██║██╔════╝██╔═══██╗
echo   ███████╗ ╚████╔╝ ███████╗    ██║██╔██╗ ██║█████╗  ██║   ██║
echo   ╚════██║  ╚██╔╝  ╚════██║    ██║██║╚██╗██║██╔══╝  ██║   ██║
echo   ███████║   ██║   ███████║    ██║██║ ╚████║██║     ╚██████╔╝
echo   ╚══════╝   ╚═╝   ╚══════╝    ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝
echo %RESET%

:: Date & Time
echo %MAGENTA%  ^>  %DATE%  ^|  %TIME:~0,8%%RESET%
echo %CYAN%  ─────────────────────────────────────────────────%RESET%

:: User & Hostname
echo %WHITE%  User:     %GREEN%%USERNAME%%WHITE%  @  %CYAN%%COMPUTERNAME%%RESET%

:: OS Info
for /f "tokens=2 delims==" %%a in ('wmic os get Caption /value 2^>nul') do set "OS=%%a"
echo %WHITE%  OS:       %YELLOW%%OS%%RESET%

:: Uptime
for /f "tokens=2 delims==" %%a in ('wmic os get LastBootUpTime /value 2^>nul') do set "BOOT=%%a"
set "BOOT_DATE=!BOOT:~0,8!"
echo %WHITE%  Boot:     %GREEN%!BOOT_DATE:~0,4!-!BOOT_DATE:~4,2!-!BOOT_DATE:~6,2! !BOOT:~8,2!:!BOOT:~10,2!:!BOOT:~12,2!%RESET%

echo %CYAN%  ─────────────────────────────────────────────────%RESET%

:: CPU Usage
for /f "skip=1 tokens=2 delims=," %%a in ('wmic cpu get LoadPercentage /format:csv 2^>nul') do (
    set "CPU=%%a"
    goto :cpu_done
)
:cpu_done
if not defined CPU set "CPU=0"
set /a CPU_INT=%CPU%
call :draw_bar %CPU_INT% 100 CPU_BAR
echo %WHITE%  CPU:      %GREEN%%CPU_INT%% %RESET%
echo   !CPU_BAR!

:: RAM
for /f "skip=1 tokens=2 delims=," %%a in ('wmic os get TotalVisibleMemorySize /format:csv 2^>nul') do set "TOTAL_MEM=%%a" & goto :total_mem_done
:total_mem_done
for /f "skip=1 tokens=2 delims=," %%a in ('wmic os get FreePhysicalMemory /format:csv 2^>nul') do set "FREE_MEM=%%a" & goto :free_mem_done
:free_mem_done
set /a USED_MEM=(%TOTAL_MEM% - %FREE_MEM%) / 1024
set /a TOTAL_MB=%TOTAL_MEM% / 1024
set /a MEM_PCT=USED_MEM * 100 / TOTAL_MB
call :draw_bar %MEM_PCT% 100 MEM_BAR
echo %WHITE%  RAM:      %GREEN%%USED_MEM%MB / %TOTAL_MB%MB  (%MEM_PCT%%%)%RESET%
echo   !MEM_BAR!

:: Disk
for /f "tokens=3" %%a in ('dir /-c c:\ 2^>nul ^| find "bytes free"') do set "DISK_FREE_B=%%a"
for /f "skip=1 tokens=2 delims=," %%a in ('wmic logicaldisk where "DeviceID='C:'" get Size /format:csv 2^>nul') do set "DISK_TOTAL_B=%%a" & goto :disk_done
:disk_done
set /a DISK_FREE_GB=%DISK_FREE_B:,=% / 1073741824 2>nul
for /f %%a in ('powershell -command "[math]::Round(%DISK_TOTAL_B% / 1GB, 0)" 2^>nul') do set "DISK_TOTAL_GB=%%a"
set /a DISK_USED_GB=%DISK_TOTAL_GB% - %DISK_FREE_GB%
set /a DISK_PCT=%DISK_USED_GB% * 100 / %DISK_TOTAL_GB%
call :draw_bar %DISK_PCT% 100 DISK_BAR
echo %WHITE%  Disk C:   %GREEN%%DISK_USED_GB%GB / %DISK_TOTAL_GB%GB  (%DISK_PCT%%%)%RESET%
echo   !DISK_BAR!

echo %CYAN%  ─────────────────────────────────────────────────%RESET%

:: IP Address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "IP=%%a"
    goto :ip_done
)
:ip_done
echo %WHITE%  Local IP: %GREEN%%IP:~1%%RESET%

:: Top Process
for /f "skip=1 tokens=1 delims=," %%a in ('wmic process get Name /format:csv 2^>nul ^| sort') do (
    set "TOP_PROC=%%a"
    goto :proc_done
)
:proc_done
echo %WHITE%  Top Proc: %RED%%TOP_PROC%%RESET%

echo %CYAN%  ─────────────────────────────────────────────────%RESET%
echo %YELLOW%  Press CTRL+C to exit  ^|  Refreshes every 2 seconds%RESET%

timeout /t 2 /nobreak >nul
goto :loop

:: Draw bar function
:draw_bar
set /a _filled=%1 * 30 / %2
set /a _empty=30 - _filled
set "_bar=["
for /l %%i in (1,1,%_filled%) do set "_bar=!_bar!#"
for /l %%i in (1,1,%_empty%) do set "_bar=!_bar!."
set "_bar=!_bar!]"
set "%3=!_bar!"
exit /b
