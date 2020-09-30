[CmdletBinding()] 
    Param (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] 
        [string]$Path
)
<# .SYNOPSIS Gets file encoding.
.DESCRIPTION The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM). Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx
 
.EXAMPLE
 Get-ChildItem c:\ws\git_repos\COMPONENT_TEMPLATE -recurse -File |
    select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}}
  
$erroractionpreference = 'stop'
  Get-ChildItem c:\ws\git_repos\COMPONENT_TEMPLATE -recurse -File |
    foreach {
        Write-Output $_.FullName
        Get-FileEncoding $_.FullName
    }
      
     This command gets ps1 files in current directory where encoding is not ASCII
  
 .EXAMPLE Get-ChildItem *.ps1 |
     select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} |
         where {$_.Encoding -ne 'ASCII'} foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding ASCII}
          
         Same as previous example but fixes encoding using set-content #>
# Modified by F.RICHARD August 2010
# add comment + more BOM
# http://unicode.org/faq/utf_bom.html
# http://en.wikipedia.org/wiki/Byte_order_mark
#
# Do this next line before or add function in Profile.ps1
# Import-Module .\Get-FileEncoding.ps1
#>
function Get-FileEncoding
{
    [CmdletBinding()] 
    Param (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] 
        [string]$Path
    )
    $legacyEncoding = $false
    try {
        try {
            [byte[]]$byte = get-content -AsByteStream -ReadCount 4 -TotalCount 4 -LiteralPath $Path
            
        } catch {
            [byte[]]$byte = get-content -Encoding Byte -ReadCount 4 -TotalCount 4 -LiteralPath $Path
            $legacyEncoding = $true
        }
        
        if(-not $byte) {
            if($legacyEncoding) { "unknown" } else {  [System.Text.Encoding]::Default }
        }
    } catch {
        throw
    }
    
    #Write-Host Bytes: $byte[0] $byte[1] $byte[2] $byte[3]
 
    # EF BB BF (UTF8)
    if ( $byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf )
    { if($legacyEncoding) { "UTF8" } else { [System.Text.Encoding]::UTF8 } }
 
    # FE FF (UTF-16 Big-Endian)
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
    { if($legacyEncoding) { "bigendianunicode" } else { [System.Text.Encoding]::BigEndianUnicode } }
 
    # FF FE (UTF-16 Little-Endian)
    elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe)
    { if($legacyEncoding) { "unicode" } else { [System.Text.Encoding]::Unicode }}
 
    # 00 00 FE FF (UTF32 Big-Endian)
    elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
    { if($legacyEncoding) { "utf32" } else { [System.Text.Encoding]::UTF32 }}
 
    # FE FF 00 00 (UTF32 Little-Endian)
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff -and $byte[2] -eq 0 -and $byte[3] -eq 0)
    { if($legacyEncoding) { "utf32" } else { [System.Text.Encoding]::UTF32 }}
 
    # 2B 2F 76 (38 | 38 | 2B | 2F)
    elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76 -and ($byte[3] -eq 0x38 -or $byte[3] -eq 0x39 -or $byte[3] -eq 0x2b -or $byte[3] -eq 0x2f) )
    {if($legacyEncoding) { "utf7" } else { [System.Text.Encoding]::UTF7}}
 
    # F7 64 4C (UTF-1)
    elseif ( $byte[0] -eq 0xf7 -and $byte[1] -eq 0x64 -and $byte[2] -eq 0x4c )
    { throw "UTF-1 not a supported encoding" }
 
    # DD 73 66 73 (UTF-EBCDIC)
    elseif ($byte[0] -eq 0xdd -and $byte[1] -eq 0x73 -and $byte[2] -eq 0x66 -and $byte[3] -eq 0x73)
    { throw "UTF-EBCDIC not a supported encoding" }
 
    # 0E FE FF (SCSU)
    elseif ( $byte[0] -eq 0x0e -and $byte[1] -eq 0xfe -and $byte[2] -eq 0xff )
    { throw "SCSU not a supported encoding" }
 
    # FB EE 28 (BOCU-1)
    elseif ( $byte[0] -eq 0xfb -and $byte[1] -eq 0xee -and $byte[2] -eq 0x28 )
    { throw "BOCU-1 not a supported encoding" }
 
    # 84 31 95 33 (GB-18030)
    elseif ($byte[0] -eq 0x84 -and $byte[1] -eq 0x31 -and $byte[2] -eq 0x95 -and $byte[3] -eq 0x33)
    { throw "GB-18030 not a supported encoding" }
 
    else
    { if($legacyEncoding) { "ascii" } else { [System.Text.Encoding]::ASCII }}
}

Get-FileEncoding $Path