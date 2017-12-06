function Set-FileTime{
    param(
      [string[]]$Paths,
      [bool]$ModificationOnly = $false,
      [bool]$AccessOnly = $false,
      [DateTime]$DateTime = $(Get-Date)
    );
  
    begin {
      function updateFileSystemInfo([System.IO.FileSystemInfo]$fsInfo) {
        if ( $AccessOnly )
        {
           $fsInfo.LastAccessTime = $DateTime
        }
        elseif ( $ModificationOnly )
        {
           $fsInfo.LastWriteTime = $DateTime
        }
        else
        {
           $fsInfo.CreationTime = $DateTime
           $fsInfo.LastWriteTime = $DateTime
           $fsInfo.LastAccessTime = $DateTime
         }
      }
     
      function touchExistingFile($arg) {
        if ($arg -is [System.IO.FileSystemInfo]) {
          updateFileSystemInfo($arg)
        }
        else {
          $resolvedPaths = resolve-path $arg
          foreach ($rpath in $resolvedPaths) {
            if (test-path -type Container $rpath) {
              $fsInfo = new-object System.IO.DirectoryInfo($rpath)
            }
            else {
              $fsInfo = new-object System.IO.FileInfo($rpath)
            }
            updateFileSystemInfo($fsInfo)
          }
        }
      }
     
      function touchNewFile([string]$path) {
        #$null > $path
        Set-Content -Path $path -value $null;
      }
    }
   
    process {
      if ($_) {
        if (test-path $_) {
          touchExistingFile($_)
        }
        else {
          touchNewFile($_)
        }
      }
    }
   
    end {
      if ($Paths) {
        foreach ($path in $Paths) {
          if (test-path $path) {
            touchExistingFile($path)
          }
          else {
            touchNewFile($path)
          }
        }
      }
    }
  }

  New-Alias touch Set-FileTime