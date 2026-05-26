$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = 'C:\Users\ziyad\OneDrive\Desktop\events\events\devent\devent'
$sourceDir = Join-Path $root 'assets\branding'
New-Item -ItemType Directory -Force -Path $sourceDir | Out-Null

function New-RoundedRectPath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $Radius * 2
    $path.AddArc($X, $Y, $d, $d, 180, 90)
    $path.AddArc($X + $Width - $d, $Y, $d, $d, 270, 90)
    $path.AddArc($X + $Width - $d, $Y + $Height - $d, $d, $d, 0, 90)
    $path.AddArc($X, $Y + $Height - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-DeventIconBitmap {
    param([int]$Size)

    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    try {
        $rect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $rect,
            [System.Drawing.ColorTranslator]::FromHtml('#050505'),
            [System.Drawing.ColorTranslator]::FromHtml('#1B1B1B'),
            90
        )
        $graphics.FillRectangle($bgBrush, $rect)

        $glowBrush1 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60, 255, 255, 255))
        $glowBrush2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(35, 255, 255, 255))
        $graphics.FillEllipse($glowBrush1, [int]($Size * 0.08), [int]($Size * 0.12), [int]($Size * 0.5), [int]($Size * 0.5))
        $graphics.FillEllipse($glowBrush2, [int]($Size * 0.44), [int]($Size * 0.42), [int]($Size * 0.42), [int]($Size * 0.42))

        $cardRect = New-Object System.Drawing.RectangleF ([float]($Size * 0.11)), ([float]($Size * 0.1)), ([float]($Size * 0.78)), ([float]($Size * 0.8))
        $cardPath = New-RoundedRectPath -X $cardRect.X -Y $cardRect.Y -Width $cardRect.Width -Height $cardRect.Height -Radius ([float]($Size * 0.09))
        $cardBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 245, 245, 245))
        $graphics.FillPath($cardBrush, $cardPath)

        $calendarRect = New-Object System.Drawing.RectangleF ([float]($Size * 0.18)), ([float]($Size * 0.19)), ([float]($Size * 0.64)), ([float]($Size * 0.62))
        $calendarPath = New-RoundedRectPath -X $calendarRect.X -Y $calendarRect.Y -Width $calendarRect.Width -Height $calendarRect.Height -Radius ([float]($Size * 0.06))
        $calBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        $graphics.FillPath($calBrush, $calendarPath)

        $headerRect = New-Object System.Drawing.RectangleF $calendarRect.X, $calendarRect.Y, $calendarRect.Width, ([float]($Size * 0.17))
        $headerPath = New-RoundedRectPath -X $headerRect.X -Y $headerRect.Y -Width $headerRect.Width -Height $headerRect.Height -Radius ([float]($Size * 0.06))
        $headerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 20, 20, 20))
        $graphics.FillPath($headerBrush, $headerPath)
        $graphics.FillRectangle($headerBrush, [int]$headerRect.X, [int]($headerRect.Y + $headerRect.Height/2), [int]$headerRect.Width, [int]($headerRect.Height/2 + 2))

        $ringBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 250, 250, 250))
        foreach ($x in @([float]($Size * 0.31), [float]($Size * 0.50), [float]($Size * 0.69))) {
            $graphics.FillEllipse($ringBrush, $x - ($Size * 0.02), ($Size * 0.255), ($Size * 0.04), ($Size * 0.04))
        }

        $lineBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 30, 30, 30))
        foreach ($y in @([float]($Size * 0.42), [float]($Size * 0.50), [float]($Size * 0.58))) {
            $lineRect = New-Object System.Drawing.RectangleF ([float]($Size * 0.27)), $y, ([float]($Size * 0.46)), ([float]($Size * 0.028))
            $linePath = New-RoundedRectPath -X $lineRect.X -Y $lineRect.Y -Width $lineRect.Width -Height $lineRect.Height -Radius ([float]($Size * 0.014))
            $graphics.FillPath($lineBrush, $linePath)
        }

        $pinBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        $pinInnerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245, 20, 20, 20))
        $pinX = [float]($Size * 0.63)
        $pinY = [float]($Size * 0.6)
        $graphics.FillEllipse($pinBrush, $pinX, $pinY, ([float]($Size * 0.09)), ([float]($Size * 0.09)))
        $graphics.FillEllipse($pinInnerBrush, $pinX + ([float]($Size * 0.023)), $pinY + ([float]($Size * 0.023)), ([float]($Size * 0.044)), ([float]($Size * 0.044)))

        $fontSize = [float]($Size * 0.28)
        $font = New-Object System.Drawing.Font('Arial Black', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $letterBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 20, 20, 20))
        $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(80, 0, 0, 0))
        $fmt = New-Object System.Drawing.StringFormat
        $fmt.Alignment = [System.Drawing.StringAlignment]::Center
        $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
        $letterRect = New-Object System.Drawing.RectangleF ([float]($Size * 0.21)), ([float]($Size * 0.33)), ([float]($Size * 0.58)), ([float]($Size * 0.36))
        $shadowRect = New-Object System.Drawing.RectangleF ($letterRect.X + ($Size * 0.008)), ($letterRect.Y + ($Size * 0.008)), $letterRect.Width, $letterRect.Height
        $graphics.DrawString('D', $font, $shadowBrush, $shadowRect, $fmt)
        $graphics.DrawString('D', $font, $letterBrush, $letterRect, $fmt)

        $outlinePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(35, 255, 255, 255)), 4
        $graphics.DrawPath($outlinePen, $cardPath)

        return $bmp
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
    }
}

$master = New-DeventIconBitmap -Size 1024
$sourcePath = Join-Path $sourceDir 'devent_app_icon.png'
$master.Save($sourcePath, [System.Drawing.Imaging.ImageFormat]::Png)

$targets = @(
    @{ Path = Join-Path $root 'android\app\src\main\res\mipmap-mdpi\ic_launcher.png'; Size = 48 },
    @{ Path = Join-Path $root 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png'; Size = 72 },
    @{ Path = Join-Path $root 'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png'; Size = 96 },
    @{ Path = Join-Path $root 'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png'; Size = 144 },
    @{ Path = Join-Path $root 'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png'; Size = 192 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png'; Size = 20 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png'; Size = 40 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png'; Size = 60 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png'; Size = 29 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png'; Size = 58 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png'; Size = 87 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png'; Size = 40 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png'; Size = 80 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png'; Size = 120 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png'; Size = 120 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png'; Size = 180 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png'; Size = 76 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png'; Size = 152 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png'; Size = 167 },
    @{ Path = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png'; Size = 1024 },
    @{ Path = Join-Path $root 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_16.png'; Size = 16 },
    @{ Path = Join-Path $root 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_32.png'; Size = 32 },
    @{ Path = Join-Path $root 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_64.png'; Size = 64 },
    @{ Path = Join-Path $root 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_128.png'; Size = 128 },
    @{ Path = Join-Path $root 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_256.png'; Size = 256 },
    @{ Path = Join-Path $root 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_512.png'; Size = 512 },
    @{ Path = Join-Path $root 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_1024.png'; Size = 1024 },
    @{ Path = Join-Path $root 'web\favicon.png'; Size = 48 },
    @{ Path = Join-Path $root 'web\icons\Icon-192.png'; Size = 192 },
    @{ Path = Join-Path $root 'web\icons\Icon-512.png'; Size = 512 },
    @{ Path = Join-Path $root 'web\icons\Icon-maskable-192.png'; Size = 192 },
    @{ Path = Join-Path $root 'web\icons\Icon-maskable-512.png'; Size = 512 }
)

foreach ($target in $targets) {
    $dir = Split-Path $target.Path
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $bmp = New-Object System.Drawing.Bitmap $target.Size, $target.Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($master, 0, 0, $target.Size, $target.Size)
        $bmp.Save($target.Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $g.Dispose()
        $bmp.Dispose()
    }
}

$master.Dispose()
Write-Output $sourcePath
