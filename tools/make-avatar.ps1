# Draws the FavoriteItems heart (the same design as Media\Heart.tga, the 32x32
# in-game icon) at any size, for the CurseForge project avatar.
# Usage: .\tools\make-avatar.ps1 -Size 400 -Png curseforge\avatar.png
param(
    [int]$Size = 400,
    [Parameter(Mandatory)][string]$Png
)
Add-Type -AssemblyName System.Drawing

$s = $Size / 32.0   # the design is laid out on the icon's 32x32 grid
function Argb([int]$a, [int]$r, [int]$g, [int]$b) { [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }
function Pt([double]$x, [double]$y) { New-Object System.Drawing.PointF ([float]($x*$s)), ([float]($y*$s)) }

$bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.PixelOffsetMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::Transparent)

# heart outline: two lobes meeting at a dip at (16,5.5), point at (16,29)
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddBezier((Pt 16 29), (Pt 10 23.5), (Pt 1.5 17), (Pt 1.5 10))
$path.AddBezier((Pt 1.5 10), (Pt 1.5 4.5), (Pt 5.5 1.5), (Pt 9 1.5))
$path.AddBezier((Pt 9 1.5), (Pt 12.5 1.5), (Pt 15 3.5), (Pt 16 5.5))
$path.AddBezier((Pt 16 5.5), (Pt 17 3.5), (Pt 19.5 1.5), (Pt 23 1.5))
$path.AddBezier((Pt 23 1.5), (Pt 26.5 1.5), (Pt 30.5 4.5), (Pt 30.5 10))
$path.AddBezier((Pt 30.5 10), (Pt 30.5 17), (Pt 22 23.5), (Pt 16 29))
$path.CloseFigure()

# fill: bright pink-red at the top to deeper red at the point
$fill = New-Object System.Drawing.Drawing2D.LinearGradientBrush (Pt 0 1), (Pt 0 29), (Argb 255 246 52 90), (Argb 255 200 30 58)
$g.FillPath($fill, $path)

# dark wine outline
$pen = New-Object System.Drawing.Pen (Argb 255 63 5 15), ([float](1.6*$s))
$pen.LineJoin = 'Round'
$g.DrawPath($pen, $path)

# glossy highlight on the left lobe
$hl = New-Object System.Drawing.RectangleF ([float](8*$s)), ([float](6.5*$s)), ([float](4.4*$s)), ([float](5.2*$s))
$glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$glowPath.AddEllipse($hl)
$glow = New-Object System.Drawing.Drawing2D.PathGradientBrush $glowPath
$glow.CenterColor = Argb 255 255 236 240
$glow.SurroundColors = @((Argb 200 252 200 210))
$g.FillEllipse($glow, $hl)

$g.Dispose()
$dir = Split-Path -Parent ([System.IO.Path]::GetFullPath($Png))
if ($dir) { New-Item -ItemType Directory -Force $dir | Out-Null }
$bmp.Save([System.IO.Path]::GetFullPath($Png), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"Wrote $Png"
