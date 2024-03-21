<#
.SYNOPSIS
    This script performs an automatic backup of specified files or directories.

.DESCRIPTION
    The script prompts the user to enter the source files or directories to be backed up, as well as the destination directory where the backup will be stored. It then creates a backup directory if it doesn't exist and copies the source files or directories to the backup folder. The script also logs the backup process in a log file and displays a summary of the backup process.

.PARAMETER None

.EXAMPLE
    .\AutoBackup.ps1
    - Prompts the user to enter the source files or directories and the destination directory for the backup.

.NOTES
    Author: [Your Name]
    Date: [Current Date]
#>

try {
    # Prompt the user to enter the source files or directories to be backed up
    $source = Read-Host "Enter the source files or directories to be backed up"

    # Prompt the user to enter the destination directory where the backup will be stored
    $destination = Read-Host "Enter the destination directory for the backup"

    # Create the backup directory if it doesn't exist
    if (-not (Test-Path -Path $destination)) {
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    # Get the current date and time to create a unique backup folder name
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolder = Join-Path -Path $destination -ChildPath "Backup_$timestamp"

    # Create a log file in the source directory to track the backup process
    $logFilePath = Join-Path -Path $source -ChildPath "backup_log.txt"

    # Initialize counters for successful and failed backups
    $successCount = 0
    $failedCount = 0

    # Copy the source files or directories to the backup folder
    $source | ForEach-Object {
        $item = $_
        try {
            Copy-Item -Path $item -Destination $backupFolder -Recurse -Force -ErrorAction Stop

            # Log the successful backup in the log file
            Add-Content -Path $logFilePath -Value "SUCCESS: $item"
            $successCount++
        }
        catch {
            # Log the failed backup in the log file
            Add-Content -Path $logFilePath -Value "FAILED: $item"
            $failedCount++
        }

        # Update the progress bar
        $progress = ($successCount + $failedCount) / $source.Count * 100
        Write-Progress -Activity "Backing up files" -Status "Progress: $progress%" -PercentComplete $progress
    }

    # Output the path of the backup folder
    Write-Host "Backup created at: $backupFolder"

    # Display the summary of the backup process
    Write-Host "Backup Summary:"
    Write-Host "Total files or directories: $($source.Count)"
    Write-Host "Successful backups: $successCount"
    Write-Host "Failed backups: $failedCount"

    # Add the summary to the log file
    Add-Content -Path $logFilePath -Value "Backup Summary:"
    Add-Content -Path $logFilePath -Value "Total files or directories: $($source.Count)"
    Add-Content -Path $logFilePath -Value "Successful backups: $successCount"
    Add-Content -Path $logFilePath -Value "Failed backups: $failedCount"

    # Display the files or directories that failed to be backed up
    if ($failedCount -gt 0) {
        Write-Host "The following files or directories failed to be backed up:"
        Get-Content -Path $logFilePath | Where-Object { $_ -like "FAILED:*" } | ForEach-Object {
            $failedItem = $_ -replace "FAILED: ", ""
            Write-Host $failedItem
        }
    }
}
catch {
    Write-Host "An error occurred during the backup process at step: $_"
}
