🖧 Quick Ping Tool (Continuous Mode)

A simple, interactive PowerShell console tool for quickly pinging multiple hosts, viewing results, and exporting reports. Designed for fast network checks, troubleshooting, and sanity-checking whether things are alive or very much not.

✨ Features

✅ Ping multiple IPs and hostnames at once

🌐 Automatic DNS resolution for hostnames

⏱️ Displays latency, status, and resolved IP

📊 Clear summary statistics after each scan:

Online

Offline

Timeout

Errors

🖥️ Interactive menu-driven UI

📄 Export results to TXT reports:

All devices

Offline only

Timeout only

All problem devices

⚡ “Quick Test” mode with common targets

🎨 Color-coded output for fast visual scanning

🛠 Requirements

Windows

PowerShell 5.1+ or PowerShell 7+

Network access to the targets you want to test

🚀 How to Use

Save the script to a file, for example:

QuickPingTool.ps1


Run it from PowerShell:

.\QuickPingTool.ps1


Use the menu:

1. Ping devices – Enter IPs/hostnames (space or comma separated)

2. View results – See the last scan in a table

3. Export results – Save a report to your Desktop

4. Quick test – Runs a built-in test set

5. Exit – Close the tool

🧪 Input Examples

You can enter targets like:

8.8.8.8 google.com 192.168.1.1


or

8.8.8.8, google.com, localhost


The tool will:

Resolve hostnames to IPs

Ping each target

Show live status feedback

Summarize results at the end

📊 Output

For each device, you’ll see:

Target (hostname or IP)

Status: Online / Offline / Timeout / DNS Error / Error

IP Address (if resolved)

Latency (if online)

Timestamp (internally tracked)

A summary includes:

Total scanned

Online / Offline / Timeout / Errors

Scan duration

Success rate %

📄 Exporting Reports

Reports are saved as .txt files to your Desktop and include:

Report type (All, Offline, Timeout, Problems, etc.)

Generation timestamp

List of devices and their status

You can choose the filename or press Enter to use the default.

🧱 Script Structure (High Level)

Show-Header – Draws the UI header

Test-SinglePing – Resolves DNS and pings one target

Run-PingScan – Runs a scan against multiple targets

Show-Results – Displays results in a table

Export-Results – Exports selected results to a file

Main loop – Interactive menu system

⚠️ Notes

Ping timeout is clamped between 100 ms and 10,000 ms

DNS failures are reported separately from ping failures

Some networks may block ICMP (ping), causing false “Offline/Timeout” results

📜 License

Use it, modify it, break it, fix it, make it better.
(If you want, you can add a proper license like MIT later.)

If you want, I can also:

Add CSV export

Add continuous/looping ping mode

Add parallel pinging for speed

Add logging to file automatically 📈
