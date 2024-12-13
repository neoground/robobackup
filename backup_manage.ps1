# Install / uninstall the Scheduled Task for the backup script
# See config in backup_config.json, which is applied here.
#
# Will add or remove the Scheduled Task which will run as highest run level as current user.
#
# Execute this script in a PowerShell Admin shell via:
# PS C:\> & 'C:\Path To Scripts\backup_manage.ps1'

# Path to the configuration file
$configPath = "C:\robobackup\backup_config.json"

# Get the current user
$currentUser = "$env:USERDOMAIN\$env:USERNAME"

# Check if running as administrator
function Ensure-AdminPrivileges {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "This script must be run as an administrator."
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" @args" -Verb RunAs
        exit
    }
}

# Install the scheduled task
function Install-ScheduledTask {
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    $taskName = $config.taskName
    $scriptPath = $config.scriptPath
    $triggers = $config.triggers

    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Output "Task '$taskName' already exists. Skipping creation."
        return
    }

    Write-Output "Creating task '$taskName'..."

    # Define the action
    $taskAction = "powershell.exe"
    $taskArguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $action = New-ScheduledTaskAction -Execute $taskAction -Argument $taskArguments

    # Define triggers from config
    $triggerObjects = @()
    foreach ($trigger in $triggers) {
        $dayOfWeek = $trigger.dayOfWeek
        $time = $trigger.time
        $triggerObjects += New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dayOfWeek -At ([datetime]::ParseExact($time, "HH:mm", $null))
    }

    # Register the task
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggerObjects -User $currentUser -RunLevel Highest
        Write-Output "Task '$taskName' has been created successfully."
    } catch {
        Write-Error "Failed to create task '$taskName': $_"
    }
}

# Uninstall the scheduled task
function Uninstall-ScheduledTask {
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    $taskName = $config.taskName

    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Output "Removing task '$taskName'..."
        try {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Output "Task '$taskName' has been removed successfully."
        } catch {
            Write-Error "Failed to remove task '$taskName': $_"
        }
    } else {
        Write-Output "Task '$taskName' does not exist. Nothing to remove."
    }
}

# Main logic based on input parameters
Ensure-AdminPrivileges

switch ($Action.ToLower()) {
    "install" {
        if (-not (Get-ScheduledTask -TaskName ((Get-Content -Raw -Path $configPath | ConvertFrom-Json).taskName) -ErrorAction SilentlyContinue)) {
            Install-ScheduledTask
        } else {
            Write-Output "Task is already installed."
        }
    }
    "uninstall" {
        Uninstall-ScheduledTask
    }
    default {
        Uninstall-ScheduledTask
        Install-ScheduledTask
    }
}

Write-Host -NoNewLine 'Press any key to exit...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
