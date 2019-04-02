#Uninstall exportpoints
write-host chocolateyPackageFolder  =$env:chocolateyPackageFolder
write-host chocolateyPackageName    =$env:chocolateyPackageName
write-host chocolateyPackageVersion =$env:chocolateyPackageVersion

write-host `$ErrorActionPreference=$ErrorActionPreference
write-host `$VerbosePreference=$VerbosePreference

$tools = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
.  $(join-path $tools "helpers.ps1")
.  $(join-path $tools "properties.ps1")

UnInstall-ChocolateyZipPackage -PackageName $env:chocolateyPackageName -ZipFileName $("${env:chocolateyPackageName}Install.zip")
