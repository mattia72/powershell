
function Get-ADEntry 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [String]$UserName = $env:USERNAME
    )
    begin
    {
        $root = [ADSI]''
        $searcher = new-object     System.DirectoryServices.DirectorySearcher($root)
        $searcher.filter = "(&(objectClass=user)(SAMAccountName=$UserName))"
        $user = $searcher.findall()
    }

    process
    {
        if ($user.count -gt 1)
        {    
            $count = 0
            foreach ($i in $user)
            {
                write-host $count ": " $i.path
                $count = $count + 1
            }

            $selection = Read-Host "Please select item: "
            return $user[$selection]
        }
        else
        {
            return $user[0]
        }
    }
    end {}
}