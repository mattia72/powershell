. .\Get-ADEntry

Clear-Host
 
While (!$user)
{
    $UserName = $env:USERNAME 
    Write-Host "Current user: $UserName"
    if (!$UserName)
    {
        $UserName = Read-Host "Username" 
    }
    $user = Get-ADEntry -username $UserName
}

# get domain password policy (max pw age)
$D = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$Domain = [ADSI]"LDAP://$D"
# $Domain | Get-Member
$MPA = $Domain.maxPwdAge.Value
$MinPA = $Domain.minPwdAge.Value
# Convert to Int64 ticks (100-nanosecond intervals).
$lngMaxPwdAge = $Domain.ConvertLargeIntegerToInt64($MPA)
$lngMinPwdAge = $Domain.ConvertLargeIntegerToInt64($MinPA)
$MinPwdLength = $Domain.minPwdLength
$PwdHistory = $Domain.pwdHistoryLength
# $PwdHistory = $Domain.pwd
 
# Convert to days.
$MaxPwdAge = - $lngMaxPwdAge / (600000000 * 1440)
$MinPwdAge = - $lngMinPwdAge / (600000000 * 1440)
 
$lngPwdLastSet = $user.Properties.pwdlastset
$pwdLastSet = [datetime]::FromFileTime($lngPwdLastSet[0])
 
Write-Host $user.Path
Write-Host $user.Properties.cn ": " $user.Properties.userprincipalname
Write-Host "Password Last Set   : " $pwdLastSet
$pwdLastSetDays = New-TimeSpan -Start (Get-Date) -End $pwdLastSet
Write-Host "Password Age        : " $pwdLastSetDays.Days " day(s)"
Write-Host "Max Password Age    : " $MaxPwdAge " day(s)"
Write-Host "Min Password Age    : " $MinPwdAge " day(s)"
Write-Host "Password History    : " $PwdHistory
Write-Host "Min Password Length : " $MinPwdLength


if ($pwdLastSet -ge (Get-Date).AddDays( - $MinPwdAge)) {
    Write-Host -ForegroundColor Red "Password can not be changed, it is only $($pwdLastSetDays.Days) days old!"
}
if ($pwdLastSet -ge (Get-Date).AddDays($MaxPwdAge)) {
    Write-Host -ForegroundColor Red "Password Expired!"
}