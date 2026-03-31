<#
.SYNOPSIS
    Pester unit tests for media-converter-kit.ps1

.DESCRIPTION
    Tests verify that the script:
      - Identifies and converts single MKV, MP4, and OGG files to MP3
      - Processes all supported files in a flat directory
      - Processes all supported files recursively when -Recursive is used

    Compatibility
    -------------
    Written for Pester 3.4 (bundled with Windows PowerShell 5.1). In Pester 3,
    BeforeAll/AfterAll must be inside a Describe block, so all tests live under
    one outer Describe that owns the shared setup and teardown.

    Strategy
    --------
    The script calls `exit`, which would terminate the Pester host if invoked
    in-process. Each test therefore runs the script in a PowerShell subprocess
    via `powershell -File` / `pwsh -File`.

    A mock `ffmpeg.cmd` is injected at the front of $env:PATH. It locates the
    output file by scanning for the `-y` flag (the argument that immediately
    precedes the output path in every ffmpeg call made by the script), creates
    that file, and exits with code 0. This satisfies both conditions checked by
    Convert-ToMp3: ($LASTEXITCODE -eq 0) -and (Test-Path $OutputFile).
#>

# ── Helper ────────────────────────────────────────────────────────────────────
# Runs the script under test in a subprocess and returns the exit code.
function Invoke-ConverterScript {
    param(
        [string] $InputPath,
        [string] $OutputPath,
        [switch] $Recursive
    )
    $argList = @(
        '-NoProfile'
        '-ExecutionPolicy', 'Bypass'
        '-File', $script:ScriptPath
        '-InputPath',  $InputPath
        '-OutputPath', $OutputPath
    )
    if ($Recursive) { $argList += '-Recursive' }

    & $script:PSExe @argList | Out-Null
    return $LASTEXITCODE
}

# =============================================================================
Describe 'Media Converter Kit' {

    BeforeAll {
        # ── Paths ─────────────────────────────────────────────────────────────
        $script:OriginalPath = $env:PATH
        $script:ScriptPath   = Join-Path $PSScriptRoot '..\media-converter-kit.ps1'
        # Use pwsh when running under PowerShell 7+, powershell for Windows PS 5.1
        $script:PSExe = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }

        # ── Mock ffmpeg ────────────────────────────────────────────────────────
        # Create a temporary bin directory and write ffmpeg.cmd into it.
        # The batch file walks the argument list looking for the -y flag; the
        # very next argument is the output file path. It creates that file
        # (simulating a successful conversion) and exits 0.
        $script:MockBinDir = Join-Path $TestDrive 'bin'
        New-Item -ItemType Directory -Path $script:MockBinDir -Force | Out-Null

        $mockFfmpegContent = @'
@echo off
setlocal enabledelayedexpansion
set "outfile="
:parse
if "%~1"=="" goto create_file
if /i "%~1"=="-y" (
    set "outfile=%~2"
    goto create_file
)
shift
goto parse
:create_file
if defined outfile (
    type nul > "!outfile!"
)
exit /b 0
'@
        Set-Content -Path (Join-Path $script:MockBinDir 'ffmpeg.cmd') `
                    -Value $mockFfmpegContent

        # Prepend mock bin directory so it shadows any real ffmpeg installation.
        # Child processes inherit this modified PATH automatically.
        $env:PATH = "$($script:MockBinDir);$env:PATH"
    }

    AfterAll {
        $env:PATH = $script:OriginalPath
    }

    # ── Single file conversion ─────────────────────────────────────────────────

    Context 'Single MKV file' {
        It 'Correctly identifies and converts a single MKV file to MP3' {
            $inputDir  = Join-Path $TestDrive 'single-mkv-in'
            $outputDir = Join-Path $TestDrive 'single-mkv-out'
            New-Item -ItemType Directory -Path $inputDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $inputDir 'sample.mkv') -Force | Out-Null

            Invoke-ConverterScript -InputPath (Join-Path $inputDir 'sample.mkv') `
                                   -OutputPath $outputDir

            Join-Path $outputDir 'sample.mp3' | Should Exist
        }
    }

    Context 'Single MP4 file' {
        It 'Correctly identifies and converts a single MP4 file to MP3' {
            $inputDir  = Join-Path $TestDrive 'single-mp4-in'
            $outputDir = Join-Path $TestDrive 'single-mp4-out'
            New-Item -ItemType Directory -Path $inputDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $inputDir 'sample.mp4') -Force | Out-Null

            Invoke-ConverterScript -InputPath (Join-Path $inputDir 'sample.mp4') `
                                   -OutputPath $outputDir

            Join-Path $outputDir 'sample.mp3' | Should Exist
        }
    }

    Context 'Single OGG file' {
        It 'Correctly identifies and converts a single OGG file to MP3' {
            $inputDir  = Join-Path $TestDrive 'single-ogg-in'
            $outputDir = Join-Path $TestDrive 'single-ogg-out'
            New-Item -ItemType Directory -Path $inputDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $inputDir 'sample.ogg') -Force | Out-Null

            Invoke-ConverterScript -InputPath (Join-Path $inputDir 'sample.ogg') `
                                   -OutputPath $outputDir

            Join-Path $outputDir 'sample.mp3' | Should Exist
        }
    }

    # ── Directory processing ───────────────────────────────────────────────────

    Context 'Flat directory (no -Recursive)' {
        It 'Correctly processes all supported files in a given directory' {
            $inputDir  = Join-Path $TestDrive 'dir-flat-in'
            $outputDir = Join-Path $TestDrive 'dir-flat-out'
            New-Item -ItemType Directory -Path $inputDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $inputDir 'clip.mkv')  -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $inputDir 'movie.mp4') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $inputDir 'track.ogg') -Force | Out-Null

            Invoke-ConverterScript -InputPath $inputDir -OutputPath $outputDir

            Join-Path $outputDir 'clip.mp3'  | Should Exist
            Join-Path $outputDir 'movie.mp3' | Should Exist
            Join-Path $outputDir 'track.mp3' | Should Exist
        }
    }

    Context 'Recursive directory scan (-Recursive flag)' {
        It 'Correctly processes all supported files in a directory and its subdirectories when -Recursive is used' {
            $inputDir  = Join-Path $TestDrive 'dir-recursive-in'
            $subDir    = Join-Path $inputDir  'subdir'
            $subSubDir = Join-Path $subDir    'nested'
            $outputDir = Join-Path $TestDrive 'dir-recursive-out'
            New-Item -ItemType Directory -Path $subSubDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $inputDir  'root.mkv') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $subDir    'sub.mp4')  -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $subSubDir 'deep.ogg') -Force | Out-Null

            Invoke-ConverterScript -InputPath $inputDir -OutputPath $outputDir -Recursive

            # The script writes all converted files flat into OutputPath regardless
            # of how deeply nested the source file was.
            Join-Path $outputDir 'root.mp3' | Should Exist
            Join-Path $outputDir 'sub.mp3'  | Should Exist
            Join-Path $outputDir 'deep.mp3' | Should Exist
        }
    }
}
