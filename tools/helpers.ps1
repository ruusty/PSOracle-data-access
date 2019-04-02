
function get-InstDrive
{
  if (test-path -Path 'd:' -Type Container)
  {
   $rv="d:"
  }
  elseif (test-path -Path 'c:' -Type Container)
  {
    $rv = "c:"
  }
  else
  {
    throw [System.IO.FileNotFoundException]  "Install Drive not available"
  }
  $rv
}

