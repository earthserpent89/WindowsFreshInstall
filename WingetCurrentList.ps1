# Export all installed packages to a JSON file
winget export -o .\winget_packages.json | ForEach-Object { $_ -replace "Installed package is not available from any source: " } | Out-File -FilePath .\winget_packages.log
