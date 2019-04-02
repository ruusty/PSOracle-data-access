#Installer
write-host chocolateyPackageFolder  =$env:chocolateyPackageFolder
write-host chocolateyPackageName    =$env:chocolateyPackageName
write-host chocolateyPackageVersion =$env:chocolateyPackageVersion

write-host `$ErrorActionPreference=$ErrorActionPreference
write-host `$VerbosePreference=$VerbosePreference

$tools = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
.  $(join-path $tools "helpers.ps1")
.  $(join-path $tools "properties.ps1")

$ZipPath = $(join-path $DeliverablesDir $ZipName)

New-Item $installDirPath -ItemType Directory -force | Out-Null
$moduleDirPath = $installDirPath
if (Test-Path $moduleDirPath) { Remove-Item -path $(Join-Path -Path $moduleDirPath -ChildPath "*") -Recurse -Force }

Get-ChocolateyUnzip  -PackageName $env:chocolateyPackageName -FileFullPath $ZipPath -Destination $installDirPath

$psModulePath = [Environment]::GetEnvironmentVariable('PSModulePath','Machine')

# if installation dir path is not already in path then add it.
if(!($psModulePath.Split(';').Contains($installModulesDirPath))){
    Write-Host "Attemptin to add $installModulesDirPath to '$env:PSModulePath'"

    # trim trailing semicolon if exists
    $psModulePath = $psModulePath.TrimEnd(';');

    # append path
    $psModulePath = $psModulePath + ";$installModulesDirPath"

    # save
    Install-ChocolateyEnvironmentVariable -variableName "PSModulePath" -variableValue $psModulePath -variableType 'Machine'
    # make effective in current session
    $env:PSModulePath = $env:PSModulePath + ";$installModulesDirPath"
}

