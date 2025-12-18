```markdown
```
# Datto EDR Behavioral Attack Simulator

A comprehensive attack simulation script designed to test EDR detection capabilities across the MITRE ATT&CK framework. Built specifically for customer demonstrations and security validation testing.

## Overview

This script executes multiple MITRE ATT&CK adversarial behaviors including execution, discovery, defense evasion, persistence, credential access, lateral movement, and impact techniques. All persistence mechanisms point to benign binaries (calc.exe, cmd.exe) and are automatically cleaned up upon completion.

**Repository:** [GitHub - KaseyaDEDR/PowershellTools](https://github.com/KaseyaDEDR/PowershellTools/tree/master/AttackSim)

### Key Features

- **Automatic OS Detection** - Adapts behavior for Windows 10 vs Windows 11
- **Comprehensive Coverage** - Tests across all major ATT&CK tactics
- **Safe for Demos** - Designed for controlled testing environments
- **Auto-Cleanup** - Removes all artifacts automatically

---

## Quick Start

### Prerequisites

| Requirement | Details |
|-------------|---------|
| **Privileges** | Administrator rights required |
| **PowerShell** | Version 5.1 or higher |
| **.NET** | Version 4.5 or higher |
| **Platform** | Windows 10, Windows 11, Server 2016+ |
| **Internet** | Required for downloading test tools |

### Run Attack Simulation

**From PowerShell (as Administrator):**

```powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Invoke-Expression (New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/KaseyaDEDR/PowershellTools/master/AttackSim/attackscript.ps1")
```

**From Command Prompt or Batch Script:**

```cmd
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/KaseyaDEDR/PowershellTools/master/AttackSim/attackscript.ps1')"
```

**Run Local Script:**

```powershell
cd C:\Path\To\Script
.\attackscript.ps1
```

---

## MITRE ATT&CK Coverage

### Tactics & Techniques Tested

| Tactic | Technique ID | Description |
|--------|--------------|-------------|
| **Execution** | T1059.001 | PowerShell with obfuscation and encoding |
| | | Alternate Data Stream (ADS) execution |
| | | Base64 encoded command execution |
| **Discovery** | T1082 | System information discovery |
| | T1018 | Remote system discovery |
| | | Antivirus product enumeration |
| **Defense Evasion** | T1027 | Obfuscated files (certutil encoding) |
| | T1562.001 | Disabling security tools |
| | | Double-extension file execution |
| **Persistence** | T1547.001 | Registry Run Keys (HKCU & HKLM) |
| | T1547.009 | Shortcut file modification |
| | T1053.005 | Scheduled task creation |
| **Credential Access** | T1003 | LSASS memory dumping with ProcDump |
| | | Mimikatz credential extraction |
| **Lateral Movement** | T1021 | Remote service execution attempts |
| | | WinRM/CredSSP abuse |
| **Impact** | T1490 | Inhibit system recovery features |
| | T1491 | Internal defacement (wallpaper) |

---

## Windows 11 Compatibility

### What Works Seamlessly

- Registry-based persistence mechanisms
- Scheduled task creation and modification
- Discovery commands (CIM replaces WMIC)
- File-based persistence
- Obfuscation and encoding techniques
- LOLBin abuse (certutil, reg.exe, sc.exe)

### Expected Security Blocks

Some techniques may be blocked by Windows 11's enhanced security features:

| Technique | Typical Block | Why This Is Good |
|-----------|---------------|------------------|
| LSASS dumping | Access Denied | Credential Guard active |
| Defender modifications | Access Denied | Tamper Protection working |
| Mimikatz execution | Blocked/Detected | Enhanced AV/EDR protection |

> **Note:** These blocks demonstrate that Windows 11 security AND your EDR are functioning correctly. The attempted behaviors should still generate EDR alerts.

### Technical Improvements for Windows 11

- **CIM Cmdlets** replace deprecated WMIC commands
- **Enhanced TLS/SSL** support for secure downloads
- **Improved error handling** for stricter execution policies
- **Version detection** automatically adapts behavior

---

## Cleanup & Restoration

### Option 1: Automatic (Built-in)

The attack script automatically cleans up all artifacts upon completion. No manual intervention required.

### Option 2: Manual Cleanup Script

Use this if the script is interrupted or for post-demo verification:

**From PowerShell:**

```powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Invoke-Expression (New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/KaseyaDEDR/PowershellTools/master/AttackSim/attackscript_fullrestore.ps1")
```

**From Command Prompt:**

```cmd
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/KaseyaDEDR/PowershellTools/master/AttackSim/attackscript_fullrestore.ps1')"
```

**Run Local Cleanup:**

```powershell
cd C:\Path\To\Script
.\attackscript_fullrestore.ps1
```

### What Gets Cleaned Up

- Scheduled tasks (T1053_005_OnLogon, T1053_005_OnStartup)
- Registry Run keys (HKCU & HKLM)
- Startup folder items (shortcuts, EICAR files)
- Downloaded tools (ProcDump, PsExec, etc.)
- Temporary attack directory
- Windows Defender settings restored
- AlwaysInstallElevated registry keys
- System Restore policy settings

---

## Expected EDR Alerts

Your Datto EDR should generate detections for:

### High-Confidence Detections
- Mimikatz execution and signatures
- LSASS memory access attempts
- Credential dumping behavior
- EICAR test file detection

### Behavioral Detections
- Suspicious PowerShell execution patterns
- Living-off-the-land binary (LOLBin) abuse
- Multiple persistence mechanism creation
- Defense evasion techniques
- Encoded/obfuscated command execution
- Certutil download and decode operations

### Policy Violations
- Registry modification (Run keys)
- Scheduled task creation
- Security tool tampering attempts
- System recovery feature modifications

---

## Managing Windows Defender

### Temporarily Disable Real-time Protection

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
```

### Re-enable Real-time Protection

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
```

> **Windows 11 Note:** Tamper Protection may prevent these commands. Disable Tamper Protection first:
> 
> `Settings → Privacy & Security → Windows Security → Virus & threat protection → Manage settings → Tamper Protection (Off)`

---

## Troubleshooting

### Script Won't Execute

**Issue:** PowerShell execution policy blocking script

```powershell
# Check current policy
Get-ExecutionPolicy

# Temporarily bypass for current session
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### Access Denied Errors

**Issue:** Enhanced security features blocking operations

- **This is expected behavior on Windows 11**
- EDR should still detect the attempt
- Temporarily disable Tamper Protection if full execution is needed for testing

### WMIC Command Not Found (Windows 11)

**Issue:** WMIC deprecated in Windows 11

- **Script automatically handles this**
- Uses CIM cmdlets instead of WMIC
- Ensure you're using the latest version of the script

### Download Failures

**Issue:** Unable to download tools or scripts

- Check internet connectivity
- Verify firewall/proxy settings
- Ensure TLS 1.2 is enabled (script handles automatically)
- Some URLs may be blocked by corporate security

### Datto EDR Agent Not Detected

**Issue:** Script reports agent not installed/running

```powershell
# Check service status
Get-Service -Name HUNTAgent

# Verify installation
Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Datto*" }
```

---

## Repository Structure

```
AttackSim/
│
├── attackscript.ps1              # Main attack simulation script
├── attackscript_fullrestore.ps1  # Cleanup and restoration script
└── README.md                     # Documentation (this file)
```

---

## Security Considerations

### Safe Usage Guidelines

- **Testing Only** - Use only in controlled environments
- **Authorization Required** - Only run on systems you own or have permission to test
- **VM Recommended** - Consider using virtual machines or isolated test systems
- **EDR Active** - Keep EDR/AV running to properly test detection
- **Network Isolation** - Consider network segmentation for testing

### What This Script Does NOT Do

- Does not install persistent malware
- Does not exfiltrate data
- Does not destroy or encrypt files
- Does not spread to other systems
- Does not save or transmit passwords

### What This Script DOES Do

- Downloads legitimate Microsoft Sysinternals tools
- Creates temporary registry keys (cleaned automatically)
- Creates temporary scheduled tasks (cleaned automatically)
- Temporarily executes Mimikatz (memory only, not persisted)
- Tests EDR detection capabilities
- Generates security alerts for analysis

---

## Version History

### Version 2.0 - Windows 11 Compatibility Update
- Added automatic Windows version detection
- Replaced WMIC with CIM cmdlets for Windows 11
- Enhanced error handling for stricter security policies
- Improved TLS 1.2 support
- Comprehensive cleanup verification
- Updated documentation

### Version 1.0 - Initial Release
- Windows 10 and Server 2016+ support
- Core MITRE ATT&CK technique coverage
- Basic persistence mechanisms
- Mimikatz integration

---

## Best Practices for Demos

1. **Pre-Demo Checklist**
   - Verify Datto EDR agent is running
   - Confirm Administrator privileges
   - Test internet connectivity
   - Prepare EDR console for monitoring

2. **During Demo**
   - Explain each tactic/technique as it executes
   - Show EDR console alerts in real-time
   - Emphasize detection vs prevention
   - Highlight behavioral vs signature-based detection

3. **Post-Demo**
   - Run cleanup script (or verify auto-cleanup)
   - Review all generated alerts
   - Export alert data for customer review
   - Reset environment for next demo

---

## Support & Contributing

### Getting Help

- Review this documentation thoroughly
- Check existing issues for similar problems
- Contact Datto EDR support for product-specific questions

---

## Legal Disclaimer

**IMPORTANT:** This tool is provided for legitimate security testing, EDR validation, and customer demonstration purposes only.

- Only use on systems you own or have explicit written permission to test
- The authors assume no liability for misuse or damage
- By using this tool, you agree to use it legally and ethically.

---

**Remember:** The goal is to TEST detection capabilities. Techniques being blocked by security features is a POSITIVE indicator that protections are working!

---

*For the latest updates and additional tools, visit the [PowershellTools repository](https://github.com/KaseyaDEDR/PowershellTools).*
```
