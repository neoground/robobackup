# RoboBackup: Rsync-like Mirror Backup Solution for Windows

![Header Banner](https://raw.githubusercontent.com/neoground/robobackup/refs/heads/main/banner.webp)

---

RoboBackup is a PowerShell-based script designed for those who prefer efficient, no-nonsense, 
and highly customizable backups on Windows. Built by **Neoground**, this tool is for backup experts who want
a rsync-like experience on Windows 10/11, leveraging the powerhouse `robocopy` utility.

Why RoboBackup? It’s lean, powerful, and avoids the fluff of GUI-based tools. You get reliable, 
background backup operations, whether for local drives or network shares.

This script works reliably on our Windows machines and backs up everything to our network shares.

---

## Features

- **Rsync-like Backup**: Perform fast, mirror-style backups with precision.
- **Runs in the Background**: No intrusive GUIs or apps hogging your screen.
- **Highly Customizable**: JSON configuration handles everything from schedules to exclusions.
- **Network Share Ready**: Perfect for backing up to NAS drives or remote shares.
- **Performance & Reliability**: Robocopy’s battle-tested efficiency paired with PowerShell's flexibility.

## License

This project is licensed under the **MPL License**, allowing flexibility for both open-source and proprietary use.

---

## Installation

1. **Clone the Repository**:

   ```powershell
   git clone https://github.com/neoground/robobackup.git
   ```

2. **Navigate to the Directory**:

   ```powershell
   cd robobackup
   ```

3. **Adjust the Path in Scripts**:

   Edit both `backup.ps1` and `backup_manage.ps1` at the top to point to the location of your `backup_config.json`. 
   Double backslashes (`\\`) are essential in paths to handle escaping correctly.

   ```powershell
   $configPath = "C:\\robobackup\\backup_config.json"
   ```

---

## Configuration File

Here’s an example configuration file `backup_config.json`. You define your backup schedule and all directories in here.
Edit this to suit your backup requirements:

```json
{
    "taskName": "Periodic PowerShell Backup",
    "scriptPath": "C:\\robobackup\\backup.ps1",
    "triggers": [
        { "dayOfWeek": "Wednesday", "time": "13:00" },
        { "dayOfWeek": "Saturday", "time": "19:30" }
    ],
    "backups": [
        {
            "source": "C:\\Users",
            "destination": "\\\\192.168.1.1\\Backup\\Users",
            "excludeFiles": ["*.tmp", "*.log", "*.log.*", "NTUSER.DAT", "Cache_*"],
            "excludeDirs": ["cache", "temp", "node_modules", "tmp", "*Temp*", "*Cache*", "Logs"]
        },
        {
            "source": "C:\\Windows\\Fonts",
            "destination": "\\\\192.168.1.1\\Backup\\Fonts",
            "excludeFiles": ["*.tmp"],
            "excludeDirs": ["cache"]
        }
    ],
    "appListPath": "C:\\robobackup\\InstalledApps.txt",
    "logPath": "C:\\robobackup\\backup.log",
    "retryCount": 1,
    "waitTime": 1
}
```

### Explanation of Values

- **`taskName`**: The name of the scheduled task created for the backup.
- **`scriptPath`**: Full path to the `backup.ps1` script. Adjust this to your setup.
- **`triggers`**: Schedule for backups. Specify `dayOfWeek` and `time` for each run.
- **`backups`**:
  - `source`: Directory to back up.
  - `destination`: Target location for the backup. Works with network shares (use double backslashes for paths, e.g., `\\\\192.168.1.1\\Backup\\`).
  - `excludeFiles`: File patterns to exclude.
  - `excludeDirs`: Folder patterns to exclude.
- **`appListPath`**: File to save a list of installed applications (optional, needs `winget`).
- **`logPath`**: Path to store the log file. Note that you need to enable logging in the backup script (line 47).
- **`retryCount`**: Number of times robocopy retries a failed operation.
- **`waitTime`**: Seconds between retries.

---

## Usage

### Run the Backup Script

Start the backup process:

```powershell
.\backup.ps1
```

### Automate with Task Scheduler

Add (or update) the scheduled task for automated backups:

```powershell
.\backup_manage.ps1
```

**No arguments needed!** The script will configure the schedule based on the `triggers` in the JSON file. 
If a task with the same name already exists, it removes and re-adds it with the updated configuration.

You can also manually adjust the scheduled task. You find it in the main directory in the Task Scheduler.

---

## Why Use RoboBackup?

1. **Mirror-Like Backups**: Create exact replicas, making recovery simple.
2. **No Fluff**: No GUIs, no bloatware — just a clean, lean PowerShell script.
3. **Network Ready**: Works seamlessly with network shares. Just ensure credentials for the share are stored under the current user.
4. **Runs with Elevated Privileges**: Backups run with admin rights for maximum reliability.
5. **Customization**: Adjust schedules, paths, and exclusions without limits.

---

## Pro Tips

- **Paths & Escaping**: Always use double backslashes (`\\`) in paths to handle PowerShell's escaping properly.
- **Network Shares**: Ensure credentials for your network share are stored in Windows Credential Manager. The script runs as the current user, so pre-authentication is key.
- **Logging**: Check logs at the specified `logPath` for a detailed view of backup operations.

---

Happy backing up! 🚀
