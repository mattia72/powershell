function HasText([System.Array]$content, [string]$text) {
    foreach ($line in $content) {
        if ($line.Contains($text)) {
            return $line
        }
    }
    return ""
}
function CollectFiles($fileInfo) {
    if ($_.GetType().Name -ne 'FileInfo') {
        return # i.e. reject DirectoryInfo and other types
    }
    
}
function ReplaceText($fileInfo) {
    begin {}
    process {
        if ($_.GetType().Name -ne 'FileInfo') {
            return # i.e. reject DirectoryInfo and other types
        }
        
        $old = 'old text' #'my old text regexp'
        $new = 'new text' #'my new text'
    
        $content = Get-Content $fileInfo.FullName
        $line = HasText $content $old  
        
        if (0 -ne $line.Length) {
            "Old text: " + $line
            $new_content = ($content | ForEach-Object {$_ -replace $old, $new} | Set-Content -path $fileInfo.FullName -passthru -confirm )
            "New text: " + (HasText $new_content $new)
            "Changed: " + $fileInfo.FullName
        }
        else {
            "Not Changed: " + $fileInfo.FullName
        }
    }
    end {}
}

Set-Location $dir

Get-ChildItem . -recurse | Where-Object {$_.Name -like "*.xml"} | ForEach-Object { ReplaceText( $_ ) }