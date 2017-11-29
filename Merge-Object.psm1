Function Merge-Objects {
<#
    .SYNOPSIS
    Combine two PowerShell Objects into one.
 
    .DESCRIPTION
    will combine two custom powershell objects in order to make one. This can be helpfull to add information to an already existing object. (this might make sence in all the cases through).
     
 
    .EXAMPLE
     
    Combine objects allow you to combine two seperate custom objects together in one.
 
    $Object1 = [PsCustomObject]@{"UserName"=$UserName;"FullName" = $FullName;"UPN"=$UPN}
    $Object2 = [PsCustomObject]@{"VorName"= $Vorname;"NachName" = $NachName}
 
    Combine-Object -Object1 $Object1 -Object2 $Object2
 
    Name                           Value                                                                                                                                                                                           
    ----                           -----                                                                                                                                                                                           
    UserName                       Vangust1                                                                                                                                                                                        
    FullName                       Stephane van Gulick                                                                                                                                                                             
    UPN                            @PowerShellDistrict.com                                                                                                                                                                                     
    VorName                        Stephane                                                                                                                                                                                        
    NachName                       Van Gulick 
     
    .EXAMPLE
 
    It is also possible to combine system objects (Which could not make sence sometimes though!).
 
    $User = Get-ADUser -identity vanGulick
    $Bios = Get-wmiObject -class win32_bios
 
    Merge-Objects -Object1 $bios -Object2 $User
 
 
    .NOTES
    -Author: Stephane van Gulick
    -Twitter : stephanevg 
    -CreationDate: 10/28/2014
    -LastModifiedDate: 10/28/2014
    -Version: 1.0
    -History:
 
.LINK
 
http://www.powershellDistrict.com
 
#>
 
 
    Param (
        [Parameter(mandatory=$true)]$Object1, 
        [Parameter(mandatory=$true)]$Object2
    )
     
    $arguments = [Pscustomobject]@()
 
    foreach ( $Property in $Object1.psobject.Properties){
        $arguments += @{$Property.Name = $Property.value}
         
    }
 
    foreach ( $Property in $Object2.psobject.Properties){
        $arguments += @{ $Property.Name= $Property.value}
         
    }
     
     
    $Object3 = [Pscustomobject]$arguments
     
 
    return $Object3
}

Export-ModuleMember -Function Merge-Objects