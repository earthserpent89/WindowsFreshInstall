<#
.SYNOPSIS
This script installs a list of applications using the 'winget' package manager and performs additional configuration tasks.

.DESCRIPTION
The script starts by checking if the 'winget' command is available. If not, it installs the 'winget' package using the NuGet package provider and the 'winget' module. 
Next, it defines a list of applications to install using 'winget'. For each application in the list, it attempts to install the application using the 'winget install' command. If the installation fails, the script logs the error message and adds the application to the list of failed applications.
After installing the applications, the script saves the list of failed applications to a log file.
Finally, the script performs additional configuration tasks in the Windows Subsystem for Linux (WSL). It creates a new user named 'joshua' in the Ubuntu WSL distribution and configures sudo access for the user. It then updates the Ubuntu distribution.

.PARAMETER LogFilePath
Specifies the path to the log file where the script will write log messages. The default value is "C:\Logs\App-Setup.log".

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
.\App-Setup.ps1
Runs the script with the default settings.

.EXAMPLE
.\App-Setup.ps1 -LogFilePath "D:\Logs\App-Setup.log"
Runs the script and specifies a custom log file path.

.NOTES
- This script requires PowerShell 5.1 or later.
- The script requires administrative privileges to install applications and perform WSL configuration tasks.
- The 'winget' package manager and the applications to be installed must be available and compatible with the system.

.LINK
- winget documentation: https://docs.microsoft.com/windows/package-manager/winget/
- NuGet package provider documentation: https://docs.microsoft.com/powershell/scripting/gallery/installing-psget?view=powershell-7.1#installing-a-package-provider
- WSL documentation: https://docs.microsoft.com/windows/wsl/
#>

# Logging function
function WriteToLog {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$LogFilePath = "C:\Logs\App-Setup.log"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"

    Write-Host $logMessage
    Add-Content -Path $LogFilePath -Value $logMessage
}

# Check if 'winget' command is available, if not, install 'winget' package
if (-not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
    WriteToLog -Message "Installing 'winget' package"
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Install-Module -Name winget -Force -Scope CurrentUser
}

# List of applications to install
$wingetArgs = "-e --silent --accept-package-agreements --accept-source-agreements"
$applications = @(
    "Balena.Etcher",
    "Adobe.Acrobat.Reader.64-bit",
    "Bitwarden.Bitwarden",
    "CodeSector.TeraCopy",
    "CodecGuide.K-LiteCodecPack.Standard",
    "VideoLAN.VLC",
    "HandBrake.HandBrake",
    "Corsair.iCUE.4",
    "CrystalDewWorld.CrystalDiskMark.ShizukuEdition",
    "CrystalDewWorld.CrystalDiskInfo.ShizukuEdition",
    "DigitalScholar.Zotero",
    "ElectronicArts.EADesktop",
    "EpicGames.EpicGamesLauncher",
    "Google.Drive",
    "Google.Chrome",
    "Logitech.GHUB",
    "Microsoft.DirectX",
    "Microsoft.DotNet.Runtime.7",
    "Microsoft.PowerToys",
    "Microsoft.VisualStudioCode",
    "NexusMods.Vortex",
    "Nvidia.GeForceExperience",
    "Nvidia.PhysX",
    "Notepad++.Notepad++",
    "Oracle.JavaRuntimeEnvironment",
    "Piriform.Speccy",
    "Python.Python.3.11",
    "Anaconda.Anaconda3",
    "REALiX.HWiNFO",
    "RealVNC.VNCViewer",
    "RevoUninstaller.RevoUninstaller",
    "Streamlabs.Streamlabs",
    "Valve.Steam",
    "AntibodySoftware.WizTree",
    "WinSCP.WinSCP",
    "goatcorp.XIVLauncher",
    "Spotify.Spotify",
    "DelugeTeam.Deluge",
    "angryziber.AngryIPScanner",
    "Mozilla.Firefox",
    "Amazon.Kindle",
    "CPUID.CPU-Z.AORUS",
    "Discord.Discord",
    "GitHub.GitHubDesktop",
    "Microsoft.Git",
    "Guru3D.Afterburner",
    "Daum.PotPlayer",
    "PopcornTime.Popcorn-Time",
    "RaspberryPiFoundation.RaspberryPiImager",
    "VMware.WorkstationPro",
    "Canonical.Ubuntu.2204"
)

$failedApps = @()

foreach ($app in $applications) {
    $installCommand = "winget install --id $app $wingetArgs"
    try {
        Invoke-Expression $installCommand
        WriteToLog -Message "Installed $app"
    }
    catch {
        $failedApps += $app
        $errorMessage = $_.Exception.Message
        WriteToLog -Message "Failed to install $app. Error: $errorMessage"
    }
}

# Save failed apps to log file
$failedAppsLogFile = "C:\Logs\Failed-Apps.log"
$failedApps | Out-File -FilePath $failedAppsLogFile -Append
WriteToLog -Message "Failed to install the following applications. See $failedAppsLogFile for more information."

# Create new user in WSL named joshua
wsl -d Ubuntu -u root useradd -m -s /bin/bash joshua
WriteToLog -Message "Created user joshua in WSL"

# Configure sudo for user joshua
wsl -d Ubuntu -u root bash -c "echo 'joshua ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
WriteToLog -Message "Configured sudo for user joshua"

# Update Ubuntu
wsl -d Ubuntu -u joshua bash -c "sudo apt update && sudo apt upgrade -y"
WriteToLog -Message "Updated Ubuntu"
