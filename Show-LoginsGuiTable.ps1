<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    GuiTable
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(400,400)
$Form.text                       = "Form"
$Form.TopMost                    = $true

$ListView1                       = New-Object system.Windows.Forms.ListView
$ListView1.text                  = "listView"
$ListView1.width                 = 359
$ListView1.height                = 295
$ListView1.Anchor                = 'top,right,bottom,left'
$ListView1.location              = New-Object System.Drawing.Point(20,46)

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "&OK"
$Button1.width                   = 60
$Button1.height                  = 30
$Button1.Anchor                  = 'right,bottom'
$Button1.location                = New-Object System.Drawing.Point(320,355)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Table content:"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(25,17)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)


$Form.controls.AddRange(@($ListView1,$Button1,$Label1))

$Button1.Add_Click({ Btn1_OnClick })
$Form.KeyPreview                 = $true
$Form.Add_KeyDown({ Form_OnKeyDown $this $_})

function Form_OnKeyDown ( [object] $s, [System.Windows.Forms.KeyEventArgs] $e)
{ 
  if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape)
  {
    $Form.Close()
  }
}

function Btn1_OnClick 
{ 
    $Form.Close()
}

function Set-ListViewContent() 
{
  $ListView1.View = [System.Windows.Forms.View]::Details

  Import-Module -Name Get-LogonEvents -Force 

  $header1 = New-Object System.Windows.Forms.ColumnHeader(0);
  $header1.Text = "Logon"
  $header1.Width = 0
  $ListView1.Columns.Add($header1) | Out-Null

  Get-LogonEvents | Get-Member -MemberType NoteProperty | ForEach-Object {
    # -2 autosize
    $ListView1.Columns.Add($_.Name, -2 , [System.Windows.Forms.HorizontalAlignment]::Left)
  } | Out-Null
  $i = 0
  Get-LogonEvents | ForEach-Object { 
    try {
      if ($_ -ne $null) 
      {
        $item = New-Object System.Windows.Forms.ListViewItem("Logon $i", $i++)
        $item.SubItems.Add($_.Date.ToString())
        $item.SubItems.Add($_.Elapsed.ToString())
        $item.SubItems.Add($_.Login)
        $item.SubItems.Add($_.LoginTime ? $_.LoginTime.ToString() : "")
        $item.SubItems.Add($_.Logout)
        $item.SubItems.Add($_.LogoutTime ? $_.LogoutTime.ToString() : "")
        $ListView1.Items.Add($item) 
      }
    }
    catch {
      Write-Error "Exception occured: $($_.Exception.Message)`n$($_.Exception.StackTrace)" 
    }
  } | Out-Null
}

function Set-ButtonIcon ($btn, $iconpath)
{
  $Icon1 = [System.Drawing.Icon]::ExtractAssociatedIcon($iconpath)
# $Icon1 = New-Object System.Drawing.Icon([System.Drawing.SystemIcons]::Exclamation, 40, 40);
  $ImageList= New-Object System.Windows.Forms.ImageList
  $ImageList.Images.Add("OK",$Icon1.ToBitmap())
  $btn.ImageList = $ImageList
  $btn.ImageIndex = 0
  $btn.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft    
  $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
  $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
}

Set-ButtonIcon $Button1 "C:\Windows\System32\notepad.exe"
Set-ListViewContent

[void]$Form.ShowDialog()