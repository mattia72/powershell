function Get-LogonEvents {
  param(
    [CmdletBinding()]
    [int] $DaysBefore = 21,
    [string] $OutputFilePath,
    [string] $OutputCSVFilePath,
    [switch] $FormatTable = $false
  )
  begin {
    $ErrorActionPreference = "Stop"
    $logins = @()

    [System.Diagnostics.Debug]::WriteLine("DaysBefore $DaysBefore")
    [System.Diagnostics.Debug]::WriteLine("OutputFilePath $OutputFilePath")
    [System.Diagnostics.Debug]::WriteLine("DoNotWaitInTheEnd $DoNotWaitInTheEnd")

    $LoginEventID = 7001
    $LogoutEventID = 7002
    $DateFrom = $(Get-Date).AddDays(-1*$DaysBefore) 
  }

  process {
    #depricated
    #Get-EventLog System -source Microsoft-Windows-Winlogon -After $((Get-Date).AddDays(-1*$DaysBefore)) | Sort-Object -Property TimeWritten | 
    Get-WinEvent -ProviderName Microsoft-Windows-Winlogon | Where-Object { $_.ID -in ($LoginEventID, $LogoutEventID) -and $_.TimeCreated -gt $DateFrom} | 
    Sort-Object -Property TimeCreated |
    ForEach-Object {
      $time = $_.TimeCreated

      if ($_.ID -eq $LogoutEventID -and $logins.Length -gt 0) {
        $last = $logins.Length - 1
        $logins[$last].Logout = $time.ToString("HH:mm")
        $logins[$last].LogoutTime = $time
        $logins[$last].Elapsed = (New-TimeSpan -Start $logins[$last].LoginTime -End $time).ToString("dd\.hh\:mm").Replace("00.", "")
      }
      elseif ($_.ID -eq $LoginEventID) {
        $logins += [PSCustomObject]@{
          Date       = $time.ToString("yyyy.MM.dd")
          LoginTime  = $time
          Login      = $time.ToString("HH:mm")
          Logout     = ""
          LogoutTime = $null
          Elapsed    = (New-TimeSpan -Start $time -End $(Get-Date)).ToString("dd\.hh\:mm").Replace("00.", "")
        }
      }
    }
    if ($OutputCSVFilePath) {
      $logins | Select-Object -Property Date, Login, Logout, Elapsed | Export-Csv -NoTypeInformation -Path $OutputCSVFilePath
    }
    if ($OutputFilePath) {
      $content = $logins | Format-Table -HideTableHeaders -Property Date, Login, Logout, Elapsed | Out-String
      # Write-Debug $msg
      if ($null -eq $content) {
        $content = "No event found."
      }

      $msg = "Writing $($content.Length) chars to $OutputFilePath"
      [System.Diagnostics.Debug]::WriteLine($msg);

      $content.Replace('  ', ' ') | Out-File $OutputFilePath
      Get-Content $OutputFilePath
    }

    if ($FormatTable) {
      $logins | Format-Table -Property Date, Login, Logout, Elapsed
    }
    else {
      $logins 
    }
  }
  end {

  }
}

Export-ModuleMember -Function Get-LogonEvents