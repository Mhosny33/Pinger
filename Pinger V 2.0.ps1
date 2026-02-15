# ==============================
# SAFE CENTERING HELPER
# ==============================

function Write-Centered {
    param(
        [string]$Text,
        [string]$Color = "White"
    )

    $width = 80
    try { $width = $Host.UI.RawUI.WindowSize.Width } catch {}

    if (-not $width -or $width -lt 20) {
        $width = 80
    }

    $padding = [int][Math]::Floor(($width - $Text.Length) / 2)
    if ($padding -lt 0) { $padding = 0 }

    Write-Host (" " * $padding + $Text) -ForegroundColor $Color
}

# ==============================
# ASCII HEADER (SAFE)
# ==============================

function Show-Header {
    Clear-Host

    $width = 80
    try { $width = $Host.UI.RawUI.WindowSize.Width } catch {}

    if ($width -lt 60) { $width = 80 }

    $line = "=" * $width
    Write-Host $line -ForegroundColor DarkGray
    Write-Host ""

    Write-Centered "########  #### ##    ##  ######  ######## ########" Cyan
    Write-Centered "##     ##  ##  ###   ## ##    ## ##       ##     ##" Cyan
    Write-Centered "##     ##  ##  ####  ## ##       ##       ##     ##" Cyan
    Write-Centered "########   ##  ## ## ## ##   #### ######   ########" Cyan
    Write-Centered "##         ##  ##  #### ##    ##  ##       ##   ##" Cyan
    Write-Centered "##        #### ##   ###  ######  ######## ##    ##" Cyan

    Write-Host ""
    Write-Centered "CONTINUOUS NETWORK MONITOR" DarkCyan
    Write-Host ""
    Write-Host $line -ForegroundColor DarkGray
    Write-Host ""
}

# ==============================
# PING FUNCTION
# ==============================

function Test-SinglePing {
    param([string]$Target)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($Target, 2000)

        if ($reply.Status -eq "Success") {
            Write-Host " ONLINE ($($reply.RoundtripTime)ms)" -ForegroundColor Green
            return [PSCustomObject]@{
                Time    = $timestamp
                Target  = $Target
                Status  = "Online"
                Latency = "$($reply.RoundtripTime)ms"
            }
        }
        else {
            Write-Host " OFFLINE" -ForegroundColor Red
            return [PSCustomObject]@{
                Time    = $timestamp
                Target  = $Target
                Status  = "Offline"
                Latency = "N/A"
            }
        }
    }
    catch {
        Write-Host " ERROR" -ForegroundColor Magenta
        return [PSCustomObject]@{
            Time    = $timestamp
            Target  = $Target
            Status  = "Error"
            Latency = "N/A"
        }
    }
    finally {
        if ($ping) { $ping.Dispose() }
    }
}

# ==============================
# EXPORT FUNCTION (ONLY PROBLEMS)
# ==============================

function Export-Results {
    param($Results)

    $problemDevices = $Results | Where-Object { $_.Status -ne "Online" }

    if (-not $problemDevices -or $problemDevices.Count -eq 0) {
        Write-Host ""
        Write-Centered "All devices are ONLINE. Nothing to export." Green
        Write-Host ""
        return
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "PingProblems_$timestamp.txt"

    $content = @()
    $content += "PINGER - PROBLEM DEVICES EXPORT"
    $content += "Generated: $(Get-Date)"
    $content += "----------------------------------------"

    foreach ($r in $problemDevices) {
        $content += "$($r.Time) | $($r.Target) | $($r.Status) | $($r.Latency)"
    }

    $content | Out-File $fileName -Encoding UTF8

    Write-Host ""
    Write-Centered "Problem devices exported to $fileName" Yellow
    Write-Host ""
}

# ==============================
# MAIN LOOP
# ==============================

while ($true) {

    Show-Header

    Write-Centered "MAIN MENU" Cyan
    Write-Centered ("-" * 20) DarkGray
    Write-Host ""

    Write-Centered "1. Ping devices"
    Write-Centered "2. Quick test"
    Write-Centered "3. Exit"

    Write-Host ""
    Write-Centered ("-" * 20) DarkGray
    Write-Host ""

    $choice = Read-Host "Select option"

    switch ($choice) {

        '1' {
            Show-Header
            Write-Host "Enter IPs or hostnames (space separated)"
            $inputTargets = Read-Host "Targets"
            $targets = $inputTargets -split '\s+'

            $results = @()

            foreach ($target in $targets) {
                Write-Host "`n$target"
                $result = Test-SinglePing -Target $target
                if ($result) { $results += $result }
            }

            Write-Host ""
            $exportChoice = Read-Host "Export problem devices to text file? (Y/N)"

            if ($exportChoice -match "^[Yy]$") {
                Export-Results -Results $results
            }

            Write-Host "`nPress any key..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }

        '2' {
            Show-Header
            Write-Host "Running quick test..."
            $targets = "8.8.8.8 google.com localhost 192.168.255.255 badhost" -split '\s+'

            $results = @()

            foreach ($target in $targets) {
                Write-Host "`n$target"
                $result = Test-SinglePing -Target $target
                if ($result) { $results += $result }
            }

            Write-Host ""
            $exportChoice = Read-Host "Export problem devices to text file? (Y/N)"

            if ($exportChoice -match "^[Yy]$") {
                Export-Results -Results $results
            }

            Write-Host "`nPress any key..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }

        '3' {
            Write-Host "Goodbye!" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            exit
        }

        default {
            Write-Host "Invalid choice!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
