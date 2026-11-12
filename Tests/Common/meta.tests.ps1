# ==============================================================================
# Filename: Meta.Tests.ps1
# Version:  0.1.0 | Updated: 2026-05-20
# Author:   johnsarie27
# ==============================================================================

BeforeDiscovery {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent

    $script:sourceFiles = Get-ChildItem -Path $projectRoot -Recurse -File -Include '*.ps1', '*.psm1', '*.psd1' |
        Where-Object -FilterScript {
            $_.FullName -notmatch '[\\/](Staging|Artifacts|\.git)[\\/]'
        } |
        ForEach-Object -Process { @{ Path = $_.FullName; Name = $_.FullName.Substring($projectRoot.Length + 1) } }
}

Describe 'File encoding and indentation: <Name>' -ForEach $script:sourceFiles {
    It 'is UTF-8 without BOM' {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -ge 3) {
            $hasBom = $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
            $hasBom | Should -BeFalse -Because 'PowerShell files must be UTF-8 without BOM'
        }
    }

    It 'contains no tab characters' {
        $content = [System.IO.File]::ReadAllText($Path)
        $content | Should -Not -Match "`t" -Because '4-space indentation only; no tabs'
    }
}
