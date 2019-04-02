[CmdletBinding(SupportsShouldProcess = $true)]
param
(
  [Parameter(Position = 0)]
  [String[]]$tasklist = '?'
)

$CommandName = $PSCmdlet.MyInvocation.InvocationName;
# Get the list of parameters for the command
"${CommandName}: Input", (((Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters) |
  %{ Get-Variable -Name $_.Values.Name -ErrorAction SilentlyContinue; } |
  Format-Table -AutoSize @{ Label = "Name"; Expression = { $_.Name }; }, @{ Label = "Value"; Expression = { (Get-Variable -Name $_.Name -EA SilentlyContinue).Value }; }) |
Out-String | write-verbose
#endregion

$params = @{
  WhatIfPreference       = $WhatIfPreference;
  VerbosePreference      = $VerbosePreference;
  DebugPreference        = $DebugPreference;
  IsVerbose              = ($VerbosePreference -eq 'Continue')
}

$props = @{
}

Invoke-psake -nologo -buildFile build.psakefile.ps1 -parameters $params -properties $props -taskList $tasklist
