# System Boot Script meant to change the Datto EDR agentId on cloned virtual desktop hosts. 
# The approach here is to change the Machine Profile (HKLM) on boot up (not login) to
# a key that is globally unique and consistently derived from the hostname

$EDR_SERVICE_NAME = "HUNTAgent"
$RegistryKey = 'HKLM:\SOFTWARE\Datto\EDR\'

# Get System Info
$name = hostname
$domain = $env:USERDNSDOMAIN
Write-Host "Hostname: $name (Domain: $domain)"


 # Get EDR Service
 $Service = Get-CimInstance -Query "select * from win32_service where name='HUNTAgent'" -ea 1
 if (-NOT $Service) {
     Write-Host "  RESULT: Could not find a service named '$name'"
     return
 }

 # Get EDR InstallDirectory from service imagepath
 try {
    $imagePath = [regex]::Match($Service.PathName, "(['`"](?<p>[^'`"]+)['`"]|(?<p>[^\s]+))").Groups["p"].Value
    if (Test-Path $imagePath) {
        $Directory = $imagePath | split-path
    } else {
        Write-Host "!  WARNING: Could not parse or find ImagePath: [$($Service.PathName)] -> [$imagePath]"
        return
    }
 } catch {
    Write-Error "Issue parsing image path from HUNTAgent service"
    return
 }

# Stop Agent
Get-Service -Name HUNTAgent | Stop-Service

# Get EDR Registry Keys
if (Test-Path $RegistryKey) {
    $EDRRegistry = Get-ItemProperty $RegistryKey -ea 1
} else {
    Write-Host "! WARNING: EDR Registry key '$RegistryKey' does not exist!"
    return
} 

# Get EDR Registry Keys
$AgentId = $EDRRegistry.AgentId
#$DeviceId = $EDRRegistry.DeviceId



# Get EDR from config.toml
$configTOMLPath = "$Directory\config.toml"
try {
    if (Test-Path $configTOMLPath -ea 0) {
        $Config_raw = get-content $configTOMLPath -ea 1   
    } else {
        Write-Host "! WARNING: Config.toml at '$configTOMLPath' does not exist!"
        return
    }
} catch {
    $err = $err.Exception.Message
    Write-Error $err
    return
}

$Config = [PSCustomObject]@{}
if ($Config_raw) {
    try {
        $Config_raw.split("`n") | foreach { 
            if ($_) { 
                $var_name = ($_ -split " = ")[0]
                $var_value = ($_ -split " = ")[1].Replace('"', '').Replace("'","")
                $Config | Add-Member -MemberType NoteProperty -Name $var_name -Value $var_value
            }
        }
        $InstanceName = [regex]::Match($Config.'api-url', "https://(?<cname>[^\.]+)\.infocyte\.com").Groups["cname"].Value
    } catch {
        Write-Host "! ERROR parsing config"
        $err = $err.Exception.Message
        Write-Error $err
        $Config_raw
        return
    }   
} else {
    Write-Error "Couldn't parse config.toml"
    return
}



# Verify Sha1 of file
$stringToHash = $InstanceName+$name+$domain
Write-Host "Hashing: $stringToHash"
try {
    $hasher = [System.Security.Cryptography.HashAlgorithm]::Create('md5')
    $Hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToHash))
    $Hash = [System.BitConverter]::ToString($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToHash)))
    $md5 = $Hash.Replace('-','').ToLower()

    #"$($md5.Substring(0,8))-$($md5.Substring(8, 4))-$($md5.Substring(12, 4))-$($md5.Substring(16, 4))-$($md5.Substring(20, 12))"
    $newAgentId = "$("clone"+$md5.Substring(5,2))-$($md5.Substring(8, 4))-$($md5.Substring(12, 4))-$($md5.Substring(16, 4))-$($md5.Substring(20, 12))"
    Write-Host "New AgentID: $newAgentId -- Old Agent ID: $AgentId"
} catch {
    Write-Warning "Hash Error. $_"
    return
}

Write-Host "New AgentID: $newAgentId -- Old Agent ID: $AgentId"

if ($AgentId -ne $newAgentId) {
    Set-ItemProperty -Path $RegistryKey -Name "AgentId" -Value $newAgentId -ea 1
} else {
    Write-Host "AgentIds already match: $AgentId"
    return $true
}

#Start Agent with new AgentId
Get-Service -Name HUNTAgent | Start-Service

