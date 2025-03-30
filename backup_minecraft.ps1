# A simple script to create a 7z backup of a minecraft world.
# This can easily be adjusted to any game or file that needs to be saved from time to time.
# Keeps the latest 3 backups.

# Define the paths
$SaveDir = "$env:APPDATA\.minecraft\saves"          # Default Minecraft saves directory
$BackupDir = "$env:APPDATA\.minecraft\saves_backup" # Backup directory
$WorldName = "MyFancyWorld"                         # Specify your world name
$SevenZipPath = "C:\Program Files\7-Zip\7z.exe"     # Path to 7-Zip executable

# Ensure the backup directory exists
if (-not (Test-Path -Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

# Check if the specified world exists
$WorldPath = Join-Path -Path $SaveDir -ChildPath $WorldName
if (-not (Test-Path -Path $WorldPath)) {
    Write-Host "Error: The specified world '$WorldName' does not exist in '$SaveDir'."
    exit 1
}

# Get current timestamp
$Timestamp = Get-Date -Format "MMdd-HHmm"

# Define the backup file name
$BackupFile = Join-Path -Path $BackupDir -ChildPath "$WorldName-$Timestamp.7z"

# Compress the world directory
Write-Host "Backing up world '$WorldName' to '$BackupFile'..."
& "$SevenZipPath" a -t7z "$BackupFile" "$WorldPath" -mx7
if ($LASTEXITCODE -eq 0) {
    Write-Host "Backup successful!"
} else {
    Write-Host "Error during backup. Please check 7-Zip settings."
    exit 1
}

# Manage backups: Keep only the latest 3 backups
Write-Host "Checking for old backups to delete..."
$Backups = Get-ChildItem -Path $BackupDir -Filter "$WorldName-*.7z" | Sort-Object LastWriteTime -Descending

if ($Backups.Count -gt 3) {
    $BackupsToDelete = $Backups | Select-Object -Skip 3
    foreach ($Backup in $BackupsToDelete) {
        Write-Host "Deleting old backup: $($Backup.FullName)"
        Remove-Item -Path $Backup.FullName -Force
    }
} else {
    Write-Host "No old backups to delete. Total backups: $($Backups.Count)"
}

Write-Host "Backup process complete!"
