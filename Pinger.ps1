
function Show-Header {
    Clear-Host
    Write-Host  -ForegroundColor Cyan
    Write-Host "QUICK PING TOOL - CONTINUOUS MODE" -ForegroundColor Cyan
    Write-Host  -ForegroundColor Cyan
    Write-Host ""
}

function Test-SinglePing {
    param(
        [string]$Target,
        [int]$Timeout = 2000
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $originalTarget = $Target
    
    $isIPAddress = $false
    if ($Target -match '^\d+\.\d+\.\d+\.\d+$') {
        $isIPAddress = $true
        $ipAddress = $Target
    } elseif ($Target -eq 'localhost') {
        $isIPAddress = $true
        $ipAddress = '127.0.0.1'
    }
    
    if (-not $isIPAddress) {
        try {
            Write-Host "  Resolving..." -ForegroundColor Gray -NoNewline
            $resolvedIPs = [System.Net.Dns]::GetHostAddresses($Target)
            if ($resolvedIPs.Count -gt 0) {
                $ipAddress = $resolvedIPs[0].IPAddressToString
                Write-Host " OK" -ForegroundColor Gray
            } else {
                Write-Host " NO DNS" -ForegroundColor Red
                return [PSCustomObject]@{
                    Target = $originalTarget
                    Status = "DNS Error"
                    IP = "N/A"
                    Latency = "N/A"
                    Error = "No DNS records"
                    Timestamp = $timestamp
                }
            }
        }
        catch {
            Write-Host " NOT FOUND" -ForegroundColor Red
            return [PSCustomObject]@{
                Target = $originalTarget
                Status = "DNS Error"
                IP = "N/A"
                Latency = "N/A"
                Error = "Host not found"
                Timestamp = $timestamp
            }
        }
    } else {
        $ipAddress = $Target
    }
    
    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        if ($Timeout -lt 100) { $Timeout = 100 }
        if ($Timeout -gt 10000) { $Timeout = 10000 }
        
        Write-Host "  Pinging..." -ForegroundColor Gray -NoNewline
        $reply = $ping.Send($ipAddress, $Timeout)
        
        if ($reply.Status -eq 'Success') {
            Write-Host " ONLINE" -ForegroundColor Green
            return [PSCustomObject]@{
                Target = $originalTarget
                Status = "Online"
                IP = $reply.Address.ToString()
                Latency = "$($reply.RoundtripTime)ms"
                Error = $null
                Timestamp = $timestamp
            }
        } else {
            Write-Host " OFFLINE" -ForegroundColor Red
            $status = if ($reply.Status -eq 'TimedOut') { "Timeout" } else { "Offline" }
            return [PSCustomObject]@{
                Target = $originalTarget
                Status = $status
                IP = "N/A"
                Latency = "N/A"
                Error = $reply.Status.ToString()
                Timestamp = $timestamp
            }
        }
    }
    catch {
        Write-Host " ERROR" -ForegroundColor Red
        return [PSCustomObject]@{
            Target = $originalTarget
            Status = "Error"
            IP = "N/A"
            Latency = "N/A"
            Error = "Ping failed"
            Timestamp = $timestamp
        }
    }
    finally {
        if ($ping) { 
            try { $ping.Dispose() } catch {} 
        }
    }
}

function Run-PingScan {
    param(
        [string]$inputTargets
    )
    
    $targets = $inputTargets -split '[,;\s]+' | Where-Object { $_ -ne '' } | ForEach-Object { $_.Trim() }

    if ($targets.Count -eq 0) {
        Write-Host "No targets entered!" -ForegroundColor Red
        Start-Sleep -Seconds 1
        return $null
    }

    Write-Host "Ping Results:" -ForegroundColor Yellow
    Write-Host "-------------"

    $results = @()
    $startTime = Get-Date

    $counter = 0
    foreach ($target in $targets) {
        $counter++
        Write-Host "`n[$counter/$($targets.Count)] $($target):" -ForegroundColor White
        $result = Test-SinglePing -Target $target
        $results += $result
    }

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    Write-Host "`n" + ("=" * 60) -ForegroundColor DarkGray
    Write-Host "SCAN COMPLETE" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    
    $onlineCount = ($results | Where-Object { $_.Status -eq "Online" }).Count
    $offlineCount = ($results | Where-Object { $_.Status -eq "Offline" }).Count
    $timeoutCount = ($results | Where-Object { $_.Status -eq "Timeout" }).Count
    $errorCount = ($results | Where-Object { $_.Status -in @("DNS Error", "Error") }).Count
    
    Write-Host "TOTAL: $($targets.Count)" -ForegroundColor White
    Write-Host "Online: $onlineCount" -ForegroundColor Green
    Write-Host "Offline: $offlineCount" -ForegroundColor Red
    Write-Host "Timeout: $timeoutCount" -ForegroundColor Yellow
    Write-Host "Errors: $errorCount" -ForegroundColor Magenta
    Write-Host "Duration: $($duration.ToString('0.00'))s" -ForegroundColor Gray
    
    $onlineDevices = $results | Where-Object { $_.Status -eq "Online" }
    $offlineDevices = $results | Where-Object { $_.Status -eq "Offline" }
    $timeoutDevices = $results | Where-Object { $_.Status -eq "Timeout" }
    $errorDevices = $results | Where-Object { $_.Status -in @("DNS Error", "Error") }
    $problemDevices = $results | Where-Object { $_.Status -in @("Offline", "Timeout", "DNS Error", "Error") }
    
    return @{
        Results = $results
        OnlineDevices = $onlineDevices
        OfflineDevices = $offlineDevices
        TimeoutDevices = $timeoutDevices
        ErrorDevices = $errorDevices
        ProblemDevices = $problemDevices
        Summary = @{
            Total = $targets.Count
            Online = $onlineCount
            Offline = $offlineCount
            Timeout = $timeoutCount
            Errors = $errorCount
            Problems = $problemDevices.Count
            SuccessRate = if ($targets.Count -gt 0) { ($onlineCount / $targets.Count * 100).ToString('0.00') } else { "0.00" }
            StartTime = $startTime
            EndTime = $endTime
            Duration = $duration
        }
    }
}

function Show-Results {
    param(
        $scanResults
    )
    
    if (-not $scanResults) {
        Write-Host "No results to show!" -ForegroundColor Red
        return
    }
    
    Show-Header
    Write-Host "RESULTS" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    
    Write-Host "`nDevice Name           Status      IP Address      Latency"
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    
    foreach ($result in $scanResults.Results) {
        $statusColor = switch ($result.Status) {
            "Online" { "Green" }
            "Offline" { "Red" }
            "Timeout" { "Yellow" }
            default { "Gray" }
        }
        
        Write-Host "$($result.Target.PadRight(20)) " -NoNewline
        Write-Host "$($result.Status.PadRight(10)) " -NoNewline -ForegroundColor $statusColor
        Write-Host "$($result.IP.PadRight(15)) " -NoNewline
        Write-Host "$($result.Latency)" -ForegroundColor Gray
    }
    
    Write-Host "`n" + ("=" * 60) -ForegroundColor DarkGray
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-Results {
    param(
        $scanResults
    )
    
    if (-not $scanResults) {
        Write-Host "No results to export!" -ForegroundColor Red
        return
    }
    
    while ($true) {
        Show-Header
        Write-Host "EXPORT OPTIONS" -ForegroundColor Cyan
        Write-Host ("=" * 60) -ForegroundColor DarkGray
        
        Write-Host "`nWhat do you want to export?" -ForegroundColor White
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        Write-Host "1. All devices ($($scanResults.Results.Count))"
        Write-Host "2. Offline devices only ($($scanResults.OfflineDevices.Count))" -ForegroundColor Red
        Write-Host "3. Timeout devices only ($($scanResults.TimeoutDevices.Count))" -ForegroundColor Yellow
        Write-Host "4. All problem devices ($($scanResults.ProblemDevices.Count))" -ForegroundColor Yellow
        Write-Host "5. Back to menu"
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        
        $choice = Read-Host "`nSelect option"
        
        if ($choice -eq '5') {
            return
        }
        
        $exportData = $null
        $reportName = ""
        
        switch ($choice) {
            '1' {
                $exportData = $scanResults.Results
                $reportName = "All Devices"
                if ($exportData.Count -eq 0) {
                    Write-Host "No data to export!" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                    continue
                }
            }
            '2' {
                $exportData = $scanResults.OfflineDevices
                $reportName = "Offline Devices"
                if ($exportData.Count -eq 0) {
                    Write-Host "No offline devices!" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                    continue
                }
            }
            '3' {
                $exportData = $scanResults.TimeoutDevices
                $reportName = "Timeout Devices"
                if ($exportData.Count -eq 0) {
                    Write-Host "No timeout devices!" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                    continue
                }
            }
            '4' {
                $exportData = $scanResults.ProblemDevices
                $reportName = "Problem Devices"
                if ($exportData.Count -eq 0) {
                    Write-Host "No problem devices!" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                    continue
                }
            }
            default {
                Write-Host "Invalid choice!" -ForegroundColor Red
                Start-Sleep -Seconds 1
                continue
            }
        }
        
        $defaultFile = "$reportName - $(Get-Date -Format 'yyyy-MM-dd HHmmss').txt"
        Write-Host "`nSave as: $defaultFile" -ForegroundColor Gray
        Write-Host "Press Enter for default, or type new name:" -ForegroundColor Gray
        
        $fileName = Read-Host "Filename"
        if ([string]::IsNullOrWhiteSpace($fileName)) {
            $fileName = $defaultFile
        }
        if (-not $fileName.EndsWith('.txt')) {
            $fileName += '.txt'
        }
        
        $report = "Ping Scan Report - $reportName`n"
        $report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $report += "=" * 40 + "`n`n"
        
        foreach ($device in $exportData) {
            $report += "$($device.Target) - $($device.Status)`n"
        }
        
        try {
            $desktop = [Environment]::GetFolderPath("Desktop")
            $filePath = Join-Path $desktop $fileName
            $report | Out-File -FilePath $filePath -Encoding UTF8
            Write-Host "`n✅ Saved to: $filePath" -ForegroundColor Green
            
            Write-Host "`nPreview:" -ForegroundColor Cyan
            Write-Host ("-" * 40) -ForegroundColor DarkGray
            Write-Host $report -ForegroundColor Gray
            Write-Host ("-" * 40) -ForegroundColor DarkGray
        }
        catch {
            Write-Host "`n❌ Could not save file!" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "`nReport content:" -ForegroundColor Yellow
            Write-Host ("=" * 40) -ForegroundColor DarkGray
            Write-Host $report -ForegroundColor White
        }
        
        Write-Host "`n1. Export another"
        Write-Host "2. Back to menu"
        
        $next = Read-Host "`nSelect"
        if ($next -eq '2') {
            return
        }
    }
}

$lastScanResults = $null

while ($true) {
    Show-Header
    
    if ($lastScanResults) {
        Write-Host "LAST SCAN:" -ForegroundColor Cyan
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        Write-Host "Total: $($lastScanResults.Summary.Total)" -ForegroundColor White
        Write-Host "Online: $($lastScanResults.Summary.Online)" -ForegroundColor Green
        Write-Host "Offline: $($lastScanResults.Summary.Offline)" -ForegroundColor Red
        Write-Host "Timeout: $($lastScanResults.Summary.Timeout)" -ForegroundColor Yellow
        Write-Host "Errors: $($lastScanResults.Summary.Errors)" -ForegroundColor Magenta
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        Write-Host ""
    }
    
    Write-Host "MAIN MENU:" -ForegroundColor Cyan
    Write-Host ("-" * 40) -ForegroundColor DarkGray
    Write-Host "1. Ping devices"
    Write-Host "2. View results"
    Write-Host "3. Export results"
    Write-Host "4. Quick test"
    Write-Host "5. Exit"
    Write-Host ("-" * 40) -ForegroundColor DarkGray
    
    $choice = Read-Host "`nSelect"
    
    switch ($choice) {
        '1' {
            Show-Header
            Write-Host "PING DEVICES" -ForegroundColor Cyan
            Write-Host ("-" * 40) -ForegroundColor DarkGray
            Write-Host "Enter IPs or hostnames (space or comma separated)"
            Write-Host "Examples: 8.8.8.8 google.com 192.168.1.1" -ForegroundColor Gray
            Write-Host ("-" * 40) -ForegroundColor DarkGray
            
            $inputTargets = Read-Host "`nTargets"
            $lastScanResults = Run-PingScan -inputTargets $inputTargets
            
            Write-Host "`nPress any key..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        '2' {
            if ($lastScanResults) {
                Show-Results -scanResults $lastScanResults
            } else {
                Write-Host "Run a scan first!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        '3' {
            if ($lastScanResults) {
                Export-Results -scanResults $lastScanResults
            } else {
                Write-Host "Run a scan first!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        '4' {
            Show-Header
            Write-Host "QUICK TEST" -ForegroundColor Cyan
            Write-Host ("-" * 40) -ForegroundColor DarkGray
            Write-Host "Testing common targets..." -ForegroundColor Gray
            Write-Host ("-" * 40) -ForegroundColor DarkGray
            
            $testTargets = "8.8.8.8 google.com localhost 192.168.255.255 bad-hostname.xyz"
            $lastScanResults = Run-PingScan -inputTargets $testTargets
            
            Write-Host "`nPress any key..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        '5' {
            Write-Host "`nExit? (Y/N)" -ForegroundColor Yellow
            if ((Read-Host) -eq 'Y') {
                Write-Host "Goodbye!" -ForegroundColor Cyan
                Start-Sleep -Seconds 1
                exit
            }
        }
        default {
            Write-Host "Invalid choice!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}