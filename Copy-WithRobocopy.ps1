<#
.SYNOPSIS
Robocopy Wrapper

.DESCRIPTION
Robocopy with exclude dir wildcard suppport for copy backup

.PARAMETER SrcPath
Path of source directory

.PARAMETER DestPath
Path of destinations directory

.PARAMETER ExcludeFiles
Exlude file patterns

.PARAMETER ExcludeDirs
Exlude dir patterns in SrcPath 

.PARAMETER ExcludeAllDirs
Exlude dir patterns searched recursively by Get-ChildItem

.EXAMPLE
Copy-WithRobocopy -SrcPath "$env:HOME" -DestPath "$BackupDir\home" -ExcludeAllDirs ".git", ".tmp.drivedownload" -ExcludeDirs "tmp"

.NOTES
Some important parameters of RoboCopy
    /B :: copy files in Backup mode.
    /COPY:copyflag[s] :: what to COPY for files (default is /COPY:DAT).
                      (S=Security=NTFS ACLs, O=Owner info, U=aUditing info).
                      (copyflags : D=Data, A=Attributes, T=Timestamps).
    /COPYALL :: COPY ALL file info (equivalent to /COPY:DATSOU).
    /E :: Copies all subdirectories (including empty ones).
    /ETA :: show estimated time
    /NDL :: No Directory List - don't log directory names.
    /NFL :: No File List - don't log file names.
    /R:1000 :: Reply on error. The default value of N is 1,000,000 (one million retries).
    /SL :: copy symbolic links versus the target.
    /W:2 :: Wait between replies 
    /XD :: exclude dir 
    /XF :: exclude file 
    /Z :: Restartable mode.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
      HelpMessage = "Source path: directory or file, wildcard can be given.")]
    [ValidateScript( { ((Test-Path -Path $_)) })]
    [Alias("SourceDirectory")]
    [string] $SrcPath,
    [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true,
      HelpMessage = "Destination directory")]
    [Alias("DestinationDirectory")]
    [string] $DestPath,
    [string[]] $What = @('/MIR'),
    [string[]] $Options = @('/ETA', '/Z'), #, '/NFL', '/NDL'),
    [String[]] $ExcludeFiles,
    [String[]] $ExcludeAllDirs,
    [String[]] $ExcludeDirs,
    [switch] $ProgressIndicator
)
function Remove-ItemIfExists {
  param(
    [string] $Path
  )
  if (Test-Path $Path) {
    Remove-Item $Path
  }
}
function Copy-WithRobocopy {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
      HelpMessage = "Source path: directory or file, wildcard can be given.")]
    [ValidateScript( { ((Test-Path -Path $_)) })]
    [Alias("SourceDirectory")]
    [string] $SrcPath,
    [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true,
      HelpMessage = "Destination directory")]
    [Alias("DestinationDirectory")]
    [string] $DestPath,
    [string[]] $What = @('/MIR'),
    [string[]] $Options = @('/ETA', '/Z'), #, '/NFL', '/NDL'),
    [String[]] $ExcludeFiles,
    [String[]] $ExcludeAllDirs,
    [String[]] $ExcludeDirs,
    [switch] $ProgressIndicator
  )

  begin {
    $ROBOCOPY_IS_RUNNING = "ROBOCOPY_IS_RUNNING-$script:logtime"

    "robocopy $SrcPath to $DestPath"
    if ( -not(Test-Path "$DestPath") ) {
      New-Item -path  "$DestPath" -type directory | Out-Null
    }

    if ( -not(Test-Path $(Join-Path "$DestPath" $ROBOCOPY_IS_RUNNING)) ) {
      New-Item -path  "$DestPath" -name $ROBOCOPY_IS_RUNNING -type file | Out-Null
    }

    $robocopy_start = $(Get-Date)
    $estimated = New-TimeSpan
    $remaining = New-TimeSpan
    $full_estimated = New-TimeSpan


    $exclFiles = @()
    if ($ExcludeFiles.Count -gt 0) {
      $exclFiles += "/XF"
      foreach ($item in $ExcludeFiles) {
        $exclFiles += "`"`"$item`"`""
      }
    }
    $exclDirs = @()
    if ($ExcludeDirs.Count -gt 0) {
      $exclDirs += "/XD" 
      foreach ($item in $ExcludeDirs) {
        ForEach-Object { $exclDirs += "`"`"$(Join-Path $SrcPath $item)`"`"" }
      }
    }
    $exclAllDirs = @()
    if ($ExcludeAllDirs.Count -gt 0) {
      if ($exclDirs.Count -eq 0) {
        $exclAllDirs += "/XD" 
      }
      foreach ($item in $ExcludeAllDirs) {
        Get-ChildItem -Path $SrcPath -Filter $item -Attributes Directory -Recurse -Force |
        ForEach-Object { 
          $skipp = $false
          foreach ($item in $exclDirs) {
            if ($_.FullName.StartsWith($item.Trim('"'))) {
              $skipp = $true
              break
            }
          }
          if (-not $skipp) {
            $exclAllDirs += "`"`"$($_.FullName)`"`"" 
          }
        }
      }
    }
  }

  process {

    $cmdArgs = @("$SrcPath", "$DestPath", $What, $Options, $exclFiles, $exclDirs, $exclAllDirs)
    robocopy @cmdArgs |
    ForEach-Object {
      if (-not $ProgressIndicator) {
        $_
      }
      else {
        switch -regex ($_) {
          '^\s*New( File|er).*\t(.*)$' {
            $ActFileName = $Matches[2]
            $_
          }
          '^ *((\d{1,3})(\.\d)*)%\s*$' {
            $int_procent = $Matches[2]
            [float]$full_procent = $Matches[1]
            $status = "$full_procent % completed. Elapsed:{3:00}:{4:00}:{5:00}; Estimate:{6:00}:{7:00}:{8:00}; Remaining:{0:00}:{1:00}:{2:00}" -f  
            $estimated.Hours, $estimated.Minutes, $estimated.Seconds,
            $remaining.Hours, $remaining.Minutes, $remaining.Seconds,
            $full_estimated.Hours, $full_estimated.Minutes, $full_estimated.Seconds
            Write-Progress -activity "Downloading $ActFileName." -status $status -percentcomplete $int_procent
            if ($full_procent -gt 0) {
              $remaining = New-TimeSpan -Start $robocopy_start -End $(Get-Date)
				
              $full_est_seconds = $(($remaining.TotalSeconds) * (100 / $full_procent))
              $full_estimated = New-TimeSpan -Seconds $full_est_seconds
		
              if ( $full_estimated - $remaining -gt 0) {
                $estimated = $full_estimated - $remaining
              }
            }
            # "<$_> full_proc:<$full_procent> full_e:<$full_estimated> r:<$remaining>"
          }
          default {
            $_
          }
        }
      }
    }
    $script:robocopy_lastexitcode = $LASTEXITCODE

  }
  end {
    Remove-ItemIfExists $(Join-Path "$DestPath" $ROBOCOPY_IS_RUNNING)
    if ( $script:robocopy_lastexitcode -gt 7 ) {
      Write-Host  "Robocopy ended with error: $script:robocopy_lastexitcode." -ForegroundColor Red
    }
    else {
      Write-Host  "Robocopy ended successfully." -ForegroundColor Green
    }
  }
}

$ErrorActionPreference = "Stop"
$ScriptLocation = Split-Path -parent $MyInvocation.InvocationName
$script:logtime = $(Get-Date -uformat "%Y-%m-%d-%H-%M-%S")

$logfile = "robocopy.$script:logtime.log"
$logdir = $(Join-Path -path $ScriptLocation -childpath ".ROBOCOPY-logs")

if ( -not (Test-Path "$logdir") ) {
  New-Item -path $logdir -type directory | Out-Null
}
[string] $script:logpath = $(Join-Path $logdir $logfile)

Copy-WithRobocopy -SrcPath $SrcPath -DestPath $DestPath -What $What -Options $Options -ExcludeDirs $ExclDirs -ExcludeAllDirs $ExclAllDirs -ExcludeFiles $ExclFiles -ProgressIndicator:$ProgressIndicator | 
Tee-Object -Append -FilePath $script:logpath

if ( $script:robocopy_lastexitcode -gt 7 ) {
  Move-Item $script:logpath -destination (Join-Path "$DestPath" "robocopy.ERROR.$script:logtime.log" )
  throw "Robocopy error, see $logfile for details!"
}
else {
  Move-Item $logpath -destination (Join-Path $DestPath "robocopy.OK.$script:logtime.log" )
}
