@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

:::: Browsers
choco install googlechrome-allusers -fy
choco install firefox -fy

:::: Text editors / IDEs
choco install notepadplusplus.install -fy

:::: Media
choco install vlc -fy
choco install steam -fy
choco install epicgameslauncher -fy
choco install twitch -fy
choco install kindle -fy
choco install discord.install -fy
choco install slack -fy
choco install origin -fy
choco install plexmediaserver -fy
choco install potplayer -fy

:::: Utilities + other
choco install 7zip.install -fy
choco install adobereader -fy
choco install cpu-z.install -fy
choco install google-backup-and-sync -fy
choco install speccy -fy
choco install windirstat -fy
choco install crystaldiskinfo -fy
choco install crystaldiskmark -fy
choco install filezilla -fy
choco install jre8 -fy
choco install k-litecodecpackfull -fy
choco install logitechgaming -fy
choco install geforce-game-ready-driver -fy
choco install rainmeter -fy
choco install teracopy -fy
choco install visipics -fy
choco install hwinfo -fy
choco install virtualbox -fy
choco install uget -fy
choco install keepass.install -fy
choco install cuda -fy
choco install aida64-extreme -fy
choco install pushbullet -fy
choco install sysinternals -fy
choco install inconsolata -fy

#--- Configuring Windows properties ---
SET ThisScriptsDirectory=%~dp0
SET PowerShellScriptPath=%ThisScriptsDirectory%MyDefaults.ps1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PowerShellScriptPath%""' -Verb RunAs}";