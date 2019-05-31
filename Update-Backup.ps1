[CmdletBinding(DefaultParameterSetName = "User")]
param (
  [parameter(Position = 0, Mandatory = $false, ParameterSetName = "Home")]
  [switch] $SetHomeParams,
  [parameter(Position = 0, Mandatory = $false, ParameterSetName = "Work")]
  [switch] $SetWorkParams,
  [parameter(Position = 0, Mandatory = $false, ParameterSetName = "User")]
  [string] $BackupDir = $(Get-Location).Path,
  [parameter(Position = 1, Mandatory = $false, ParameterSetName = "User")]
  [string[]] $EnvVarsToBackup,
  [switch] $WaitInTheEnd
)

begin {

  $ParamSetName = $PSCmdlet.ParameterSetName
  switch ($ParamSetName) {
    Home {  
      $BackupDir = "$env:USERPROFILE\Box Sync\backup"
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
    }
    Work {  
      $BackupDir = "s:\Backup_All\"
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
        Get-Item "env:$($item)" 
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

  function Save-ScheduledTasks {
    [CmdletBinding()]
    param (
      [String] $BackupPath = $(Join-Path '.' 'Restore-ScheduledTasks.ps1') 
    )
    begin {
      # $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
      "#Scheduled tasks backup $(Get-Date)" | Out-File -FilePath $BackupPath 
      $BackupDir = $(Get-Item $BackupPath).DirectoryName
    }

    process {
      Get-ScheduledTask -TaskPath \MyTasks\ | Foreach-Object { 
        $backupTaskXml = $(Join-Path $BackupDir "$($_.TaskName)-ScheduledTask.xml")
        Export-ScheduledTask $(Join-Path $_.TaskPath $_.TaskName) |
        Out-File -FilePath $backupTaskXml
        "Register-ScheduledTask -TaskPath \MyTasks\ -TaskName `"$($_.TaskName)`" -Xml `"$(Get-Content $backupTaskXml | Out-String)`"" | Out-File -FilePath $BackupPath -Append
        Write-Host "Scheduled Task: `"$($_.TaskName)`" saved to `"$backupTaskXml`"." -ForegroundColor Green
      }
    }
    end {
      Write-Host "Scheduled tasks are saved to $BackupPath successfully." -ForegroundColor Green
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
      Write-Host "Symbolic links are saved from $SearchPath to $BackupPath successfully." -ForegroundColor Green
    }
  }
  function Write-LogError {
    [CmdletBinding()]
    param (
      [String] $ErrorText,
      [String] $FilePrefix
    )
    begin {
      $logTime= $(Get-Date -uformat "%Y-%m-%d-%H-%M-%S")
      $logFileName = "$FilePrefix.$logTime.error.log"
    }
    process{
      if ($ErrorText) {
        $ProcessError | Out-File $(Join-Path "$BackupDir" "$logFileName")
      }
    }
  }


  Import-Module ${env:HOME}\dev\powershell\Modules\Get-DirectoryStats -Force
}
process {
  # $ErrorActionPreference = "Stop"
  $EnvVarsToBackup | Save-EnvVarsBackup -BackupPath $(Join-Path $BackupDir "Restore-EnvVarsBackup.ps1") -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "EnvVarsBackup"

  Save-SymbolicLinks -SearchPath "$env:USERPROFILE\Documents" -BackupPath $(Join-Path $BackupDir "Restore-SymbolicLinks.ps1") -ReplaceEnv "USERPROFILE" -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "SymbolicLinksInDocumentsBackup" 

  Save-SymbolicLinks -SearchPath "$env:HOME" -BackupPath $(Join-Path $BackupDir "Restore-SymbolicLinks.ps1") -Append -ReplaceEnv "HOME" -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "SymbolicLinksInHomeBackup"

  Save-ScheduledTasks -BackupPath  $(Join-Path $BackupDir "Restore-ScheduledTasks.ps1") -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "ScheduledTaskBackup"

  .\Optimize-GitRepo -Path "$env:HOME" -Recurse -WriteSummary -ErrorAction Stop -ErrorVariable ProcessError;
  Write-LogError -ErrorText $ProcessError -FilePrefix "OptimizeGetRepo"

  #Only at home
  if ($ParamSetName -eq "Home") {
    Save-ChocoBackup -BackupPath  $(Join-Path $BackupDir "Restore-ChocoInstallBackup.ps1")

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
    $ExclFiles = @( "*.driveupload" )
  }

  $what = @("/MIR")
  $options = @("/ETA", "/Z", "/NFL", "/NDL")

  ########################
  #       ROBOCOPY       #
  ########################
  .\Copy-WithRobocopy -SrcPath "$env:HOME" -DestPath "$(Join-Path $BackupDir "home")" -What $what -Options $options `
    -ExcludeDirs $ExclDirs -ExcludeAllDirs $ExclAllDirs -ExcludeFiles $ExclFiles
}

end {
  $backupSize = $(Get-ByteSize -Size  $(Get-DirectoryStats -Directory $BackupDir -Recurse).Size)
  Write-Host "Backup updated in " -ForegroundColor Green -NoNewline
  Write-Host "$BackupDir " -ForegroundColor Blue -NoNewline
  Write-Host "successfully. Its size is " -ForegroundColor Green -NoNewline
  Write-Host "$backupSize" -ForegroundColor Yellow 
  if ($WaitInTheEnd) {
    Read-Host "Press enter to exit"
  }
}

