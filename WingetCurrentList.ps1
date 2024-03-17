<#
.SYNOPSIS
Export installed packages to a JSON file using Winget.

.DESCRIPTION
This script exports all installed packages to a JSON file using the Winget package manager. It then removes the "Installed package is not available from any source: " string from each package entry and saves the modified output to a log file.

.PARAMETER None

.EXAMPLE
.\WingetCurrentList.ps1

This example runs the script and exports the installed packages to a JSON file.

.NOTES
Author: Joshua Betts
Date: 03-17-2024
#>

winget export -o .\winget_packages.json | ForEach-Object { $_ -replace "Installed package is not available from any source: " } | Out-File -FilePath .\winget_packages.log
