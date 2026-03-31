# Media Converter Kit

Media Converter Kit is a PowerShell utility that converts media files to MP3 using FFmpeg.

Supported input formats:
- MKV (`.mkv`)
- MP4 (`.mp4`)
- OGG (`.ogg`)

Output format:
- MP3 (`.mp3`)

## Features

- Convert a single file to MP3
- Convert all supported files in a folder
- Optional recursive folder scanning
- Custom output directory
- Configurable MP3 bitrate (default `192k`)

## Requirements

- Windows PowerShell 5.1+ (or PowerShell 7+)
- FFmpeg installed and available in your `PATH`

### Install FFmpeg

- Download: `https://ffmpeg.org/download.html`
- Chocolatey: `choco install ffmpeg`
- Scoop: `scoop install ffmpeg`

## Script

- [`media-converter-kit.ps1`](/D:/scripts/mkvtomp3/media-converter-kit.ps1)

## Usage

```powershell
.\media-converter-kit.ps1 -InputPath <path> [-OutputPath <path>] [-Bitrate <value>] [-Recursive]
```

## Parameters

- `-InputPath` (required): Path to a media file or directory.
- `-OutputPath` (optional): Directory for output MP3 files.  
  Default: same location as input.
- `-Bitrate` (optional): MP3 bitrate (examples: `128k`, `192k`, `256k`, `320k`).  
  Default: `192k`.
- `-Recursive` (optional switch): Search subdirectories when `InputPath` is a directory.

## Examples

Convert one MKV file:

```powershell
.\media-converter-kit.ps1 -InputPath "C:\Videos\movie.mkv"
```

Convert one OGG file:

```powershell
.\media-converter-kit.ps1 -InputPath "C:\Media\audio.ogg"
```

Convert all supported files in a folder with 320k bitrate:

```powershell
.\media-converter-kit.ps1 -InputPath "C:\Videos" -Bitrate 320k
```

Convert folder recursively and write MP3 files to a different directory:

```powershell
.\media-converter-kit.ps1 -InputPath "C:\Videos" -OutputPath "C:\Music" -Recursive
```

## Notes

- Existing output files are overwritten automatically.
- If FFmpeg is missing, the script prints install instructions and exits.
- The script prints a conversion summary: total, successful, and failed files.

## Troubleshooting

- `ffmpeg is not installed or not in PATH`:
  Install FFmpeg, then restart your terminal and run:
  ```powershell
  ffmpeg -version
  ```

- `running scripts is disabled on this system`:
  Run PowerShell as Administrator and allow local scripts:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

- `Input path does not exist`:
  Verify the full path is correct and quoted if it contains spaces:
  ```powershell
  .\media-converter-kit.ps1 -InputPath "C:\My Videos\input.mkv"
  ```

- No files found in a folder:
  Ensure the folder contains `.mkv`, `.mp4`, or `.ogg` files, and add `-Recursive` for nested folders.

- Output not in expected location:
  Use `-OutputPath` explicitly to control where MP3 files are written.

- Conversion failed for specific files:
  The source file may be corrupted or encoded with unsupported streams. Try converting that file directly with FFmpeg to inspect the full error:
  ```powershell
  ffmpeg -i "C:\path\file.mkv" -vn -acodec libmp3lame -b:a 192k "C:\path\file.mp3"
  ```
