# Logging function
function Write-LogMessage {
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
        Log-Message -Message "Installed $app"
    }
    catch {
        $failedApps += $app
        $errorMessage = $_.Exception.Message
        Log-Message -Message "Failed to install $app. Error: $errorMessage"
    }
}

# Save failed apps to log file
$failedAppsLogFile = "C:\Logs\Failed-Apps.log"
$failedApps | Out-File -FilePath $failedAppsLogFile -Append
Log-Message -Message "Failed to install the following applications. See $failedAppsLogFile for more information."

# Create new user in WSL named joshua
wsl -d Ubuntu -u root useradd -m -s /bin/bash joshua
Log-Message -Message "Created user joshua in WSL"

# Configure sudo for user joshua
wsl -d Ubuntu -u root bash -c "echo 'joshua ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
Log-Message -Message "Configured sudo for user joshua"

# Update Ubuntu
wsl -d Ubuntu -u joshua bash -c "sudo apt update && sudo apt upgrade -y"
Log-Message -Message "Updated Ubuntu"
