
function Create-FileImageObject () 
{ 
    [CmdletBinding()] 
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( { ($_.Exists) })]
        [System.IO.FileInfo]$File 
    )


    Write-Verbose "Processing file '$($File.FullName)'"
    $objImage = [System.Drawing.Image]::FromFile($File.FullName)
    $objFileInfo = [System.IO.FileInfo]::new($File.FullName)

    $Props = [ordered]@{
        Name          = $File.Name
        FullName      = $File.FullName
        BaseName      = $File.BaseName
        Size          = $objFileInfo.Length
        Extension     = $File.Extension
        DateCreated   = $File.CreationTime
        DateAccessed  = $File.LastAccessTime
        Tag           = $objImage.Tag
        PixelFormat   = $objImage.PixelFormat
        HorizontalRes = $objImage.HorizontalResolution
        VerticalRes   = $objImage.VerticalResolution
        Width         = $objImage.Width
        Height        = $objImage.Height
    }

    New-Object -TypeName psobject -Property $Props 
}

function Get-ImageFiles()
{
    [CmdletBinding()] 
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { (Test-Path -Path $_) })]
        [String]$Path,
        [ValidateSet("", ".jpg", ".gif", ".bmp")]
        [String]$FilterExtension = "",
        [int]$FilterWidth,
        [int]$FilterHeight
    )
    begin
    {        
        Add-Type -AssemblyName System.Windows.Forms
    } 
    process
    {
        $Files = @()

        if ( (Get-Item $Path) -is [System.IO.DirectoryInfo] )
        {
            $Files += Get-ChildItem -Path $Path
        }
        else 
        {
            if ( (Get-Item $Path) -is [System.IO.FileInfo] )
            {
                $Files += [System.IO.FileInfo]::new($Path)
            }
        }

        foreach ($fi in $Files)
        {
            if ($fi.Exists)
            {
                if ($FilterExtension -ne "" -and $FilterExtension -ne $fi.Extension)
                {
                    continue;
                }

                $img = [System.Drawing.Image]::FromFile($fi.FullName)
                if ($FilterWidth -ne 0 -and $FilterWidth -ne $img.Width)
                {
                    continue;
                }
                if ($FilterHeight -ne 0 -and $FilterHeight -ne $img.Height)
                {
                    continue;
                }

                Create-FileImageObject -File $fi
            }
            else
            {
                Write-Error "File not found: $Path" 
            }   
        }
    }    
    end {}
}

function Get-ItemsOlderThan()
{
[CmdletBinding()] 
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { ($_ -gt 0) })]
        [int]$Days,
        [ValidateScript( { ((Get-Item $_) -is [System.IO.DirectoryInfo]) -and (Test-Path -Path $_) })]
        [String]$Path
    )

    $limit = (Get-Date).AddDays(-$Days)
    Get-ChildItem -Path $Path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } 
}
function Copy-Images()
{
    [CmdletBinding()] 
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $True)]
        [ValidateScript( { ((Get-Item $_) -is [System.IO.DirectoryInfo]) -and (Test-Path -Path $_) })]
        [String]$Source,
        [ValidateScript( { ((Get-Item $_) -is [System.IO.DirectoryInfo]) -and (Test-Path -Path $_) })]
        [String]$Destination,
        [ValidateSet("", "jpg", "gif", "bmp")]
        [String]$NewExtension = "",
        [int]$FilterWidth = 0,
        [int]$FilterHeight = 0
    )

    $imgFiles = Get-ImageFiles -Path $Source -FilterWidth $FilterWidth -FilterHeight $FilterHeight

    Write-Progress -Activity "Copying file" -status "$Source -> $Destination" -PercentComplete 0
    $i = 1;
    foreach ($imgFile in $imgFiles)
    {

        $destFile = Join-Path $Destination "$($imgFile.BaseName).$NewExtension"
        Write-Progress -Activity "Copying file" -status "$destFile" -PercentComplete ([int](100 * $i / $imgFiles.Count))
        Copy-Item -Path $imgFile.FullName -Destination $destFile
        Write-Verbose "Copy image $($imgFile.Name) [$($imgFile.Width)x$($imgFile.Height)] -> $destFile"

        $i = $i + 1;
    }

    Write-Progress -Activity "Copying file" -Status "Ready" -Completed

}

$From = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
$To = "$env:USERPROFILE\Pictures\Windows Spotlight"

Copy-Images -Source $From -Destination $To -NewExtension "jpg" -FilterWidth 1920 -Verbose

Get-ItemsOlderThan -Days 30 -Path $To | Remove-Item -Verbose

# Access denied :(
#Get-ImageFile -path $To -FilterWidth 1080 | Select-Object Name,Width,Height
#Get-ImageFile -path $To -FilterWidth 1080 | ForEach-Object { Remove-Item $_.FullName -Verbose } 
#Get-ImageFile -path $To -FilterWidth 1080 | ForEach-Object { 
    # Write-Host "delete $($_.BaseName)"
    # (Get-Item $_.FullName).Delete() 
# } 

