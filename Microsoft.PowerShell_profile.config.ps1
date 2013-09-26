$Metadata = @{
	Title = "Microsoft PowerShell profile configuration"
	Filename = "Microsoft.PowerShell_profile.config.ps1"
	Description = ""
	Tags = "microsoft, powershell, configuration, installation"
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "www.janikvonrotz.ch"
	CreateDate = "2013-04-11"
	LastEditDate = "2013-09-20"
	Version = "3.0.0"
	License = @'
This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License. 
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}

$global:PSProfilePath = Split-Path $MyInvocation.MyCommand.Definition -Parent
	
$global:PSfunctions = @{
	Path = Join-Path -Path $PSProfilePath -ChildPath "functions"
}

$global:PSlogs = @{
	Path = Join-Path -Path $PSProfilePath -ChildPath "logs"
}

$global:PSconfigs = @{
	Path = Join-Path -Path $PSProfilePath -ChildPath "configs";
    Profile = @{
        Filter = "*.profile.config.xml"
    };
    Remote = @{
        Filter = "*.remote.config.*"
    };
    Mail = @{
        Filter = "*.mail.config.xml";
        ErrorClass = "ErrorReport"
    };
	GitUpdateTask = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "configs") -Filter "Git-Update.task.config.xml" -Recurse;
	LogFileRetentionTask = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "configs") -Filter "Delete-ObsoleteLogFiles.task.config.xml" -Recurse
}	

$global:PSscripts = @{
	Path = Join-Path -Path $PSProfilePath -ChildPath "scripts";
    GitUpdateTask = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "scripts") -Filter "Git-Update.ps1" -Recurse;
	LogFileRetentionTask = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "scripts") -Filter "Delete-ObsoleteLogFiles.ps1" -Recurse
}

$global:PSapps = @{
	Path = Join-Path -Path $PSProfilePath -ChildPath "apps"
    PowerShell = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
}

$global:PStemplates = @{
    Path = Join-Path -Path $PSProfilePath -ChildPath "templates";
    Mail = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "templates") -Filter "EXAMPLE.mail.config.xml" -Recurse;
    Profile = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "templates") -Filter "EXAMPLE.profile.config.xml" -Recurse;
    Remote = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "templates") -Filter "EXAMPLE.remote.config.xml" -Recurse;
    Task = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "templates") -Filter "EXAMPLE.task.config.xml" -Recurse;
    RDP = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "templates") -Filter "Default.rdp" -Recurse;
    WinSCP = Get-ChildItem -Path (Join-Path -Path $PSProfilePath -ChildPath "templates") -Filter "WinSCP.ini" -Recurse
} 