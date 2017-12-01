Clear-Host
$searcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]'')
 
While (!$result) {
    $UserName = $env:USERNAME 
    Write-Host "Current user: $UserName"
    if (!$UserName) {
        $UserName = Read-Host "Username" 
    }
    $searcher.Filter = "(&(objectClass=User)(samAccountName=$UserName))"
    $result = $searcher.Findone()
}

Write-Host $result.Path

# get domain password policy (max pw age)
$D = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$Domain = [ADSI]"LDAP://$D"

# $oldPassword = $(Read-Host -Prompt "Old Password" -AsSecureString)
$newPassword = $(Read-Host -Prompt "Provide New Password" -AsSecureString)

#$s= "LDAP://CN=$UserName,OU=ERlF,OU=User,OU=_CentralServices,DC=$www,DC=$domain,DC=$hu"
#$o = [adsi]"$s"

$Domain.SetPassword($newPassword);

Write-Host "Ready"