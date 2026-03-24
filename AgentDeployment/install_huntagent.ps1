New-Module -name install_dattoedr -scriptblock {
 # Datto EDR scripted installation option. If unfamiliar with this script, contact your IT or Security team.
 # www.datto.com

 # WARNING: Single line scripted installers like this use similiar techniques to modern staged malware.
 # As a result, this script will likely trigger behavioral detection products and may need to be whitelisted by your current security software.

 # To execute this script as a one liner on a windows host with powershell 3.0+ (.NET 4.5+), run this command replacing instancename and key with your hunt instance <mandatory> and registration key [optional]. NOTE: Instancename is the cname from the URL, not the FULL url https://instancename.infocyte.com). This script will append the url for you during install.
 # [System.Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072); (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/Infocyte/PowershellTools/master/AgentDeployment/install_huntagent.ps1") | iex; Install-EDR -InstanceName <instancename> -RegKey [regkey] -Region [ap|eu]

 # Example:
 # [System.Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072); (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/Infocyte/PowershellTools/master/AgentDeployment/install_huntagent.ps1") | iex; Install-EDR -InstanceName allsafemsp -RegKey asdf1234 -Region ap

 # Logs are stored here: "C:\Windows\Temp\agentinstallscript.log"

 Function Install-EDR() {
  <#
  .SYNOPSIS
  Installs the Infocyte agent

  .DESCRIPTION
  Installs the Infocyte agent

  .ALIASES
  installagent

  .LINK
  https://github.com/Infocyte/PowershellTools/master/AgentDeployment

  #>
  param(
   [Parameter(Mandatory=$true, Position = 0, HelpMessage="The API URL or cname from the URL: https://<instancename>.infocyte.com or https://<instancename>.<region>.infocyte.com)")]
   [Alias("InstanceName")]
   [String]$URL,

   [Parameter(Position = 1, HelpMessage="This will automatically approve the agent registration and add it to its' default Target Group.")]
   [String]$RegKey,

   [Parameter(HelpMessage="Will register a name for the system. Otherwise will use the hostname.")]
   [String]$FriendlyName,

   [Parameter(HelpMessage='Authenticated: "user:password@192.168.1.1:8080" or Unauthenticated: "192.168.1.1:8080"')]
   [String]$Proxy,

   [Parameter(HelpMessage="The temporary location where agent setup will be downloaded to and ran from.")]
   [String]$DownloadPath = "$($env:TEMP)\agent.windows.exe",

   [Parameter(HelpMessage="Silent install is default. Use this switch to display output.")]
   [Switch]$Interactive,

   [Parameter(HelpMessage="Will force a reinstall if agent already installed.")]
   [Switch]$Force
  )

  $LogPath = "$env:Temp\agentinstallscript.log"

  # Validate $URL is not accidentally a parameter flag (e.g. --url or --InstanceName passed incorrectly)
  if ($URL -match "^-") {
   Write-Warning "[Error] Invalid URL value: '$URL'. Parameters must use a single dash (e.g. -URL or -InstanceName), not double dash."
   "$(Get-Date) [Error] Installation Error: URL parameter received an invalid value '$URL'. Caller may have used -- instead of - for parameter names." >> $LogPath
   return
  }

  $processor = Get-WmiObject Win32_Processor
  $arch = $processor.Architecture

  if ($arch -eq 12) {
   # ARM64
   $agentURL = "https://s3.us-east-2.amazonaws.com/infocyte-support/executables/agent.windows-arm64.exe"
  } elseif ([System.IntPtr]::Size -eq 4) {
   # x86 32-bit
   $agentURL = "https://s3.us-east-2.amazonaws.com/infocyte-support/executables/agent.windows32.exe"
  } else {
   # x64 64-bit
   $agentURL = "https://s3.us-east-2.amazonaws.com/infocyte-support/executables/agent.windows64.exe"
  }

  If (-NOT $URL) {
   Write-Warning "[Error] Please provide Datto EDR URL or instance name (i.e. mycompany in mycompany.infocyte.com) or a full URL to your EDR instance."
   "$(Get-Date) [Error] Installation Error: No InstanceName or URL provided in arguments!" >> $LogPath
   return
  }

  If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
   Write-Warning "[Error] You do not have Administrator rights to run this script!`nPlease re-run as an Administrator!"
   "$(Get-Date) [Error] Installation Error: Script not run as administrator!" >> $LogPath
   return
  }

  if ($URL -match "https://.*?\.infocyte\.com/?") {
   $hunturl = $URL.TrimEnd('/')
  } elseif ($URL -match "\.infocyte\.com/?") {
   $hunturl = "https://$($URL.TrimEnd('/'))"
  } elseif ($URL -notmatch "([:\\/-]|.com)") {
   $hunturl = "https://$URL.infocyte.com"
  } else {
   if ($Interactive) { Write-Error "Could not parse instance name or url correctly: $URL" }
   "$(Get-Date) [Error] Could not parse instance name or url correctly: $URL" >> $LogPath
   return
  }

  if ([Uri]::IsWellFormedUriString($hunturl, [URIKind]::RelativeOrAbsolute)) {
   if ($Interactive) { Write-Host "Installing with URL: $hunturl" }
   "$(Get-Date) [Information] Installing with URL: $hunturl" >> $LogPath
  } else {
   if ($Interactive) { Write-Error "URL is invalid: $hunturl" }
   "$(Get-Date) [Error] URL is invalid: $hunturl" >> $LogPath
   return
  }

  If (Get-Service -name huntAgent -ErrorAction SilentlyContinue) {
   if (-NOT $Force) {
    if ($Interactive) { Write-Error "Datto EDR already installed" }
    "$(Get-Date) [Information] Datto EDR is already installed and HUNTAgent service running. Skipping." >> $LogPath
    return
   }
  }

  # Explicitly set all available TLS protocols to maximize compatibility
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

  $wc = New-Object Net.WebClient
  $wc.Encoding = [System.Text.Encoding]::UTF8

  $proxyAddr = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyServer
  if ($Proxy) {
   $ProxyObj = New-Object System.Net.WebProxy
   if ($proxy.split("@").count -gt 1) {
    $proxyaddr = $proxy.split("@")[1]
    $user = $proxy.split("@")[0].split(':')[0]
    $pass = $proxy.split("@")[0].split(':')[1]
    $Credentials = New-Object Net.NetworkCredential($user,$pass,"")
    $ProxyObj.Address = $proxyaddr
    $ProxyObj.Credentials = $Credentials
   } else {
    $ProxyObj.Address = $proxy
   }
   $wc.Proxy = $ProxyObj
  } elseif ($proxyAddr) {
   $ProxyObj = New-Object System.Net.WebProxy
   $ProxyObj.Address = $proxyAddr
   $ProxyObj.UseDefaultCredentials = $true
   $wc.Proxy = $ProxyObj
  } else {
   $wc.UseDefaultCredentials = $true
  }

  # Attempt download with WebClient, fallback to Invoke-WebRequest
  if ($Interactive) { Write-Host "$(Get-Date) [Information] Attempting to download agent from $agentURL" }
  "$(Get-Date) [Information] Attempting to download agent from $agentURL" >> $LogPath

  try {
   $wc.DownloadFile($agentURL, $DownloadPath)
  } catch {
   $downloadError = $_.Exception.Message
   if ($Interactive) { Write-Warning "WebClient download failed: $downloadError. Trying Invoke-WebRequest fallback..." }
   "$(Get-Date) [Warning] WebClient download failed: $downloadError. Attempting Invoke-WebRequest fallback." >> $LogPath

   try {
    Invoke-WebRequest -Uri $agentURL -OutFile $DownloadPath -UseBasicParsing
   } catch {
    $fallbackError = $_.Exception.Message
    if ($Interactive) { Write-Warning "Invoke-WebRequest fallback also failed: $fallbackError" }
    "$(Get-Date) [Error] Installation Error: Both download methods failed. WebClient: $downloadError | Invoke-WebRequest: $fallbackError" >> $LogPath
    return
   }
  }

  # Verify file exists and is not empty before proceeding
  if (-NOT (Test-Path $DownloadPath) -or (Get-Item $DownloadPath).Length -eq 0) {
   if ($Interactive) { Write-Warning "Downloaded file is missing or empty: $DownloadPath" }
   "$(Get-Date) [Error] Installation Error: Downloaded file is missing or empty: $DownloadPath" >> $LogPath
   return
  }

  # Verify Sha1 of file
  try {
   $SHA1CryptoProvider = New-Object -TypeName System.Security.Cryptography.SHA1CryptoServiceProvider
   $inputBytes = [System.IO.File]::ReadAllBytes($DownloadPath)
   $Hash = [System.BitConverter]::ToString($SHA1CryptoProvider.ComputeHash($inputBytes))
   $sha1 = $Hash.Replace('-','').ToUpper()
  } catch {
   if ($Interactive) { Write-Warning "Hash Error. $_" }
   $sha1 = "Hashing Error"
   "$(Get-Date) [Warning] Installation Warning: Could not hash agent file." >> $LogPath
  }

  # Build arguments array with each flag and value as separate elements
  $arguments = @("--url", $hunturl, "--no-gui", "--no-verify")
  if ($RegKey) { $arguments += @("--key", $RegKey) }
  if ($FriendlyName) { $arguments += @("--friendly", $FriendlyName) }
  if ($Proxy) { $arguments += @("--proxy", $Proxy) }
  if (-NOT $Interactive) { $arguments += "--quiet" }

  $version = & "$DownloadPath" --version
  if ($version -notmatch "RTS Agent") {
   if ($Interactive) {
    Write-Warning "$(Get-Date) [Error] $DownloadPath (version: $version, sha1: $sha1) is not valid or appears to be corrupt."
    Write-Warning "Output: `n$version"
   }
   "$(Get-Date) [Error] $DownloadPath (version: $version, sha1: $sha1) is not valid or appears to be corrupt." >> $LogPath
   "$(Get-Date) [Error] Output: `n$version" >> $LogPath
  }

  if ($Interactive) { Write-Host "$(Get-Date) [Information] Downloaded agent.windows.exe (version: $version, sha1: $sha1) from $agentURL" }
  if ($Interactive) { Write-Host "$(Get-Date) [Information] Installing Agent: $($DownloadPath.Substring($DownloadPath.LastIndexOf('\')+1)) $arguments" }
  "$(Get-Date) [Information] Installing Agent: Downloaded agent.windows.exe from $agentURL [sha1: $sha1] and executing with commandline: $($DownloadPath.Substring($DownloadPath.LastIndexOf('\')+1)) $arguments" >> $LogPath

  # Execute!
  try {
   Start-Process -NoNewWindow -FilePath $DownloadPath -ArgumentList $arguments -Wait -ErrorAction Stop
   if ($Interactive) { Write-Host "$(Get-Date) [Success] Installation Succeeded! Agent associated to $URL." }
   "$(Get-Date) [Success] Installation Succeeded! Agent associated to $URL." >> $LogPath
  } catch {
   if ($Interactive) { Write-Error "$(Get-Date) [Error] Installation Error: Could not start agent.windows.exe. [$_]" }
   "$(Get-Date) [Error] Installation Error: Could not start agent.windows.exe. [$_]" >> $LogPath
  }
 }

 Function Uninstall-EDR() {
  <#
  .SYNOPSIS
  Uninstalls the Datto EDR agent

  .DESCRIPTION
  Uninstalls the Datto EDR agent

  .Aliases
  uninstallagent

  .LINK
  https://github.com/Infocyte/PowershellTools/master/AgentDeployment

  #>
  param(
   [Parameter(HelpMessage="Use this switch silence output.")]
   [Switch]$Silent
  )
  $LogPath = "$env:SystemDrive\windows\Temp\agentinstallscript.log"

  If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
   Write-Warning "[Error] You do not have Administrator rights to run this script!`nPlease re-run as an Administrator!"
   "$(Get-Date) [Error] Installation Error: Script not run as administrator!" >> $LogPath
   return
  }

  $service = Get-WmiObject -class win32_service -Filter "name='HUNTAgent'" -ea SilentlyContinue | Select-Object PathName -ExpandProperty PathName

  If ($Service) {
   if ($service -match '^"(.*?)" --service') {
    $AgentPath = $matches[1]
   } else {
    $AgentPath = 'C:\Program Files\Infocyte\Agent\agent.exe'
   }

   if (-NOT $Silent) { Write-Host "Uninstalling Datto EDR Agent." }
   "$(Get-Date) [Information] Uninstalling Datto EDR Agent." >> $LogPath

   $arguments = @("--uninstall", "--no-gui")
   if ($Silent) { $arguments += "--quiet" }

   try {
    Start-Process -NoNewWindow -FilePath $AgentPath -ArgumentList $arguments -Wait -ErrorAction Stop
   } catch {
    if (-NOT $Silent) { Write-Error "$(Get-Date) [Error] Uninstall Error: Could not execute agent.exe --uninstall. [$_]" }
    "$(Get-Date) [Error] Uninstall Error: Could not execute agent.windows.exe --uninstall. [$_]" >> $LogPath
   }

  } else {
   if (-NOT $Silent) { Write-Warning "Agent was not installed." }
   "$(Get-Date) [Information] Attempted to uninstall Agent but was not installed. Skipping." >> $LogPath
  }
 }

 Export-ModuleMember -Alias 'installagent' -Function 'Install-EDR'
 Export-ModuleMember -Alias 'uninstallagent' -Function 'Uninstall-EDR'
} | Out-Null
Set-Alias installagent -Value Install-EDR
Set-Alias uninstallagent -Value Uninstall-EDR