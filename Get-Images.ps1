#Requires -Version 4

function Get-Images
{
    <# 
 .SYNOPSIS
  Script to get image file information like 'DateTaken'

 .DESCRIPTION
  Script to get image file information like 'DateTaken'
  Script returns a PS object containing image file(s) information

 .PARAMETER Source
  Path to one or more folders where image files are located

 .PARAMETER Extension
  One or more image file extensions, such as .jpg and .gif
  If no extensions are specified, the script looks for .jpg and .gif 
  image files by default.

 .EXAMPLE
  Get-Images -Source E:\Pictures\001 -Extension .jpg
  This example will return information on image files with .jpg extension in the given folder and its subfolders

 .EXAMPLE
  Get-Images e:\pictures\001,e:\pictures\005 -Verbose
  This example gets image information on images files in the 2 specified folders, showing verbose messages during processing

 .EXAMPLE
  $Images = Get-Images e:\pictures\001,e:\pictures\005 | 
    Select Name,@{N='Size(KB)';E={[Math]::Round($_.Size/1KB,0)}},DateTaken,CameraMaker,Width,Height | Sort DateTaken -Descending
  $Images | Format-Table -AutoSize # Display on console
  $Images | Out-GridView # Disply on PowerShell_ISE gridview
  $Images | Export-CSV .\myimages.csv -NoType # Save to CSV

 .EXAMPLE
    # Move image files from $SourceFolders to year based folders under $RootFolder based on DateTaken
    $SourceFolders = @('e:\pictures\001','e:\pictures\005')
    $RootFolder    = 'd:\sandbox\pics'
    Get-Images $SourceFolders | % {
        $YearTaken = $_.DateTaken.Split('/')[2].Split(' ')[0]
        if (-not (Test-Path -Path "$RootFolder\$YearTaken")) { 
            "Creating folder '$RootFolder\$YearTaken'"
            New-Item -Path "$RootFolder\$YearTaken" -ItemType Directory -Force -Confirm:$false
        }
        "Moving image '$($_.Name)' from '$(Split-Path -Path $_.FullName )' to '$RootFolder\$YearTaken'"
        Move-Item -Path $_.FullName -Destination "$RootFolder\$YearTaken" -Force -Confirm:$false
    }

 .OUTPUTS
  Script will return an array of PS Objects, each has the following properties:
    Name         
    FullName      
    Size         
    #Type         
    Extension     
    DateModified 
    DateCreated   
    DateAccessed  
    DateTaken   
    CameraModel  
    CameraMaker  
    BitDepth      
    HorizontalRes 
    VerticalRes 
    Width       
    Height        

 .LINK
  http://superwidgets.wordpress.com/category/powershell/
  http://superwidgets.wordpress.com/2014/08/15/powershell-script-to-get-detailed-image-file-information-such-as-datetaken/
  
 .NOTES
  Script by Sam Boutros
  v1.0 - 1/11/2015

  Changed by Mattia72
  v1.5 - 2017.07.10 

#>

    [CmdletBinding()] 
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( { (Test-Path -Path $_) })]
        [String[]]$Source, 
        [Parameter(Mandatory = $false, Position = 1)]
        [String[]]$Extension = @('.jpg', '.gif')
    )

     
    # Get folder list
    $Folders = @()
    $Duration = Measure-Command { 
        $Source | ForEach-Object { $Folders += (Get-ChildItem -Path $Source -Recurse -Directory -Force).FullName }
    }
    Write-Verbose "Got '$($Folders.Count)' folder(s) in $($Duration.Minutes):$($Duration.Seconds) mm:ss"
    $Folders += $Source

    $Images = @()

    Add-Type -AssemblyName System.Windows.Forms

    $Folders | ForEach-Object {

        if ($_ -ne 0)
        {
            foreach ($File in Get-ChildItem $_)
            { 
                if ($File.Extension -in $Extension)
                {
                    $objImage = [System.Drawing.Image]::FromFile($File.FullName)
                    $objFileInfo = [System.IO.FileInfo]::new($File.FullName)

                    Write-Verbose "Processing file '$($File.Path)'"
                    $Props = [ordered]@{
                        Name          = $File.Name
                        FullName      = $File.FullName
                        Size          = $objFileInfo.Length
                        #Type          = $objFileInfo.
                        Extension     = $File.Extension
                        DateCreated   = $File.DateCreated
                        DateModified  = $File.DateModified
                        DateAccessed  = $File.DateAccessed
                        DateTaken     = $objImage.DateTaken
                        CameraModel   = $objImage.CameraModel
                        CameraMaker   = $objImage.CameraMaker
                        BitDepth      = [int]$objImage.BitDepth
                        HorizontalRes = $objImage.HorizontalRes
                        VerticalRes   = $objImage.VerticalRes
                        Width         = $objImage.Width
                        Height        = $objImage.Height
                    }

                    $Images += New-Object -TypeName psobject -Property $Props

                } # if $Extension

            } # foreach $File
        }

    } # foreach $Folder
    $Images

} # function

$Images = Get-Images -Source "C:\Users\mattiassich\Pictures\Windows Spotlight"  
$Images | Select-Object Name,Width,Height |
    Format-Table
    #Where-Object {$_.Width -eq 1080} |  
    #Remove-item -Path $_.FullName 