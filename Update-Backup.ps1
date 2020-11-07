[CmdletBinding(DefaultParameterSetName = "User")]
param (
  [parameter(Position = 0, Mandatory = $false, ParameterSetName = "Home")]
  [switch] $SetHomeParams,
  [parameter(Position = 0, Mandatory = $false, ParameterSetName = "Work")]
  [switch] $SetWorkParams,
  [parameter(Position = 0, Mandatory = $false, ParameterSetName = "Marktsoft")]
  [switch] $SetMarktsoftParams,
  [parameter(Position = 0, Mandatory = $false, ParameterSetName = "User", HelpMessage = "Source directory of the backup")]
  [string] $BackupSrc,
  [parameter(Position = 1, Mandatory = $false, ParameterSetName = "User")]
  [string] $BackupDest = $(Get-Location).Path,
  [parameter(Position = 2, Mandatory = $false, ParameterSetName = "User")]
  [string[]] $EnvVarsToBackup,
  [switch] $WaitInTheEnd
)

begin {

  $DoNotBackupDirFileName = ".DO_NOT_BACKUP_THIS_DIR"
 # $DoNotBackupAnyDirName = ".DO_NOT_BACKUP_ANY"

 # $LogFile = "Backup_$(Get-Date -uformat "%Y-%m-%d-%H-%M-%S").log"
  $LogFile = "backup.log"

  $ParamSetName = $PSCmdlet.ParameterSetName
  switch ($ParamSetName) {
    Home {  
      $BackupSrc = "$env:HOME" 
      $BackupDest = "$env:USERPROFILE\Box Sync\backup"
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
        "NVIMPATH",
        "WIX",
        "XDG_CONFIG_HOME",
        "XDG_DATA_HOME",
        "CLINK_DIR",
        # "CLINK_ROOT",
        "CLINK_PROFILE",
        "PSModulePath",
        "ChocolateyToolsLocation", 
        "MYVIMRC")
    }
    Marktsoft {  
      $BackupSrc = "$env:HOME" 
      $BackupDest = "$env:USERPROFILE\OneDrive - Marktsoft Kft\backup"
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
        "NVIMPATH",
        "WIX",
        "XDG_CONFIG_HOME",
        "XDG_DATA_HOME",
        "CLINK_DIR",
        # "CLINK_ROOT",
        "CLINK_PROFILE",
        "PSModulePath",
        "ChocolateyToolsLocation", 
        "MYVIMRC")
    }
    Work {  
      $BackupSrc = "$env:HOME" 
      $BackupDest = "s:\Backup_All\"
      $EnvVarsToBackup = (
        "AG32TEST",
        "AG32UNITTEST",
        "AGRTM",
        "AGSRC",
        #"EDITOR",
        "HOME",
        # "MSYSHOME",
        # "MSYSROOT",
        # "MYEDITOR",
        "MYVIMRC",
        # "PUTTYPATH",
        "TEMP",
        "TMP",
        "VIMPATH",
        "NVIMPATH",
        "XDG_CONFIG_HOME",
        "XDG_DATA_HOME",
        "CLINK_DIR",
        "CLINK_PROFILE",
        # "CLINK_ROOT",
        "MYVIMRC")
    } 
  }

  function Get-EnvVars {
    [CmdletBinding()]
    param (
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [String[]]$EnvVars
    )
    begin { }
    process {
      foreach ($item in $EnvVars) {
        try {
          Get-Item "env:$($item)"  -ErrorAction Stop
        }
        catch [System.Management.Automation.ItemNotFoundException] {
          Write-Log $LogFile "Environment variable '$item' not found." -ForegroundColor Yellow
        }
        catch {
          Write-Log $LogFile "Unexpected error on '$item'" -ForegroundColor Yellow
        }
      }
    }
    end { }
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
      Write-Log $LogFile "EnvVars saved to $BackupPath successfully." -ForegroundColor Green
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
      Select-String -Pattern '^([\w.-]+) [\d.]+$' |
      ForEach-Object { "choco install $($_.Matches.Groups[1].Value) -y" } | 
      Out-File -FilePath $BackupPath -Append
    }
    end {
      Write-Log $LogFile "Choco install packages are saved to $BackupPath successfully." -ForegroundColor Green
    }
  }

  function Save-ScheduledTasks {
    [CmdletBinding()]
    param (
      [String] $BackupPath = $(Join-Path '.' 'Restore-ScheduledTasks.ps1') 
    )
    begin {
      # $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
      "#Scheduled tasks backup $(Get-Date)" | Out-File -FilePath $BackupPath 
      $BackupDest = $(Get-Item $BackupPath).DirectoryName
    }

    process {
      Get-ScheduledTask -TaskPath \MyTasks\ | Foreach-Object { 
        $backupTaskXml = $(Join-Path $BackupDest "$($_.TaskName)-ScheduledTask.xml")
        Export-ScheduledTask $(Join-Path $_.TaskPath $_.TaskName) |
        Out-File -FilePath $backupTaskXml
        "Register-ScheduledTask -TaskPath \MyTasks\ -TaskName `"$($_.TaskName)`" -Xml '$(Get-Content $backupTaskXml | Out-String)'" | Out-File -FilePath $BackupPath -Append
        Write-Log $LogFile "Scheduled Task: `"$($_.TaskName)`" saved to `"$backupTaskXml`"." -ForegroundColor Green
      }
    }
    end {
      Write-Log $LogFile "Scheduled tasks are saved to $BackupPath successfully." -ForegroundColor Green
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
      function Write-EnvVarsInText {
        param($Text, $EnvVarName)
        $ret = $Text.replace($(Get-Item "env:$($EnvVarName)").Value , "`$env:$EnvVarName")
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
      Write-Log $LogFile "Symbolic links are saved from $SearchPath to $BackupPath successfully." -ForegroundColor Green
    }
  }
  
  function Write-Log {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
        HelpMessage = "Logfile name prefix")]
      [string] $LogFileName,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
        HelpMessage = "Text of log entry")]
      [string] $Text,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipelineByPropertyName = $true, 
        HelpMessage = "Foreground color of text on console")]
      [ConsoleColor] $ForegroundColor,
      [Parameter(Position = 4, Mandatory = $false, ValueFromPipelineByPropertyName = $true, 
        HelpMessage = "No new line after entry")]
      [switch] $NoNewline
    )
    begin {
      if ($LogFileName.Length -eq 0) {
        $logTime = $(Get-Date -uformat "%Y-%m-%d-%H-%M-%S")
        $LogFileName = "$($MyInvocation.MyCommand.Name).$logTime.log"
      }
    }
    process {
      if ($Text) {
        $Text | Out-File $(Join-Path "$BackupDest" "$LogFileName") -Append
      }
      Write-Host $Text -ForegroundColor $ForegroundColor -NoNewline:$NoNewline
    }
  }
  function Write-LogError {
    [CmdletBinding()]
    param (
      [String] $ErrorText,
      [String] $FilePrefix
    )
    begin {
      $logTime = $(Get-Date -uformat "%Y-%m-%d-%H-%M-%S")
      $logFileName = "$FilePrefix.$logTime.error.log"
    }
    process {
      if ($ErrorText) {
        $ProcessError | Out-File $(Join-Path "$BackupDest" "$logFileName")
      }
    }
  }

  function Find-ExcludeDirs {
    param (
      [String] $Path,
      [String] $DoNotBackupDirFileName
    )
    Push-Location $Path | Out-Null
    Find-Files $Path $DoNotBackupDirFileName -MatchFullName -UseEverything |  
    ForEach-Object { $(Resolve-Path -Relative $_.Directory) -replace "^\.\\", "" }     
    Pop-Location | Out-Null
  }

  # PSModulePath should be set!
  Import-Module Get-DirectoryStats -Force
  Import-Module Find-Everything -Force

}
process {
  # $ErrorActionPreference = "Stop"
  $EnvVarsToBackup | Save-EnvVarsBackup -BackupPath $(Join-Path $BackupDest "Restore-EnvVarsBackup.ps1") -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "EnvVarsBackup"

  Save-SymbolicLinks -SearchPath "$env:USERPROFILE\Documents" -BackupPath $(Join-Path $BackupDest "Restore-SymbolicLinks.ps1") -ReplaceEnv "USERPROFILE" -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "SymbolicLinksInDocumentsBackup" 

  Save-SymbolicLinks -SearchPath "$env:HOME" -BackupPath $(Join-Path $BackupDest "Restore-SymbolicLinks.ps1") -Append -ReplaceEnv "HOME" -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "SymbolicLinksInHomeBackup"

  Save-ScheduledTasks -BackupPath  $(Join-Path $BackupDest "Restore-ScheduledTasks.ps1") -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "ScheduledTaskBackup"

  .\Optimize-GitRepo -Path "$env:HOME" -Recurse -WriteSummary -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "OptimizeGetRepo"

  #Only at home
  if ($ParamSetName -eq "Home") {
    Save-ChocoBackup -BackupPath  $(Join-Path $BackupDest "Restore-ChocoInstallBackup.ps1")

    $ExclAllDirs = @(
      # ".git" 
      ".tmp.drivedownload" 
      "*.vimview"
    )
    $ExclFiles = @( "*.driveupload" )
  }

  $ExclDirs = Find-ExcludeDirs -Path $BackupSrc $DoNotBackupDirFileName

  $what = @("/MIR")
  $options = @("/ETA", "/Z", "/NFL", "/NDL")

  ########################
  #       ROBOCOPY       #
  ########################
  $targetLeaf=$(Get-Item $BackupSrc) -replace "\\","_"
  $targetLeaf=$targetLeaf -replace ":","!"
  $robocopyDestPath =  "$(Join-Path $BackupDest $targetLeaf)"

  .\Copy-WithRobocopy -SrcPath $BackupSrc -DestPath $robocopyDestPath -What $what -Options $options `
    -ExcludeDirs $ExclDirs -ExcludeAllDirs $ExclAllDirs -ExcludeFiles $ExclFiles
    
  Remove-Item "$BackupDest\robocopy.OK.*" 
  $robocopyLog =  $(Get-ChildItem $robocopyDestPath -Filter "robocopy*")
  Move-Item $robocopyLog.FullName $BackupDest 

  Write-Log $LogFile "Robocopy ended. See $robocopyLog for details" -ForegroundColor Green

  Write-Log $LogFile "Collect installed programs from registry." -ForegroundColor Green
  $installs = $(Join-Path $BackupDest "InstalledPrograms.txt") 
  .\Get-InstalledPrograms | Out-File -FilePath $installs
  Write-Log $LogFile "Installed Programs are saved to $installs" -ForegroundColor Green
}

end {
  $backupSize = $(Get-ByteSize -Size  $(Get-DirectoryStats -Directory $BackupDest -Recurse).Size)
  Write-Log $LogFile "`r`nBackup updated in " -ForegroundColor Green -NoNewline
  Write-Log $LogFile "$BackupDest " -ForegroundColor Blue -NoNewline
  Write-Log $LogFile "successfully. Its size is " -ForegroundColor Green -NoNewline
  Write-Log $LogFile "$backupSize" -ForegroundColor Yellow 
  if ($WaitInTheEnd) {
    Read-Host "Press enter to exit"
  }
}

