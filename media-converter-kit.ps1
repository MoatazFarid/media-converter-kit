<#
.SYNOPSIS
    Media Converter Kit: Converts MKV, MP4, OGG, and MOV files to MP3 audio format.

.DESCRIPTION
    This script uses FFmpeg to extract audio from MKV, MP4, OGG, and MOV files and convert them to MP3 format.
    It can process a single file, multiple files, or all supported files in a directory.

.PARAMETER InputPath
    Path to a media file (MKV, MP4, OGG, MOV) or directory containing media files.

.PARAMETER OutputPath
    Optional. Directory where MP3 files will be saved. Defaults to same location as input.

.PARAMETER Bitrate
    Audio bitrate for MP3 output. Default is 192k. Common values: 128k, 192k, 256k, 320k.

.PARAMETER Recursive
    If specified, searches subdirectories for media files.

.EXAMPLE
    .\media-converter-kit.ps1 -InputPath "C:\Videos\movie.mkv"
    Converts a single MKV file to MP3.

.EXAMPLE
    .\media-converter-kit.ps1 -InputPath "C:\Media\audio.ogg"
    Converts a single OGG file to MP3.

.EXAMPLE
    .\media-converter-kit.ps1 -InputPath "C:\Videos\clip.mov"
    Converts a single MOV file to MP3.

.EXAMPLE
    .\media-converter-kit.ps1 -InputPath "C:\Videos" -Bitrate 320k
    Converts all MKV, MP4, OGG, and MOV files in the directory to MP3 with 320k bitrate.

.EXAMPLE
    .\media-converter-kit.ps1 -InputPath "C:\Videos" -OutputPath "C:\Music" -Recursive
    Converts all supported files (including subdirectories) to MP3 and saves to C:\Music.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Path to media file (MKV, MP4, OGG, MOV) or directory")]
    [string]$InputPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Bitrate = "192k",
    
    [Parameter(Mandatory=$false)]
    [switch]$Recursive
)

# Function to check if FFmpeg is installed
function Test-FFmpegInstalled {
    try {
        $ffmpegVersion = & ffmpeg -version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] FFmpeg detected" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "[FAIL] FFmpeg is not installed or not in PATH" -ForegroundColor Red
        Write-Host "`nPlease install FFmpeg:" -ForegroundColor Yellow
        Write-Host "  1. Download from: https://ffmpeg.org/download.html" -ForegroundColor Cyan
        Write-Host "  2. Or install via Chocolatey: choco install ffmpeg" -ForegroundColor Cyan
        Write-Host "  3. Or install via Scoop: scoop install ffmpeg" -ForegroundColor Cyan
        return $false
    }
}

# Supported file extensions
$supportedExtensions = @("*.mkv", "*.mp4", "*.ogg", "*.mov")

# Function to convert single media file to MP3
function Convert-ToMp3 {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$Bitrate
    )
    
    Write-Host "`nConverting: $InputFile" -ForegroundColor Cyan
    Write-Host "Output: $OutputFile" -ForegroundColor Cyan
    
    try {
        # FFmpeg command to extract audio and convert to MP3
        # -i: input file
        # -vn: disable video
        # -acodec: audio codec (libmp3lame for MP3)
        # -b:a: audio bitrate
        # -y: overwrite output file if exists
        & ffmpeg -i $InputFile -vn -acodec libmp3lame -b:a $Bitrate -y $OutputFile 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
            $outputSize = (Get-Item $OutputFile).Length / 1MB
            Write-Host "[OK] Success! Output size: $([math]::Round($outputSize, 2)) MB" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[FAIL] Conversion failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[FAIL] Error: $_" -ForegroundColor Red
        return $false
    }
}

# Main script execution
Write-Host "==================================" -ForegroundColor Magenta
Write-Host "  Media Converter Kit" -ForegroundColor Magenta
Write-Host "  (MKV, MP4, OGG, MOV -> MP3)" -ForegroundColor Magenta
Write-Host "==================================" -ForegroundColor Magenta
Write-Host "   ____                                 _            " -ForegroundColor DarkCyan
Write-Host "  / ___|___  _ ____   _____ _ __ _ __ | |_ ___ _ __ " -ForegroundColor DarkCyan
Write-Host " | |   / _ \| '_ \ \ / / _ \ '__| '_ \| __/ _ \ '__|" -ForegroundColor DarkCyan
Write-Host " | |__| (_) | | | \ V /  __/ |  | |_) | ||  __/ |   " -ForegroundColor DarkCyan
Write-Host "  \____\___/|_| |_|\_/ \___|_|  | .__/ \__\___|_|   " -ForegroundColor DarkCyan
Write-Host "                                 |_|                 " -ForegroundColor DarkCyan
Write-Host "                              converter              " -ForegroundColor DarkCyan

# Check if FFmpeg is installed
if (-not (Test-FFmpegInstalled)) {
    exit 1
}

# Validate input path
if (-not (Test-Path $InputPath)) {
    Write-Host "`n[FAIL] Error: Input path does not exist: $InputPath" -ForegroundColor Red
    exit 1
}

# Determine if input is file or directory
$isDirectory = (Get-Item $InputPath) -is [System.IO.DirectoryInfo]

# Get list of media files
$mediaFiles = @()
if ($isDirectory) {
    foreach ($ext in $supportedExtensions) {
        if ($Recursive) {
            $mediaFiles += Get-ChildItem -Path $InputPath -Filter $ext -Recurse -File
        }
        else {
            $mediaFiles += Get-ChildItem -Path $InputPath -Filter $ext -File
        }
    }

    if ($mediaFiles.Count -eq 0) {
        Write-Host "`n[FAIL] No supported files (MKV, MP4, OGG, MOV) found in: $InputPath" -ForegroundColor Red
        exit 1
    }

    Write-Host "`nFound $($mediaFiles.Count) media file(s)" -ForegroundColor Yellow
}
else {
    $fileExt = [System.IO.Path]::GetExtension($InputPath).ToLower()
    if ($fileExt -notin @(".mkv", ".mp4", ".ogg", ".mov")) {
        Write-Host "`n[FAIL] Error: Input file must be an MKV, MP4, OGG, or MOV file" -ForegroundColor Red
        exit 1
    }
    $mediaFiles = @(Get-Item $InputPath)
}

# Set output directory
if ($OutputPath -eq "") {
    if ($isDirectory) {
        $OutputPath = $InputPath
    }
    else {
        $OutputPath = Split-Path $InputPath -Parent
    }
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "[OK] Created output directory: $OutputPath" -ForegroundColor Green
}

Write-Host "`nSettings:" -ForegroundColor Yellow
Write-Host "  Bitrate: $Bitrate" -ForegroundColor White
Write-Host "  Output Directory: $OutputPath" -ForegroundColor White

# Convert files
$successCount = 0
$failCount = 0
$totalFiles = $mediaFiles.Count

for ($i = 0; $i -lt $totalFiles; $i++) {
    $file = $mediaFiles[$i]
    $progress = [math]::Round((($i + 1) / $totalFiles) * 100, 1)
    
    Write-Host "`n[$($i + 1)/$totalFiles - $progress%]" -ForegroundColor Yellow
    
    # Generate output filename
    $outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + ".mp3"
    $outputFilePath = Join-Path $OutputPath $outputFileName
    
    # Convert file
    if (Convert-ToMp3 -InputFile $file.FullName -OutputFile $outputFilePath -Bitrate $Bitrate) {
        $successCount++
    }
    else {
        $failCount++
    }
}

# Summary
Write-Host "`n==================================" -ForegroundColor Magenta
Write-Host "  Conversion Complete" -ForegroundColor Magenta
Write-Host "==================================" -ForegroundColor Magenta
Write-Host "Total files: $totalFiles" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red

if ($successCount -gt 0) {
    Write-Host "`n[OK] MP3 files saved to: $OutputPath" -ForegroundColor Green
}

exit 0

