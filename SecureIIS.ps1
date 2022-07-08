#PCI-DSS HARDENING IIS SCRIPT - Version 1 from Heinrich Badenhorst https://github.com/heibad/
#Requires -RunAsAdministrator

Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Unrestricted -Force
$Choice = Read-Host -Prompt 'Enter 0 to backup and 1 to Disabled Ciphers/Hashes/Protocols, Enter 2 to roll back, 3 to Reboot, 4 to enable Tls 1.2'

<#
PowerShell script to automate the process of securing Ciphers, Protocols, and Hashes 
typically used on an IIS server
It disables deprecated/weak Ciphers, Protocols, and Hashes
This script needs to run under a user context that has permission to write to the local registry
ALSO NOTE: THIS IS FOR IIS ALONE AND BASED ON PCI DSS 4.1
#>
if($Choice -eq 0){
Write-Host "Processing Backup before Deployment...Please ensure C:\ is writable for the Admin Account used" -ForegroundColor Green
#Backup before Deployment
Reg export 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL' C:\SecureIISRollback.reg /y
Write-Host "Completed Backup to  C:\SecureIISRollback.reg " -ForegroundColor Green
}
if($Choice -eq 1){
Write-Host "Processing Backup before Deployment...Please ensure C:\ is writable for the Admin Account used" -ForegroundColor Green
#Backup before Deployment
Reg export 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL' C:\SecureIISRollback.reg /y
Write-Host "Defining PCI DSS Deployment Standards" -ForegroundColor Green
#region Input
$Protocols = @('PCT 1.0','SSL 2.0','SSL 3.0','TLS 1.0','TLS 1.1') # Leaving TLS 1.2 to be enabled in option 4
$Hashes    = @('MD5','SHA') # SHA1 that is, leaving 'SHA 256', 'SHA 384', and 'SHA 512' 
# Warning: SHA1 is still required for Skype for Business 2016 (16.0.7830.1013) 64-bit
$Ciphers   = @(
    'DES 56/56'
    'RC2 40/128','RC2 56/128','RC2 128/128'
    'RC4 40/128','RC4 56/128','RC4 64/128','RC4 128/128'
    'Triple DES 168','AES 128/128'
	'RC2 128/128','RC2 128/128','RC2 40/128','RC2 56/128','RC4 128/128','RC4 40/128','RC4 56/128'
	'RC4 64/128'
) # which leaves 'AES 256/256'
$RegKey    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL'
#endregion

Write-Host "Disabling Protocols..." -ForegroundColor Green

#region Disable protocols
$Protocols | % {
    New-Item -Path "$RegKey\Protocols\$_" -Name 'Client' -ItemType directory -Force
    New-ItemProperty -Path "$RegKey\Protocols\$_\Client" -PropertyType DWORD -Name 'DisabledByDefault' -Value 1 -Force
    New-ItemProperty -Path "$RegKey\Protocols\$_\Client" -PropertyType DWORD -Name 'Enabled' -Value 0 -Force
    New-Item -Path "$RegKey\Protocols\$_" -Name 'Server' -ItemType directory -Force
    New-ItemProperty -Path "$RegKey\Protocols\$_\Server" -PropertyType DWORD -Name 'DisabledByDefault' -Value 1 -Force
    New-ItemProperty -Path "$RegKey\Protocols\$_\Server" -PropertyType DWORD -Name 'Enabled' -Value 0 -Force
}
#endregion

Write-Host "Disabling Hashes..." -ForegroundColor Green

#region Disable hashes
$Hashes | % {
    New-Item -Path "$RegKey\Hashes" -Name $_ -ItemType directory -Force
    New-ItemProperty -Path "$RegKey\Hashes\$_" -PropertyType DWORD -Name 'Enabled' -Value 0 -Force
    New-ItemProperty -Path "$RegKey\Hashes\$_" -PropertyType DWORD -Name 'DisabledByDefault' -Value 1 -Force
}
#endregion

Write-Host "Disabling Ciphers..." -ForegroundColor Green

#region Disable ciphers
$Ciphers | % {
    if ($_ -match '/') { $Name = "$($_.Split('/')[0])$([char]0x2215)$($_.Split('/')[1])" } else { $Name = $_ } 
    New-Item -Path "$RegKey\Ciphers" -Name $Name -ItemType directory -Force
    New-ItemProperty -Path "$RegKey\Ciphers\$Name" -PropertyType DWORD -Name 'Enabled' -Value 0 -Force
    New-ItemProperty -Path "$RegKey\Ciphers\$Name" -PropertyType DWORD -Name 'DisabledByDefault' -Value 1 -Force
}
#endregion
Write-Host "Completed Hardening IIS Registry Key..." -ForegroundColor Green
Write-Host "Disabling SNMP Service" -ForegroundColor Green
Set-Service SNMPTRAP -StartupType Disabled
} 
if($Choice -eq 2){
#Rollback Deployment
Write-Host "Removing Changes from Registry Key..." -ForegroundColor Red
$RegKey    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL'
Remove-Item $RegKey -Recurse
Write-Host "Removed" -ForegroundColor Green
#endregion
Reg import C:\SecureIISRollback.reg *>&1 | out-null
Write-Host "Restored Registry Key..." -ForegroundColor Red
Write-Host "Restoring SNMP" -ForegroundColor Green
Set-Service SNMPTRAP -StartupType Automatic
Write-Host "Completed!" -ForegroundColor Green
}
if($Choice -eq 3){
#Rollback Deployment Dependant on setup of Machine.
Write-Host "Restarting Server!" -ForegroundColor Green
Restart-Computer 
}


if($Choice -eq 4){
Write-Host "Processing Backup before Deployment...Please ensure C:\ is writable for the Admin Account used" -ForegroundColor Green
#Backup before Deployment
Reg export 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL' C:\SecureIISRollback.reg /y
Write-Host "Defining PCI DSS Deployment Standards" -ForegroundColor Green
#region Input
$Protocols = @('TLS 1.2') # Enabling TLS 1.2
}
#endregion

Write-Host "Enabling TLS 1.2" -ForegroundColor Green

#region Disable protocols
$Protocols | % {
    New-Item -Path "$RegKey\Protocols\$_" -Name 'Client' -ItemType directory -Force
    New-ItemProperty -Path "$RegKey\Protocols\$_\Client" -PropertyType DWORD -Name 'DisabledByDefault' -Value 0 -Force
    New-ItemProperty -Path "$RegKey\Protocols\$_\Client" -PropertyType DWORD -Name 'Enabled' -Value 1 -Force
    New-Item -Path "$RegKey\Protocols\$_" -Name 'Server' -ItemType directory -Force
    New-ItemProperty -Path "$RegKey\Protocols\$_\Server" -PropertyType DWORD -Name 'DisabledByDefault' -Value 0 -Force
    New-ItemProperty -Path "$RegKey\Protocols\$_\Server" -PropertyType DWORD -Name 'Enabled' -Value 1 -Force
}
#endregion

Write-Host "TLS 1.2 Enabled" -ForegroundColor Green
