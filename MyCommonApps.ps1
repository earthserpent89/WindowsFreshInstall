$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFile = Join-Path -Path $desktopPath -ChildPath 'AppDeployment.log'
Start-Transcript -Path $logFile -Append

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Not running as Administrator. Attempting to restart as Administrator..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

write-host "disabling UAC..."
Disable-UAC

# ------------------------------
# Step 1: Checking for Windows updates
# ------------------------------
Write-Host "Checking for Windows updates..."
$updates = New-Object -ComObject Microsoft.Update.Session
$updates.CreateUpdateSearcher().Search("IsInstalled=0 and Type='Software'").Updates

# ------------------------------
# Step 2: Downloading and installing updates
# ------------------------------
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

# ------------------------------
# Step 3: Configuring Windows Subsystem for Linux and Ubuntu setup
# ------------------------------
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
Write-host "Ubuntu has been updated."

# ------------------------------
# Step 4: Installing applications
# ------------------------------
Write-Host "Installing applications..."
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$jsonPath = Join-Path -Path $scriptPath -ChildPath 'apps.json'
winget import -i $jsonPath

# ------------------------------
# Step 5: Configuring Windows Features
# ------------------------------
Write-Host "Configuring Windows Features..."
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions

# ------------------------------
# Step 6: Configuring File Explorer Settings
# ------------------------------
Write-Host "Configuring File Explorer Settings..."
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name SeparateProcess -Type DWord -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel -Name AllItemsIconView -Type DWord -Value 1
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowRecent -Type DWord -Value 0
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowFrequent -Type DWord -Value 0

# ------------------------------
# Step 7: Configuring Taskbar Settings
# ------------------------------
Write-Host "Configuring Taskbar Settings..."
Set-TaskbarOptions -Size Small -Dock Left -Combine Full -Lock
Set-TaskbarOptions -Size Small -Dock Left -Combine Full -AlwaysShowIconsOn
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarAl -Value 0
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name PeopleBand -Value 0

# ------------------------------
# Step 8: Configuring Windows Updates Settings
# ------------------------------
Write-Host "Configuring Windows Updates Settings..."
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name UxOption -Type DWord -Value 1
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config -Name DODownloadMode -Type DWord -Value 1
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization -Name SystemSettingsDownloadMode -Type DWord -Value 3
Write-Host "Windows Updates Settings configured."

# ------------------------------
# Step 9: Rebooting the system
# ------------------------------
Write-Host "Rebooting the system..."
shutdown.exe /r /t 30

Stop-Transcript