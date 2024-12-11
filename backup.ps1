# Robocopy backup script
# See config in backup_config.json, which is applied here. Adjust its path in line 7 as needed.
# This script can be run manually or automatically via the Task Scheduler (see backup_manage.ps1).
# Will run robocopy on the defined folders, if possible in Backup mode.

# Load configuration
$configPath = "C:\robobackup\backup_config.json"
$config = Get-Content -Raw -Path $configPath | ConvertFrom-Json

# Total number of tasks
$totalTasks = $config.backups.Count
$currentTask = 0  # Progress tracker

$isSystemUser = ($env:USERNAME -eq "SYSTEM")
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isSystemUser -or $isAdmin) {
    Write-Host "Running in backup mode" -ForegroundColor Yellow
}

# Iterate through each backup task
foreach ($task in $config.backups) {
	$currentTask++  # Increment task count

	# Calculate percentage progress
    $percentage = [math]::Round(($currentTask / $totalTasks) * 100, 0) - 2

	$source = $task.source
    $destination = $task.destination
    $excludeFiles = $task.excludeFiles
    $excludeDirs = $task.excludeDirs

    # Base robocopy command
    $robocopyCommand = @(
        "robocopy",
        "`"$source`"",        # Escape quotes
        "`"$destination`"",   # Escape quotes
        "/MIR",               # Mirror directories and delete extraneous files
        "/COPY:DT",           # Copy Data + Timestamps, but no Attributes / ACL / Owner / Auditing
        "/E",                 # Include subdirectories (even empty ones)
        "/S",                 # Exclude empty directories
        "/Z",                 # Enable restartable mode
        "/NP",                # No progress logging
        "/XJ",                # Exclude junction points (like symlinks, prevents recursion)
        "/R:$($config.retryCount)", # Retry count from config
        "/W:$($config.waitTime)"#,   # Wait time from config
        #"/LOG:$($config.logPath)"   # Log file from config
    )

    # Determine if backup mode is usable (system user or admin)
    if ($isSystemUser -or $isAdmin) {
        $robocopyCommand += "/B"  # Enable backup mode
    }

    # Add directory exclusions
    foreach ($dir in $excludeDirs) {
        $robocopyCommand += "/XD"
        $robocopyCommand += "`"$dir`""
    }

    # Add file exclusions
    foreach ($file in $excludeFiles) {
        $robocopyCommand += "/XF"
        $robocopyCommand += "`"$file`""
    }

    # Join the command
    $command = $robocopyCommand -join " "

    # Execute the command
    Write-Host "[$percentage %] Executing: $command" -ForegroundColor Yellow
    Invoke-Expression $command
}

# Backup list of installed apps

# Query installed applications using Winget
Write-Host "Saving list with installed applications via Winget" -ForegroundColor Yellow
winget list | Out-String | Out-File -FilePath $config.appListPath -Encoding utf8

Write-Host "Backup completed!" -ForegroundColor Green
