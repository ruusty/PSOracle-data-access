param (
   [Parameter(Mandatory=$false)]
   [string] $OdpVersion = $("2.112.4.0")
       )
$SCRIPT:conn = $null

function Load {
param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $version,
    [Parameter(Position=1)] [switch] $passThru
)
    $name = ("Oracle.DataAccess, Version={0}, Culture=neutral, PublicKeyToken=89b483f429c47342" -f $version)
    $asm = [System.Reflection.Assembly]::Load($name)
    if ($passThru) { $asm }
}
filter Skip-Empty { $_ | ?{ $_ -ne $null -and $_ } }
<#
.SYNOPSIS
Connects to oracle via a connection string.

.DESCRIPTION
Creates a new Oracle Connection and opens it using the specified connections string.
Created connection is stored and not returned unless -PassThru is specified.

.PARAMETER ConnectionString
The full connection string of the connection to be created and opened.

.PARAMETER PassThru
If -PassThru is supplied, the created connection will be returned and not stored.

.EXAMPLE
Connect to Oracle with a connection string and store the connection for later use without outputting it.

Connect "Data Source=LOCALDEV;User Id=HR;Password=Pass"

Using the Oracle Wallet to store password

Connect "User Id=/`;Data Source=pond.world"

.NOTES
If -PassThru isn't used, the connection will be available for later operations such as Disconnect, without having to pass it.
#>
function Connect {
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)] [string]$ConnectionString,
[Parameter(Mandatory=$false)] [switch]$PassThru )
    $conn= New-Object Oracle.DataAccess.Client.OracleConnection($ConnectionString)
    $conn.Open()
    if (!$PassThru) {
        $SCRIPT:conn = $conn
        Write-Verbose ("Connected with {0}" -f $conn.ConnectionString)
    }
    else {
        $conn
    }
}

function Connect-TNS {
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)] [string]$TNS,
[Parameter(Mandatory=$true)] [string]$UserId,
[Parameter(Mandatory=$true)] [string]$Password,
[Parameter(Mandatory=$false)] [switch]$PassThru )
    $connectString = ("Data Source={0};User Id={1};Password={2};" -f $TNS, $UserId, $Password)
    Connect $connectString -PassThru:$PassThru
}

function Get-Connection ($conn) {
    if (!$conn) { $conn = $SCRIPT:conn }
    $conn
}

function Disconnect {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [Oracle.DataAccess.Client.OracleConnection]$conn)
    $conn = Get-Connection($conn)
    if (!$conn) {
        Write-Verbose "No connection is available to disconnect from"; return
    }
    if ($conn -and $conn.State -eq [System.Data.ConnectionState]::Closed) {
        Write-Verbose "Connection is already closed"; return
    }
    $conn.Close()
    Write-Verbose ("Closed connection to {0}" -f $conn.ConnectionString)
    $conn.Dispose()
}

function Get-DataTable {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [Oracle.DataAccess.Client.OracleConnection]$conn,
    [Parameter(Mandatory=$true)] [string]$sql,
    [Parameter(Mandatory=$false)] $paramValues = $null
)
    $conn = Get-Connection($conn)
    $cmd = New-Object Oracle.DataAccess.Client.OracleCommand($sql.Replace("`r"," "),$conn)

    #Add the Parameters
    $cmd.BindByName = $true
    $paramValues | Skip-Empty | foreach {
      write-verbose("Parameter:" + $_.ParameterName);
      $_ | Format-List | Out-String | write-verbose
    }
    $paramValues | Skip-Empty | foreach { $cmd.Parameters.Add($_) | out-null }
  
    $da = New-Object Oracle.DataAccess.Client.OracleDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    [void]$da.Fill($dt)
    ,$dt
}


function Invoke {
[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    [Parameter(Mandatory=$false)][Oracle.DataAccess.Client.OracleConnection]$conn,
    [Parameter(Mandatory=$true)][string]$sql,
    [Parameter(Mandatory=$false)]$paramValues = $null,
    [Parameter(Mandatory=$false)][switch]$passThru
)
    $conn = Get-Connection($conn)
    $cmd = New-Object Oracle.DataAccess.Client.OracleCommand($sql.Replace("`r"," "),$conn)
  
    #Add the Parameters
    $cmd.BindByName = $true
    $paramValues | Skip-Empty | foreach {
      write-verbose("Parameter:" + $_.ParameterName);
      $_ | Format-List | Out-String | write-verbose
    }
    $paramValues | Skip-Empty | foreach { $cmd.Parameters.Add($_) | out-null }
  
  
  $trans = $conn.BeginTransaction()
    $result = $cmd.ExecuteNonQuery();
    $cmd.Dispose()

    if ($psCmdlet.ShouldProcess($conn.DataSource)) {
        $trans.Commit()
    }
    else {
        $trans.Rollback(); "$result row(s) affected"
    }

    if ($passThru) { $result }
}

# Write the dbms_output using write-verbose
#
#Helper functions
#

# Create an Oracle Command of type CommandType.StoredProcedure
function New-ProcedureCommand  {
[CmdletBinding( )]
Param(
  $procedure,
  $parameters
)
    $cmd = New-Object Oracle.DataAccess.Client.OracleCommand($procedure, (New-Connection))
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $parameters | foreach {$cmd.Parameters.Add($_) | Out-Null }
    $cmd
}


# Create an OracleParameter
function New-OraCmdParam{
[CmdletBinding( )]
Param(
  [Parameter(Mandatory=$true)][string] $name,
  [Parameter(Mandatory=$true)][Oracle.DataAccess.Client.OracleDbType] $type,
  [Parameter(Mandatory=$true)]$value,
  [int] $size = 0,
  [System.Data.ParameterDirection] $direction = [System.Data.ParameterDirection]::Input
)
    New-Object Oracle.DataAccess.Client.OracleParameter($name, $type, $size) -property @{Direction = $direction; Value = $value}
}

<#

   Execute an anonymous pl/sql block with simple type parameters
   If VerbosePreference dbms_output is displayed

$paramValues = @(
        (New-Param -name "i_employee_id" -type ([Oracle.DataAccess.Client.OracleDbType]::Int32)   -value $employeeId)
        (New-Param -name "RETURN_VALUE"  -type ([Oracle.DataAccess.Client.OracleDbType]::Varchar2) -direction ([System.Data.ParameterDirection]::ReturnValue) -size 46)
    )

#>

function Invoke_WITH_DBMS_OUTPUT {
[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    [Parameter(Mandatory=$false)][Oracle.DataAccess.Client.OracleConnection]$conn,
    [Parameter(Mandatory=$true)][string]$sql,
    [Parameter(Mandatory=$false)]$paramValues = $null,
    [Parameter(Mandatory=$false)][switch]$passThru
)
    write-debug( "Invoke_WITH_DBMS_OUTPUT")
    if ($PassThru) {
       $result = 0;
    }
    $conn = Get-Connection($conn)
    # Default is CommandType.Text
    $cmd  = New-Object Oracle.DataAccess.Client.OracleCommand($sql.Replace("`r"," "), $conn)
    write-verbose ("OracleCommand.CommandText" + $sql)
  
    #Add the Parameters
    $cmd.BindByName = $true
    $paramValues | Skip-Empty | foreach {
      write-verbose("Parameter:" + $_.ParameterName);
      $_ | Format-List | Out-String | write-verbose
    }
    $paramValues | Skip-Empty | foreach { $cmd.Parameters.Add($_) | out-null }
  
  $trans = $conn.BeginTransaction()
    try{
      $result = $cmd.ExecuteNonQuery();
    }
      catch [Oracle.DataAccess.Client.OracleException]{
         write-verbose("Oracle.DataAccess.Client.OracleException");
         write-verbose($_.Exception.Datasource + " " + $_.Exception.Message)
         if (($_.Exception.Number -lt 20010) -or ($_.Exception.Number -gt 20999)) {write-verbose($cmd.CommandText);}
   }
  
    write-verbose ("cmd.ExecuteNonQuery:" + $result)

    $num_to_fetch = 8;
    $numLinesFetched = 0;

    #
    # Now get the dbms_output buffer contents
    #
    $p_lines = new-object Oracle.DataAccess.Client.OracleParameter("dbms_output_lines", [Oracle.DataAccess.Client.OracleDbType]::Varchar2, $num_to_fetch , "", [System.Data.ParameterDirection]::Output );
    $p_lines.CollectionType =[Oracle.DataAccess.Client.OracleCollectionType]::PLSQLAssociativeArray;
    $p_lines.ArrayBindSize = 0,0,0,0,0,0,0,0
    # set the bind size value for each element
    for ($i = 0; $i -lt $num_to_fetch; $i++)
    {
      $p_lines.ArrayBindSize[$i] = 32000;
    }
    # this is an input output parameter...
    # on input it holds the number of lines requested to be fetched from the buffer
    # on output it holds the number of lines actually fetched from the buffer
    $p_numlines =  new-object Oracle.DataAccess.Client.OracleParameter("dbms_output_numlines",[Oracle.DataAccess.Client.OracleDbType]::Decimal,"",[System.Data.ParameterDirection]::InputOutput);
    $p_numlines.Value = $num_to_fetch;


    $cmddbms  = New-Object Oracle.DataAccess.Client.OracleCommand($sql.Replace("`r"," "),$conn)
    $cmddbms.BindByName = $true
    $cmddbms.CommandText = "begin dbms_output.get_lines(:dbms_output_lines, :dbms_output_numlines); end;";
    $cmddbms.CommandType = [System.Data.CommandType]::Text;
    $cmddbms.Parameters.Add($p_lines)    | out-NULL;
    $cmddbms.Parameters.Add($p_numlines) | out-NULL;
    Write-debug ("Fetching DBMS_OUTPUT");
    $cmddbms.ExecuteNonQuery()           | out-null;
    # get the number of lines that were fetched (0 = no more lines in buffer)
    $numLinesFetched = 0;
    $numLinesFetched = ([Int32] $p_numlines.Value);
    Write-debug("Number DBMS_OUTPUT Fetched:" +$numLinesFetched);
    # as long as lines were fetched from the buffer...
    while ($numLinesFetched -gt 0){
       #  write the text returned for each element in the pl/sql
       #  associative array to the console window
       for ($i = 0; $i -lt $numLinesFetched; $i++)
       {
          write-verbose ("DBMS_OUTPUT{0}:{1}" -f $i, [string]($p_lines.Value)[$i] )
       }
       # re-execute the command to fetch more lines (if any remain)
       $numLinesFetched=0;
       $cmddbms.ExecuteNonQuery() | out-null;
       # get the number of lines that were fetched (0 = no more lines in buffer)
       $numLinesFetched = ([Int32] $p_numlines.Value);
    }
    $p_numlines.Dispose() ;
    $p_lines.Dispose()    ;
    $cmddbms.Dispose()    ;
    $cmd.Dispose()        ;

    if ($psCmdlet.ShouldProcess($conn.DataSource)) {
        $trans.Commit()
    }
    else {
        $trans.Rollback()
        write-verbose("$result row(s) affected")
    }
    if ($passThru) { return($result) }
}


Export-ModuleMember -Function Connect,Connect-TNS,Disconnect,Get-DataTable,Invoke,Invoke_WITH_DBMS_OUTPUT,New-OraCmdParam,New-ProcedureCommand
Load -version $OdpVersion