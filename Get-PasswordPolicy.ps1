Clear-Host
 
$searcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]'')
 
While (!$result) {
    $UserName = Read-Host 'Username'
    if (!$UserName) {
        Write-Host "No Username Entered"
        exit
    }
    $searcher.Filter = "(&(objectClass=User)(samAccountName=" + $username + "))"
    $result = $searcher.Findone()
}
# get domain password policy (max pw age)
$D = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$Domain = [ADSI]"LDAP://$D"
$MPA = $Domain.maxPwdAge.Value
$MinPA = $Domain.minPwdAge.Value
# Convert to Int64 ticks (100-nanosecond intervals).
$lngMaxPwdAge = $Domain.ConvertLargeIntegerToInt64($MPA)
$lngMinPwdAge = $Domain.ConvertLargeIntegerToInt64($MinPA)
$MinPwdLength = $Domain.minPwdLength
$PwdHistory = $Domain.pwdHistoryLength
 
# Convert to days.
$MaxPwdAge = - $lngMaxPwdAge / (600000000 * 1440)
$MinPwdAge = - $lngMinPwdAge / (600000000 * 1440)
 
$lngPwdLastSet = $result.Properties.pwdlastset
$pwdLastSet = [datetime]::FromFileTime($lngPwdLastSet[0])
 
Write-Host $result.Path
Write-Host $result.Properties.cn " " $result.Properties.userprincipalname
Write-Host "Password Last Set : " $pwdLastSet
Write-Host "Max Password Age : " $MaxPwdAge
Write-Host "Min Password Age : " $MinPwdAge
Write-Host "Password History : " $PwdHistory
Write-Host "Min Password Length : " $MinPwdLength
if ($pwdLastSet -ge (Get-Date).AddDays( - $MinPwdAge)) {Write-Host -ForegroundColor Red "Password can not be changed - Min Age"}
if ($pwdLastSet -ge (Get-Date).AddDays($MaxPwdAge)) {Write-Host -ForegroundColor Red "Password Expired"}