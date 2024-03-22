<#
.SYNOPSIS
Configures Windows Subsystem for Linux (WSL) and sets up Ubuntu.

.DESCRIPTION
This script enables Windows Subsystem for Linux, Virtual Machine Platform, and sets WSL default version to 2. It then installs Ubuntu, sets the root password, creates a user named Joshua, configures sudo for Joshua, and updates Ubuntu.

.NOTES
- This script requires administrative privileges to run.
- Make sure to change the default root password after running this script.

.EXAMPLE
.\WSL_Setup.ps1
#>

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