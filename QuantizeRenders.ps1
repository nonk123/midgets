$outputPath = $Args[0]

$palettePath = "$outputPath\..\..\sprites\Palette.png"
$ditherMethod = 'None'

$files = Get-ChildItem -Recurse -Path $outputPath

foreach ($file in $files) {
    if ($file -is [System.IO.FileInfo]) {
        $fileName = $file.FullName

        if ($fileName -like '*.png') {
            magick $fileName -dither $ditherMethod -remap $palettePath $fileName
        }
    }
}
