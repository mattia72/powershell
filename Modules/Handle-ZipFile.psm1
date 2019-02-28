function Create-Zip
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[string] $SourceDirectory, 
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [string] $DestinationDirectory,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [string] $ZipName
        )
    begin
    {
        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    }
	process
	{
		$ZipFile = $DestinationDirectory 
		if ( $ZipName -ne $null) {
			$ZipFile = $(Join-Path $DestinationDirectory $ZipName)
		}
		Write-Output "Create zip archive from ${SourceDirectory}`nto ${ZipFile}..."
		[System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDirectory, $ZipFile)
		Write-Output "Create zip finished to`n${ZipFile}..."
    }
}          
function Restore-AllFromZip
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFile, 
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [object] $DestinationDirectory
        )
    begin
    {
        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    }
	process
	{

	    switch -wildcard ($ZipFile)
	    {
		    '*.7z'
		    {
			    if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) 
			    {
				    throw "Error: $env:ProgramFiles\7-Zip\7z.exe not exists!"
			    }
			    set-alias sevenZip "$env:ProgramFiles\7-Zip\7z.exe"
			    Write-Output "Extract 7zip archive ${ZipFile}`nto ${DestinationDirectory}..."
			    sevenZip x -o"${DestinationDirectory}" $ZipFile
			    Write-Output "7zip finished extracting`n${ZipFile} to`n${DestinationDirectory}..."
		    }
		    '*.zip'
		    {
			    Write-Output "Extract zip archive ${ZipFile}`nto ${DestinationDirectory}..."
		   	    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $DestinationDirectory)
			    Write-Output "Extracting finished `n${ZipFile} to`n${DestinationDirectory}..."
		    }
		    default {Write-Error "$ZipFile is not a zip file!" }
	    }
    }
}          

function Restore-FileFromZip
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFile, 
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[string] $EntryName,
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [object] $DestinationDirectory
        )
    begin
    {
        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    }
	process
	{
	   	$ZipArchive = [System.IO.Compression.ZipFile]::Open($ZipFile, "Read")
		$destinationPath = Join-Path $DestinationDirectory $EntryName
		[System.IO.Compression.ZipFileExtensions]::ExtractToFile($ZipArchive, $destinationPath)
    }
}

function Get-ZipEntries
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFile
        )
    begin
    {
        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    }
	process
	{
   	    $ZipFile = [System.IO.Compression.ZipFile]::Open($ZipFile, "Read")
	    $ZipFile.Entries
    }
}

function Get-ZipEntry
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFile, 
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[string] $EntryName)
	process
	{
		$ZipArchive = [System.IO.Compression.ZipFile]::Open($ZipFile, "Read")
		$ZipEntry = $ZipArchive.GetEntry($EntryName)
		if (!$ZipEntry) 
		{
			Write-Error "$ZipFile doesn't contain $EntryName"
			return
		}

        $ZipEntry
	}
}

function Get-DotNetZipZipEntry
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFilePath, 
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[string] $EntryPath)
	process
	{
        [System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\Ionic.Zip.dll") 
        $ZipFile = new-object Ionic.Zip.ZipFile($ZipFilePath) | Out-Null
        $ZipEntry = $($ZipFile.Entries | Where-Object FileName -match "$EntryPath$")
        return $ZipEntry
	}
}


function Get-DotNetZipZipEntries
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFilePath)
	process
	{
        [System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\Ionic.Zip.dll") 
        $ZipFile = new-object Ionic.Zip.ZipFile($ZipFilePath)
        return $($ZipFile.Entries)
	}
}

Export-ModuleMember -Function Restore-AllFromZip, Get-ZipEntries, Restore-FileFromZip, Get-ZipEntry, Get-DotNetZipZipEntry, Get-DotNetZipZipEntries, Create-Zip
