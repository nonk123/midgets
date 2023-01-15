$palettePath = 'sprites/Palette.png'
$ditherMethod = 'None'

$files = Get-ChildItem -Recurse -Path 'models/renders'

foreach ($file in $files) {
    $fileName = $file.FullName
    magick $fileName -dither $ditherMethod -remap $palettePath $fileName
}
