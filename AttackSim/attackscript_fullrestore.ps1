# EDR Attack Simulator - Post-Demo Cleanup Script
# Run this after demos to ensure complete restoration
# Compatible with Windows 10, Windows 11, Server 2016+

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "[Error] You need Administrator rights to run this cleanup script!"
    Start-Sleep 5
    return
}

$attackDir = "$env:TEMP\AttackSim"
Write-Host "`n=== EDR Simulator Cleanup ===" -ForegroundColor Cyan
Write-Host "Removing all persistence mechanisms and artifacts...`n"

# Stop any running processes
Write-Host "[1/12] Stopping malicious processes..."
Stop-Process -Name AttackSim* -Force -ErrorAction Ignore
Stop-Process -Name calc -Force -ErrorAction Ignore
Get-Process -ErrorAction Ignore | Where-Object {$_.Path -like "*$attackDir*"} | Stop-Process -Force -ErrorAction Ignore

# Registry Run Keys
Write-Host "[2/12] Removing Registry Run keys..."
REG DELETE "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /V "Red Team" /f 2>$null
Remove-Item "HKCU:\Software\Classes\RedTeamTest" -Force -ErrorAction Ignore

# RunOnce Keys
Write-Host "[3/12] Removing RunOnce keys..."
Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "NextRun" -Force -ErrorAction Ignore

# EICAR Files
Write-Host "[4/12] Removing EICAR test files..."
Remove-Item "$AttackDir\EICAR.exe" -Force -ErrorAction Ignore
Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\EICAR.exe" -Force -ErrorAction Ignore
Get-ChildItem -Path "C:\Users" -Recurse -Filter "EICAR.exe" -ErrorAction Ignore | Remove-Item -Force -ErrorAction Ignore

# Shortcut Links
Write-Host "[5/12] Removing malicious shortcuts..."
Remove-Item "$home\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\evil_calc.lnk" -Force -ErrorAction Ignore
Remove-Item "$home\Desktop\evil_calc.lnk" -Force -ErrorAction Ignore
Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\evil_calc.lnk" -Force -ErrorAction Ignore
Remove-Item "C:\Users\Public\Desktop\evil_calc.lnk" -Force -ErrorAction Ignore

# Scheduled Tasks
Write-Host "[6/12] Removing scheduled tasks..."
schtasks /delete /tn "T1053_005_OnLogon" /f 2>$null
schtasks /delete /tn "T1053_005_OnStartup" /f 2>$null

# AlwaysInstallElevated Registry Key
Write-Host "[7/12] Removing AlwaysInstallElevated keys..."
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer" /f 2>$null
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /f 2>$null

# System Restore Registry Keys
Write-Host "[8/12] Restoring System Restore settings..."
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v "DisableConfig" /t "REG_DWORD" /d "0" /f 2>$null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v "DisableSR" /t "REG_DWORD" /d "0" /f 2>$null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "DisableConfig" /t "REG_DWORD" /d "0" /f 2>$null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "DisableSR" /t "REG_DWORD" /d "0" /f 2>$null

# Downloaded binaries
Write-Host "[9/12] Removing downloaded tools..."
Remove-Item "$attackDir\bad.exe" -Force -ErrorAction Ignore
Remove-Item "$attackDir\procdump.exe" -Force -ErrorAction Ignore
Remove-Item "$attackDir\lsass.dmp" -Force -ErrorAction Ignore
Remove-Item "$attackDir\*.pdf.exe" -Force -ErrorAction Ignore
Remove-Item "$attackDir\WindowsUpdate*.exe" -Force -ErrorAction Ignore
Remove-Item "$attackDir\Default_File_Path.ps1" -Force -ErrorAction Ignore
Remove-Item ".\test.txt" -Force -ErrorAction Ignore

# Defender Settings
Write-Host "[10/12] Restoring Windows Defender..."
sc.exe config WinDefend start= Auto 2>$null
sc.exe start WinDefend 2>$null
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Ignore

# WSMan CredSSP
Write-Host "[11/12] Disabling WSMan CredSSP..."
Disable-WSManCredSSP -Role Server -ErrorAction Ignore

# Remove Attack Directory
Write-Host "[12/12] Removing attack directory..."
Remove-Item -Path $attackDir -Recurse -Force -ErrorAction Ignore

# Verification
Write-Host "`n=== Verification ===" -ForegroundColor Cyan

$issues = @()

# Check for leftover scheduled tasks
if (schtasks /query /tn "T1053_005_OnLogon" 2>$null) { 
    $issues += "Scheduled task T1053_005_OnLogon still exists" 
}
if (schtasks /query /tn "T1053_005_OnStartup" 2>$null) { 
    $issues += "Scheduled task T1053_005_OnStartup still exists" 
}

# Check for registry keys
if (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction Ignore) {
    $runKey = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction Ignore
    if ($runKey -and $runKey."Red Team") { 
        $issues += "Registry Run key 'Red Team' still exists" 
    }
}

# Check for attack directory
if (Test-Path $attackDir) { 
    $issues += "Attack directory still exists at $attackDir" 
}

# Check for EICAR
if (Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\EICAR.exe") {
    $issues += "EICAR file still in StartUp folder"
}

if ($issues.Count -eq 0) {
    Write-Host "All artifacts removed successfully" -ForegroundColor Green
    Write-Host "System restored to clean state" -ForegroundColor Green
} else {
    Write-Host "Some items may need manual cleanup:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
}

Write-Host "`nCleanup completed!`n" -ForegroundColor Cyan
