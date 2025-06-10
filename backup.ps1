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

$logPath = $($config.logPath)
"===== BACKUP STARTED: $(Get-Date) =====" | Out-File $logPath
"User: $(whoami)" | Out-File $logPath -Append
"Script path: $($MyInvocation.MyCommand.Path)" | Out-File $logPath -Append
"Working directory: $(Get-Location)" | Out-File $logPath -Append

# SE Backup privilege enabler
function Enable-SeBackupPrivilege {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class TokenAdjuster {
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out long lpLuid);
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges,
        ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    public const int SE_PRIVILEGE_ENABLED = 0x2;
    public const int TOKEN_ADJUST_PRIVILEGES = 0x20;
    public const int TOKEN_QUERY = 0x8;

    public struct TOKEN_PRIVILEGES {
        public int PrivilegeCount;
        public long Luid;
        public int Attributes;
    }

    public static void EnablePrivilege(string privilege) {
        IntPtr hToken;
        OpenProcessToken(System.Diagnostics.Process.GetCurrentProcess().Handle, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out hToken);
        long luid;
        LookupPrivilegeValue(null, privilege, out luid);
        TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
        tp.PrivilegeCount = 1;
        tp.Luid = luid;
        tp.Attributes = SE_PRIVILEGE_ENABLED;
        AdjustTokenPrivileges(hToken, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    }
}
"@
    [TokenAdjuster]::EnablePrivilege("SeBackupPrivilege")
}

[bool] $isAdmin = 0
try {
    Enable-SeBackupPrivilege
    "SeBackupPrivilege: Enabled." | Out-File $logPath -Append
    $isAdmin = 1
} catch {
    "SeBackupPrivilege failed: $_" | Out-File $logPath -Append
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
        "/MT:12",             # Enable multithreaded copy (up to 128)
        "/DCOPY:T",           # Ensure directory timestamps preserved
        "/R:$($config.retryCount)", # Retry count from config
        "/W:$($config.waitTime)",   # Wait time from config
        "/LOG+:`"$($config.rclogPath)`"" # Log file from config
    )

    # Determine if backup mode is usable (system user or admin)
    if ($isAdmin) {
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
    "[$percentage %] Executing: $command" | Out-File $logPath -Append
    Invoke-Expression $command
}

# Backup list of installed apps

# Query installed applications using Winget
"Saving list with installed applications via Winget" | Out-File $logPath -Append
winget list | Out-String | Out-File -FilePath $config.appListPath -Encoding utf8

"===== BACKUP COMPLETED: $(Get-Date) =====" | Out-File $logPath -Append
