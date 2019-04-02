$Hostname = (Get-WmiObject -Class Win32_ComputerSystem -Property Name).Name
$poshModFolder = ".PowershellModules"

if ($Hostname -like "COVM*")
{#Ched Servers
  $installRootDirPath = "$env:ProgramFiles\Ched Services\posh\Modules"
}
else
{
  $installRootDirPath = $((Split-Path -Path $env:LOCALAPPDATA) | Split-Path) | Join-Path -child $poshModFolder
}

$moduleName= "Oracle.DataAccess" #Top filepath in zip file
$moduleDirPath = Join-Path -Path $installRootDirPath -ChildPath $moduleName

$ZipName= "PSoracle-data-access.zip"

$config_vars += @(
  'installRootDirPath'
  ,'moduleName'
  ,'moduleDirPath'
  ,'ZipName'
)

$config_vars | get-variable | sort-object -unique -property "Name" | Select-Object Name, value | Format-Table | Out-Host

