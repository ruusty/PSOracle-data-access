<#	
	.DESCRIPTION
		Test String version comparison
#>
#10gR2
$version = '1.102.5.0'
if ($version -le '1.102.5.0') { Write-Host $("Input:{0} Result:10gR2" -f $version) }

#11gR2
#Oracle 11.2.4.0
$version = '2.112.4.0'

if ($version -gt '1.102.5.0') { Write-Host $("Input:{0} Result:11gR2" -f $version) }