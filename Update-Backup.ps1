$EnvVarsToBackup = (
  "EDITOR",
  "HOME",
  "MSYSHOME",
  "MSYSROOT",
  "MYEDITOR",
  "MYVIMRC",
  "PUTTYPATH",
  "TEMP",
  "TMP",
  "VIMPATH",
  "WIX",
  "XDG_CONFIG_HOME",
  "XDG_DATA_HOME",
  "CLINK_DIR",
  "CLINK_ROOT",
  "ChocolateyToolsLocation", 
  "MYVIMRC")

function Get-EnvVars {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String[]]$EnvVars
  )
  begin { }
  process {
    foreach ($item in $EnvVars) {
      Get-Item "env:$($item)" 
    }
  }
  end { }
}

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
General notes
#>
function Copy-WithRobocopy {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ValidateScript( { ((Test-Path -Path $_) -and ((Get-Item $_) -is [System.IO.DirectoryInfo])) })]
    [String]$SrcPath,
    [Parameter(Mandatory = $true)]
    [ValidateScript( { ((Test-Path -Path $_) -and ((Get-Item $_) -is [System.IO.DirectoryInfo])) })]
    [String]$DestPath,
    [String[]]$ExcludeFiles,
    [String[]]$ExcludeAllDirs,
    [String[]]$ExcludeDirs
  )
    
  begin {
    #    /B :: copy files in Backup mode.
    #    /COPY:copyflag[s] :: what to COPY for files (default is /COPY:DAT).
    #                      (S=Security=NTFS ACLs, O=Owner info, U=aUditing info).
    #                      (copyflags : D=Data, A=Attributes, T=Timestamps).
    #    /COPYALL :: COPY ALL file info (equivalent to /COPY:DATSOU).
    #    /E :: Copies all subdirectories (including empty ones).
    #    /ETA :: show estimated time
    #    /NDL :: No Directory List - don't log directory names.
    #    /NFL :: No File List - don't log file names.
    #    /R:1000 :: Reply on error. The default value of N is 1,000,000 (one million retries).
    #    /SL :: copy symbolic links versus the target.
    #    /W:2 :: Wait between replies 
    #    /XD :: exclude dir 
    #    /XF :: exclude file 
    #    /Z :: Restartable mode.
    # $what = @("/COPYALL", "/B", "/MIR")
    $what = @("/MIR")
    # $options = @("/NFL", "/NDL")
    $options = @("/ETA", "/Z", "/NFL")

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
            if ($_.FullName.StartsWith($item.Trim('"'))){
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
    $cmdArgs = @("$SrcPath", "$DestPath", $what, $options, $exclFiles, $exclDirs, $exclAllDirs)
  }
    
  process {
    robocopy @cmdArgs
  }
    
  end {
  }
}

function Save-EnvVarsBackup {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String[]]$EnvVarsToBackup,
    [String] $BackupPath = $(Join-Path '.' 'Restore-EnvVarsBackup.ps1') 
  )
  begin {
    # $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    "# EnvBackup backup $(Get-Date)" | Out-File -FilePath $BackupPath 
  }
  process {
    $EnvVarsToBackup | 
    Get-EnvVars | 
    ForEach-Object { "setx $($_.Name) `"$($_.Value)`"`nWrite-Host `"$($_.Name) = $($_.Value) was saved.`"" } | 
    Out-File -FilePath $BackupPath  -Append
  }
  end {
    Write-Host "EnvVars saved to $BackupPath successfully." -ForegroundColor Green
  }
}

function Save-ChocoBackup {
  [CmdletBinding()]
  param (
    [String] $BackupPath = $(Join-Path '.' 'Restore-ChocoInstallBackup.ps1') 
  )
  begin {
    # $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    "#Choco installs backup $(Get-Date)" | Out-File -FilePath $BackupPath 
    "#Requires -RunAsAdministrator" | Out-File -FilePath $BackupPath -Append 
  }

  process {
    choco list -l | 
    Select-String -Pattern '^([\w.]+) [\d.]+$' |
    ForEach-Object { "choco install $($_.Matches.Groups[1].Value) -y" } | 
    Out-File -FilePath $BackupPath -Append
  }
  end {
    Write-Host "Choco install packages are saved to $BackupPath successfully." -ForegroundColor Green
  }
}

function Save-SymbolicLinks {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateScript( { ((Test-Path -Path $_) -and ((Get-Item $_) -is [System.IO.DirectoryInfo])) })]
    [String]$SearchPath = (Get-Location).Path,
    [String]$BackupPath = $(Join-Path '.' 'Restore-SymbolicLinks.ps1'),
    [Switch]$Append,
    [String]$ReplaceEnv = "USERPROFILE"
  )
  
  begin {
    "# Symbolic links backup from $((Get-Item $SearchPath).FullName) $(Get-Date)" | Out-File -FilePath $BackupPath -Append:$Append
    function Write-EnvVarsInText{
      param($Text, $EnvVarName)
      $ret = $Text.replace($(Get-Item "env:$($EnvVarName)").Value ,"`$env:$EnvVarName")
      return $ret
    }
  }
  
  process {
    Get-ChildItem $SearchPath -Recurse | Where-Object {
      -not $_.FullName.Contains(".tmp.drivedownload") -and 
      -not $_.FullName.Contains(".git") -and 
      $_.LinkType -eq "SymbolicLink" 
    } | Select-Object FullName, Target | ForEach-Object {
      $link = Write-EnvVarsInText -Text "$($_.FullName)" -EnvVarName $ReplaceEnv
      if ((Get-Item $_.FullName) -is [System.IO.DirectoryInfo]) {
        foreach ($item in $_.Target) {
          $target = Write-EnvVarsInText -Text $item -EnvVarName $ReplaceEnv
          # mklink /D LinkDir TargetDir
          "mklink /D `"$link`" `"$target`""
        }
      } 
      else {
        foreach ($item in $_.Target) {
          $target = Write-EnvVarsInText -Text $item -EnvVarName $ReplaceEnv
          "mklink `"$link`" `"$target`""
        }
      }
    } | Out-File -FilePath $BackupPath  -Append

  }
  end {
    Write-Host "Symbolic links are saved from $SearchPath to $BackupPath successfully." -ForegroundColor Green
  }
}

Import-Module ${env:HOME}\dev\powershell\Modules\Get-DirectoryStats -Force
$BackupDir = "$env:USERPROFILE\Box Sync\backup"

$EnvVarsToBackup | Save-EnvVarsBackup -BackupPath $(Join-Path $BackupDir "Restore-EnvVarsBackup.ps1")
Save-ChocoBackup -BackupPath  $(Join-Path $BackupDir "Restore-ChocoInstallBackup.ps1")
Save-SymbolicLinks -SearchPath "$env:USERPROFILE\Documents" -BackupPath $(Join-Path $BackupDir "Restore-SymbolicLinks.ps1") -ReplaceEnv "USERPROFILE"
Save-SymbolicLinks -SearchPath "$env:HOME" -BackupPath $(Join-Path $BackupDir "Restore-SymbolicLinks.ps1") -Append -ReplaceEnv "HOME"

.\Optimize-GitRepo -Path "$env:HOME" -Recurse

########################
# ROBOCOPY
########################

$ExclDirs = @(
  "downloads"
  "vimfiles"
  ".vim\plugged"
  ".cache"
)

$ExclAllDirs = @(
  # ".git" 
  ".tmp.drivedownload" 
  "*.vimview"
)

$ExclFiles = @(
  "*.driveupload" 
  "~*=" 
  "c*="
)

Copy-WithRobocopy -SrcPath "$env:HOME" -DestPath "$BackupDir\home" -ExcludeDirs $ExclDirs -ExcludeAllDirs $ExclAllDirs -ExcludeFiles $ExclFiles

$backupSize = $(Get-ByteSize -Size  $(Get-DirectoryStats -Directory $BackupDir -Recurse).Size)
Write-Host "Backup updated in " -ForegroundColor Green -NoNewline
Write-Host "$BackupDir " -ForegroundColor Blue -NoNewline
Write-Host "successfully. Its size is " -ForegroundColor Green -NoNewline
Write-Host "$backupSize" -ForegroundColor Yellow 

Read-Host "Press enter to exit"

