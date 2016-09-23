#Windows XP
#cfg_ora_version='10.2.0.100'
#Windows 7
#Windows 2012R2
#$cfg_ora_version='1.102.5.0'
#Oracle 11.2.4.0
#$cfg_ora_version = '2.112.4.0'


Import-Module "..\..\Oracle.DataAccess" -Prefix Oms -verbose
$DataSource="PON43D.WORLD"

#Using the oracle Wallet
$connStr = "User Id=/`;Data Source={0}" -f $DataSource

$Oraconn = OmsConnect -PassThru  -ConnectionString $connStr
#ParamValues
$paramValues = @(
   (New-OmsOraCmdParam -name "HV_FEEDER"   -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Input)  -size 20 -value "RD014")
   )

## Display the OMS Network Hierarchy from the HV Feeder Circuit Breaker. i.e. devices under the Feeder CB
$sqlQuery =@'
with lower_network as (
select  hd.*,ft.name
from
oms_hana.hana_network hd
join OMS_HANA.FACILITY_TYPE FT on HD.FACILITY_TYPE_ID = FT.ID
where HD.BREAK_ID > 5 and HD.FEEDER = :HV_FEEDER
)
SELECT    break_id,
          gis_id,
          zone,
          feeder,
          sap_id,
          facility_type_id,
          name,
          pri_voltage,
          description,
          LPAD (' ', 4 * (LEVEL )) || TO_CHAR (d.location_description) Device_Tree
          ,level,x,y
from
lower_network d
 left join  oms_hana.HANA_LINKS l on D.BREAK_ID = L.child
   START WITH parent = (select break_id from oms_hana.hana_network where tree_level=6 and feeder =  :HV_FEEDER)
   CONNECT BY PRIOR break_id = parent
   order siblings by d.location_description
'@


$dt2 = Get-OmsDataTable -conn $Oraconn  -sql $sqlQuery -paramValues $paramValues -verbose

write-host($dt2 | format-table | out-string);


