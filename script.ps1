# Hide cursor
[Console]::CursorVisible = $false

# Trap CTRL+C to restore cursor
[Console]::TreatControlCAsInput = $false
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    [Console]::CursorVisible = $true
}

function Draw-Bar {
    param($val, $max, $width = 30)
    $filled = [math]::Round($val * $width / $max)
    $empty = $width - $filled
    $bar = "["
    for ($i = 0; $i -lt $filled; $i++) {
        if ($i -gt $width * 0.7) { $bar += "#" }
        else { $bar += "#" }
    }
    $bar += ("." * $empty) + "]"
    return $bar
}

function Get-BarColor {
    param($pct)
    if ($pct -ge 80) { return "Red" }
    elseif ($pct -ge 50) { return "Yellow" }
    else { return "Green" }
}

function Write-ColorBar {
    param($val, $max, $width = 30)
    $filled = [math]::Round($val * $width / $max)
    $empty = $width - $filled
    $color = Get-BarColor $val
    Write-Host "  [" -NoNewline -ForegroundColor White
    Write-Host ("#" * $filled) -NoNewline -ForegroundColor $color
    Write-Host ("." * $empty) -NoNewline -ForegroundColor DarkGray
    Write-Host "]" -ForegroundColor White
}

function Write-Banner {
    $banner = @"
  ███████╗██╗   ██╗███████╗    ██╗███╗   ██╗███████╗ ██████╗
  ██╔════╝╚██╗ ██╔╝██╔════╝    ██║████╗  ██║██╔════╝██╔═══██╗
  ███████╗ ╚████╔╝ ███████╗    ██║██╔██╗ ██║█████╗  ██║   ██║
  ╚════██║  ╚██╔╝  ╚════██║    ██║██║╚██╗██║██╔══╝  ██║   ██║
  ███████║   ██║   ███████║    ██║██║ ╚████║██║     ╚██████╔╝
  ╚══════╝   ╚═╝   ╚══════╝    ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝
"@
    Write-Host $banner -ForegroundColor Cyan
}

function Write-Divider {
    Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor Cyan
}

while ($true) {
    Clear-Host
    Write-Banner

    # Date & Time
    Write-Host "  🕐  $(Get-Date -Format 'dddd, MMMM dd yyyy  |  HH:mm:ss')" -ForegroundColor Magenta
    Write-Divider

    # User & Hostname
    Write-Host "  👤  User:     " -NoNewline -ForegroundColor White
    Write-Host "$env:USERNAME" -NoNewline -ForegroundColor Green
    Write-Host "  @  " -NoNewline
    Write-Host "$env:COMPUTERNAME" -ForegroundColor Cyan

    # OS Info
    $os = (Get-CimInstance Win32_OperatingSystem)
    Write-Host "  🖥️   OS:       " -NoNewline -ForegroundColor White
    Write-Host "$($os.Caption)" -ForegroundColor Yellow

    # Uptime
    $uptime = (Get-Date) - $os.LastBootUpTime
    $uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
    Write-Host "  ⏱️   Uptime:   " -NoNewline -ForegroundColor White
    Write-Host $uptimeStr -ForegroundColor Green
    Write-Divider

    # CPU Usage
    $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $cpuInt = [int]$cpu
    Write-Host "  💻  CPU Usage: " -NoNewline -ForegroundColor White
    Write-Host "$cpuInt%" -ForegroundColor (Get-BarColor $cpuInt)
    Write-ColorBar $cpuInt 100

    # RAM
    $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $freeMem  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $usedMem  = [math]::Round($totalMem - $freeMem, 1)
    $memPct   = [int]($usedMem / $totalMem * 100)
    Write-Host "  🧠  RAM:       " -NoNewline -ForegroundColor White
    Write-Host "${usedMem}GB / ${totalMem}GB  ($memPct%)" -ForegroundColor (Get-BarColor $memPct)
    Write-ColorBar $memPct 100

    # Disk
    $disk = Get-PSDrive C
    $diskUsed  = [math]::Round($disk.Used / 1GB, 1)
    $diskTotal = [math]::Round(($disk.Used + $disk.Free) / 1GB, 1)
    $diskPct   = [int]($diskUsed / $diskTotal * 100)
    Write-Host "  💾  Disk (C:): " -NoNewline -ForegroundColor White
    Write-Host "${diskUsed}GB / ${diskTotal}GB  ($diskPct%)" -ForegroundColor (Get-BarColor $diskPct)
    Write-ColorBar $diskPct 100
    Write-Divider

    # IP Address
    $ip = (Get-NetIPAddress -AddressFamily IPv4 |
           Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } |
           Select-Object -First 1).IPAddress
    Write-Host "  🌐  Local IP:  " -NoNewline -ForegroundColor White
    Write-Host $ip -ForegroundColor Green

    # Top CPU Process
    $topProc = Get-Process | Sort-Object CPU -Descending | Select-Object -First 1
    Write-Host "  🔥  Top CPU:   " -NoNewline -ForegroundColor White
    Write-Host "$($topProc.Name)  ($([math]::Round($topProc.CPU, 1))s CPU time)" -ForegroundColor Red
    Write-Divider

    Write-Host "  Press CTRL+C to exit  |  Refreshes every second" -ForegroundColor Yellow

    Start-Sleep -Seconds 1
}
