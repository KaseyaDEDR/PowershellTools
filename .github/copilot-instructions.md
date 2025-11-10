# PowershellTools Repository - Coding Agent Instructions

## Project Overview

**PowershellTools** is a collection of PowerShell tools, modules, and scripts designed for operating **Infocyte HUNT** (now Datto EDR), a cybersecurity endpoint detection and response platform. The repository provides API wrappers, agent deployment utilities, network diagnostics, attack simulation tools, and RMM (Remote Monitoring and Management) integration scripts.

### Primary Purpose
- Interface with Infocyte/Datto EDR via REST API
- Simplify agent deployment and management
- Provide network diagnostics for agentless scanning
- Offer utilities for security testing and operations

## Tech Stack

- **Language**: PowerShell 5.1+ (minimum), PowerShell 7.x compatible
- **Testing Framework**: Pester 5.x
- **Package Distribution**: PowerShell Gallery (for modules)
- **API Integration**: RESTful API calls (LoopBack-based filtering)
- **.NET Requirement**: .NET Framework 4.8+ for agent deployment
- **Platform**: Windows 7+, Server 2008R2+

## Project Structure

```
PowershellTools/
├── .github/                          # GitHub configuration (copilot instructions)
├── AgentDeployment/                  # Scripts for EDR agent deployment
│   ├── install_huntagent.ps1        # Main one-liner installation script
│   ├── force_uninstall.ps1          # Uninstallation utility
│   └── readme.md                    # Deployment documentation
├── Archive/                          # Legacy/deprecated scripts (v3.0 and earlier)
│   ├── On-Prem 3.0+/                # Old on-premise server utilities
│   └── manualscan/                  # Legacy manual scan scripts
├── AttackSim/                        # MITRE ATT&CK behavior simulators
│   ├── attackscript.ps1             # Creates test footholds for EDR testing
│   ├── attackscript_fullrestore.ps1 # Cleanup script for attack simulation
│   └── readme.md                    # Attack simulation documentation
├── HUNT Powershell Module/           # Main API module (published to PSGallery)
│   ├── InfocyteHUNTAPI.psd1         # Module manifest (version 2.0.7)
│   ├── InfocyteHUNTAPI.psm1         # Main module loader
│   ├── auth.ps1                     # Authentication functions
│   ├── scan.ps1                     # Scanning operations
│   ├── data.ps1                     # Data retrieval (Get-ICObject, etc.)
│   ├── admin.ps1                    # Administrative functions
│   ├── extensions.ps1               # Extension development tools
│   ├── rules.ps1                    # Rule management
│   ├── requestHelpers.ps1           # HTTP request utilities
│   ├── tests/                       # Pester test suite
│   │   ├── RunTests.ps1             # Test runner (requires Pester module)
│   │   └── *.test.ps1               # Individual test files
│   └── README.md                    # Module documentation
├── NetworkDiagnostics/               # Network troubleshooting module
│   ├── InfocyteNetworkTest.psd1     # Module manifest
│   └── InfocyteNetworkTest.psm1     # Test-ICNetworkAccess function
├── RMMScripts/                       # RMM integration utilities
│   ├── AgentIDSetter.ps1            # Fixes agent IDs on cloned VMs
│   ├── rdptriage.ps1                # RDP connection diagnostics
│   └── Combine_EDRRMMDeviceLists.ps1 # Device list reconciliation
├── Utilities/                        # General-purpose helper scripts
│   └── Get-LockingProcs.ps1         # Find processes locking files
├── README.md                         # Main repository documentation
└── LICENSE                           # Copyright notice
```

## Coding Guidelines

### PowerShell Standards
- **Minimum Version**: Target PowerShell 5.1 as baseline
- **Version Check**: Module includes version validation (see InfocyteHUNTAPI.psm1 lines 5-11)
- **Naming Conventions**:
  - Functions: Use approved PowerShell verbs (Get-, Set-, New-, Remove-, Invoke-, etc.)
  - Module prefix: `IC` for InfocyteHUNTAPI functions (e.g., `Get-ICObject`)
  - Parameters: Use PascalCase
  - Variables: Use camelCase or PascalCase consistently

### Function Structure
- Use `[CmdletBinding()]` for advanced functions
- Include proper parameter attributes:
  ```powershell
  [parameter(Mandatory=$true, ValueFromPipeline=$true)]
  [alias('scanId')]
  [String]$Id
  ```
- Add `PROCESS {}` blocks for pipeline processing
- Use `Write-Verbose` for debugging output

### Comment-Based Help
Follow existing patterns (see Get-LockingProcs.ps1):
```powershell
<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.PARAMETER ParameterName
    Parameter description
.EXAMPLE
    Usage example
#>
```

### Error Handling
- Use `-ErrorAction` parameters appropriately
- Prefer `Write-Error` and `Throw` for critical failures
- Use `Write-Warning` for non-critical issues
- Always validate prerequisites (file existence, service status, etc.)

## Module Development

### InfocyteHUNTAPI Module
- **Entry Point**: `InfocyteHUNTAPI.psm1` loads all component scripts via dot-sourcing
- **Exported Functions**: Defined in `InfocyteHUNTAPI.psd1` FunctionsToExport array
- **Adding New Functions**:
  1. Create/modify appropriate component file (auth.ps1, scan.ps1, etc.)
  2. Add function name to FunctionsToExport in .psd1 manifest
  3. Increment ModuleVersion in .psd1
  4. Add tests to tests/ directory

### API Request Patterns
- Use `Invoke-ICAPI` and `Get-ICAPI` helper functions from requestHelpers.ps1
- Implement LoopBack where-filters as hashtables:
  ```powershell
  $where = @{ threatName = @{ regexp = "Unknown|Suspicious" } }
  Get-ICObject -Type File -where $where
  ```
- Support `-NoLimit` for large result sets
- Use pipeline support with `ValueFromPipelineByPropertyName`

## Testing

### Pester Tests
- **Framework**: Pester 5.7.1+ (installed in environment)
- **Location**: `HUNT Powershell Module/tests/`
- **Test Runner**: `tests/RunTests.ps1`
- **Test Pattern**:
  ```powershell
  Describe "FunctionName" {
      It "Does something specific" {
          $result = Function-Call -Param "value"
          $result | Should -Be $expected
      }
  }
  ```

### Running Tests
```powershell
cd "HUNT Powershell Module/tests"
.\RunTests.ps1  # Runs all *.test.ps1 files
```

**Note**: Tests require:
- Valid API token (Set-ICToken must work)
- Connection to test instance (currently hardcoded to "TestPanXSOAR")
- Tests are integration tests, not unit tests

### Before Committing
- No formal linting configured, but follow existing code style
- Run Pester tests if modifying InfocyteHUNTAPI module
- Test with PowerShell 5.1 and 7.x if possible

## Known Issues and Workarounds

### TODO Items
1. **Survey upload completion detection** (scan.ps1:588, Archive/Hunt-Survey-Submit.ps1:44):
   - Import-ICSurvey does not detect when scan finishes processing submissions
   - Consider polling task status with `Get-ICTask` until completion

2. **ICLZ file deduplication** (Archive/On-Prem 3.0+/Import-HuntICLZs.ps1:236):
   - Script uploads duplicate .iclz files
   - Should hash and rename files before upload to prevent errors

### Archive Folder
- Contains legacy scripts for older versions (3.0 and earlier)
- **Do not modify** Archive/ scripts unless specifically requested
- Reference for historical context only

## Common Build/Execution Failures

### Module Import Issues
**Problem**: "Module not found" or version errors
```powershell
# Solution: Import from local path during development
Import-Module ./InfocyteHUNTAPI.psd1 -Force
Remove-Module InfocyteHUNTAPI -Force -ErrorAction Ignore  # Clean reload
```

### Authentication Failures
**Problem**: API calls fail with 401/403
```powershell
# Solution: Set token for your instance
Set-ICToken -Instance "your-instance" -Token "your-api-token" -Save
```

### Pester Test Failures
**Problem**: Tests fail to connect
- Verify test instance configuration in `RunTests.ps1` (lines 21-23)
- Ensure `Set-ICToken` succeeds before running tests
- Tests require live API access (not unit tests)

### PowerShell Version Conflicts
**Problem**: Script fails on older PowerShell
- Check minimum version requirements (PSVersion in .psd1)
- InfocyteHUNTAPI requires 5.1+
- NetworkDiagnostics requires 3.0+
- AgentDeployment requires 2.0+ (Windows 7+)

## Agent Deployment Notes

### One-Liner Pattern
All deployment scripts follow a download-and-execute pattern:
```powershell
(new-object Net.WebClient).DownloadString("https://url/script.ps1") | iex; Command
```

### Installation Script (install_huntagent.ps1)
- Requires Administrator privileges
- Mandatory parameter: `-url <EDR-instance-url>`
- Optional: `-RegKey`, `-FriendlyName`, `-Proxy`, `-Force`, `-Interactive`
- Logs to: `$env:Temp\agentinstallscript.log`

### Force Reinstall
Use `-Force` parameter to reinstall over existing agent

## Network Diagnostics

### Test-ICNetworkAccess
Located in NetworkDiagnostics module, tests:
- WinRM connectivity
- Credential validation
- Network ports and firewall rules
- Required for agentless scanning troubleshooting

## Quick Reference

### Essential Commands
```powershell
# Module management
Install-Module -Name InfocyteHUNTAPI
Update-Module -Name InfocyteHUNTAPI
Import-Module ./InfocyteHUNTAPI.psd1 -Force

# Authentication
Set-ICToken -Instance "demo1" -Token "YOUR-TOKEN" -Save

# Data retrieval
Get-ICObject -Type Process -NoLimit
Get-ICVulnerability
Get-ICAlert

# Scanning
New-ICScanOptions | Invoke-ICScan -TargetGroupId $tgId

# Testing
cd "HUNT Powershell Module/tests"
.\RunTests.ps1
```

### File Types
- `.ps1` - PowerShell script
- `.psm1` - PowerShell module (script module)
- `.psd1` - PowerShell module manifest (metadata)

### When Adding Features
1. Determine which component file to modify (auth, scan, data, etc.)
2. Follow existing function patterns (CmdletBinding, proper parameters)
3. Add to FunctionsToExport in .psd1 if creating new public function
4. Create corresponding .test.ps1 file in tests/ directory
5. Update version in .psd1 manifest
6. Test with both PowerShell 5.1 and 7.x if possible

## Additional Resources

- **LoopBack API Filtering**: https://loopback.io/doc/en/lb3/Where-filter.html
- **PowerShell Gallery**: Search "InfocyteHUNTAPI" and "InfocyteNetworkTest"
- **Main README**: See repository root for installation instructions
- **Module README**: See HUNT Powershell Module/README.md for API usage examples
