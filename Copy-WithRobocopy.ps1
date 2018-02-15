Param(
   [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, 
   HelpMessage="Source path: directory or file, wildcard can be given.")]
   [Alias("SourceDirectory")]
   [string] $SourcePath,
   [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true,
   HelpMessage="Destination directory")]
   [Alias("DestinationDirectory")]
   [string] $DestDir
)

$ScriptLocation=Split-Path -parent $MyInvocation.MyCommand.Definition
$logtime=$(get-date -uformat "%Y-%m-%d-%H-%M-%S")

$download_in_progress="DOWNLOAD_IN_PROGRESS-$logtime"

$DestDir = $DestDir -replace "`"", ""
$SourcePath = $SourcePath -replace "`"", ""

"robocopy $SourcePath to $DestDir"
if ( -not(Test-Path "$DestDir") )
{
    New-Item -path  "$DestDir" -type directory | Out-Null
}

if ( -not(Test-Path $(Join-Path "$DestDir" $download_in_progress)) )
{
    New-Item -path  "$DestDir" -name $download_in_progress -type file | Out-Null
}

$logfile="robocopy.$logtime.log"
$logdir=$(Join-Path -path $ScriptLocation -childpath "log")
$logpath=$(Join-Path $logdir $logfile)
if ( -not(Test-Path "$logdir") )
{
    New-Item -path $logdir -type directory | Out-Null
}

$FileSpecifier="*.*"
if(Test-Path "$SourcePath" -PathType Leaf) 
{
    $FileSpecifier=Split-Path "$SourcePath" -Leaf
    $SourcePath=Split-Path "$SourcePath" -Parent
}

$robocopy_start=$(Get-Date)
$estimated=New-TimeSpan
$remaining=New-TimeSpan
$full_estimated=New-TimeSpan

#    * /E Copies all subdirectories (including empty ones).
#    * /Z Restartable mode.
#    * /ETA show estimated time
#    * /XD exclude dir 
#    * /XF exclude file 
#    * /R:1000 Reply on error. The default value of N is 1,000,000 (one million retries).
#    * /W:2 Wait between replies 
ROBOCOPY "$SourcePath" "$DestDir" "$FileSpecifier" /E /Z /ETA /W:1 | 
    	%{
		switch -regex ($_){
		'^\s*New( File|er).*\t(.*)$'
		{
			$ActFileName=$Matches[2]
			$_
		}
		'^ *((\d{1,3})(\.\d)*)%\s*$'
		{
			$int_procent=$Matches[2]
			[float]$full_procent=$Matches[1]
			$status="$full_procent % completed. Elapsed:{3:00}:{4:00}:{5:00}; Estimate:{6:00}:{7:00}:{8:00}; Remaining:{0:00}:{1:00}:{2:00}" -f  
				$estimated.Hours, $estimated.Minutes, $estimated.Seconds,
                $remaining.Hours, $remaining.Minutes, $remaining.Seconds,
                $full_estimated.Hours, $full_estimated.Minutes, $full_estimated.Seconds
			Write-Progress -activity "Downloading $ActFileName." -status $status -percentcomplete $int_procent
			if($full_procent -gt 0)
			{
				$remaining=New-TimeSpan -Start $robocopy_start -End $(Get-Date)
				
                $full_est_seconds=$(($remaining.TotalSeconds) * (100/$full_procent))
				$full_estimated=New-TimeSpan -Seconds $full_est_seconds
		
				if( $full_estimated - $remaining -gt 0)
				{
					$estimated = $full_estimated - $remaining
				}
			}
            "<$_> full_proc:<$full_procent> full_e:<$full_estimated> r:<$remaining>"
		}
		default
		{
			$_
			Out-File -InputObject $_ -Append -FilePath $logpath
		}
	}
}

if( $LASTEXITCODE -ne 0 )
{
    Remove-Item (Join-Path "$DestDir" $download_in_progress)
    Move-Item $logpath -destination (Join-Path "$DestDir" "robocopy.ERROR.$logtime.log" )
    throw "Robocopy error, see $logfile for details!"
}
else
{
    Move-Item $logpath -destination (Join-Path "$DestDir" "robocopy.OK.$logtime.log" )
    Remove-Item (Join-Path "$DestDir" $download_in_progress )
}
Read-Host 