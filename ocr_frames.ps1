Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName Windows.Media.Ocr

$videoPath = "C:\Users\xinxin\Videos\屏幕录制\屏幕录制 2026-04-23 174538.mp4"
$framesDir = "c:\Users\xinxin\wifi-analyzer\frames"
$outputFile = "c:\Users\xinxin\wifi-analyzer\ocr_results.txt"

$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
if ($null -eq $engine) {
    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Media.Ocr.OcrLanguage]::En)
}

$frames = Get-ChildItem $framesDir -Filter "*.png" | Sort-Object Name
$allResults = @()

foreach ($frame in $frames) {
    Write-Host "Processing: $($frame.Name)"
    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $bitmap.UriSource = New-Object System.Uri($frame.FullName)
    $bitmap.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::None
    $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bitmap.EndInit()

    $ocrResult = $engine.RecognizeAsync($bitmap).GetAwaiter().GetResult()
    $lines = $ocrResult.Lines
    $text = ($lines | ForEach-Object { $_.Text }) -join "`n"
    $allResults += "=== $($frame.Name) ==="
    $allResults += $text
    $allResults += ""
}

$allResults | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Done. Output: $outputFile"
Write-Host ""
Write-Host "--- OCR Results ---"
Get-Content $outputFile
