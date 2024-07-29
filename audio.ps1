# function: convert .m4s files to MP3 format
# date: 2024.07.24
# author: aiwting
# define output directory
$folderPath = "$PWD\music"r
if ((Test-Path -Path $folderPath -PathType Container)) {
    Remove-Item $folderPath
}
# get foldernames
$folderNames = @(' ')
$music = @()
$invalidChars = '[\\/:*?"<>|\0-\x1F\x7F]'
$folderNames += Get-ChildItem -Path $PWD -Directory | Select-Object -ExpandProperty Name
$folderNames | ForEach-Object { echo $_ } #show the folders
Write-Host ($folderNames.Length - 1) "audios were found"
Write-Host "Press any key to continue..." -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
mkdir $folderPath # create output directory
for ($i = 1; $i -lt $folderNames.Length; $i++) {
    $folderName = $folderNames[$i]
    cd ".\$folderName"
    # get audio titles
    $infor = Select-String -Path .\videoInfo.json -Pattern 'title'
    $pattern = 'title":"(.*?)","duration'
    if ($infor -match $pattern) {
        $name = $Matches[1] # $Matches is an automatic variable
    }
    $name = $name -replace $invalidChars, '' # delete illegal characters
    Write-Output $name
    # get m4s format files
    $fileNames = Get-ChildItem -Filter *.m4s | Select-Object -ExpandProperty Name
    # modify m4s files
    for ($j = 0; $j -lt 2; $j++) {
        $fileName = $fileNames[$j]
        $fileName = "$PWD\$fileName"
        # read m4s files as binary format and delete useless partial
        $bytes = [System.IO.File]::ReadAllBytes("$fileName")
        $newBytes = New-Object byte[] ($bytes.Length - 9)
        [array]::Copy($bytes, 9, $newBytes, 0, $newBytes.Length)
        [System.IO.File]::WriteAllBytes("$fileName", $newBytes)
        # identify m4s files audio or video
        ffprobe -v error -show_streams -print_format json $fileName > .\identify
        $identify = Select-String -Path .\identify -Pattern 'codec_type'
        $pattern3 = 'codec_type": "(.*?)"'
        if ($identify -match $pattern3) {  
            $type = $Matches[1] # $Matches is an automatic variable
        }
        # convert to mp3 format 
        if ($type -eq "audio") {
            ffmpeg -i $fileName -vn -ar 44100 -ab 128k -ac 2 ..\music\$name.mp3
            # output compressed mp3 format, each song occupy 3MB, you can also output other format
        }
        ri .\identify
    }
    $music += $name
    cd ..\
}
Write-Host ($folderNames.Length -1) "audios were successfully converted:"
$music | ForEach-Object { echo $_ }