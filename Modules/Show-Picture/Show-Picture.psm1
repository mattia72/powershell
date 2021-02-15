
<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    ShowPicture
#>
function Show-Picture {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true )]
    [System.Drawing.Image] $Image
  )

  begin {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $Form = New-Object system.Windows.Forms.Form
    $Form.ClientSize = New-Object System.Drawing.Point(206, 195)
    $Form.text = "Form"
    $Form.TopMost = $false

    $PictureBox1 = New-Object system.Windows.Forms.PictureBox
    $PictureBox1.width = 167
    $PictureBox1.height = 159
    $PictureBox1.Anchor = 'top,right,bottom,left'
    $PictureBox1.location = New-Object System.Drawing.Point(18, 15)
    $PictureBox1.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $PictureBox1.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $Form.controls.AddRange(@($PictureBox1))
  }
  process {
    $PictureBox1.Image = $Image
    $Form.ShowDialog()
  }
  end {
  }
}
Export-ModuleMember -Function Show-Picture 