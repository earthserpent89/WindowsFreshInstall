<#
.SYNOPSIS
This script performs a fresh installation of Windows and configures various settings and applications.

.DESCRIPTION
This script automates the process of setting up a fresh installation of Windows. It performs the following steps:
1. Disables UAC (User Account Control)
2. Checks for Windows updates and installs them
3. Uninstalls unnecessary applications that come with Windows out of the box
4. Removes provisioned packages
5. Configures Windows Subsystem for Linux and installs Ubuntu
6. Installs applications specified in the 'apps.json' file
7. Configures Windows Features
8. Configures File Explorer Settings
9. Configures Taskbar Settings
10. Configures Windows Updates Settings
11. Reboots the system

.PARAMETER None
This script does not accept any parameters.

.EXAMPLE
.\MyCommonApps.ps1
Runs the script to perform the fresh installation and configuration of Windows.

.NOTES
- This script requires administrative privileges to run.
- Make sure to review and modify the 'apps.json' file to specify the applications to be installed.
- This script will automatically reboot the system after completing the configuration.

Author: Joshua Betts
Date: 03-17-2024
#>

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted

$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFile = Join-Path -Path $desktopPath -ChildPath 'AppDeployment.log'
Start-Transcript -Path $logFile -Append

# Disable UAC
Write-Host "Disabling UAC..."
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0

# Step 1: Checking for Windows updates
Write-Host "Checking for Windows updates..."
$session = New-Object -ComObject Microsoft.Update.Session
$searcher = $session.CreateUpdateSearcher()
$updates = $searcher.Search("IsInstalled=0")

# Step 2: Downloading and installing updates
Write-Host "Downloading and installing updates..."
$downloader = $session.CreateUpdateDownloader()
$downloader.Updates = $updates
$downloader.Download()

$installer = $session.CreateUpdateInstaller()
$installer.Updates = $updates
$installationResult = $installer.Install()

foreach ($update in $updates) {
    $updateTitle = $update.Title
    $updateID = $update.Identity.UpdateID

    if ($installationResult.GetUpdateResult($updateID).ResultCode -eq 2) {
        Write-Host "Successfully installed $updateTitle"
    } else {
        Write-Host "Failed to install $updateTitle"
    }
}

# Step 3: Remove provisioned packages
Write-Host "Removing provisioned packages..."
$packages = Get-AppxProvisionedPackage -Online
foreach ($package in $packages) {
    try {
        Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop
        Write-Host "Successfully removed provisioned package: $($package.PackageName)"
    } catch {
        Write-Host "Failed to remove provisioned package: $($package.PackageName)"
        Write-Host "Error: $_"
    }
}

# Step 4: Configuring Windows Subsystem for Linux and Ubuntu setup
Write-Host "Configuring Windows Subsystem for Linux and Ubuntu setup..."

Write-Host "Enabling Windows Subsystem for Linux..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

Write-Host "Enabling Virtual Machine Platform..."
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "Setting WSL default version to 2..."
wsl --set-default-version 2

Write-Host "Installing Ubuntu..."
winget install -e --id Canonical.Ubuntu

Write-Host "Setting root password..."
wsl -d Ubuntu -u root bash -c "echo 'root:root' | chpasswd"
Write-Host "Root password set to 'root'. Use 'passwd' command to change it."

Write-Host "Creating user Joshua..."
wsl -d Ubuntu -u root useradd -m -s /bin/bash joshua

Write-Host "Configuring sudo for user Joshua..."
wsl -d Ubuntu -u root bash -c "echo 'joshua ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"

Write-Host "User Joshua created and sudo configured."

Write-Host "Updating Ubuntu..."
wsl -d Ubuntu -u joshua bash -c "sudo apt update && sudo apt upgrade -y"
Write-Host "Ubuntu has been updated."

# Step 5: Installing applications
Write-Host "Installing applications..."
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$jsonPath = Join-Path -Path $scriptPath -ChildPath 'apps.json'
winget import -i $jsonPath

# Step 6: Configuring Windows Features
Write-Host "Configuring Windows Features..."
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions

# Step 7: Configuring File Explorer Settings
Write-Host "Configuring File Explorer Settings..."
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name SeparateProcess -Type DWord -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel -Name AllItemsIconView -Type DWord -Value 1
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowRecent -Type DWord -Value 0
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowFrequent -Type DWord -Value 0

# Re-enable UAC
Write-Host "Enabling UAC..."
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1

# Step 10: Rebooting the system
Write-Host "Rebooting the system..."
shutdown.exe /r /t 30

Stop-Transcript