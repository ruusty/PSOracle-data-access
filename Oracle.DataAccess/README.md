# Oracle Data Access #

Must be initiated in a 32bit process because we only have a 32bit Oracle.DataAccess installed on Servers and PCs


## Load the Module ##

~~~
$cfg_ora_version='10.2.0.100'
Import-Module Oracle.DataAccess -Prefix Oms -ArgumentList $cfg_ora_version

~~~

## Connect ##

### SYNOPSIS ###

Connects to oracle via a connection string.

### DESCRIPTION ###
Creates a new Oracle Connection and opens it using the specified connections string.
Created connection is stored and not returned unless -PassThru is specified.

### PARAMETER ConnectionString ###
The full connection string of the connection to be created and opened.

### PARAMETER PassThru ###
If -PassThru is supplied, the created connection will be returned and not stored.

### EXAMPLE ###
Connect to Oracle with a connection string and store the connection for later use without outputting it.

	Connect "Data Source=LOCALDEV;User Id=HR;Password=Pass"

Using the Oracle Wallet to store password

	Connect "User Id=/`;Data Source=pond.world"

### NOTES ###
If -PassThru isn't used, the connection will be available for later operations such as Disconnect, without having to pass it




### Example Query ###


~~~

$sqlEfcQuery =@'
BEGIN
dbms_output.enable;
:lv_sp_gis_id              := null;
:lv_tx_name                := 'unknown';
:lv_feeder                 := 'unknown';
:lv_feeder_cat             := 'unknown';
:lv_tx_desc                := 'unknown';
:lv_tx_rating              := 'unknown';
:lv_parent_tx_name         := 'unknown';
:lv_parent_tx_rating       := 'unknown';
:lv_inverter_cap_child     := null;
:lv_inverter_cap_parent    := null;
:lv_substation_xml         := 'unknown';
:lv_transformer_xml        := 'unknown';

 OMS_EFC.PKG_EFC.PRO_GET_EFC_NMI_DETAIL (
     :lv_nmi
   , :lv_sp_gis_id
   , :lv_tx_name
   , :lv_feeder
   , :lv_feeder_cat
   , :lv_tx_desc
   , :lv_tx_rating
   , :lv_parent_tx_name
   , :lv_parent_tx_rating
   , :lv_inverter_cap_child
   , :lv_inverter_cap_parent
   , :lv_substation_xml
   , :lv_transformer_xml
    );


EXCEPTION
   WHEN no_data_found THEN
       dbms_output.put_line('FATAL>SQLCODE=' || SQLCODE  || ' ' ||  SQLERRM );
       dbms_output.put_line           ('FATAL> ' || 'No data found for nmi=' || :lv_nmi );
       raise_application_error(-20011, 'FATAL> ' || 'No data found for nmi=' || :lv_nmi );
   WHEN others THEN
       dbms_output.put_line('FATAL>SQLCODE=' || SQLCODE  || ' ' ||  SQLERRM );
       raise;
end;
'@

	#Assume calling script will import module
	#Import-Module Oracle.DataAccess -Prefix Oms
	$connStr = "User Id=/`;Data Source={0}" -f $DataSource

	$Oraconn = OmsConnect -PassThru  -ConnectionString $connStr

	$dt2 = Get-OmsDataTable -conn $Oraconn  -sql "select * from global_name"

	write-host($dt2 | format-table | out-string);

    $paramValues = @(
       (New-OmsOraCmdParam -name "lv_nmi"                 -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Input)  -size 20 -value $nmi_item.nmi)
      ,(New-OmsOraCmdParam -name "lv_sp_gis_id"           -type ([Oracle.DataAccess.Client.OracleDbType]::Decimal)   -direction ([System.Data.ParameterDirection]::Output) -value 0)
      ,(New-OmsOraCmdParam -name "lv_tx_name"             -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Output) -size 80  -value "" )
      ,(New-OmsOraCmdParam -name "lv_feeder"              -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Output) -size 80  -value "")
      ,(New-OmsOraCmdParam -name "lv_feeder_cat"          -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Output) -size 80  -value "")
      ,(New-OmsOraCmdParam -name "lv_tx_desc"             -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Output) -size 80  -value "")
      ,(New-OmsOraCmdParam -name "lv_tx_rating"           -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Output) -size 80  -value "")
      ,(New-OmsOraCmdParam -name "lv_parent_tx_name"      -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Output) -size 80  -value "")
      ,(New-OmsOraCmdParam -name "lv_parent_tx_rating"    -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)  -direction ([System.Data.ParameterDirection]::Output) -size 80  -value "")
      ,(New-OmsOraCmdParam -name "lv_inverter_cap_child"  -type ([Oracle.DataAccess.Client.OracleDbType]::Decimal)   -direction ([System.Data.ParameterDirection]::Output) -value 0 )
      ,(New-OmsOraCmdParam -name "lv_inverter_cap_parent" -type ([Oracle.DataAccess.Client.OracleDbType]::Decimal)   -direction ([System.Data.ParameterDirection]::Output) -value 0 )

      ,(New-OmsOraCmdParam -name "lv_substation_xml"      -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)   -direction ([System.Data.ParameterDirection]::Output) -size 4000 -value "" )
      ,(New-OmsOraCmdParam -name "lv_transformer_xml"     -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2)   -direction ([System.Data.ParameterDirection]::Output) -size 4000 -value "" )
    )

      $result = OmsInvoke_WITH_DBMS_OUTPUT -conn $Oraconn -sql $sqlEfcQuery -paramValues $paramValues -PassThru -verbose
      $result | foreach {
          write-verbose("OmsInvoke_WITH_DBMS_OUTPUT.result:" + $_.gettype() + "," + $($_ | format-list | out-string))
      }


      if ($result -eq -1) {
            #SUCCESS
            write-host("SUCCESS>Details for  (nmi={0})"  -f $paramValues[0].value)
            $paramValues | foreach {
                write-verbose($_.ParameterName + "==>" + $_.Value);
            }

          } else {
              #FAILURE
              $InvalidNmiCSV += new-object PSObject -property @{ "nmi" =   $nmi_item.nmi}
          }
	 }


~~~
