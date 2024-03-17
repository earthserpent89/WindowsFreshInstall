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

$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFile = Join-Path -Path $desktopPath -ChildPath 'AppDeployment.log'
Start-Transcript -Path $logFile -Append

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Not running as Administrator. Attempting to restart as Administrator..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Disable UAC
Write-Host "Disabling UAC..."
Disable-UAC

# Step 1: Checking for Windows updates
Write-Host "Checking for Windows updates..."
$updates = New-Object -ComObject Microsoft.Update.Session
$updates.CreateUpdateSearcher().Search("IsInstalled=0 and Type='Software'").Updates

# Step 2: Downloading and installing updates
Write-Host "Downloading and installing updates..."
foreach ($update in $updates) {
    Write-Host "Installing $($update.Title)..."
    $updateInstaller = New-Object -ComObject Microsoft.Update.Installer
    $updateInstaller.Updates = $update
    $result = $updateInstaller.Install()

    if ($result.ResultCode -ne 2) {
        Write-Host "Failed to install $($update.Title)"
    }
}

# Step 3A: Uninstalling unnecessary applications that come with Windows out of the box
Write-Host "Uninstalling unnecessary applications that come with Windows out of the box..."
$applicationList = @(
    "Microsoft.3DBuilder",
    "Microsoft.BingFinance",
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)
foreach ($app in $applicationList) {
    if (Get-WindowsPackage -Name $app -ErrorAction SilentlyContinue) {
        Write-Host "Uninstalling $app..."
        Uninstall-WindowsPackage -Name $app -Confirm:$false
        Write-Host "$app has been uninstalled."
    } else {
        Write-Host "$app not found. Skipping..."
    }
}

# Step 3B: Remove provisioned packages
$packages = Get-AppxProvisionedPackage -Online
foreach ($package in $packages) {
    Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName
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

# Step 8: Configuring Taskbar Settings
Write-Host "Configuring Taskbar Settings..."
Set-TaskbarOptions -Size Small -Dock Left -Combine Full -Lock
Set-TaskbarOptions -Size Small -Dock Left -Combine Full -AlwaysShowIconsOn
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarAl -Value 0
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name PeopleBand -Value 0

# Step 9: Configuring Windows Updates Settings
Write-Host "Configuring Windows Updates Settings..."
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name UxOption -Type DWord -Value 1
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config -Name DODownloadMode -Type DWord -Value 1
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization -Name SystemSettingsDownloadMode -Type DWord -Value 3
Write-Host "Windows Updates Settings configured."

# Re-enable UAC
Write-Host "Enabling UAC..."
Enable-UAC

# Step 10: Rebooting the system
Write-Host "Rebooting the system..."
shutdown.exe /r /t 30

Stop-Transcript