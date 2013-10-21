$Metadata = @{
    Title = "Profile Installation"
    Filename = "Microsoft.PowerShell_profile.install.ps1"
    Description = ""
    Tags = "powershell, profile, installation"
    Project = ""
    Author = "Janik von Rotz"
    AuthorContact = "www.janikvonrotz.ch"
    CreateDate = "2013-03-18"
    LastEditDate = "2013-10-17"
    Version = "6.0.0"
    License = @'
This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.�
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}

#--------------------------------------------------#
#  project init
#--------------------------------------------------#

# check compatiblity
if($Host.Version.Major -lt 2){
    throw "Only compatible with Powershell version 2 and higher"
}

# create PowerShell Profile
if (!(Test-Path $Profile)){

    # Create a profile
    Write-Host "Add a default profile script"
	New-Item -path $Profile -type file -force
}

#--------------------------------------------------#
#  global settings
#--------------------------------------------------#
    
# load global configurations
$PSProfileConfig = Join-Path -Path (Get-Location).Path -ChildPath "Microsoft.PowerShell_profile.config.ps1"
if((Test-Path $PSProfileConfig) -and $PSProfile -eq $null){
    iex $PSProfileConfig
}elseif($PSProfile -ne $null){
	Write-Host "Using global configuration of this session"
}elseif(-not (Test-Path $PSProfileConfig)){
    throw "Couldn't find $PSProfileConfig"
}

#--------------------------------------------------#
#  prerequisites
#--------------------------------------------------#

# install chocolatey
if(!(Get-Command "cinst" -ErrorAction SilentlyContinue)){
	iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

if(!(Get-Module -ListAvailable | where{$_.Name -eq "PsGet"})){

    # install module with chocolatey
    & C:\Chocolatey\bin\cinst.bat psget -force

    # import module with static path
    Import-Module "C:\Program Files\Common Files\Modules\PsGet\PsGet.psm1"

}else{

    Import-Module PsGet
}

if(!(Get-Module -ListAvailable | where{$_.Name -eq "pscx"})){

    # install module with PsGet
    Install-Module pscx
}

Import-Module pscx

# autoinclude functions
Get-childitem ($PSfunctions.Path) -Recurse | where{-not $_.PSIsContainer} | foreach{. ($_.Fullname)}

# create custom event log
$EventLog = Get-WmiObject win32_nteventlogfile -filter "filename='$($PSlogs.EventLogName)'"
if(-not ($EventLog)){
    
	Write-Host "Create event log: $($PSlogs.EventLogName)"
    New-EventLog -LogName $PSlogs.EventLogName -Source $PSlogs.EventLogSources -ErrorAction SilentlyContinue
}
# [System.Diagnostics.EventLog]::CreateEventSource(�MySource�, "Application")

#--------------------------------------------------#
#  profile settings
#--------------------------------------------------#

# cast vars
$Features = @()
$Systemvariables = @()

# load configuration files
Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.Profile.Filter -Recurse | %{
    [xml]$(get-content $_.FullName)} | %{
        $Features += $_.Content.Feature;$Systemvariables += $_.Content.Systemvariable}

# add system variables
if($SystemVariables -ne $Null){$SystemVariables | %{
        
        Write-Host ("Adding path variable: $($_.Value)")
        
        if($_.RelativePath -eq "true"){
        
            Add-PathVariable -Value (Convert-Path -Path (Join-Path -Path $(Get-Location).Path -Childpath $_.Value)) -Name $_.Name -Target $_.Target
            
        }else{            
            
            Add-PathVariable -Value (Invoke-Expression ($Command = '"' + $_.Value + '"')) -Name $_.Name -Target $_.Target
        }
    }
}

#--------------------------------------------------#
# feature selection
#--------------------------------------------------#


# Git Update

if($Features | Where{$_.Name -eq "Git Update"}){
   
    Update-PowerShellProfile
    
    if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.GitUpdate.Name -Recurse)){    
        Write-Host "Copy $($PStemplates.GitUpdate.Name) file to the config folder"      
        Copy-Item -Path $PStemplates.GitUpdate.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.GitUpdate.Name)
	}
    
    Update-ScheduledTask
}


# Powershell Remoting

if($Features | Where{$_.Name -eq "Powershell Remoting"}){
    
    Write-Host "Enabling Powershell Remoting"
	Enable-PSRemoting -Confirm:$false
	Set-Item WSMan:\localhost\Client\TrustedHosts "RemoteComputer" -Force
	Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 1024
	restart-Service WinRM -Confirm:$false
}


# Enable Open Powershell here

if($Features | Where{$_.Name -eq "Enable Open Powershell here"}){
    
    Write-Host "Adding 'Open PowerShell Here' to context menu "
	$Null = Enable-OpenPowerShellHere
		
}


# Log File Retention

if($Features | Where{($_.Name -contains "Log File Retention") -and ($_.Run -match "asDailyJob")}){

    if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.LogFileRetention.Name -Recurse)){    
        Write-Host "Copy $($PStemplates.LogFileRetention.Name) file to the config folder"      
        Copy-Item -Path $PStemplates.LogFileRetention.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.LogFileRetention.Name)
	}
    
    Update-ScheduledTask
}


# Multi Remote Management
  
if($Features | Where{$_.Name -eq "Multi Remote Management"}){
       
    if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.RDP.Name -Recurse)){
    
        Write-Host "Copy $($PStemplates.RDP.Name) file to the config folder"        
		Copy-Item -Path $PStemplates.RDP.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.RDP.Name)
	}   

    if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.WinSCP.Name -Recurse)){
    
        Write-Host "Copy $($PStemplates.WinSCP.Name) file to the config folder"        
		Copy-Item -Path $PStemplates.WinSCP.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.WinSCP.Name)
	}   
    
}

# cast vars
$PPContent = @()
$PPISEContent = @()

# Metadata

$PPContent += @'
    
$Metadata = @{
Title = "Powershell Profile"
Filename = "Microsoft.PowerShell_profile.ps1"
Description = ""
Tags = "powershell, profile"
Project = ""
Author = "Janik von Rotz"
AuthorContact = "www.janikvonrotz.ch"
CreateDate = "2013-04-22"
LastEditDate = "2013-10-17"
Version = "6.0.0"
License = "This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.�To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA."
}

'@


# Metadata ISE   
 
$PPISEContent += @'
    
$Metadata = @{
Title = "Powershell ISE Profile"
Filename = "Microsoft.PowerShellISE_profile.ps1"
Description = ""
Tags = "powershell, ise, profile"
Project = ""
Author = "Janik von Rotz"
AuthorContact = "www.janikvonrotz.ch"
CreateDate = "2013-04-22"
LastEditDate = "2013-10-17"
Version = "6.0.0"
License = "This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.�To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA."
}

'@


# main

$PPContent += $Content = @'
# main
. '
'@ + (Join-Path -Path $PSProfile.Path -ChildPath "Microsoft.PowerShell_profile.config.ps1") + "'`n"

$PPISEContent += $Content


# Autoinclude Functions

if($Features | Where{$_.Name -eq "Autoinclude Functions"}){
    Write-Host "Add Autoinclude Functions to the profile script"
	$PPContent += $Content = @'
# Autoinclude Functions
Get-childitem ($PSfunctions.Path) -Recurse | where{-not $_.PSIsContainer} | foreach{. ($_.Fullname)}

'@
    $PPISEContent += $Content
}


# Transcript Logging
	
if($Features | Where{$_.Name -eq "Transcript Logging"}){
    Write-Host "Add Transcript Logging to the profile script"
	$PPContent += @'
# Transcript Logging
Start-Transcript -path $PSlogs.SessionFile
Write-Host ""

'@
}


# Log File Retention

if($Features | Where{($_.Name -contains "Log File Retention") -and ($_.Run -match "withProfileScript")}){
                    
    Write-Host "Add Log File Retention to the profile script"
    $PPContent += $Content = @'
# Log File Retention
Delete-ObsoleteLogFiles

'@
    $PPISEContent += $Content
}


# Custom PowerShell Profile script

if($Features | Where{$_.Name -contains "Custom PowerShell Profile script"}){

    if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.CustomPPscript.Name -Recurse)){    
        Write-Host "Copy $($PStemplates.CustomPPscript.Name) file to the config folder"      
        Copy-Item -Path $PStemplates.CustomPPscript.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.CustomPPscript.Name)
	}
    
    Write-Host "Include Custom PowerShell Profile script"
	$PPContent += $(Get-Content (Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.CustomPPscript.Name -Recurse).Fullname) + "`n"
}

# Custom PowerShell Profile ISE script

if($Features | Where{$_.Name -contains "Custom PowerShell Profile ISE script"}){

    if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.CustomPPISEscript.Name -Recurse)){    
        Write-Host "Copy $($PStemplates.CustomPPISEscript.Name) file to the config folder"      
        Copy-Item -Path $PStemplates.CustomPPISEscript.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.CustomPPISEscript.Name)
	}
    
    Write-Host "Include Custom PowerShell Profile script"
	$PPISEContent += $Content = $(Get-Content (Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.CustomPPISEscript.Name -Recurse).Fullname) + "`n"
}

# Get Quote Of The Day

if($Features | Where{$_.Name -eq "Get Quote Of The Day"}){
    Write-Host "Add Get Quote Of The Day to the profile script"
	$PPContent += $Content = @'
# Get Quote Of The Day
Get-QuoteOfTheDay
Write-Host ""

'@
    $PPISEContent += $Content
}


# main end

$PPContent += $Content = @'
# main end
Set-Location $WorkingPath

'@
$PPISEContent += $Content

#--------------------------------------------------#
# feature selection end
#--------------------------------------------------#

# Write content to PowerShell Profile script file
Write-Host "Creating PowerShell Profile Script"
Set-Content -Value $PPContent -Path $Profile

# Add ISE Profile Script
if($Features | Where{$_.Name -eq "Add ISE Profile Script"}){
    Write-Host "Creating PowerShell ISE Profile Script"
    Set-Content -Value $PPISEContent -Path (Join-Path -Path (Split-Path $profile -Parent) -ChildPath "Microsoft.PowerShellISE_profile.ps1")
}

Set-Location $WorkingPath

Write-Host "Finished" -BackgroundColor Black -ForegroundColor Green