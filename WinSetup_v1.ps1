<#
.SYNOPSIS
  An interactive, all-in-one script to install applications via winget and
  configure WSL distributions (Ubuntu, Arch Linux) on a new Windows system.

.DESCRIPTION
  This script provides a menu-driven interface within the PowerShell terminal
  to guide the user through setting up their environment. It combines application
  installation and WSL configuration into a single, self-contained utility.

  Features:
  - Checks for required Administrator privileges.
  - Interactively prompts the user to select application categories for installation.
  - Performs a robust check for WSL2 prerequisites (Hyper-V, Virtual Machine Platform,
    Windows Subsystem for Linux), properly detecting if a reboot is pending.
  - Prompts for a WSL username to be created in the Linux distributions.
  - Displays a final confirmation summary before making any changes.
  - Installs selected applications using winget.
  - Installs and configures Ubuntu and ArchLinux in WSL.
  - Creates the specified user, grants passwordless sudo, and sets the user as default.
  - Updates all system packages within the WSL distributions.
  - Outputs all actions to a log file at C:\Logs\WinSetup.log.

.NOTES
  Version: 2.3
  Author: Gemini
  Requires: PowerShell 5.1+, running in an elevated (Administrator) terminal.
#>

# --- SCRIPT CONFIGURATION ---

# Define the global path for the log file.
$Global:LogFilePath = "C:\Logs\WinSetup.log"

# Define all available applications, grouped by category.
$AllApplications = @(
    # System
    @{ Category = 'System'; Id = '7zip.7zip' },
    @{ Category = 'System'; Id = 'Balena.Etcher' },
    @{ Category = 'System'; Id = 'CodeSector.TeraCopy' },
    @{ Category = 'System'; Id = 'CodecGuide.K-LiteCodecPack.Standard' },
    @{ Category = 'System'; Id = 'AntibodySoftware.WizTree' },
    @{ Category = 'System'; Id = 'Piriform.Speccy' },
    @{ Category = 'System'; Id = 'REALiX.HWiNFO' },
    @{ Category = 'System'; Id = 'CrystalDewWorld.CrystalDiskMark.ShizukuEdition' },
    @{ Category = 'System'; Id = 'CrystalDewWorld.CrystalDiskInfo.ShizukuEdition' },
    @{ Category = 'System'; Id = 'WinSCP.WinSCP' },
    @{ Category = 'System'; Id = 'bruhov.WinThumbsPreloader' },
    @{ Category = 'System'; Id = '9NV4BS3L1H4S'; Source = 'msstore'; Name = 'PowerShell' },
    # Productivity
    @{ Category = 'Productivity'; Id = 'Adobe.Acrobat.Reader.64-bit' },
    @{ Category = 'Productivity'; Id = 'Bitwarden.Bitwarden' },
    @{ Category = 'Productivity'; Id = 'Google.Chrome' },
    @{ Category = 'Productivity'; Id = 'Mozilla.Firefox' },
    @{ Category = 'Productivity'; Id = 'Amazon.Kindle' },
    @{ Category = 'Productivity'; Id = 'Google.GoogleDrive' },
    # Development
    @{ Category = 'Development'; Id = 'Microsoft.DirectX' },
    @{ Category = 'Development'; Id = 'Microsoft.DotNet.Runtime.7' },
    @{ Category = 'Development'; Id = 'Microsoft.PowerToys' },
    @{ Category = 'Development'; Id = 'Microsoft.VisualStudioCode' },
    @{ Category = 'Development'; Id = 'Git.Git' },
    @{ Category = 'Development'; Id = 'Python.Python.3.11' },
    @{ Category = 'Development'; Id = 'Anaconda.Anaconda3' },
    @{ Category = 'Development'; Id = 'DigitalScholar.Zotero' },
    @{ Category = 'Development'; Id = 'Notepad++.Notepad++' },
    @{ Category = 'Development'; Id = 'Oracle.JavaRuntimeEnvironment' },
    @{ Category = 'Development'; Id = 'RProject.R' },
    @{ Category = 'Development'; Id = 'Posit.RStudio' },
    @{ Category = 'Development'; Id = 'RProject.Rtools' },
    @{ Category = 'Development'; Id = 'nepnep.neofetch-win' },
    @{ Category = 'Development'; Id = 'RaspberryPiFoundation.RaspberryPiImager' },
    # Gaming
    @{ Category = 'Gaming'; Id = 'ElectronicArts.EADesktop' },
    @{ Category = 'Gaming'; Id = 'EpicGames.EpicGamesLauncher' },
    @{ Category = 'Gaming'; Id = 'EDCD.EliteDangerousMarketConnector' },
    @{ Category = 'Gaming'; Id = 'goatcorp.XIVLauncher' },
    @{ Category = 'Gaming'; Id = 'Streamlabs.Streamlabs' },
    @{ Category = 'Gaming'; Id = 'Elgato.StreamDeck' },
    # Media
    @{ Category = 'Media'; Id = 'VideoLAN.VLC' },
    @{ Category = 'Media'; Id = 'Daum.PotPlayer' },
    @{ Category = 'Media'; Id = 'HandBrake.HandBrake' },
    @{ Category = 'Media'; Id = 'Gyan.FFmpeg' },
    @{ Category = 'Media'; Id = 'Audacity.Audacity' },
    @{ Category = 'Media'; Id = '9NCBCSZSJRSB'; Source = 'msstore'; Name = 'Spotify' },
    # Hardware
    @{ Category = 'Hardware'; Id = 'Corsair.iCUE.5' },
    @{ Category = 'Hardware'; Id = 'Logitech.GHUB' },
    @{ Category = 'Hardware'; Id = 'Guru3D.Afterburner' },
    @{ Category = 'Hardware'; Id = 'CPUID.CPU-Z.AORUS' },
    @{ Category = 'Hardware'; Id = 'RealVNC.VNCViewer' },
    # Networking
    @{ Category = 'Networking'; Id = 'DelugeTeam.Deluge' },
    @{ Category = 'Networking'; Id = 'angryziber.AngryIPScanner' }
)

# --- HELPER FUNCTIONS ---

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    
    # Write to the console
    Write-Host $logMessage -ForegroundColor $Color
    
    # Append to the log file
    try {
        Add-Content -Path $Global:LogFilePath -Value $logMessage -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not write to log file at $($Global:LogFilePath). Error: $_"
    }
}

function Write-SectionHeader {
    param([string]$Title)
    # Create a dynamic, centered header for better visual separation
    $titleText = " $($Title.ToUpper()) "
    if ($titleText.Length -ge 80) {
        $headerLine = $titleText
    } else {
        $paddingLength = 80 - $titleText.Length
        $leftPadding = [Math]::Floor($paddingLength / 2)
        $rightPadding = [Math]::Ceiling($paddingLength / 2)
        $leftLine = "=" * $leftPadding
        $rightLine = "=" * $rightPadding
        $headerLine = $leftLine + $titleText + $rightLine
    }
    
    # Write header to console and to log file
    Write-Host ""
    Write-Host $headerLine -ForegroundColor Cyan
    Write-Host ""
    Add-Content -Path $Global:LogFilePath -Value "`n$headerLine`n"
}

# --- UI FUNCTIONS ---

function Show-CategorySelection {
    $categories = $AllApplications.Category | Select-Object -Unique
    
    do {
        Clear-Host
        Write-SectionHeader "Application Category Selection"
        Write-Host "Please select which application categories you want to install."
        Write-Host "You can select multiple by separating numbers with a comma (e.g., 1,3,5)."
        Write-Host "" # Blank line for spacing
        
        # Loop through each category and display its apps
        for ($i = 0; $i -lt $categories.Length; $i++) {
            $categoryName = $categories[$i]
            Write-Host ("[{0,2}] {1}" -f ($i + 1), $categoryName) -ForegroundColor Yellow
            
            $appsInCategory = $AllApplications | Where-Object { $_.Category -eq $categoryName }
            
            foreach ($app in $appsInCategory) {
                # Use the 'Name' property if it exists, otherwise default to the 'Id'
                $appName = if ($app.PSObject.Properties['Name']) { $app.Name } else { $app.Id }
                Write-Host ("      - {0}" -f $appName)
            }
            Write-Host "" # Add a blank line for spacing after each category
        }
        
        Write-Host "[ A] All Categories" -ForegroundColor Green
        Write-Host "[ N] None (Skip App Installation)" -ForegroundColor Green
        Write-Host "`n"
        
        $choice = Read-Host "Enter your selection(s)"
        $selectedCategories = @()
        $validChoice = $true

        if ($choice -eq 'A' -or $choice -eq 'a') {
            return $categories
        }
        if ($choice -eq 'N' -or $choice -eq 'n') {
            return @()
        }

        $choices = $choice -split ',' | ForEach-Object { $_.Trim() }
        
        foreach ($c in $choices) {
            if ($c -match '^\d+$' -and [int]$c -ge 1 -and [int]$c -le $categories.Length) {
                $selectedCategories += $categories[[int]$c - 1]
            }
            else {
                Write-Host "Invalid selection: '$c'. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
                $validChoice = $false
                break
            }
        }
    } while (-not $validChoice)
    
    return $selectedCategories | Select-Object -Unique
}


function Get-WslUsername {
    Clear-Host
    Write-SectionHeader "WSL User Configuration"
    $defaultUser = "earthserpent"
    $wslUsername = Read-Host "Enter the username to create in WSL distributions (default: $defaultUser)"
    if ([string]::IsNullOrWhiteSpace($wslUsername)) {
        return $defaultUser
    }
    return $wslUsername
}

# --- CORE LOGIC FUNCTIONS ---

function Check-Prerequisites {
    Write-SectionHeader "Checking Prerequisites"

    # 1. Administrator Check
    Write-Log "Checking for Administrator privileges..."
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "ERROR: This script must be run as an Administrator." -Color Red
        Write-Log "Please re-launch PowerShell as an Administrator and run the script again." -Color Yellow
        Read-Host "Press Enter to exit..."
        return $false
    }
    Write-Log "Administrator check passed." -Color Green

    # 2. WSL Features Check
    Write-Log "Checking for required Windows Features for WSL2..."
    $requiredFeatures = @(
        @{ Name = "Windows-Subsystem-Linux"; Display = "Windows Subsystem for Linux" },
        @{ Name = "VirtualMachinePlatform"; Display = "Virtual Machine Platform" },
        @{ Name = "Microsoft-Hyper-V"; Display = "Hyper-V" }
    )
    $missingFeatures = @()
    $pendingRebootFeatures = @()
    $rebootIsRequired = $false

    foreach ($feature in $requiredFeatures) {
        $featureIsOk = $false
        try {
            $status = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction Stop
            switch ($status.State) {
                'Enabled' {
                    Write-Log "  - $($feature.Display): Enabled" -Color Green
                    $featureIsOk = $true
                }
                'EnablePending' {
                    Write-Log "  - $($feature.Display): Enabled (Pending Reboot)" -Color Yellow
                    $pendingRebootFeatures += $feature.Display
                    $rebootIsRequired = $true
                    $featureIsOk = $true # It's enabled, just needs a reboot
                }
            }
        }
        catch {
            # This catch block is intentionally empty. We will handle the failure below.
        }

        if (-not $featureIsOk) {
            # If Get-WindowsOptionalFeature fails or shows disabled, try a secondary check for WSL.
            if ($feature.Name -eq "Windows-Subsystem-Linux") {
                Write-Log "  - Primary check for $($feature.Display) failed. Attempting fallback check..." -Color Yellow
                try {
                    wsl.exe --status 2> $null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "  - Fallback check for $($feature.Display) PASSED. WSL is functional." -Color Green
                        $featureIsOk = $true
                    }
                } catch {}
            }
        }

        if (-not $featureIsOk) {
            Write-Log "  - $($feature.Display): Disabled or Missing" -Color Red
            $missingFeatures += $feature.Name
        }
    }

    if ($missingFeatures.Count -gt 0) {
        Write-Host "----------------------------------------------------------------" -ForegroundColor Red
        Write-Host "ERROR: Required Windows Features are not enabled: $($missingFeatures -join ', ')"
        Write-Host "Run this command in an elevated PowerShell, RESTART, then run this script again:" -ForegroundColor Yellow
        Write-Host "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /featurename:VirtualMachinePlatform /featurename:Microsoft-Hyper-V /all /norestart" -ForegroundColor Cyan
        Write-Host "----------------------------------------------------------------" -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        return $false
    }

    if ($rebootIsRequired) {
        Write-Host "----------------------------------------------------------------" -ForegroundColor Red
        Write-Host "RESTART REQUIRED: The following features need a reboot: $($pendingRebootFeatures -join ', ')"
        Write-Host "Please restart your computer and run this script again." -ForegroundColor Yellow
        Write-Host "----------------------------------------------------------------" -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        return $false
    }

    Write-Log "All required Windows Features for WSL2 are enabled and active." -Color Green
    return $true
}

function Run-AppInstallation {
    param([string[]]$SelectedCategories)
    
    Write-SectionHeader "Application Installation"

    if ($SelectedCategories.Count -eq 0) {
        Write-Log "No application categories selected. Skipping installation." -Color Yellow
        return
    }

    Write-Log "Updating winget sources..."
    winget source update --accept-source-agreements

    $appsToInstall = $AllApplications | Where-Object { $SelectedCategories -contains $_.Category }
    Write-Log "Found $($appsToInstall.Count) applications to install in the selected categories."

    foreach ($app in $appsToInstall) {
        $appName = if ($app.Name) { "$($app.Name) ($($app.Id))" } else { $app.Id }
        Write-Log "Installing $appName..."
        $args = @('install', '--id', $app.Id, '--exact', '--silent', '--accept-package-agreements', '--accept-source-agreements')
        if ($app.Source) { $args += @('-s', $app.Source) }
        
        try {
            Start-Process winget -ArgumentList $args -Wait -NoNewWindow -ErrorAction Stop
            Write-Log "Successfully installed $appName." -Color Green
        }
        catch {
            Write-Log "Failed to install $appName. Error: $_" -Color Red
        }
    }

    Write-Log "Upgrading all existing winget packages..."
    winget upgrade --all --silent --include-unknown --accept-package-agreements --accept-source-agreements
    Write-Log "Application installation and upgrades complete."
}

function Run-WslConfiguration {
    param([string]$WslUsername)

    Write-SectionHeader "WSL Distribution Setup"

    # This helper function now properly checks the exit code of commands run inside WSL.
    function Invoke-WslCommand {
        param(
            [Parameter(Mandatory=$true)] [string]$DistroName,
            [Parameter(Mandatory=$true)] [string]$Command,
            [string]$User = "root"
        )
        Write-Log "Executing in '$DistroName' as user '$User': $Command"
        # The '&' ensures we wait for the command and capture its exit code.
        & wsl.exe -d $DistroName -u $User -- bash -c "$Command"
        if ($LASTEXITCODE -ne 0) {
            Write-Log "  -> Command failed with exit code $LASTEXITCODE." -Color Red
            return $false
        }
        Write-Log "  -> Command completed successfully." -Color Green
        return $true
    }

    # Define distro-specific settings, including the correct admin group.
    $distributions = @(
        @{ Name = "Ubuntu";    AdminGroup = "sudo" },
        @{ Name = "ArchLinux"; AdminGroup = "wheel" }
    )

    foreach ($distro in $distributions) {
        $distroName = $distro.Name
        $adminGroup = $distro.AdminGroup
        $userExists = $false
        Write-Log "--- Processing distribution: $distroName ---"

        # Install distro if not present
        if (-not (wsl.exe -l -q | Where-Object { $_ -eq $distroName })) {
            Write-Log "Installing $distroName..."
            wsl.exe --install -d $distroName --no-launch
        } else {
            Write-Log "$distroName is already installed."
        }

        # Perform initial root-level setup for specific distros
        if ($distroName -eq "ArchLinux") {
            Write-Log "Performing initial setup for Arch Linux (installing sudo)..."
            # The base Arch WSL image is minimal. It needs the package database synced and sudo installed.
            if (Invoke-WslCommand -DistroName $distroName -Command "pacman -Sy --noconfirm sudo") {
                # If sudo was installed successfully, configure the sudoers file.
                # This command safely uncomments the '%wheel ALL=(ALL:ALL) ALL' line in the sudoers file.
                Invoke-WslCommand -DistroName $distroName -Command "sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers"
            } else {
                Write-Log "FATAL: Failed to install sudo on Arch Linux. Skipping further Arch configuration." -Color Red
                continue # Skip to the next distro
            }
        }

        # Explicitly check if user exists
        Write-Log "Checking for user '$WslUsername' in '$distroName'..."
        wsl.exe -d $distroName -u root -- id -u $WslUsername 2> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "User '$WslUsername' already exists." -Color Yellow
            $userExists = $true
        } else {
            Write-Log "User '$WslUsername' not found. Creating user..."
            $userAddCommand = "useradd -m -G $adminGroup -s /bin/bash $WslUsername"
            if (Invoke-WslCommand -DistroName $distroName -Command $userAddCommand) {
                $userExists = $true
            } else {
                Write-Log "FATAL: Failed to create user '$WslUsername' in '$distroName'. Skipping configuration for this distro." -Color Red
                continue # Skip to the next distro
            }
        }

        # This block only runs if the user was confirmed to exist or was successfully created.
        if ($userExists) {
            # Grant passwordless sudo rights
            Write-Log "Granting passwordless sudo to '$WslUsername'..."
            Invoke-WslCommand -DistroName $distroName -Command "mkdir -p /etc/sudoers.d"
            $sudoerFileContent = "'$WslUsername ALL=(ALL) NOPASSWD:ALL'"
            Invoke-WslCommand -DistroName $distroName -Command "echo $sudoerFileContent > /etc/sudoers.d/$WslUsername && chmod 440 /etc/sudoers.d/$WslUsername"

            # Set the new user as the default for this distribution
            Write-Log "Setting '$WslUsername' as default user..."
            $wslConfigContent = "[user]`ndefault=$WslUsername"
            Invoke-WslCommand -DistroName $distroName -Command "echo '$wslConfigContent' > /etc/wsl.conf"

            # Update and upgrade the distribution as the newly created user
            Write-Log "Updating and upgrading $distroName..."
            if ($distroName -eq "ArchLinux") {
                Invoke-WslCommand -DistroName $distroName -User $WslUsername -Command "sudo pacman -Syu --noconfirm"
                Write-Log "Installing 'yay' in Arch Linux..."
                $yayInstallCommands = "sudo pacman -S --needed --noconfirm git base-devel && git clone https://aur.archlinux.org/yay.git ~/yay && cd ~/yay && makepkg -si --noconfirm"
                Invoke-WslCommand -DistroName $distroName -User $WslUsername -Command $yayInstallCommands
            } else { # Ubuntu
                Invoke-WslCommand -DistroName $distroName -User $WslUsername -Command "sudo apt update && sudo apt upgrade -y"
            }
        }
    }
    Write-Log "WSL configuration complete."
}

# --- MAIN EXECUTION ---

# Ensure the log directory exists
try {
    if (-not (Test-Path (Split-Path $Global:LogFilePath))) {
        New-Item -Path (Split-Path $Global:LogFilePath) -ItemType Directory -Force | Out-Null
    }
}
catch {
    Write-Warning "Could not create log directory at $(Split-Path $Global:LogFilePath). Log file may not be written."
}


Clear-Host
Write-SectionHeader "Windows Setup Assistant"
Write-Host "Welcome! This script will guide you through setting up your Windows environment."

# 1. Run prerequisite checks. The function will now return $false on failure.
if (-not (Check-Prerequisites)) {
    # The Check-Prerequisites function handles user notification and exiting.
    exit
}

# This line will only be reached if the prerequisite checks pass.
Read-Host "Prerequisite checks passed. Press Enter to continue to configuration..."

# 2. Get user configuration choices
$selectedCategories = Show-CategorySelection
$wslUsername = Get-WslUsername

# 3. Final Confirmation
Clear-Host
Write-SectionHeader "Confirmation"
Write-Host "The script is ready to perform the following actions:"
Write-Host ""
Write-Host "  - Install Applications from Categories:" -ForegroundColor Cyan
if ($selectedCategories.Count -gt 0) {
    $selectedCategories | ForEach-Object { Write-Host "    - $_" }
} else {
    Write-Host "    - None (Skipping)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  - Configure WSL with Username:" -ForegroundColor Cyan
Write-Host "    - $wslUsername"
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Log "Operation cancelled by user." -Color Yellow
    exit
}

# 4. Execute the setup
Run-AppInstallation -SelectedCategories $selectedCategories
Run-WslConfiguration -WslUsername $wslUsername

Write-SectionHeader "Setup Complete"
Write-Log "All selected tasks have been completed." -Color Green
Read-Host "Press Enter to exit..."
