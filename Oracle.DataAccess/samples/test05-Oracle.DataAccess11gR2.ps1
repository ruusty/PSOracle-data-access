#Windows XP
#cfg_ora_version='10.2.0.100'
#Windows 7
#Windows 2012R2
$cfg_ora_version='1.102.5.0'
#Oracle 11.2.4.0
$cfg_ora_version='2.112.4.0'

Import-Module "..\..\Oracle.DataAccess" -Prefix Oms -ArgumentList $cfg_ora_version -verbose
$DataSource="POND.WORLD"

#Using the oracle Wallet
$connStr = "User Id=/`;Data Source={0}" -f $DataSource

$Oraconn = OmsConnect -PassThru  -ConnectionString $connStr

$dt2 = Get-OmsDataTable -conn $Oraconn -sql "select * from global_name" -verbose
write-host($dt2 | format-table | out-string);

$dt2 = Get-OmsDataTable -conn $Oraconn -sql "select username  from user_users" -verbose
write-host($dt2 | format-table | out-string);

$dt2 = Get-OmsDataTable -conn $Oraconn -sql "select * from oms_ivr.IVR_OUTAGE_INFO order by locality_name" -verbose

write-host($dt2 | format-table | out-string);

write-host($dt2 | format-list | out-string);

