Add-Type -AssemblyName System.IO.Compression.FileSystem
$pptxPath = "C:\Users\hp\Downloads\CDC PROJECT SEC-L-1 (1).pptx"
$tempPath = "$env:TEMP\pptx_extract"
if (Test-Path $tempPath) { Remove-Item -Recurse -Force $tempPath }
[System.IO.Compression.ZipFile]::ExtractToDirectory($pptxPath, $tempPath)
$slidesPath = Join-Path $tempPath "ppt\slides"
$textOut = ""
if (Test-Path $slidesPath) {
    # Slides might not be in order, but that's okay for searching keywords
    $slides = Get-ChildItem -Path $slidesPath -Filter "*.xml" | Sort-Object Name
    foreach ($slide in $slides) {
        $xmlContent = Get-Content $slide.FullName -Raw
        $regex = [regex]'(?i)<a:t[^>]*>(.*?)</a:t>'
        $matches = $regex.Matches($xmlContent)
        foreach ($m in $matches) {
            $textOut += $m.Groups[1].Value + " "
        }
        $textOut += "`n`n--- Slide ---`n`n"
    }
}
Remove-Item -Recurse -Force $tempPath
Set-Content -Path "C:\Users\hp\change data capture\pptx_content.txt" -Value $textOut
Write-Host "Extraction complete."
