#Installer
write-host chocolateyPackageFolder  =$env:chocolateyPackageFolder
write-host chocolateyPackageName    =$env:chocolateyPackageName
write-host chocolateyPackageVersion =$env:chocolateyPackageVersion

$tools = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
.  $(join-path $tools "properties.ps1")
.  $(join-path $tools "helpers.ps1")

$ZipPath = $(join-path $tools $ZipName)

#Remove everything under $moduleDirPath
if (Test-Path $moduleDirPath) { Remove-Item -path $(Join-Path -Path $moduleDirPath -ChildPath "*") -Recurse -Force }

Get-ChocolateyUnzip -PackageName $env:chocolateyPackageName -FileFullPath $ZipPath -Destination $installRootDirPath
$psModulePath = [Environment]::GetEnvironmentVariable('PSModulePath','Machine')

# if installation dir path is not already in path then add it.
if(!($psModulePath.Split(';').Contains($installRootDirPath))){
  Write-Host "Attempting to add $installRootDirPath to '$env:PSModulePath'"
    # trim trailing semicolon if exists
    $psModulePath = $psModulePath.TrimEnd(';');
    # append path
    $psModulePath = $psModulePath + ";$installRootDirPath"
    # save
    Install-ChocolateyEnvironmentVariable -variableName "PSModulePath" -variableValue $psModulePath -variableType 'Machine'
    # make effective in current session
    #$env:PSModulePath = $env:PSModulePath + ";$installModulesDirPath"
}
